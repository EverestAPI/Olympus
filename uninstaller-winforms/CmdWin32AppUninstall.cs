using Microsoft.Win32;
using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Windows.Forms;


namespace Olympus {
    public class CmdWin32AppUninstall {
        public string Run(bool quiet) {
            if (!quiet) {
                try {
                    Application.EnableVisualStyles();
                } catch {
                }
            }

            string selfPath = Assembly.GetExecutingAssembly().Location;

            string root = Environment.GetEnvironmentVariable("OLYMPUS_ROOT");
            if (string.IsNullOrEmpty(root))
                root = Win32RegHelper.OpenOrCreateKey(@"HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\Olympus", false)?.GetValue("InstallLocation") as string;
            if (string.IsNullOrEmpty(root))
                root = Path.GetDirectoryName(Path.GetDirectoryName(selfPath));

            if (!File.Exists(Path.Combine(root, "main.exe")) ||
                !File.Exists(Path.Combine(root, "love.dll")) ||
                !Directory.Exists(Path.Combine(root, "sharp"))) {
                if (!quiet)
                    MessageBox.Show("The Olympus uninstaller has encountered an error:\nCan't verify the main folder.\n\nPlease delete %AppData%/Olympus manually.", "Olympus", MessageBoxButtons.OK);
                return null;
            }

            if (selfPath.StartsWith(root)) {
                string tmpDir = Path.Combine(Path.GetTempPath(), "Olympus.Uninstall");
                string tmp = Path.Combine(tmpDir, "uninstall.exe");
                try {
                    if (!Directory.Exists(tmpDir))
                        Directory.CreateDirectory(tmpDir);
                    if (File.Exists(tmp))
                        File.Delete(tmp);
                    File.Copy(selfPath, tmp);
                } catch {
                    if (!quiet)
                        MessageBox.Show("The Olympus uninstaller has encountered an error:\nCan't copy the uninstaller into %TMP%.\n\nPlease delete %AppData%/Olympus manually.", "Olympus", MessageBoxButtons.OK);
                    return null;
                }

                Environment.SetEnvironmentVariable("OLYMPUS_ROOT", root);

                Process process = new Process();
                process.StartInfo.FileName = tmp;
                process.StartInfo.Arguments = quiet ? " --quiet" : "";
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
