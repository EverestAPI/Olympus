using MonoMod.Utils;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;

namespace Olympus {
    public static class AhornHelper {

        private const string PrefixGlobal = @"
@eval(Base, ttyhascolor(term_type = nothing) = false)
@eval(Base, get_have_color() = false)

";

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

        public static AhornHelperMode Mode = AhornHelperMode.System;

        private static string _RootPath;
        public static string RootPath {
            get {
                if (Mode == AhornHelperMode.VHD)
                    return VHDMountPath;

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

                return _RootPath = Path.Combine(Program.RootDirectory, "ahorn");
            }
            set {
                if (_RootPath == value)
                    return;

                _RootPath = value;
                JuliaPath = null;
                AhornEnvPath = null;
                AhornPath = null;
            }
        }

        private static string _VHDPath;
        public static string VHDPath {
            get {
                if (!string.IsNullOrEmpty(_VHDPath))
                    return _VHDPath;

                string path = Environment.GetEnvironmentVariable("OLYMPUS_AHORN_VHD");
                if (!string.IsNullOrEmpty(path))
                    return _VHDPath = path;

                // VHDs are only supported on Windows by default.
                if (!PlatformHelper.Is(Platform.Windows))
                    return null;

                return _VHDPath = Path.Combine(Program.ConfigDirectory, "ahorn.vhdx");
            }
            set {
                _VHDPath = value;
                VHDMountPath = null;
            }
        }

        private static string _VHDMountPath;
        public static string VHDMountPath {
            get {
                if (!string.IsNullOrEmpty(_VHDMountPath))
                    return _VHDMountPath;

                string path = Environment.GetEnvironmentVariable("OLYMPUS_AHORN_VHDMOUNT");
                if (!string.IsNullOrEmpty(path))
                    return _VHDMountPath = path;

                // VHDs are only supported on Windows by default.
                if (!PlatformHelper.Is(Platform.Windows))
                    return null;

                return _VHDMountPath = VHDPath + ".mount";
            }
            set => _VHDMountPath = value;
        }

        private static string _AhornGlobalEnvPath;
        public static string AhornGlobalEnvPath {
            get {
                if (!string.IsNullOrEmpty(_AhornGlobalEnvPath))
                    return _AhornGlobalEnvPath;

                string path = Environment.GetEnvironmentVariable("OLYMPUS_AHORN_GLOBALENV");
                if (!string.IsNullOrEmpty(path))
                    return _AhornGlobalEnvPath = path;

                // The following is based off of how Ahorn's install_ahorn.jl determines the env path.

                if (PlatformHelper.Is(Platform.Windows)) {
                    return _AhornGlobalEnvPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Ahorn", "env");

                } else {
                    // This must be done like this as it behaves exactly like this on ALL non-Windows platforms.
                    string config = Environment.GetEnvironmentVariable("XDG_CONFIG_HOME");
                    if (string.IsNullOrEmpty(config))
                        config = Path.Combine(Environment.GetEnvironmentVariable("HOME"), ".config");
                    return _AhornGlobalEnvPath = Path.Combine(config, "Ahorn", "env");
                }
            }
            set {
                if (_AhornGlobalEnvPath == value)
                    return;

                _AhornGlobalEnvPath = value;
                AhornPath = null;
            }
        }

        private static string _AhornEnv;
        public static string AhornEnvPath {
            get {
                if (!string.IsNullOrEmpty(_AhornEnv))
                    return _AhornEnv;

                string path = Environment.GetEnvironmentVariable("OLYMPUS_AHORN_ENV");
                if (!string.IsNullOrEmpty(path))
                    return _AhornEnv = path;

                return _AhornEnv = Path.Combine(RootPath, "ahorn-env");
            }
            set {
                if (_AhornEnv == value)
                    return;

                _AhornEnv = value;
                AhornPath = null;
            }
        }

        public static string JuliaPath { get; private set; }
        public static bool JuliaIsLocal { get; private set; }

