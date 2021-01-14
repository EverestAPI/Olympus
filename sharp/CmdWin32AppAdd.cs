using Microsoft.Win32;
using Mono.Cecil;
using Mono.Cecil.Cil;
using MonoMod.Utils;
using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.ComTypes;
using System.Text;
using System.Threading.Tasks;

namespace Olympus {
    public class CmdWin32AppAdd : Cmd<string, string, string> {

        public override string Run(string exepath, string version) {
            using (RegistryKey key = Win32RegHelper.OpenOrCreateKey(@"HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\Olympus", true)) {
                if (key == null)
                    return null;

                key.SetValue("DisplayName", "Olympus");
                key.SetValue("Publisher", "Everest Team");
                key.SetValue("HelpLink", "https://everestapi.github.io/");
                key.SetValue("DisplayIcon", $"{exepath},0");
                key.SetValue("DisplayVersion", version);
                DirectoryInfo dir = new DirectoryInfo(Path.GetDirectoryName(exepath));
                key.SetValue("InstallLocation", dir);
                key.SetValue("InstallDate", dir.CreationTime.ToString("yyyyMMdd"));
                key.SetValue("EstimatedSize", (int) (GetDirectorySize(dir) / 1024));
                key.SetValue("UninstallString", $"\"{Program.SelfPath}\" --uninstall");
                key.SetValue("QuietUninstallString", $"\"{Program.SelfPath}\" --uninstall --quiet");
                key.SetValue("NoModify", 1);
                key.SetValue("NoRepair", 1);

                return null;
            }
        }

        public static long GetDirectorySize(DirectoryInfo dir) {
            long size = 0;

            foreach (FileInfo file in dir.EnumerateFiles())
                size += file.Length;

            foreach (DirectoryInfo subdir in dir.EnumerateDirectories())
                size += GetDirectorySize(subdir);

            return size;
        }

    }
}
