using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Security.Cryptography;
using YYProject.XXHash;

namespace Olympus {
    public class CmdModList : Cmd<string, bool, IEnumerator> {

        public static HashAlgorithm Hasher = XXHash64.Create();

        public override IEnumerator Run(string root, bool onlyHashEnabledMods) {
            root = Path.Combine(root, "Mods");
            if (!Directory.Exists(root))
                yield break;

            List<string> blacklist;
            string blacklistPath = Path.Combine(root, "blacklist.txt");
            if (File.Exists(blacklistPath))
                blacklist = File.ReadAllLines(blacklistPath).Select(l => (l.StartsWith("#") ? "" : l).Trim()).ToList();
            else
                blacklist = new List<string>();

            List<string> updaterBlacklist;
            string updaterBlacklistPath = Path.Combine(root, "updaterblacklist.txt");
            if (File.Exists(updaterBlacklistPath))
                updaterBlacklist = File.ReadAllLines(updaterBlacklistPath).Select(l => (l.StartsWith("#") ? "" : l).Trim()).ToList();
            else
                updaterBlacklist = new List<string>();

            // === mod directories

            string[] files = Directory.GetDirectories(root);
            for (int i = 0; i < files.Length; i++) {
                string file = files[i];
                string name = Path.GetFileName(file);
                if (name == "Cache")
                    continue;

                ModInfo info = new ModInfo() {
                    Path = file,
                    IsFile = false,
                    IsBlacklisted = blacklist.Contains(name),
                    IsUpdaterBlacklisted = updaterBlacklist.Contains(name)
                };

                try {
                    string yamlPath = Path.Combine(file, "everest.yaml");
                    if (!File.Exists(yamlPath))
                        yamlPath = Path.Combine(file, "everest.yml");

                    if (File.Exists(yamlPath)) {
                        using (FileStream stream = File.Open(yamlPath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete))
                        using (StreamReader reader = new StreamReader(stream))
                            info.Parse(reader);
                    }
                } catch (UnauthorizedAccessException) { }

                yield return info;
            }


            // === mod zips

            files = Directory.GetFiles(root);
            for (int i = 0; i < files.Length; i++) {
                string file = files[i];
                string name = Path.GetFileName(file);
                if (!file.EndsWith(".zip"))
                    continue;

                ModInfo info = new ModInfo() {
                    Path = file,
                    IsFile = true,
                    IsBlacklisted = blacklist.Contains(name),
                    IsUpdaterBlacklisted = updaterBlacklist.Contains(name)
                };

                using (FileStream zipStream = File.Open(file, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete)) {
                    // info.Hash = BitConverter.ToString(Hasher.ComputeHash(zipStream)).Replace("-", "");
                    zipStream.Seek(0, SeekOrigin.Begin);

                    using (ZipArchive zip = new ZipArchive(zipStream, ZipArchiveMode.Read))
                    using (Stream stream = (zip.GetEntry("everest.yaml") ?? zip.GetEntry("everest.yml"))?.Open())
                    using (StreamReader reader = stream == null ? null : new StreamReader(stream))
                        info.Parse(reader);
                }

                if (info.Name != null && (!onlyHashEnabledMods || (!info.IsBlacklisted && !info.IsUpdaterBlacklisted))) {
                    using (FileStream stream = File.Open(file, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete))
                        info.Hash = BitConverter.ToString(Hasher.ComputeHash(stream)).Replace("-", "").ToLowerInvariant();
                }

                yield return info;
            }


            // === bin files

            for (int i = 0; i < files.Length; i++) {
                string file = files[i];
                string name = Path.GetFileName(file);
                if (!file.EndsWith(".bin"))
                    continue;

                ModInfo info = new ModInfo() {
                    Path = file,
                    IsFile = true,
                    IsBlacklisted = blacklist.Contains(name),
                    IsUpdaterBlacklisted = updaterBlacklist.Contains(name)
                };

                yield return info;
            }
        }

        public class ModInfo {
            public string Path;
            public string Hash;
            public bool IsFile;
            public bool IsBlacklisted;
            public bool IsUpdaterBlacklisted;

            public string Name;
            public string Version;
            public string DLL;
            public string[] Dependencies;
            public bool IsValid;

            public void Parse(TextReader reader) {
                try {
                    if (reader != null) {
                        List<EverestModuleMetadata> yaml = YamlHelper.Deserializer.Deserialize<List<EverestModuleMetadata>>(reader);
                        if (yaml != null && yaml.Count > 0) {
                            Name = yaml[0].Name;
                            Version = yaml[0].Version;
                            DLL = yaml[0].DLL;
                            Dependencies = yaml[0].Dependencies.Select(dep => dep.Name).ToArray();

                            IsValid = Name != null && Version != null;
                        }
                    }
                } catch {
                    // ignore parse errors
                }
            }
        }

        public class EverestModuleMetadata {
            public string Name;
            public string Version;
            public string DLL;
            public List<EverestModuleMetadata> Dependencies;
        }

    }
}
