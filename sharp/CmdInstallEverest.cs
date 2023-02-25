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
    public unsafe partial class CmdInstallEverest : Cmd<string, string, IEnumerator> {

        public override IEnumerator Run(string root, string artifactBase) {
            // MiniInstaller reads orig/Celeste.exe and copies Celeste.exe into it but only if missing.
            // Olympus can help out and delete the orig folder if the existing Celeste.exe isn't modded.
            string installedVersion = Cmds.Get<CmdGetVersionString>().Run(root);
            if (installedVersion.StartsWith("Celeste ") && !installedVersion.Contains("Everest")) {
                string orig = Path.Combine(root, "orig");
                if (Directory.Exists(orig)) {
                    yield return Status("Deleting previous backup", false, "", false);
                    Directory.Delete(orig, true);
                }
            }

            bool isNative;
            if (artifactBase.StartsWith("file://")) {
                artifactBase = artifactBase.Substring("file://".Length);
                yield return Status($"Unzipping {Path.GetFileName(artifactBase)}", false, "download", false);

                using (FileStream wrapStream = File.Open(artifactBase, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete))
                using (ZipArchive wrap = new ZipArchive(wrapStream, ZipArchiveMode.Read)) {
                    ZipArchiveEntry zipEntry = wrap.GetEntry("olympus-build/build.zip");
                    if (zipEntry == null) {
                        isNative = CheckNativeMiniInstaller(wrap, "main/");
                        yield return Unpack(wrap, root, "main/");
                    } else {
                        using (Stream zipStream = zipEntry.Open())
                        using (ZipArchive zip = new ZipArchive(zipStream, ZipArchiveMode.Read)) {
                            isNative = CheckNativeMiniInstaller(zip);
                            yield return Unpack(zip, root);
                        }
                    }
                }

            } else {
                // Only new builds offer olympus-meta and olympus-build artifacts.
                yield return Status("Downloading metadata", false, "", false);

                int size;

                try {
                    byte[] zipData;
                    using (WebClient wc = new WebClient())
                        zipData = wc.DownloadData(artifactBase + "olympus-meta");
                    using (MemoryStream zipStream = new MemoryStream(zipData))
                    using (ZipArchive zip = new ZipArchive(zipStream, ZipArchiveMode.Read)) {
                        using (Stream sizeStream = zip.GetEntry("olympus-meta/size.txt").Open())
                        using (StreamReader sizeReader = new StreamReader(sizeStream))
                            size = int.Parse(sizeReader.ReadToEnd().Trim());
                    }

                } catch (Exception) {
                    size = 0;
                }

                if (size > 0) {
                    yield return Status("Downloading olympus-build.zip", false, "download", false);

                    using (MemoryStream wrapStream = new MemoryStream()) {
                        yield return Download(artifactBase + "olympus-build", size, wrapStream);

                        yield return Status("Unzipping olympus-build.zip", false, "download", false);
                        wrapStream.Seek(0, SeekOrigin.Begin);
                        using (ZipArchive wrap = new ZipArchive(wrapStream, ZipArchiveMode.Read)) {
                            using (Stream zipStream = wrap.GetEntry("olympus-build/build.zip").Open())
                            using (ZipArchive zip = new ZipArchive(zipStream, ZipArchiveMode.Read)) {
                                isNative = CheckNativeMiniInstaller(zip);
                                yield return Unpack(zip, root);
                            }
                        }
                    }

                } else {
                    yield return Status("Downloading main.zip", false, "download", false);

                    using (MemoryStream zipStream = new MemoryStream()) {
                        yield return Download(artifactBase + "main", size, zipStream);

                        yield return Status("Unzipping main.zip", false, "download", false);
                        zipStream.Seek(0, SeekOrigin.Begin);
                        using (ZipArchive zip = new ZipArchive(zipStream, ZipArchiveMode.Read)) {
                            isNative = CheckNativeMiniInstaller(zip, "main/");
                            yield return Unpack(zip, root, "main/");
                        }
                    }
                }
            }

            // Legacy MiniInstaller builds can't correctly downgrade .NET Core installs
            // Restore the install backup in this case
            if (!isNative && File.Exists(Path.Combine(root, "Celeste.dll"))) {
                yield return Status("Restoring non-modded backup", false, "", false);

                foreach (string origEntry in Directory.EnumerateFileSystemEntries(Path.Combine(root, "orig"))) {
                    // Ignore the Content folder - it is either a symlink or a 1-to-1 copy
                    if (Path.GetFileName(origEntry) == "Content")
                        continue;

                    if (!File.Exists(origEntry) && !Directory.Exists(origEntry))
                        continue;

                    string gameEntry = Path.Combine(root, Path.GetFileName(origEntry));
                    if (File.Exists(origEntry)) {
                        File.Delete(gameEntry);
                        File.Move(origEntry, gameEntry);
                    } else if (Directory.Exists(gameEntry)) {
                        Directory.Delete(gameEntry, true);
                        Directory.Move(origEntry, gameEntry);
                    }
                }

                Directory.Delete(Path.Combine(root, "orig"), true);
                File.Delete(Path.Combine(root, "Celeste.dll")); // Explicitly delete Celeste.dll
            }

            yield return Status("Starting MiniInstaller", false, "monomod", false);
            yield return Install(root, isNative);
        }

    }
}
