using MonoMod.Utils;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Linq;

namespace Olympus {
    public class CmdInstallOlympus : Cmd<string, IEnumerator> {

        public override IEnumerator Run(string id) {
            yield return Status("Updating Olympus", false, "", false);

            JObject artifacts;
            using (MemoryStream stream = new MemoryStream()) {
                yield return Download($"https://dev.azure.com/EverestAPI/Olympus/_apis/build/builds/{id}/artifacts", 0, stream);
                stream.Seek(0, SeekOrigin.Begin);
                using (StreamReader reader = new StreamReader(stream))
                using (JsonTextReader json = new JsonTextReader(reader)) {
                    artifacts = (JObject) JToken.ReadFrom(json);
                }
            }

            List<string> wanted;
            if (PlatformHelper.Is(Platform.Windows)) {
                wanted = new List<string>() { "update", "windows.update" };
            } else if (PlatformHelper.Is(Platform.Linux)) {
                wanted = new List<string>() { "update", "linux.update" };
            } else if (PlatformHelper.Is(Platform.MacOS)) {
                wanted = new List<string>() { "update", "macos.update" };
            } else {
                wanted = new List<string>() { "update" };
            }

            yield return Status("Filtering artifacts", false, "download", false);
            string[] names = artifacts.Value<JArray>("value").Cast<JObject>()
                .Select(a => a.Value<string>("name"))
                .Where(name => wanted.Contains(name))
                .OrderBy(name => wanted.IndexOf(name))
                .ToArray();

            foreach (string name in names) {
                using (MemoryStream wrapStream = new MemoryStream()) {
                    yield return Download($"https://dev.azure.com/EverestAPI/Olympus/_apis/build/builds/{id}/artifacts?$format=zip&artifactName={name}", 0, wrapStream);
                    wrapStream.Seek(0, SeekOrigin.Begin);

                    yield return Status($"Unwrapping {name}.zip", false, "download", false);
                    using (ZipArchive wrap = new ZipArchive(wrapStream, ZipArchiveMode.Read)) {
                        yield return Unwrap(wrap, name);
                    }
                }
            }
        }

        public static IEnumerator Unwrap(ZipArchive wrap, string wrapName) {
            string prefix = wrapName + "/";
            foreach (ZipArchiveEntry entry in wrap.Entries) {
                string name = entry.FullName;
                if (string.IsNullOrEmpty(name) || name.EndsWith("/"))
                    continue;

                if (!string.IsNullOrEmpty(prefix)) {
                    if (!name.StartsWith(prefix))
                        continue;
                    name = name.Substring(prefix.Length);
                }

                switch (name) {
                    case "olympus.love":
                        yield return Status("Unpacking olympus.love", false, "download", false);
                        string to = Path.Combine(Program.RootDirectory, "olympus.new.love");
                        string toParent = Path.GetDirectoryName(to);
                        Console.Error.WriteLine($"{name} -> {to}");

                        if (!Directory.Exists(toParent))
                            Directory.CreateDirectory(toParent);

                        if (File.Exists(to))
                            File.Delete(to);

                        using (FileStream fs = File.OpenWrite(to))
                        using (Stream compressed = entry.Open())
                            compressed.CopyTo(fs);
                        break;

                    case "sharp.zip":
                        yield return Status("Unpacking sharp.zip", false, "download", false);
                        using (Stream zipStream = entry.Open())
                        using (ZipArchive zip = new ZipArchive(zipStream, ZipArchiveMode.Read)) {
                            yield return Unpack(zip, Path.Combine(Program.RootDirectory, "sharp.new"));
                        }
                        break;
                }
            }

            yield return Status($"Unwrapped {wrapName}.zip", 1f, "download", false);
        }

    }
}
