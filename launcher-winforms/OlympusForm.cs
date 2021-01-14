using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Drawing.Text;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Net;
using System.Reflection;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace Olympus {
    public partial class OlympusForm : Form {

        public Thread Thread;

        public OlympusForm() {
            InitializeComponent();

            Icon = LoadAsset<Icon>("icon.ico");
            BackgroundImage = LoadAsset<Bitmap>("logo.png");
        }

        private void OlympusForm_Load(object sender, EventArgs e) {
            Thread = new Thread(RunDownloader) {
                Name = "Olympus Downloader",
                IsBackground = true
            };
            Thread.Start();
        }

        public void Invoke(Action a) {
            base.Invoke(a);
        }

        public void RunDownloader() {
            Console.WriteLine("Downloader thread running");

            if (Directory.Exists(Program.InstallDir) && Directory.GetFiles(Program.InstallDir).Length != 0) {
                Invoke(() => {
                    MessageBox.Show(
                        @"
A previous version of Olympus was already downloaded.
Sadly, some important files went missing or are corrupted.

The Olympus downloader will now try to redownload them.
If Olympus is still crashing or if this happens often:
please ping the Everest team on the Celeste Discord server.
                        ".Trim().Replace("\r\n", "\n"),
                        "Olympus Downloader",
                        MessageBoxButtons.OK
                    );
                });
            }

            Console.WriteLine($"Wiping {Program.InstallDir}");
            try {
                Directory.Delete(Program.InstallDir, true);
            } catch (Exception e) {
                Console.WriteLine(e);
            }
            try {
                Directory.CreateDirectory(Program.InstallDir);
            } catch (Exception e) {
                Console.WriteLine(e);
            }

            const string artifactFormat = "https://dev.azure.com/EverestAPI/Olympus/_apis/build/builds/{0}/artifacts?artifactName=windows.main&$format=zip";
            const string index = "https://dev.azure.com/EverestAPI/Olympus/_apis/build/builds";

            JObject root = null;
            using (WebClient wc = new WebClient())
            using (Stream stream = wc.OpenRead(index))
            using (StreamReader reader = new StreamReader(stream))
            using (JsonTextReader jsonReader = new JsonTextReader(reader))
                root = (JObject) JToken.ReadFrom(jsonReader);

            string urlWindowsInit = null;
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
                if (string.IsNullOrEmpty(urlWindowsInit) && branch == "windows-init")
                    urlWindowsInit = string.Format(artifactFormat, id);
                if (string.IsNullOrEmpty(urlStable) && branch == "stable")
                    urlStable = string.Format(artifactFormat, id);
                if (string.IsNullOrEmpty(urlMain) && (branch == "main" || branch == "dev"))
                    urlMain = string.Format(artifactFormat, id);

                if (!string.IsNullOrEmpty(urlWindowsInit) && !string.IsNullOrEmpty(urlStable) && !string.IsNullOrEmpty(urlMain))
                    break;
            }

            string url = !string.IsNullOrEmpty(urlWindowsInit) ? urlWindowsInit : !string.IsNullOrEmpty(urlStable) ? urlStable : urlMain;
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

        public static unsafe T LoadAsset<T>(string name, bool fullPath = false) where T : class {
            Assembly assembly = Assembly.GetExecutingAssembly();
            Type t = typeof(T);

            if (t == typeof(Image) || t == typeof(Bitmap)) {
                // Stream must be kept open for the lifetime of the image!
                if (name.EndsWith(".gif"))
                    return Image.FromStream(assembly.GetManifestResourceStream(fullPath ? name : "Olympus." + name)) as T;

                using (Stream s = assembly.GetManifestResourceStream(fullPath ? name : "Olympus." + name))
                using (Image src = Image.FromStream(s))
                    return new Bitmap(src) as T;
            }

            if (t == typeof(Icon)) {
                using (Bitmap img = LoadAsset<Bitmap>(name, fullPath)) {
                    return Icon.FromHandle(img.GetHicon()) as T;
                }
            }

            if (t == typeof(PrivateFontCollection)) {
                PrivateFontCollection pfc = new PrivateFontCollection();
                byte[] data;
                using (Stream s = assembly.GetManifestResourceStream(fullPath ? name : "Olympus." + name)) {
                    data = new byte[s.Length];
                    s.Read(data, 0, (int) s.Length);
                }
                fixed (byte* pData = data)
                    pfc.AddMemoryFont((IntPtr) pData, data.Length);
                return pfc as T;
            }

            return default(T);
        }

    }
}
