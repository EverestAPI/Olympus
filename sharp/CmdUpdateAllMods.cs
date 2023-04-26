using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Security.Cryptography;
using YYProject.XXHash;

namespace Olympus {
    public class CmdUpdateAllMods : Cmd<string, bool, IEnumerator> {
        public static HashAlgorithm Hasher = XXHash64.Create();

        public override bool Taskable => true;

        public override IEnumerator Run(string root, bool onlyEnabled) {
            yield return "Downloading mod versions list...";
            Dictionary<string, ModUpdateInfo> modVersionList = downloadModUpdateList();

            yield return "Checking for outdated mods...";

            Dictionary<ModUpdateInfo, CmdModList.ModInfo> updates = new Dictionary<ModUpdateInfo, CmdModList.ModInfo>();

            int processedCount = 0;
            int totalCount = 0;

            foreach (CmdModList.ModInfo info in new EnumeratorEnumerator { Enumerator = new CmdModList().Run(root, readYamls: false, computeHashes: false, onlyUpdatable: true, onlyEnabled) }) {
                totalCount++;
            }

            foreach (CmdModList.ModInfo info in new EnumeratorEnumerator { Enumerator = new CmdModList().Run(root, readYamls: true, computeHashes: true, onlyUpdatable: true, onlyEnabled) }) {
                processedCount++;
                yield return "Checking for outdated mods (" + (int) Math.Round(processedCount * 100f / totalCount) + "%)...";

                if (info.Hash != null && modVersionList.ContainsKey(info.Name)) {
                    log($"Mod {info.Name}: installed hash {info.Hash}, latest hash(es) {string.Join(", ", modVersionList[info.Name].xxHash)}");
                    if (!modVersionList[info.Name].xxHash.Contains(info.Hash)) {
                        updates[modVersionList[info.Name]] = info;
                    }
                }
            }

            log($"{updates.Count} update(s) available");

            int updatingMod = 1;
            foreach (KeyValuePair<ModUpdateInfo, CmdModList.ModInfo> update in updates) {
                string messagePrefix = $"[{updatingMod}/{updates.Count}] Updating {update.Value.Name}";

                yield return messagePrefix + "...";

                // download from GameBanana, if that fails download from mirror
                string tempZip = Path.Combine(root, "mod-update.zip");
                foreach (string message in new EnumeratorEnumerator { Enumerator = tryDownloadWithMirror(update.Key, messagePrefix, tempZip) }) {
                    yield return message;
                }

                yield return messagePrefix + ": verifying checksum";
                verifyChecksum(update.Key, tempZip);

                yield return messagePrefix + ": installing update";
                installModUpdate(update.Key, update.Value, tempZip);

                updatingMod++;
            }

            yield return "Update check finished!";
        }

        private static IEnumerator tryDownloadWithMirror(ModUpdateInfo info, string messagePrefix, string destination) {
            bool success = true;

            if (File.Exists(destination)) {
                File.Delete(destination);
            }

            using (FileStream stream = new FileStream(destination, FileMode.OpenOrCreate, FileAccess.Write)) {
                IEnumerator download = Download(info.URL, info.Size, stream);

                while (true) {
                    bool hasNext;

                    try {
                        hasNext = download.MoveNext();
                    } catch (Exception e) {
                        log("An uncaught exception happened while downloading from GameBanana! Falling back to mirror.\n" + e);
                        success = false;
                        break;
                    }

                    if (!hasNext) {
                        break;
                    }

                    object message = ((object[]) download.Current)[0];
                    if (message.ToString() != "") {
                        yield return messagePrefix + ": " + message;
                    }
                }
            }

            if (!success) {
                // retry with mirror, this time let exceptions go through
                using (FileStream stream = new FileStream(destination, FileMode.OpenOrCreate, FileAccess.Write)) {
                    foreach (object[] message in new EnumeratorEnumerator { Enumerator = Download(info.MirrorURL, info.Size, stream) }) {
                        if (message[0].ToString() != "") {
                            yield return messagePrefix + ": " + message[0];
                        }
                    }
                }
            }
        }

        private class ModUpdateInfo {
            public virtual string Name { get; set; }
            public virtual string URL { get; set; }
            public virtual string MirrorURL { get; set; }
            public virtual List<string> xxHash { get; set; }
            public virtual int Size { get; set; }
        }

        // Why do you need to tell C# how to get an enumerator from an enumerator
        private class EnumeratorEnumerator : IEnumerable {
            public IEnumerator Enumerator { get; set; }
            public IEnumerator GetEnumerator() => Enumerator;
        }

        private static void log(string line) {
            Console.Error.WriteLine($"[CmdUpdateAllMods] {line}");
        }

        /// <summary>
        /// Downloads the full update list from the update checker server.
        /// Returns null if the download fails for any reason.
        /// </summary>
        private static Dictionary<string, ModUpdateInfo> downloadModUpdateList() {
            Dictionary<string, ModUpdateInfo> updateCatalog = null;

            try {
                string modUpdaterDatabaseUrl = getModUpdaterDatabaseUrl();

                log($"Downloading last versions list from {modUpdaterDatabaseUrl}");

                using (WebClient wc = new WebClient()) {
                    string yamlData = wc.DownloadString(modUpdaterDatabaseUrl);
                    updateCatalog = YamlHelper.Deserializer.Deserialize<Dictionary<string, ModUpdateInfo>>(yamlData);
                    foreach (string name in updateCatalog.Keys) {
                        updateCatalog[name].Name = name;
                    }
                    log($"Downloaded {updateCatalog.Count} item(s)");
                }
            } catch (Exception e) {
                log("Downloading database failed! " + e.ToString());
            }

            return updateCatalog;
        }

        /// <summary>
        /// Verifies the downloaded mod's checksum, and throws an IOException if it doesn't match the database one.
        /// </summary>
        /// <param name="update">The mod info from the database</param>
        /// <param name="filePath">The path to the file to check</param>
        private static void verifyChecksum(ModUpdateInfo update, string filePath) {
            string actualHash;
            using (FileStream stream = File.Open(filePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete))
                actualHash = BitConverter.ToString(Hasher.ComputeHash(stream)).Replace("-", "").ToLowerInvariant();

            string expectedHash = update.xxHash[0];
            log($"Verifying checksum: actual hash is {actualHash}, expected hash is {expectedHash}");
            if (expectedHash != actualHash) {
                throw new IOException($"Checksum error: expected {expectedHash}, got {actualHash}");
            }
        }

        /// <summary>
        /// Installs a mod update in the Mods directory once it has been downloaded.
        /// This method will replace the installed mod zip with the one that was just downloaded.
        /// </summary>
        /// <param name="update">The update info coming from the update server</param>
        /// <param name="mod">The mod metadata from Everest for the installed mod</param>
        /// <param name="zipPath">The path to the zip the update has been downloaded to</param>
        private static void installModUpdate(ModUpdateInfo update, CmdModList.ModInfo mod, string zipPath) {
            // delete the old zip, and move the new one.
            log($"Deleting mod .zip: {mod.Path}");
            File.Delete(mod.Path);

            log($"Moving {zipPath} to {mod.Path}");
            File.Move(zipPath, mod.Path);
        }

        /// <summary>
        /// Retrieves the mod updater database location from everestapi.github.io.
        /// This should point to a running instance of https://github.com/maddie480/EverestUpdateCheckerServer.
        /// </summary>
        private static string getModUpdaterDatabaseUrl() {
            using (WebClient wc = new WebClient()) {
                log("Fetching mod updater database URL");
                return wc.DownloadString("https://everestapi.github.io/modupdater.txt").Trim();
            }
        }
    }
}
