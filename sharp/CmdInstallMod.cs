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

                    yield return Status($"Downloading {url}", false, "download", false);
                    using (FileStream zipStream = File.Open(from, FileMode.Create, FileAccess.ReadWrite, FileShare.ReadWrite | FileShare.Delete))
                        yield return Download(url, 0, zipStream);
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
