using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Net;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace Olympus {
    public partial class OlympusForm : Form {

        public Thread Thread;

        public OlympusForm() {
            InitializeComponent();
        }

        protected override void OnLoad(EventArgs e) {
            base.OnLoad(e);

            Thread = new Thread(RunDownloader) {
                Name = "Olympus Downloader"
            };
            Thread.Start();
        }

        public void Invoke(Action a) {
            base.Invoke(a);
        }

        public void RunDownloader() {
            Console.WriteLine("Downloader thread running");

            Thread.Sleep(2000);

            const string artifactFormat = "https://dev.azure.com/EverestAPI/Olympus/_apis/build/builds/{0}/artifacts?artifactName=windows.main&$format=zip";
            const string index = "https://dev.azure.com/EverestAPI/Olympus/_apis/build/builds";

            JObject root = null;
            using (WebClient wc = new WebClient())
            using (Stream stream = wc.OpenRead(index))
            using (StreamReader reader = new StreamReader(stream))
            using (JsonTextReader jsonReader = new JsonTextReader(reader))
                root = (JObject) JToken.ReadFrom(jsonReader);

            string urlStable = null;
            string urlMain = null;

            JArray list = root.Value<JArray>("value");
            foreach (JObject build in list) {
                if (build.Value<string>("status") != "completed" || build.Value<string>("result") != "succeeded")
                    continue;

                string reason = build.Value<string>("reason");
                if (reason != "manual" && reason != "individualCI")
                    continue;

                int id = build.Value<int>("id");
                string branch = build.Value<string>("sourceBranch").Replace("refs/heads/", "");
                if (string.IsNullOrEmpty(urlStable) && branch == "stable")
                    urlStable = string.Format(artifactFormat, id);
                if (string.IsNullOrEmpty(urlMain) && (branch == "main" || branch == "dev"))
                    urlMain = string.Format(artifactFormat, id);

                if (!string.IsNullOrEmpty(urlStable) && !string.IsNullOrEmpty(urlMain))
                    break;
            }

            string url = !string.IsNullOrEmpty(urlStable) ? urlStable : urlMain;
            if (string.IsNullOrEmpty(url))
                throw new Exception("Couldn't find valid latest build entry.");

            using (MemoryStream ms = new MemoryStream()) {
                Console.WriteLine($"Downloading {url}");
                using (WebClient wc = new WebClient())
                using (Stream stream = wc.OpenRead(url))
                    stream.CopyTo(ms);

                Console.WriteLine($"Downloaded {ms.Position} bytes");
                ms.Seek(0, SeekOrigin.Begin);

                Console.WriteLine("Opening wrapper .zip");
                using (ZipArchive wrapper = new ZipArchive(ms, ZipArchiveMode.Read)) {
                    Console.WriteLine("Opening dist .zip");
                    using (Stream stream = wrapper.GetEntry("windows.main/dist.zip").Open())
                    using (ZipArchive zip = new ZipArchive(stream, ZipArchiveMode.Read)) {
                        Console.WriteLine($"Extracting to {Program.InstallDir}");
                        zip.ExtractToDirectory(Program.InstallDir);
                    }
                }
            }

            Console.WriteLine("Done");

            Invoke(() => {
                Program.StartMain();
                Application.Exit();
            });
        }

    }
}
