using Microsoft.Win32;
using Mono.Cecil;
using Mono.Cecil.Cil;
using MonoMod.Utils;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.ComTypes;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace Olympus {
    public class CmdWin32AppUninstall : Cmd<bool, string> {
        public override string Run(bool quiet) {
            if (!quiet) {
                try {
                    Application.EnableVisualStyles();
                } catch {
                }
            }

            string root = Environment.GetEnvironmentVariable("OLYMPUS_ROOT");
            if (string.IsNullOrEmpty(root))
                root = Win32RegHelper.OpenOrCreateKey(@"HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\Olympus", false)?.GetValue("InstallLocation") as string;
            if (string.IsNullOrEmpty(root))
                root = Path.GetDirectoryName(Path.GetDirectoryName(Program.SelfPath));

            if (!File.Exists(Path.Combine(root, "main.exe")) ||
                !File.Exists(Path.Combine(root, "love.dll")) ||
                !Directory.Exists(Path.Combine(root, "sharp"))) {
                if (!quiet)
                    MessageBox.Show("The Olympus uninstaller has encountered an error:\nCan't verify the main folder.\n\nPlease delete %AppData%/Olympus manually.", "Olympus", MessageBoxButtons.OK);
                return null;
            }

            if (Program.SelfPath.StartsWith(root)) {
                string tmpDir = Path.Combine(Path.GetTempPath(), "Olympus.Uninstall");
                string tmp = Path.Combine(tmpDir, "Olympus.Sharp.exe");
                try {
                    if (!Directory.Exists(tmpDir))
                        Directory.CreateDirectory(tmpDir);
                    string tmpDep = Path.Combine(tmpDir, "MonoMod.Utils.dll");
                    if (File.Exists(tmpDep))
                        File.Delete(tmpDep);
                    File.Copy(Path.Combine(Path.GetDirectoryName(Program.SelfPath), "MonoMod.Utils.dll"), tmpDep);
                    if (File.Exists(tmp))
                        File.Delete(tmp);
                    File.Copy(Program.SelfPath, tmp);
                } catch {
                    if (!quiet)
                        MessageBox.Show("The Olympus uninstaller has encountered an error:\nCan't copy the uninstaller into %TMP%.\n\nPlease delete %AppData%/Olympus manually.", "Olympus", MessageBoxButtons.OK);
                    return null;
                }

                Environment.SetEnvironmentVariable("OLYMPUS_ROOT", root);

                Process process = new Process();
                process.StartInfo.FileName = tmp;
                process.StartInfo.Arguments = "--uninstall" + (quiet ? " --quiet" : "");
                Environment.CurrentDirectory = process.StartInfo.WorkingDirectory = tmpDir;
                process.Start();
                return null;
            }

            if (!quiet && MessageBox.Show($"Do you want to uninstall Olympus from the following folder?\n{root}\n\nEverest and all your mods will stay installed.", "Olympus", MessageBoxButtons.YesNo) != DialogResult.Yes)
                return null;

            try {
                Directory.Delete(root, true);
            } catch {
                if (!quiet)
                    MessageBox.Show("The Olympus uninstaller has encountered an error:\nCan't delete the Olympus folder.\n\nPlease delete %AppData%/Olympus manually.", "Olympus", MessageBoxButtons.OK);
                return null;
            }

            try {
                using (RegistryKey key = Win32RegHelper.OpenOrCreateKey(@"HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall", true))
                    key?.DeleteSubKeyTree("Olympus");
            } catch {
            }

            if (!quiet)
                MessageBox.Show("Olympus was uninstalled successfully.", "Olympus", MessageBoxButtons.OK);

            return null;
        }
    }
}
