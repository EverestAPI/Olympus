using MonoMod.Utils;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Olympus {
    public static class AhornHelper {

        // FIXME: Easily configurable as Julia can grow big!
        private static string _RootPath;

        public static string RootPath {
            get {
                if (!string.IsNullOrEmpty(_RootPath))
                    return _RootPath;

                string path = Environment.GetEnvironmentVariable("OLYMPUS_AHORN_ROOT");
                if (!string.IsNullOrEmpty(path))
                    return _RootPath = path;

                if (PlatformHelper.Is(Platform.Windows)) {
                    // On Windows, LocalApplicationData is used for configs and ApplicationData is used for shared installs.
                    return _RootPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "Olympus-Ahorn");

                } else {
                    // Elsewhere, ApplicationData is used for configs and LocalApplicationData is the equivalent of ~/.local/share
                    string appdata = null;
                    try {
                        appdata = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
                    } catch {
                    }
                    if (!string.IsNullOrEmpty(appdata))
                        return _RootPath = Path.Combine(appdata, "Olympus-Ahorn");

                    return _RootPath = Path.Combine(Path.GetDirectoryName(Program.RootPath), "ahorn");
                }
            }
            set {
                _RootPath = value;
            }
        }

        public static string JuliaPath;

        public static string RunProcess(string name, string args, out string err) {
            Process process = new Process();

            process.StartInfo.FileName = name;
            process.StartInfo.Arguments = args;

            process.StartInfo.UseShellExecute = false;
            process.StartInfo.CreateNoWindow = true;
            process.StartInfo.RedirectStandardOutput = true;
            process.StartInfo.RedirectStandardError = true;

            process.Start();
            process.WaitForExit();
            string data = process.StandardOutput.ReadToEnd();
            err = process.StandardError.ReadToEnd();

            process.Dispose();
            return data;
        }

        public static string FindJulia(bool force) {
            if (!force && !string.IsNullOrEmpty(JuliaPath) && File.Exists(JuliaPath))
                return JuliaPath;

            string juliaName = PlatformHelper.Is(Platform.Windows) ? "julia.exe" : "julia";
            string juliaPath = RunProcess(
                PlatformHelper.Is(Platform.Windows) ? "where.exe" : "which",
                juliaName,
                out _
            ).Split('\n').FirstOrDefault()?.Trim();
            if (!string.IsNullOrEmpty(juliaPath) && File.Exists(juliaPath))
                return JuliaPath = juliaPath;

            juliaPath = Path.Combine(RootPath, "julia", "bin", juliaName);
            if (File.Exists(juliaPath))
                return JuliaPath = juliaPath;

            return null;
        }

        public static string GetJuliaVersion() {
            return null; // FIXME: Implement!
        }

    }
}
