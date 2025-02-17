#if WIN32
using Microsoft.Win32;
using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;

namespace Olympus {
    public class CmdWin32AppUninstall : Cmd<bool, string> {
        [DllImport("user32")]
        private static extern int MessageBoxW(
            IntPtr hWnd,
            [MarshalAs(UnmanagedType.LPWStr)] string text,
            [MarshalAs(UnmanagedType.LPWStr)] string caption,
            uint type
        );

        private static void showMessage(string message) {
            MessageBoxW(IntPtr.Zero, message, "Olympus", 0 /* MB_OK */);
        }
        private static bool askForConfirmation(string message) {
            return MessageBoxW(IntPtr.Zero, message, "Olympus", 4 /* MB_YESNO */) == 6 /* IDYES */;
        }

        public override string Run(bool quiet) {
            string selfPath = Assembly.GetExecutingAssembly().Location;

            string root = Environment.GetEnvironmentVariable("OLYMPUS_ROOT");
            if (string.IsNullOrEmpty(root))
                root = Win32RegHelper.OpenOrCreateKey(@"HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\Olympus", false)?.GetValue("InstallLocation") as string;

            string selfDirectory = Path.GetDirectoryName(selfPath);
            if (string.IsNullOrEmpty(root)) root = Path.GetDirectoryName(selfDirectory);

            if (!File.Exists(Path.Combine(root, "love.exe")) ||
                !File.Exists(Path.Combine(root, "love.dll")) ||
                !Directory.Exists(Path.Combine(root, "sharp"))) {
                if (!quiet)
                    showMessage("The Olympus uninstaller has encountered an error:\nCan't verify the main folder.\n\nPlease delete %AppData%/Olympus manually.");
                return null;
            }

            if (selfPath.StartsWith(root)) {
                string tmpDir = Path.Combine(Path.GetTempPath(), "Olympus.Uninstall");
                try {
                    if (!Directory.Exists(tmpDir))
                        Directory.CreateDirectory(tmpDir);

                    foreach (string f in Directory.GetFiles(selfDirectory)) {
                        string file = Path.GetFileName(f);
                        string tmpDep = Path.Combine(tmpDir, file);
                        if (File.Exists(tmpDep)) File.Delete(tmpDep);
                        File.Copy(Path.Combine(selfDirectory, file), tmpDep);
                    }
                }
                catch {
                    if (!quiet)
                        showMessage("The Olympus uninstaller has encountered an error:\nCan't copy the uninstaller into %TMP%.\n\nPlease delete %AppData%/Olympus manually.");
                    return null;
                }

                Environment.SetEnvironmentVariable("OLYMPUS_ROOT", root);

                Process process = new Process();
                process.StartInfo.FileName = Path.Combine(tmpDir, "Olympus.Sharp.exe");
                process.StartInfo.Arguments = "--uninstall" + (quiet ? " --quiet" : "");
                Environment.CurrentDirectory = process.StartInfo.WorkingDirectory = tmpDir;
                process.Start();
                return null;
            }

            if (!quiet && !askForConfirmation($"Do you want to uninstall Olympus from the following folder?\n{root}\n\nEverest and all your mods will stay installed."))
                return null;

            try {
                Directory.Delete(root, true);
            }
            catch {
                if (!quiet)
                    showMessage("The Olympus uninstaller has encountered an error:\nCan't delete the Olympus folder.\n\nPlease delete %AppData%/Olympus manually.");
                return null;
            }

            try {
                using (RegistryKey key = Win32RegHelper.OpenOrCreateKey(@"HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall", true))
                    key?.DeleteSubKeyTree("Olympus");
            }
            catch {
            }

            if (!quiet)
                showMessage("Olympus was uninstalled successfully.");

            return null;
        }
    }
}
#endif
