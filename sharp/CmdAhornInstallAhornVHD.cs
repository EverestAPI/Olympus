using MonoMod.Utils;
using System;
using System.Collections;
using System.Diagnostics;
using System.IO;

namespace Olympus {
    public class CmdAhornInstallAhornVHD : Cmd<IEnumerator> {

        public override IEnumerator Run() {
            yield return Status("Preparing installation of Ahorn-VHD", false, "", false);

            if (!PlatformHelper.Is(Platform.Windows | Platform.Bits64)) {
                yield return Status("Unsupported platform.", 1f, "error", false);
                throw new PlatformNotSupportedException($"Platform not supported: {PlatformHelper.Current}");
            }

            string vhd = AhornHelper.VHDPath;
            if (File.Exists(vhd)) {
                yield return Status("Ahorn-VHD already exists - please delete it before reinstalling.", 1f, "error", false);
                throw new Exception("Ahorn-VHD already exists.");
            }

            string archive = vhd + ".7z";
            bool tmpPerm = File.Exists(archive);

            try {
                if (tmpPerm) {
                    yield return Status($"{Path.GetFileName(archive)} already exists - reusing and preserving", false, "", false);
                } else {
                    const string url = "https://0x0a.de/ahornvhd/files/ahornvhd.7z";
                    yield return Status($"Downloading {url} to {archive}", false, "download", false);
                    string tmp = archive + ".part";
                    if (File.Exists(tmp))
                        File.Delete(tmp);
                    using (FileStream stream = File.Open(tmp, FileMode.Create, FileAccess.ReadWrite, FileShare.None))
                        yield return Download(url, 0, stream);
                    File.Move(tmp, archive);
                }

                string sevenzip = Path.Combine(Program.RootDirectory, "7zr.exe");

                if (!File.Exists(sevenzip)) {
                    const string url = "https://raw.githubusercontent.com/EverestAPI/Olympus/main/lib-windows/7zr.exe";
                    yield return Status($"Couldn't find 7zr.exe, downloading from {url}", false, "download", false);
                    using (FileStream stream = File.Open(sevenzip, FileMode.Create, FileAccess.ReadWrite, FileShare.None))
                        yield return Download(url, 0, stream);
                }

                yield return Status("Extracting ahornvhd.7z", false, "download", false);
                using (Process process = ProcessHelper.Wrap(sevenzip, $"x \"{archive}\" \"-o{Path.GetDirectoryName(vhd)}\" {Path.GetFileName(vhd)} -bb3")) {
                    process.Start();
                    for (string line; (line = process.StandardOutput.ReadLine()) != null;)
                        yield return Status(line, false, "download", false);
                    process.WaitForExit();
                    if (process.ExitCode != 0)
                        throw new Exception("7zr encountered a fatal error:\n" + process.StandardError.ReadToEnd());
                    if (!File.Exists(vhd))
                        throw new Exception($"File not extracted: {vhd}");
                    yield return Status("ahornvhd.7z extracted", false, "download", false);
                }

            } finally {
                if (!tmpPerm && File.Exists(archive))
                    File.Delete(archive);
            }

            yield return Cmds.Get<CmdAhornMountAhornVHD>().Run();

            yield return Cmds.Get<CmdAhornInstallAhorn>().Run();
        }

    }
}
