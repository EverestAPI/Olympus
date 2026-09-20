using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;

namespace Olympus {
    // Fetches the GameBanana descriptions of installed mods, looked up by their
    // GameBanana title Descriptions come from the same search database that powers  
    // the mod browser.
    public class CmdGetModDescriptions : Cmd<string[], string[]> {
        private static readonly Logger log = new Logger(nameof(CmdGetModDescriptions));

        // GameBanana title -> description, built once per Sharp process.
        private static Dictionary<string, string> descriptionsByTitle;
        private static readonly object locker = new object();

        // The base Cmd<TInput, TOutput> parses inputs with JToken.Value<T>(), which
        // doesn't handle arrays; arrays need ToObject<T>() instead.
        public override object ParseInputTuple(JObject tuple) {
            if (!tuple.TryGetValue("Item1", out JToken value) || value.Type == JTokenType.Null)
                return new Tuple<string[]>(null);
            return new Tuple<string[]>(value.ToObject<string[]>());
        }

        public override string[] Run(string[] titles) {
            if (titles == null || titles.Length == 0)
                return new string[0];

            lock (locker) {
                if (descriptionsByTitle == null) {
                    Dictionary<string, string> map = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

                    foreach (Dictionary<string, object> entry in GameBananaAPIEmulator.Get()) {
                        if (entry == null || !entry.ContainsKey("Name") || !entry.ContainsKey("Description"))
                            continue;

                        string title = entry["Name"] as string;
                        string description = entry["Description"] as string;
                        if (string.IsNullOrEmpty(title) || string.IsNullOrEmpty(description) || map.ContainsKey(title))
                            continue;

                        map[title] = description;
                    }

                    log.Debug($"Loaded descriptions for {map.Count} mods from the GameBanana search database.");
                    descriptionsByTitle = map;
                }
            }

            string[] result = new string[titles.Length];
            for (int i = 0; i < titles.Length; i++) {
                string title = titles[i];
                // unknown mods stay as ""
                if (title != null && descriptionsByTitle.TryGetValue(title, out string description))
                    result[i] = description;
                else
                    result[i] = "";
            }

            return result;
        }
    }
}
