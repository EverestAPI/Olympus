using MonoMod.Utils;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.IO;
using System.Net;

namespace Olympus {
    public class CmdGetLoennLatestVersion : Cmd<Tuple<string, string>> {

        public override bool Taskable => true;

        public override Tuple<string, string> Run() {
            try {
                HttpWebRequest req = (HttpWebRequest) WebRequest.Create("https://maddie480.ovh/celeste/loenn-versions");
                req.UserAgent = "Olympus";
                req.Timeout = 10000;
                req.ReadWriteTimeout = 10000;
                using (HttpWebResponse res = (HttpWebResponse) req.GetResponse())
                using (StreamReader reader = new StreamReader(res.GetResponseStream()))
                using (JsonTextReader json = new JsonTextReader(reader)) {
                    JObject latestVersion = (JObject) JToken.ReadFrom(json);
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
