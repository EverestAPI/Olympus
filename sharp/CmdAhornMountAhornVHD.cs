using MonoMod.Utils;
using System;
using System.Collections;
using System.IO;

namespace Olympus {
    public class CmdAhornMountAhornVHD : Cmd<IEnumerator> {

        public override IEnumerator Run() {
            yield return Status("Preparing mounting of Ahorn-VHD", false, "", false);

            if (!PlatformHelper.Is(Platform.Windows | Platform.Bits64)) {
                yield return Status("Unsupported platform.", 1f, "error", false);
                throw new PlatformNotSupportedException($"Platform not supported: {PlatformHelper.Current}");
            }

            string vhd = AhornHelper.VHDPath;
            if (!File.Exists(vhd))
                throw new Exception("Ahorn-VHD missing.");

            string mount = AhornHelper.VHDMountPath;
            if (File.Exists(mount))
                File.Delete(mount);
            if (Directory.Exists(mount))
                Directory.Delete(mount);
            Directory.CreateDirectory(mount);

            string tmp = vhd + ".diskpart.mount.txt";
            if (File.Exists(tmp))
                File.Delete(tmp);
            File.WriteAllText(tmp, $@"
select vdisk file=""{vhd}""
detach vdisk noerr
attach vdisk
select partition 1
assign mount=""{mount}""
"
                .TrimStart().Replace("\r\n", "\n").Replace("\n", "\r\n")
            );

            yield return Status($"Mounting {vhd} to {mount}", false, "", false);
            if (ProcessHelper.RunAs("diskpart.exe", $"/s \"{tmp}\"") != 0)
                throw new Exception("diskpart encountered a fatal error.");
            yield return Status($"{Path.GetFileName(vhd)} mounted", false, "", false);
        }

    }
}
