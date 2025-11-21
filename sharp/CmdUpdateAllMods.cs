using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Security.Cryptography;

namespace Olympus {
    public class CmdUpdateAllMods : Cmd<string, bool, string, bool, string, IEnumerator> {
        private static readonly Logger log = new Logger(nameof(CmdUpdateAllMods));

        public override bool Taskable => true;

        private static readonly Dictionary<string, Dictionary<string, string>> translations = new Dictionary<string, Dictionary<string, string>> {
            {
                "en", new Dictionary<string, string> {
                    { "downloadinglist", "Downloading mod versions list" },
                    { "downloadingfile", "Downloading " },
                    { "downloadingprogress", "Downloading:" },
                    { "checking", "Checking for outdated mods" },
                    { "updating", "Updating" },
                    { "installing", "installing update" },
                    { "finished_noop", "Update check finished.\nNo updates were found." },
                    { "finished", "Update successful!\nThe following mods were updated:" },
                    { "checksum", "verifying checksum" }
                }
            }, {
                "fr", new Dictionary<string, string> {
                    { "downloadinglist", "Téléchargement de la liste des mods" },
                    { "downloadingfile", "Téléchargement de " },
                    { "downloadingprogress", "Téléchargement -" },
                    { "checking", "Vérification des mises à jour" },
                    { "updating", "Mise à jour" },
                    { "installing", "installation en cours" },
                    { "finished_noop", "La vérification est terminée.\nAucune mise à jour n'a été trouvée." },
                    { "finished", "Mise à jour terminée !\nLes mods suivants ont été mis à jour :" },
                    { "checksum", "vérification de la somme de contrôle" }
                }
            },
        };

        private static string langGet(string lang, string key) {
            if (lang.Equals("ne")) {
                char[] charArray = translations["en"][key].ToCharArray();
                Array.Reverse(charArray);
                return new string(charArray);
            }
            return translations[lang][key];
        }



        public override IEnumerator Run(string root, bool onlyEnabled, string mirrorPreferences, bool apiMirror, string lang) {
            yield return $"{langGet(lang, "downloadinglist")}...";
            Dictionary<string, ModUpdateInfo> modVersionList = downloadModUpdateList(apiMirror);

            yield return $"{langGet(lang, "checking")}...";

            Dictionary<ModUpdateInfo, CmdModList.ModInfo> updates = new Dictionary<ModUpdateInfo, CmdModList.ModInfo>();

            int processedCount = 0;
            int totalCount = 0;

            foreach (CmdModList.ModInfo info in new EnumeratorEnumerator { Enumerator = new CmdModList().Run(root, readYamls: false, computeHashes: false, onlyUpdatable: true, onlyEnabled) }) {
                totalCount++;
            }

            foreach (CmdModList.ModInfo info in new EnumeratorEnumerator { Enumerator = new CmdModList().Run(root, readYamls: true, computeHashes: true, onlyUpdatable: true, onlyEnabled) }) {
                processedCount++;
                yield return $"{langGet(lang, "checking")} (" + (int) Math.Round(processedCount * 100f / totalCount) + "%)...";

                if (info.Hash != null && modVersionList.ContainsKey(info.Name)) {
                    log.Debug($"Mod {info.Name}: installed hash {info.Hash}, latest hash(es) {string.Join(", ", modVersionList[info.Name].xxHash)}");
                    if (!modVersionList[info.Name].xxHash.Contains(info.Hash)) {
                        updates[modVersionList[info.Name]] = info;
                    }
                }
            }

            log.Info($"{updates.Count} update(s) available");

            int updatingMod = 1;
            foreach (KeyValuePair<ModUpdateInfo, CmdModList.ModInfo> update in updates) {
                string messagePrefix = $"[{updatingMod}/{updates.Count}] {langGet(lang, "updating")} {update.Value.Name}";

                yield return messagePrefix + "...";

                // download from GameBanana, if that fails download from mirror
                string tempZip = Path.Combine(root, "mod-update.zip");
                foreach (string message in new EnumeratorEnumerator { Enumerator = tryDownloadWithMirror(update.Key, messagePrefix, tempZip, mirrorPreferences, lang) }) {
                    yield return message;
                }

                yield return messagePrefix + $": {langGet(lang, "installing")}";
                installModUpdate(update.Key, update.Value, tempZip);

                updatingMod++;
            }

            // The last yielded message might be displayed as a recap popup by Olympus when relevant.
            if (updates.Count == 0) {
                yield return langGet(lang, "finished_noop");
            } else {
                yield return langGet(lang, "finished")
                    + updates.Values.Aggregate("", (a, b) => $"{a}\n- {b.Name}");
            }
        }

        internal static IEnumerable GetAllMirrorUrls(string url, string mirrorPreferences) {
            return new EnumeratorEnumerator { Enumerator = getAllMirrorUrls(url, mirrorPreferences) };
        }