        public static string AhornPath { get; private set; }
        public static bool AhornIsLocal { get; private set; }

        public static Process NewJulia(out string tmpFilename, string script, bool? localDepot = null) {
            string julia = FindJulia(false);
            if (string.IsNullOrEmpty(julia) || !File.Exists(julia)) {
                tmpFilename = null;
                return null;
            }

            bool local = localDepot ?? (JuliaIsLocal || Mode != AhornHelperMode.System);

            if (local) {
                string depot = Path.Combine(RootPath, "julia-depot");
                if (!Directory.Exists(depot))
                    Directory.CreateDirectory(depot);
                Environment.SetEnvironmentVariable("JULIA_DEPOT_PATH", depot);
            } else {
                Environment.SetEnvironmentVariable("JULIA_DEPOT_PATH", string.IsNullOrEmpty(OrigJuliaDepotPath) ? Path.PathSeparator.ToString() : OrigJuliaDepotPath);
            }

            string env = local ? AhornEnvPath : AhornGlobalEnvPath;
            Environment.SetEnvironmentVariable("AHORN_ENV", env);
            Environment.SetEnvironmentVariable("AHORN_GLOBALENV", AhornGlobalEnvPath);
            Environment.SetEnvironmentVariable("JULIA_PKG_PRECOMPILE_AUTO", "0");
            if (!Directory.Exists(env))
                Directory.CreateDirectory(env);

            tmpFilename = Path.GetTempFileName();
            File.WriteAllText(tmpFilename, PrefixGlobal + script);
            return ProcessHelper.Wrap(julia, "\"" + tmpFilename + "\"");
        }

        public static string GetJuliaOutput(string script, out string err, bool? localDepot = null) {
            string tmpFilename = null;
            try {
                using (Process process = NewJulia(out tmpFilename, script, localDepot)) {
                    if (process == null) {
                        err = null;
                        return null;
                    }
                    process.Start();
                    process.WaitForExit();
                    err = process.StandardError.ReadToEnd().Trim();
                    if (!string.IsNullOrEmpty(err))
                        Console.Error.WriteLine(err);
                    return process.StandardOutput.ReadToEnd().Trim();
                }
            } finally {
                if (!string.IsNullOrEmpty(tmpFilename) && File.Exists(tmpFilename))
                    File.Delete(tmpFilename);
            }
        }

