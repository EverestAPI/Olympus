using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.IO;
using System.Net.Http;
using System.Text;

namespace Olympus {
    public class CmdGetModIdToNameMap : Cmd<string, bool, bool> {
        private static readonly Logger log = new Logger(nameof(CmdGetModIdToNameMap));

        public override bool Taskable => true;

        private static string cacheLocation;
        private static bool apiMirror;

        public override bool Run(string cacheLocation, bool apiMirror) {
            CmdGetModIdToNameMap.cacheLocation = cacheLocation;
            CmdGetModIdToNameMap.apiMirror = apiMirror;
            log.Debug($"Cache location set to: {cacheLocation}");
            GetModIDsToNamesMap(ignoreCache: true);
            return true;
        }

        private static readonly object locker = new object();

        internal static Dictionary<string, string> GetModIDsToNamesMap(bool ignoreCache = false) {
            Dictionary<string, string> map;

            if (!ignoreCache && File.Exists(cacheLocation)) {
                log.Debug($"Loading mod IDs from {cacheLocation}");
                map = tryRun(() => {
                    lock (locker)
                    using (Stream inputStream = new FileStream(cacheLocation, FileMode.Open)) {
                        return getModIDsToNamesMap(inputStream);
                    }
                });
                if (map.Count > 0) return map;
            }

            log.Debug($"[CmdGetIdToNameMap] Loading mod IDs from the Internet (apiMirror = {apiMirror})");
            map = tryRun(() => {
                using (HttpClient wc = new HttpClientWithCompressionSupport())
                using (Stream inputStream = wc.GetAsync(
                    apiMirror ? "https://everestapi.github.io/updatermirror/mod_ids_to_names.json" : "https://maddie480.ovh/celeste/mod_ids_to_names.json"
                ).Result.Content.ReadAsStream()) {
                    return getModIDsToNamesMap(inputStream);
                }
            });
            if (map.Count > 0) lock (locker) File.WriteAllText(cacheLocation, JsonConvert.SerializeObject(map));
            return map;
        }

        private static Dictionary<string, string> tryRun(Func<Dictionary<string, string>> function) {
            try {
                return function();
            } catch (Exception e) {
                log.Warning("Error loading mod IDs to names list: " + e);
                return new Dictionary<string, string>();
            }
        }

        private static Dictionary<string, string> getModIDsToNamesMap(Stream inputStream) {
            using (TextReader textReader = new StreamReader(inputStream, Encoding.UTF8))
            using (JsonTextReader jsonTextReader = new JsonTextReader(textReader)) {
                return new JsonSerializer().Deserialize<Dictionary<string, string>>(jsonTextReader);
            }
        }
    }
}
