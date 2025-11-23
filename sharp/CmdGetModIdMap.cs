using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.IO;
using System.Net.Http;
using System.Text;

namespace Olympus {
    public class CmdGetModIdToNameMap : CmdGetModIdMap {
        internal static CmdGetModIdToNameMap Instance;
        public CmdGetModIdToNameMap() : base("mod_ids_to_names.json") {
            Instance = this;
        }
    }

    public class CmdGetModIdToCategoryMap : CmdGetModIdMap {
        internal static CmdGetModIdToCategoryMap Instance;
        public CmdGetModIdToCategoryMap() : base("mod_ids_to_categories.json") {
            Instance = this;
        }
    }

    public abstract class CmdGetModIdMap(string filename) : Cmd<string, bool, bool> {
        private static readonly Logger log = new Logger(nameof(CmdGetModIdMap));

        public override bool Taskable => true;

        private string cacheLocation;
        private bool apiMirror;

        public override bool Run(string cacheLocation, bool apiMirror) {
            this.cacheLocation = cacheLocation;
            this.apiMirror = apiMirror;
            log.Debug($"Cache location set to: {cacheLocation}");
            GetMap(ignoreCache: true);
            return true;
        }

        private readonly object locker = new object();

        internal Dictionary<string, string> GetMap(bool ignoreCache = false) {
            Dictionary<string, string> map;

            if (!ignoreCache && File.Exists(cacheLocation)) {
                log.Debug($"Loading {filename} from {cacheLocation}");
                map = tryRun(() => {
                    lock (locker)
                    using (Stream inputStream = new FileStream(cacheLocation, FileMode.Open)) {
                        return getMap(inputStream);
                    }
                });
                if (map.Count > 0) return map;
            }

            log.Debug($"Loading {filename} from the Internet (apiMirror = {apiMirror})");
            map = tryRun(() => {
                using (HttpClient wc = new HttpClientWithCompressionSupport())
                using (Stream inputStream = wc.GetAsync(
                    apiMirror ? $"https://everestapi.github.io/updatermirror/{filename}" : $"https://maddie480.ovh/celeste/{filename}"
                ).Result.Content.ReadAsStream()) {
                    return getMap(inputStream);
                }
            });
            if (map.Count > 0) lock (locker) File.WriteAllText(cacheLocation, JsonConvert.SerializeObject(map));
            return map;
        }

        private Dictionary<string, string> tryRun(Func<Dictionary<string, string>> function) {
            try {
                return function();
            } catch (Exception e) {
                log.Warning("Error loading mod IDs to names list: " + e);
                return new Dictionary<string, string>();
            }
        }

        private Dictionary<string, string> getMap(Stream inputStream) {
            using (TextReader textReader = new StreamReader(inputStream, Encoding.UTF8))
            using (JsonTextReader jsonTextReader = new JsonTextReader(textReader)) {
                return new JsonSerializer().Deserialize<Dictionary<string, string>>(jsonTextReader);
            }
        }
    }
}