        // Make sure to keep this in sync with
        // - https://github.com/EverestAPI/Everest/blob/dev/Celeste.Mod.mm/Mod/Helpers/ModUpdaterHelper.cs :: getAllMirrorUrls
        // - https://github.com/maddie480/RandomStuffWebsite/blob/main/front-vue/src/components/ModListItem.vue :: getMirrorLink
        private static IEnumerator<string> getAllMirrorUrls(string url, string mirrorPreferences) {
            uint gbid = 0;
            if ((url.StartsWith("http://gamebanana.com/dl/") && !uint.TryParse(url.Substring("http://gamebanana.com/dl/".Length), out gbid)) ||
                (url.StartsWith("https://gamebanana.com/dl/") && !uint.TryParse(url.Substring("https://gamebanana.com/dl/".Length), out gbid)) ||
                (url.StartsWith("http://gamebanana.com/mmdl/") && !uint.TryParse(url.Substring("http://gamebanana.com/mmdl/".Length), out gbid)) ||
                (url.StartsWith("https://gamebanana.com/mmdl/") && !uint.TryParse(url.Substring("https://gamebanana.com/mmdl/".Length), out gbid)))
                gbid = 0;

            if (gbid == 0) {
                yield return url;
                yield break;
            }

            foreach (string mirrorId in mirrorPreferences.Split(',')) {
                switch (mirrorId) {
                    case "gb":
                        yield return url;
                        break;

                    case "jade":
                        yield return $"https://celestemodupdater.0x0a.de/banana-mirror/{gbid}.zip";
                        break;

                    case "wegfan":
                        yield return $"https://celeste.weg.fan/api/v2/download/gamebanana-files/{gbid}";
                        break;

                    case "otobot":
                        yield return $"https://banana-mirror-mods.celestemods.com/{gbid}.zip";
                        break;
                }
            }
        }

        private static IEnumerator tryDownloadWithMirror(ModUpdateInfo info, string messagePrefix, string destination, string mirrorPreferences, string lang) {
            Exception lastException = null;

            foreach (string url in GetAllMirrorUrls(info.URL, mirrorPreferences)) {
                log.Info($"Downloading mod from {url}");
                lastException = null;

                // download the file from the selected mirror
                using (FileStream stream = new FileStream(destination, FileMode.OpenOrCreate, FileAccess.Write)) {
                    IEnumerator download = Download(url, info.Size, stream);

                    while (true) {
                        bool hasNext;

                        try {
                            hasNext = download.MoveNext();
                        } catch (Exception e) {
                            log.Warning($"An uncaught exception happened while downloading from {url}! Falling back to next mirror.\n" + e);
                            lastException = e;
                            break; // out of the download loop
                        }

                        if (!hasNext) {
                            break; // out of the download loop
                        }

                        object message = ((object[]) download.Current)[0];
                        if (message.ToString() != "") {
                            yield return messagePrefix + ": " + message.ToString()
                                .Replace(langGet("en", "downloadingfile"), langGet(lang, "downloadingfile"))
                                .Replace(langGet("en", "downloadingprogress"), langGet(lang, "downloadingprogress"));
                        }
                    }
                }

                if (lastException != null) continue; // to the next mirror

                yield return messagePrefix + ": verifying checksum";

                try {
                    verifyChecksum(info, destination);
                    yield break; // download successful!
                } catch (Exception e) {
                    log.Warning($"Error while checking integrity of file downloaded from {url}! Falling back to next mirror.\n" + e);
                    lastException = e;
                    continue; // to the next mirror
                }
            }

            if (lastException != null) {
                // we went through all mirrors, and nothing worked :despair:
                if (File.Exists(destination)) {
                    File.Delete(destination);
                }

                throw lastException;
            }
        }

        private struct ModUpdateInfo {
            public string Name { get; set; }
            public string URL { get; set; }
            public List<string> xxHash { get; set; }
            public int Size { get; set; }
        }

        // Why do you need to tell C# how to get an enumerator from an enumerator
        private class EnumeratorEnumerator : IEnumerable {
            public IEnumerator Enumerator { get; set; }
            public IEnumerator GetEnumerator() => Enumerator;
        }

        /// <summary>
        /// Downloads the full update list from the update checker server.
        /// Returns null if the download fails for any reason.
        /// </summary>
        private static Dictionary<string, ModUpdateInfo> downloadModUpdateList(bool apiMirror) {
            Dictionary<string, ModUpdateInfo> updateCatalog = null;

            try {
                string modUpdaterDatabaseUrl = getModUpdaterDatabaseUrl(apiMirror);

                log.Debug($"Downloading last versions list from {modUpdaterDatabaseUrl}");

                using (HttpClient wc = new HttpClientWithCompressionSupport()) {
                    string yamlData = wc.GetStringAsync(modUpdaterDatabaseUrl).Result;
                    updateCatalog = YamlHelper.Deserializer.Deserialize<Dictionary<string, ModUpdateInfo>>(yamlData);
                    foreach (string name in updateCatalog.Keys) {
                        updateCatalog[name] = new ModUpdateInfo {
                            Name = name,
                            URL = updateCatalog[name].URL,
                            Size = updateCatalog[name].Size,
                            xxHash = updateCatalog[name].xxHash
                        };
                    }
                    log.Debug($"Downloaded {updateCatalog.Count} item(s)");
                }
            } catch (Exception e) {
                log.Error("Downloading database failed! " + e.ToString());
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
            using (HashAlgorithm hasher = XXHash64.Create())
            using (FileStream stream = File.Open(filePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete))
                actualHash = BitConverter.ToString(hasher.ComputeHash(stream)).Replace("-", "").ToLowerInvariant();

            string expectedHash = update.xxHash[0];
            log.Debug($"Verifying checksum: actual hash is {actualHash}, expected hash is {expectedHash}");
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
            log.Debug($"Deleting mod .zip: {mod.Path}");
            File.Delete(mod.Path);

            log.Debug($"Moving {zipPath} to {mod.Path}");
            File.Move(zipPath, mod.Path);
        }

        /// <summary>
        /// Retrieves the mod updater database location from everestapi.github.io.
        /// This should point to a running instance of https://github.com/maddie480/EverestUpdateCheckerServer.
        /// </summary>
        private static string getModUpdaterDatabaseUrl(bool apiMirror) {
            if (apiMirror) return "https://everestapi.github.io/updatermirror/everest_update.yaml";

            using (HttpClient wc = new HttpClientWithCompressionSupport()) {
                log.Debug("Fetching mod updater database URL");
                return wc.GetStringAsync("https://everestapi.github.io/modupdater.txt").Result.Trim();
            }
        }
    }
}
