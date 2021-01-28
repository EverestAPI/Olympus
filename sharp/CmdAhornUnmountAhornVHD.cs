using Mono.Cecil;
using Mono.Cecil.Cil;
using MonoMod.Utils;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
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
    public unsafe class CmdAhornUnmountAhornVHD : Cmd<IEnumerator> {

        public override IEnumerator Run() {
            yield return Status("Preparing unmounting of Ahorn-VHD", false, "", false);

            if (!PlatformHelper.Is(Platform.Windows | Platform.Bits64)) {
                yield return Status("Unsupported platform.", 1f, "error", false);
                throw new PlatformNotSupportedException($"Platform not supported: {PlatformHelper.Current}");
            }

            string vhd = AhornHelper.VHDPath;
            if (!File.Exists(vhd))
                throw new Exception("Ahorn-VHD missing.");

            string tmp = vhd + ".diskpart.unmount.txt";
            if (File.Exists(tmp))
                File.Delete(tmp);
            File.WriteAllText(tmp, $@"
select vdisk file=""{vhd}""
detach
"
                .TrimStart().Replace("\r\n", "\n").Replace("\n", "\r\n")
            );

            yield return Status($"Unmounting {vhd}", false, "", false);
            if (ProcessHelper.RunAs("diskpart.exe", $"/s \"{tmp}\"") != 0)
                throw new Exception("diskpart encountered a fatal error.");
            yield return Status($"{Path.GetFileName(vhd)} unmounted", false, "", false);
        }

    }
}
