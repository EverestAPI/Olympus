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
            yield return Status($"Downloading {url}", false, "download");

            string mods = Path.Combine(root, "Mods");
            if (!Directory.Exists(mods))
                Directory.CreateDirectory(mods);

            string tmp = Path.Combine(mods, $"tmpdownload-{DateTime.Now:yyyyMMdd-HHmmss}.zip.part");
            if (File.Exists(tmp))
                File.Delete(tmp);

            try {
                List<object> yamlRoot = null;

                using (FileStream zipStream = new FileStream(tmp, FileMode.Create, FileAccess.ReadWrite, FileShare.ReadWrite | FileShare.Delete)) {
                    yield return Download(url, 0, zipStream);

                    yield return Status("Parsing everest.yaml", false, "download");
                    zipStream.Seek(0, SeekOrigin.Begin);
                    using (ZipArchive zip = new ZipArchive(zipStream)) {
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

                yield return Status($"Moving mod to {name}.zip", false, "download");
                string path = Path.Combine(mods, $"{name}.zip");
                if (File.Exists(path))
                    File.Delete(path);
                File.Move(tmp, path);

                yield return Status($"Successfully installed {name}", 1f, "done");

            } finally {
                if (File.Exists(tmp))
                    File.Delete(tmp);
            }
        }

    }
}
