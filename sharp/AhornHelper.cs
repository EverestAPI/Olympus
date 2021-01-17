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

        private const string PrefixPkgActivate = @"
using Pkg

stdoutPrev = stdout
redirect_stdout(stderr)

try
    Pkg.activate(ENV[""AHORN_ENV""])
catch e
    return
end

redirect_stdout(stdoutPrev)

";

        private static string OrigJuliaDepotPath = Environment.GetEnvironmentVariable("JULIA_DEPOT_PATH") ?? "";

        private static string _RootPath;

        public static string RootPath {
            get {
                if (!string.IsNullOrEmpty(_RootPath))
                    return _RootPath;

                string path = Environment.GetEnvironmentVariable("OLYMPUS_AHORN_ROOT");
                if (!string.IsNullOrEmpty(path))
                    return _RootPath = path;

                // On non-Windows platforms, LocalApplicationData is the equivalent of ~/.local/share
                string appdata = null;
                try {
                    appdata = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
                } catch {
                }
                if (!string.IsNullOrEmpty(appdata))
                    return _RootPath = Path.Combine(appdata, "Olympus-Ahorn");

                return _RootPath = Path.Combine(Path.GetDirectoryName(Program.RootDirectory), "ahorn");
            }
            set {
                _RootPath = value;
                JuliaPath = null;
                AhornPath = null;
            }
        }

        private static string _AhornEnv;

        public static string AhornEnv {
            get {
                if (!string.IsNullOrEmpty(_AhornEnv))
                    return _AhornEnv;

                string path = Environment.GetEnvironmentVariable("OLYMPUS_AHORN_ENV");
                if (!string.IsNullOrEmpty(path))
                    return _AhornEnv = path;

                // The following is based off of how Ahorn's install_ahorn.jl determines the env path.

                if (PlatformHelper.Is(Platform.Windows)) {
                    return _AhornEnv = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Ahorn", "env");

                } else {
                    // This must be done like this as it behaves exactly like this on ALL non-Windows platforms.
                    string config = Environment.GetEnvironmentVariable("XDG_CONFIG_HOME");
                    if (string.IsNullOrEmpty(config))
                        config = Path.Combine(Environment.GetEnvironmentVariable("HOME"), ".config");
                    return _AhornEnv = Path.Combine(config, "Ahorn", "env");
                }
            }
            set {
                _AhornEnv = value;
                AhornPath = null;
            }
        }

        public static string JuliaPath { get; private set; }
        public static bool JuliaIsLocal { get; private set; }

        public static string AhornPath { get; private set; }
        public static bool AhornIsLocal { get; private set; }

        public static Process RunProcess(string name, string args) {
            Process process = new Process();

            process.StartInfo.FileName = name;
            process.StartInfo.Arguments = args;

            process.StartInfo.UseShellExecute = false;
            process.StartInfo.CreateNoWindow = true;
            process.StartInfo.RedirectStandardOutput = true;
            process.StartInfo.RedirectStandardError = true;

            process.Start();
            return process;
        }

        public static string GetProcessOutput(string name, string args, out string err) {
            using (Process process = RunProcess(name, args)) {
                process.WaitForExit();
                err = process.StandardError.ReadToEnd().Trim();
                return process.StandardOutput.ReadToEnd().Trim();
            }
        }

        public static string GetJuliaOutput(string script, bool? localDepot = null) {
            string julia = FindJulia(false);
            if (string.IsNullOrEmpty(julia) || !File.Exists(julia))
                return null;

            if (localDepot ?? JuliaIsLocal) {
                string depot = Path.Combine(RootPath, "julia-depot");
                if (!Directory.Exists(depot))
                    Directory.CreateDirectory(depot);
                Environment.SetEnvironmentVariable("JULIA_DEPOT_PATH", depot);
            } else {
                Environment.SetEnvironmentVariable("JULIA_DEPOT_PATH", string.IsNullOrEmpty(OrigJuliaDepotPath) ? Path.PathSeparator.ToString() : OrigJuliaDepotPath);
            }

            Environment.SetEnvironmentVariable("AHORN_ENV", AhornEnv);

            string tmp = Path.GetTempFileName();
            File.WriteAllText(tmp, script);
            string rv = GetProcessOutput(julia, tmp, out string err);
            Console.Error.WriteLine(err);
            File.Delete(tmp);
            return rv;
        }

        public static string FindJulia(bool force) {
            if (!force && !string.IsNullOrEmpty(JuliaPath) && File.Exists(JuliaPath))
                return JuliaPath;
            
            string name = PlatformHelper.Is(Platform.Windows) ? "julia.exe" : "julia";

            string path = Path.Combine(RootPath, "julia", "bin", name);
            if (File.Exists(path)) {
                JuliaIsLocal = true;
                return JuliaPath = path;
            }

            path = GetProcessOutput(
                PlatformHelper.Is(Platform.Windows) ? "where.exe" : "which",
                name,
                out _
            ).Split('\n').FirstOrDefault()?.Trim();
            if (!string.IsNullOrEmpty(path) && File.Exists(path)) {
                JuliaIsLocal = false;
                return JuliaPath = path;
            }

            if (PlatformHelper.Is(Platform.Windows)) {
                // Julia on Windows is a hot mess.
                string localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
                IEnumerable<string> all = Directory.EnumerateDirectories(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData));

                string localPrograms = Path.Combine(localAppData, "Programs");
                if (Directory.Exists(localPrograms))
                    all = all.Concat(Directory.EnumerateDirectories(localPrograms));

                string localJulias = Path.Combine(localAppData, "Julia");
                if (Directory.Exists(localJulias))
                    all = all.Concat(Directory.EnumerateDirectories(localJulias));

                path = all
                    .Where(p => Path.GetFileName(p).StartsWith("Julia-") || Path.GetFileName(p).StartsWith("Julia "))
                    .OrderByDescending(p => Path.GetFileName(p.Substring(6)))
                    .FirstOrDefault();

                if (!string.IsNullOrEmpty(path) && Directory.Exists(path)) {
                    path = Path.Combine(path, "bin", name);
                    if (File.Exists(path)) {
                        JuliaIsLocal = false;
                        return JuliaPath = path;
                    }
                }
            }

            return null;
        }

        public static string FindAhorn(bool force) {
            if (!force && !string.IsNullOrEmpty(AhornPath) && File.Exists(AhornPath))
                return AhornPath;
            
            if (string.IsNullOrEmpty(JuliaPath) || !File.Exists(JuliaPath))
                return null;

            string script = PrefixPkgActivate + @"print(something(Base.find_package(""Ahorn""), """"))";

            string path = GetJuliaOutput(script, false);
            if (!string.IsNullOrEmpty(path) && File.Exists(path)) {
                AhornIsLocal = false;
                return AhornPath = path;
            }

            path = GetJuliaOutput(script, true);
            if (!string.IsNullOrEmpty(path) && File.Exists(path)) {
                AhornIsLocal = true;
                return AhornPath = path;
            }

            return null;
        }

        public static string GetJuliaVersion() {
            return GetJuliaOutput(@"print(VERSION)");
        }

        public static string GetAhornVersion() {
            return GetJuliaOutput(PrefixPkgActivate + @"
if !(""Ahorn"" ∈ keys(Pkg.installed()))
    return
end

try
    local ctx = Pkg.Types.Context()
    print(string(ctx.env.manifest[ctx.env.project.deps[""Ahorn""]].tree_hash)[1:7])
catch e
    print(""unknown"")
end
");
        }

    }
}