        public static string FindJulia(bool force) {
            if (!force && !string.IsNullOrEmpty(JuliaPath) && File.Exists(JuliaPath))
                return JuliaPath;

            string name = PlatformHelper.Is(Platform.Windows) ? "julia.exe" : "julia";
            string path;

            if (Mode == AhornHelperMode.System) {
                path = ProcessHelper.Read(
                    PlatformHelper.Is(Platform.Windows) ? "where.exe" : "which",
                    name,
                    out _
                ).Trim().Split('\n').FirstOrDefault()?.Trim();
                if (!string.IsNullOrEmpty(path) && File.Exists(path)) {
                    JuliaIsLocal = false;
                    return JuliaPath = path;
                }

                if (PlatformHelper.Is(Platform.MacOS)) {
                    // Sandboxing is hell and the Julia installation instructions make this path guaranteed on macOS.
                    path = "/usr/local/bin/julia";
                    if (File.Exists(path)) {
                        JuliaIsLocal = false;
                        return JuliaPath = path;
                    }
                }

                if (PlatformHelper.Is(Platform.Windows)) {
                    // Julia on Windows is a hot mess.
                    string localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
                    IEnumerable<string> all = Directory.EnumerateDirectories(localAppData);

                    string localPrograms = Path.Combine(localAppData, "Programs");
                    if (Directory.Exists(localPrograms))
                        all = all.Concat(Directory.EnumerateDirectories(localPrograms));

                    string localJulias = Path.Combine(localPrograms, "Julia");
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
            }

            path = Path.Combine(RootPath, "julia", "bin", name);
            if (File.Exists(path)) {
                JuliaIsLocal = true;
                return JuliaPath = path;
            }

            return null;
        }

        public static string FindAhorn(bool force) {
            if (!force && !string.IsNullOrEmpty(AhornPath) && File.Exists(AhornPath))
                return AhornPath;

            if (string.IsNullOrEmpty(JuliaPath) || !File.Exists(JuliaPath))
                return null;

            string path;

            if (Mode == AhornHelperMode.System) {
                path = GetJuliaOutput(PrefixPkgActivate + @"println(something(Base.find_package(""Ahorn""), """"))", out _, false);
                if (!string.IsNullOrEmpty(path) && File.Exists(path)) {
                    AhornIsLocal = false;
                    return AhornPath = path;
                }
            }

            path = Path.Combine(RootPath, "julia-depot", "packages", "Ahorn");
            if (Directory.Exists(path)) {
                foreach (string sub in Directory.EnumerateDirectories(path)) {
                    path = Path.Combine(sub, "src", "Ahorn.jl");
                    if (File.Exists(path)) {
                        AhornIsLocal = true;
                        return AhornPath = path;
                    }
                }
            }

            return null;
        }

        public static string GetJuliaVersion() {
            return GetJuliaOutput(@"println(VERSION)", out _);
        }

        public static string GetPkgVersion(string package) {
            return GetJuliaOutput(PrefixPkgActivate + $@"
if !(""Ahorn"" ∈ keys(Pkg.installed()))
    return
end

try
    local ctx = Pkg.Types.Context()
    println(string(ctx.env.manifest[ctx.env.project.deps[""{package}""]].tree_hash))
catch e
    println(""?"")
end
", out _);
        }

        public static string GetVersion(string package) {
            string path = AhornPath;
            if (string.IsNullOrEmpty(path) || !File.Exists(path))
                return GetPkgVersion(package) + " (pkg)";

            // julia-depot/packages/Ahorn/*/src/Ahorn.jl
            path = Path.GetDirectoryName(path); // julia-depot/packages/Ahorn/*/src
            path = Path.GetDirectoryName(path); // julia-depot/packages/Ahorn/*
            path = Path.GetDirectoryName(path); // julia-depot/packages/Ahorn
            path = Path.GetDirectoryName(path); // julia-depot/packages
            path = Path.GetDirectoryName(path); // julia-depot
            if (string.IsNullOrEmpty(path) || !Directory.Exists(path))
                return GetPkgVersion(package) + " (pkg)";

            path = Path.Combine(path, "clones");
            if (!Directory.Exists(path))
                return GetPkgVersion(package) + " (pkg)";

            foreach (string clone in Directory.EnumerateDirectories(path)) {
                string config = Path.Combine(clone, "config");
                if (!File.Exists(config))
                    continue;
                using (FileStream stream = File.Open(config, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete))
                using (StreamReader reader = new StreamReader(stream)) {
                    if (!reader.ReadLineUntil("[remote \"origin\"]"))
                        continue;
                    if (reader.ReadLine()?.Trim() != $"url = https://github.com/CelestialCartographers/{package}.git")
                        continue;
                }

                string head = Path.Combine(clone, "FETCH_HEAD");
                if (!File.Exists(head))
                    continue;
                using (FileStream stream = File.Open(head, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete))
                using (StreamReader reader = new StreamReader(stream)) {
                    head = reader.ReadLine()?.Trim() ?? "";
                    int split = head.IndexOf("\t", StringComparison.InvariantCulture);
                    if (split >= 0)
                        head = head.Substring(0, split);
                    if (string.IsNullOrEmpty(head))
                        continue;
                    return head + " (git)";
                }
            }

            return GetPkgVersion(package) + " (pkg)";
        }

    }

    public enum AhornHelperMode {
        System,
        Local,
        VHD
    }
}
