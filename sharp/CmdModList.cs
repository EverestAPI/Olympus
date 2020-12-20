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
using System.Security.Cryptography;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using YYProject.XXHash;

namespace Olympus {
    public unsafe class CmdModList : Cmd<string, IEnumerator> {

        public static HashAlgorithm Hasher = XXHash64.Create();

        public override IEnumerator Run(string root) {
            root = Path.Combine(root, "Mods");
            if (!Directory.Exists(root))
                yield break;

            List<string> blacklist;
            string blacklistPath = Path.Combine(root, "blacklist.txt");
            if (File.Exists(blacklistPath))
                blacklist = File.ReadAllLines(blacklistPath).Select(l => (l.StartsWith("#") ? "" : l).Trim()).ToList();
            else
                blacklist = new List<string>();

            string[] files = Directory.GetFiles(root);
            for (int i = 0; i < files.Length; i++) {
                string file = files[i];
                string name = Path.GetFileName(file);
                if (!file.EndsWith(".zip"))
                    continue;

                ModInfo info = new ModInfo() {
                    Path = file,
                    IsZIP = true,
                    IsBlacklisted = blacklist.Contains(name)
                };

                using (FileStream zipStream = File.Open(file, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete)) {
                    // info.Hash = BitConverter.ToString(Hasher.ComputeHash(zipStream)).Replace("-", "");
                    zipStream.Seek(0, SeekOrigin.Begin);

                    using (ZipArchive zip = new ZipArchive(zipStream, ZipArchiveMode.Read))
                    using (Stream stream = (zip.GetEntry("everest.yaml") ?? zip.GetEntry("everest.yml"))?.Open())
                    using (StreamReader reader = stream == null ? null : new StreamReader(stream))
                        info.Parse(reader);
                }

                yield return info;
            }

            files = Directory.GetDirectories(root);
            for (int i = 0; i < files.Length; i++) {
                string file = files[i];
                string name = Path.GetFileName(file);
                if (name == "Cache" || blacklist.Contains(name))
                    continue;

                ModInfo info = new ModInfo() {
                    Path = file,
                    IsZIP = false,
                    IsBlacklisted = blacklist.Contains(name)
                };

                try {
                    string yamlPath = Path.Combine(file, "everest.yaml");
                    if (!File.Exists(yamlPath))
                        yamlPath = Path.Combine(file, "everest.yml");

                    if (File.Exists(yamlPath)) {
                        using (FileStream stream = File.Open(file, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete))
                        using (StreamReader reader = new StreamReader(stream))
                            info.Parse(reader);

                        if (!string.IsNullOrEmpty(info.DLL)) {
                            string dllPath = Path.Combine(file, info.DLL);
                            if (File.Exists(dllPath)) {
                                using (FileStream stream = File.Open(file, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete))
                                    info.Hash = BitConverter.ToString(Hasher.ComputeHash(stream)).Replace("-", "");
                            }
                        }
                    }
                } catch (UnauthorizedAccessException) {
                }

                yield return info;
            }
        }

        public class ModInfo {
            public string Path;
            public string Hash;
            public bool IsZIP;
            public bool IsBlacklisted;

            public string Name;
            public string Version;
            public string DLL;
            public bool IsValid;

            public void Parse(TextReader reader) {
                if (reader != null && YamlHelper.Deserializer.Deserialize(reader) is List<object> yamlRoot &&
                    yamlRoot.Count != 0 && yamlRoot[0] is Dictionary<object, object> yamlEntry) {

                    IsValid = yamlEntry.TryGetValue("Name", out object yamlName) &&
                    !string.IsNullOrEmpty(Name = yamlName as string) &&
                    yamlEntry.TryGetValue("Version", out object yamlVersion) &&
                    !string.IsNullOrEmpty(Version = yamlVersion as string);

                    if (yamlEntry.TryGetValue("DLL", out object yamlDLL))
                        DLL = yamlDLL as string;
                }
            }
        }

    }
}
