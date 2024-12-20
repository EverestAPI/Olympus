using System;
using System.Collections;
using System.IO;
using System.IO.Compression;
using System.Net;

namespace Olympus {
    public partial class CmdInstallEverest : Cmd<string, string, string, string, IEnumerator> {

        public override IEnumerator Run(string root, string mainDownload, string olympusMetaDownload, string olympusBuildDownload) {
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

            bool isNativeInstall = File.Exists(Path.Combine(root, "Celeste.dll")), isNativeArtifact = false;

            IEnumerator UnpackEverestArtifact(ZipArchive zip, string prefix = "") {
                isNativeArtifact = CheckNativeMiniInstaller(zip, prefix);

                // Legacy MiniInstaller builds can't correctly downgrade .NET Core installs
                // Restore the install backup in this case
                if (!isNativeArtifact && isNativeInstall) {
                    yield return Status("Restoring non-modded backup", false, "", false);
                    yield return Cmds.Get<CmdUninstallEverest>().Run(root, mainDownload);
                }

                yield return Unpack(zip, root, prefix);
            }

            if (olympusBuildDownload.StartsWith("file://")) {
                olympusBuildDownload = olympusBuildDownload.Substring("file://".Length);
                yield return Status($"Unzipping {Path.GetFileName(olympusBuildDownload)}", false, "download", false);

                using (FileStream wrapStream = File.Open(olympusBuildDownload, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete))
                using (ZipArchive wrap = new ZipArchive(wrapStream, ZipArchiveMode.Read)) {
                    ZipArchiveEntry zipEntry = wrap.GetEntry("olympus-build/build.zip");
                    if (zipEntry == null)
                        yield return UnpackEverestArtifact(wrap, "main/");
                    else {
                        using (Stream zipStream = zipEntry.Open())
                        using (ZipArchive zip = new ZipArchive(zipStream, ZipArchiveMode.Read))
                            yield return UnpackEverestArtifact(zip);
                    }
                }

            } else {
                // Only new builds offer olympus-meta and olympus-build artifacts.
                yield return Status("Downloading metadata", false, "", false);

                int size;

                try {
                    byte[] zipData;
                    using (WebClient wc = new WebClient())
                        zipData = wc.DownloadData(olympusMetaDownload);
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
                        yield return Download(olympusBuildDownload, size, wrapStream);

                        yield return Status("Unzipping olympus-build.zip", false, "download", false);
                        wrapStream.Seek(0, SeekOrigin.Begin);
                        using (ZipArchive wrap = new ZipArchive(wrapStream, ZipArchiveMode.Read)) {
                            using (Stream zipStream = wrap.GetEntry("olympus-build/build.zip").Open())
                            using (ZipArchive zip = new ZipArchive(zipStream, ZipArchiveMode.Read))
                                yield return UnpackEverestArtifact(zip);
                        }
                    }

                } else {
                    yield return Status("Downloading main.zip", false, "download", false);

                    using (MemoryStream zipStream = new MemoryStream()) {
                        yield return Download(mainDownload, size, zipStream);

                        yield return Status("Unzipping main.zip", false, "download", false);
                        zipStream.Seek(0, SeekOrigin.Begin);
                        using (ZipArchive zip = new ZipArchive(zipStream, ZipArchiveMode.Read))
                            yield return UnpackEverestArtifact(zip, "main/");
                    }
                }
            }

            yield return Status($"Starting {(isNativeArtifact ? "native" : "legacy")} MiniInstaller", false, "monomod", false);
            yield return Install(root, isNativeArtifact);
        }

    }
}
