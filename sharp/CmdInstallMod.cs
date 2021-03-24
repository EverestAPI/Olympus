using Mono.Cecil;
using Mono.Cecil.Cil;
using MonoMod.Utils;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Drawing;
using System.Globalization;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Net;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace Olympus {
    public unsafe class CmdInstallMod : Cmd<string, string, IEnumerator> {

        public static readonly string MirrorPattern = "https://celestemodupdater.0x0ade.ga/banana-mirror/{0}.zip";

        public override IEnumerator Run(string root, string url) {
            string mods = Path.Combine(root, "Mods");
            if (!Directory.Exists(mods))
                Directory.CreateDirectory(mods);

            string from = null;
            bool fromIsTmp = false;

            try {
                List<object> yamlRoot = null;

                if (url.StartsWith("file://")) {
                    fromIsTmp = false;
                    from = url.Substring("file://".Length).Replace('/', Path.DirectorySeparatorChar);
                    if (from.StartsWith(mods + "/"))
                        throw new Exception($"{Path.GetFileName(from)} is already in the mods folder");

                } else {
                    fromIsTmp = true;
                    from = Path.Combine(mods, $"tmpdownload-{DateTime.Now:yyyyMMdd-HHmmss}.zip.part");
                    if (File.Exists(from))
                        File.Delete(from);

                    uint gbid = 0;
                    if ((url.StartsWith("http://gamebanana.com/dl/") && !uint.TryParse(url.Substring("http://gamebanana.com/dl/".Length), out gbid)) ||
                        (url.StartsWith("https://gamebanana.com/dl/") && !uint.TryParse(url.Substring("https://gamebanana.com/dl/".Length), out gbid)) ||
                        (url.StartsWith("http://gamebanana.com/mmdl/") && !uint.TryParse(url.Substring("http://gamebanana.com/mmdl/".Length), out gbid)) ||
                        (url.StartsWith("https://gamebanana.com/mmdl/") && !uint.TryParse(url.Substring("https://gamebanana.com/mmdl/".Length), out gbid)))
                        gbid = 0;

                    if (gbid != 0) {
                        yield return Status($"Downloading {gbid} from GameBanana", false, "download", false);
                        Exception[] ea = new Exception[1];
                        using (FileStream zipStream = File.Open(from, FileMode.Create, FileAccess.ReadWrite, FileShare.ReadWrite | FileShare.Delete))
                            yield return Try(Download(url, 0, zipStream), ea);

                        if (ea[0] != null) {
                            yield return Status($"Downloading from GameBanana failed, trying mirror", false, "download", false);
                            if (File.Exists(from))
                                File.Delete(from);
                            url = string.Format(MirrorPattern, gbid);
                            yield return Status($"Downloading {url}", false, "download", false);
                            using (FileStream zipStream = File.Open(from, FileMode.Create, FileAccess.ReadWrite, FileShare.ReadWrite | FileShare.Delete))
                                yield return Download(url, 0, zipStream);
                        }

                    } else {
                        yield return Status($"Downloading {url}", false, "download", false);
                        using (FileStream zipStream = File.Open(from, FileMode.Create, FileAccess.ReadWrite, FileShare.ReadWrite | FileShare.Delete))
                            yield return Download(url, 0, zipStream);
                    }
                }

                using (FileStream zipStream = File.Open(from, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete)) {
                    yield return Status("Parsing everest.yaml", false, "download", false);
                    using (ZipArchive zip = new ZipArchive(zipStream, ZipArchiveMode.Read)) {
                        ZipArchiveEntry entry = zip.GetEntry("everest.yaml") ?? zip.GetEntry("everest.yml");
                        if (entry == null)
                            throw new Exception("everest.yaml not found - is this a Celeste mod?");
                        using (Stream stream = entry.Open())
                        using (StreamReader reader = new StreamReader(stream))
                            yamlRoot = YamlHelper.Deserializer.Deserialize(reader) as List<object>;
                    }
                }

                if (yamlRoot == null || yamlRoot.Count == 0 ||
                    !(yamlRoot[0] is Dictionary<object, object> yamlEntry) ||
                    !yamlEntry.TryGetValue("Name", out object yamlName) ||
                    !(yamlName is string name))
                    throw new Exception("everest.yaml malformed - is this a Celeste mod?");

                if (fromIsTmp)
                    yield return Status($"Moving mod to {name}.zip", false, "download", false);
                else
                    yield return Status($"Copying mod to {name}.zip", false, "download", false);

                string path = Path.Combine(mods, $"{name}.zip");
                if (File.Exists(path))
                    File.Delete(path);

                if (fromIsTmp)
                    File.Move(from, path);
                else
                    File.Copy(from, path);

                yield return Status($"Successfully installed {name}", 1f, "done", false);

            } finally {
                if (fromIsTmp && !string.IsNullOrEmpty(from) && File.Exists(from))
                    File.Delete(from);
            }
        }

    }
}
