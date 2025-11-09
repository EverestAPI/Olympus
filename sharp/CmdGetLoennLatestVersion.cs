using MonoMod.Utils;
using Newtonsoft.Json.Linq;
using System;
using System.Net.Http;

namespace Olympus {
    public class CmdGetLoennLatestVersion : Cmd<bool, Tuple<string, string>> {

        public override bool Taskable => true;

        public override Tuple<string, string> Run(bool apiMirror) {
            try {
                using (HttpClient client = new HttpClientWithCompressionSupport()) {
                    string json = client.GetStringAsync(
                        apiMirror ? "https://everestapi.github.io/updatermirror/loenn_versions.json" : "https://maddie480.ovh/celeste/loenn-versions"
                    ).Result;
                    JObject latestVersion = (JObject) JToken.Parse(json);
                    return new Tuple<string, string>((string) latestVersion["tag_name"], GetDownloadLink((JArray) latestVersion["assets"]));
                }
            } catch (Exception ex) {
                Console.Error.WriteLine("Error while checking Loenn version: " + ex);
                return new Tuple<string, string>("unknown", "");
            }
        }

        private static string GetDownloadLink(JArray assets) {
            string wantedSuffix;
            if (PlatformHelper.Is(Platform.Windows)) {
                wantedSuffix = "-windows.zip";
            } else if (PlatformHelper.Is(Platform.Linux)) {
                wantedSuffix = "-linux.zip";
            } else if (PlatformHelper.Is(Platform.MacOS)) {
                wantedSuffix = "-macos.app.zip";
            } else {
                Console.Error.WriteLine($"Unsupported platform: {PlatformHelper.Current}");
                return "";
            }

            foreach (JToken artifact in assets) {
                string url = (string) (artifact as JObject)["browser_download_url"];
                if (url.EndsWith(wantedSuffix)) {
                    return url;
                }
            }

            Console.Error.WriteLine("Loenn artifact not found");
            return "";
        }
    }
}
