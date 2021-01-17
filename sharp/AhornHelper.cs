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

        private static string OrigJuliaDepotPath = Environment.GetEnvironmentVariable("JULIA_DEPOT_PATH") ?? "";

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

                    return _RootPath = Path.Combine(Path.GetDirectoryName(Program.RootDirectory), "ahorn");
                }
            }
            set {
                _RootPath = value;
            }
        }

        public static string JuliaPath;
        public static bool JuliaIsLocal;

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
            string data = process.StandardOutput.ReadToEnd().Trim();
            err = process.StandardError.ReadToEnd().Trim();

            process.Dispose();
            return data;
        }

        public static string RunJulia(string script, bool? localDepot = null) {
            string julia = FindJulia(false);
            if (string.IsNullOrEmpty(julia) || !File.Exists(julia))
                return null;

            if (localDepot ?? JuliaIsLocal) {
                string depot = Path.Combine(RootPath, "julia-depot");
                if (!Directory.Exists(depot))
                    Directory.CreateDirectory(depot);
                Environment.SetEnvironmentVariable("JULIA_DEPOT_PATH", $"{depot}{Path.PathSeparator}{OrigJuliaDepotPath}");
            } else {
                Environment.SetEnvironmentVariable("JULIA_DEPOT_PATH", string.IsNullOrEmpty(OrigJuliaDepotPath) ? Path.PathSeparator.ToString() : OrigJuliaDepotPath);
            }

            string tmp = Path.GetTempFileName();
            File.WriteAllText(tmp, script);
            string rv = RunProcess(julia, tmp, out _);
            File.Delete(tmp);
            return rv;
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
            if (!string.IsNullOrEmpty(juliaPath) && File.Exists(juliaPath)) {
                JuliaIsLocal = false;
                return JuliaPath = juliaPath;
            }

            juliaPath = Path.Combine(RootPath, "julia", "bin", juliaName);
            if (File.Exists(juliaPath)) {
                JuliaIsLocal = true;
                return JuliaPath = juliaPath;
            }

            return null;
        }

        public static string GetJuliaVersion() {
            return RunJulia(@"
print(VERSION)
");
        }

    }
}
