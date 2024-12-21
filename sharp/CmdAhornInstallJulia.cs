using MonoMod.Utils;
using System;
using System.Collections;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Linq;

namespace Olympus {
    public class CmdAhornInstallJulia : Cmd<bool, IEnumerator> {

        public static readonly string Version = "1.6.0";
        public static readonly string VersionBeta = "1.6.0";

        public override IEnumerator Run(bool beta) {
            yield return Status("Preparing installation of Julia", false, "", false);

            string root = AhornHelper.RootPath;
            string tmp = Path.Combine(root, "tmp");
            if (!Directory.Exists(tmp))
                Directory.CreateDirectory(tmp);

            string julia = Path.Combine(root, "julia");
            if (Directory.Exists(julia))
                Directory.Delete(julia, true);

            if (PlatformHelper.Is(Platform.Windows)) {
                string zipPath = Path.Combine(tmp, "juliadownload.zip");
                if (File.Exists(zipPath))
                    File.Delete(zipPath);

                string url;

                if (PlatformHelper.Is(Platform.Bits64)) {
                    url = beta ?
                        "https://julialang-s3.julialang.org/bin/winnt/x64/1.6/julia-1.6.0-win64.zip" :
                        "https://julialang-s3.julialang.org/bin/winnt/x64/1.6/julia-1.6.0-win64.zip";
                } else {
                    url = beta ?
                        "https://julialang-s3.julialang.org/bin/winnt/x86/1.6/julia-1.6.0-win32.zip" :
                        "https://julialang-s3.julialang.org/bin/winnt/x86/1.6/julia-1.6.0-win32.zip";
                }

                try {
                    yield return Status($"Downloading {url}", false, "download", false);
                    using (FileStream zipStream = File.Open(zipPath, FileMode.Create, FileAccess.ReadWrite, FileShare.ReadWrite | FileShare.Delete)) {
                        yield return Download(url, 0, zipStream);

                        zipStream.Seek(0, SeekOrigin.Begin);

                        yield return Status("Unzipping Julia", false, "download", false);
                        using (ZipArchive zip = new ZipArchive(zipStream, ZipArchiveMode.Read)) {
                            yield return Unpack(zip, julia, beta ? "julia-1.6.0/" : "julia-1.6.0/");
                        }
                    }

                } finally {
                    if (File.Exists(zipPath))
                        File.Delete(zipPath);
                }

                string launcher = Path.Combine(root, "launch-local-julia.bat");
                if (File.Exists(launcher))
                    File.Delete(launcher);
                File.WriteAllText(launcher, @"
@echo off
setlocal EnableDelayedExpansion
set ""JULIA_DEPOT_PATH=%~dp0\julia-depot""
set ""AHORN_GLOBALENV=%LocalAppData%\Ahorn\env""
set ""AHORN_ENV=%~dp0\ahorn-env""
""%~dp0\julia\bin\julia.exe"" %*
"
                    .TrimStart().Replace("\r\n", "\n").Replace("\n", "\r\n")
                );


            } else if (PlatformHelper.Is(Platform.Linux)) {
                string tarPath = Path.Combine(tmp, "juliadownload.tar.gz");
                if (File.Exists(tarPath))
                    File.Delete(tarPath);

                string url;

                string lsPath = ProcessHelper.Read("which", "ls", out _).Trim().Split('\n').FirstOrDefault()?.Trim();
                bool musl = !string.IsNullOrEmpty(lsPath) && ProcessHelper.Read("ldd", lsPath, out _).Contains("musl");

                if (PlatformHelper.Is(Platform.ARM)) {
                    url = beta ?
                        "https://julialang-s3.julialang.org/bin/linux/aarch64/1.6/julia-1.6.0-linux-aarch64.tar.gz" :
                        "https://julialang-s3.julialang.org/bin/linux/aarch64/1.6/julia-1.6.0-linux-aarch64.tar.gz";
                } else if (musl) {
                    url = beta ?
                        "https://julialang-s3.julialang.org/bin/musl/x64/1.6/julia-1.6.0-musl-x86_64.tar.gz" :
                        "https://julialang-s3.julialang.org/bin/musl/x64/1.6/julia-1.6.0-musl-x86_64.tar.gz";
                } else if (PlatformHelper.Is(Platform.Bits64)) {
                    url = beta ?
                        "https://julialang-s3.julialang.org/bin/linux/x64/1.6/julia-1.6.0-linux-x86_64.tar.gz" :
                        "https://julialang-s3.julialang.org/bin/linux/x64/1.6/julia-1.6.0-linux-x86_64.tar.gz";
                } else {
                    url = beta ?
                        "https://julialang-s3.julialang.org/bin/linux/x86/1.6/julia-1.6.0-linux-i686.tar.gz" :
                        "https://julialang-s3.julialang.org/bin/linux/x86/1.6/julia-1.6.0-linux-i686.tar.gz";
                }

                try {
                    yield return Status($"Downloading {url}", false, "download", false);
                    using (FileStream tarStream = File.Open(tarPath, FileMode.Create, FileAccess.ReadWrite, FileShare.ReadWrite | FileShare.Delete))
                        yield return Download(url, 0, tarStream);

                    yield return Status("Extracting Julia", false, "download", false);
                    yield return Status("", false, "download", false);
                    using (Process process = ProcessHelper.Wrap("tar", $"-xvf \"{tarPath}\" -C \"{root}\"")) {
                        process.Start();
                        for (string line; (line = process.StandardOutput.ReadLine()) != null;)
                            yield return Status(line, false, "download", true);
                        process.WaitForExit();
                        if (process.ExitCode != 0)
                            throw new Exception("tar encountered a fatal error:\n" + process.StandardError.ReadToEnd());
                        yield return Status("Julia archive extracted", false, "download", true);
                    }

                    yield return Status("Moving Julia", false, "download", false);
                    Directory.Move(Path.Combine(root, beta ? "julia-1.6.0" : "julia-1.6.0"), julia);

                } finally {
                    if (File.Exists(tarPath))
                        File.Delete(tarPath);
                }

                string launcher = Path.Combine(root, "launch-local-julia.sh");
                if (File.Exists(launcher))
                    File.Delete(launcher);
                File.WriteAllText(launcher, @"
#!/bin/sh
ROOTDIR=$(dirname ""$0"")
export JULIA_DEPOT_PATH=""${ROOTDIR}/julia-depot""
if [ ! -z ""${XDG_CONFIG_HOME}"" ]; then
    export AHORN_GLOBALENV=""${XDG_CONFIG_HOME}/Ahorn/env""
else
    export AHORN_GLOBALENV=""${HOME}/.config/Ahorn/env""
fi
export AHORN_ENV=""${ROOTDIR}/ahorn-env""
""${ROOTDIR}/julia/bin/julia"" $@
"
                    .TrimStart().Replace("\r\n", "\n")
                );

                ProcessHelper.Read("chmod", $"a+x \"{launcher}\"", out _);


            } else if (PlatformHelper.Is(Platform.MacOS)) {
                string dmgPath = Path.Combine(tmp, "juliadownload.dmg");
                if (File.Exists(dmgPath))
                    File.Delete(dmgPath);

                string mount = Path.Combine(tmp, "juliamount");
                if (Directory.Exists(mount))
                    Directory.Delete(mount);

                string url = beta ?
                    "https://julialang-s3.julialang.org/bin/mac/x64/1.6/julia-1.6.0-mac64.dmg" :
                    "https://julialang-s3.julialang.org/bin/mac/x64/1.6/julia-1.6.0-mac64.dmg";

                bool mounted = false;

                try {
                    yield return Status($"Downloading {url}", false, "download", false);
                    using (FileStream dmgStream = File.Open(dmgPath, FileMode.Create, FileAccess.ReadWrite, FileShare.ReadWrite | FileShare.Delete))
                        yield return Download(url, 0, dmgStream);

                    yield return Status("Mounting Julia", false, "download", false);
                    using (Process process = ProcessHelper.Wrap("hdiutil", $"attach -mountpoint \"{mount}\" \"{dmgPath}\"")) {
                        process.Start();
                        for (string line; (line = process.StandardOutput.ReadLine()) != null;)
                            yield return Status(line, false, "download", false);
                        process.WaitForExit();
                        if (process.ExitCode != 0)
                            throw new Exception("hdiutil attach encountered a fatal error:\n" + process.StandardError.ReadToEnd());
                    }
                    mounted = true;

                    yield return Status("Copying Julia", false, "download", false);
                    yield return Status("", false, "download", false);
                    using (Process process = ProcessHelper.Wrap("cp", $"-rvf \"{Path.Combine(mount, beta ? "Julia-1.6.app" : "Julia-1.6.app", "Contents", "Resources", "julia")}\" \"{julia}\"")) {
                        process.Start();
                        for (string line; (line = process.StandardOutput.ReadLine()) != null;)
                            yield return Status(line, false, "download", true);
                        process.WaitForExit();
                        if (process.ExitCode != 0)
                            throw new Exception("cp encountered a fatal error:\n" + process.StandardError.ReadToEnd());
                        yield return Status("Julia copied", false, "download", true);
                    }

                    yield return Status("Unmounting Julia", false, "download", false);
                    using (Process process = ProcessHelper.Wrap("hdiutil", $"detach \"{mount}\"")) {
                        process.Start();
                        for (string line; (line = process.StandardOutput.ReadLine()) != null;)
                            yield return Status(line, false, "download", false);
                        process.WaitForExit();
                        if (process.ExitCode != 0)
                            throw new Exception("hdiutil detach encountered a fatal error:\n" + process.StandardError.ReadToEnd());
                    }
                    mounted = false;

                } finally {
                    if (mounted) {
                        try {
                            using (Process process = ProcessHelper.Wrap("hdiutil", $"detach \"{mount}\"")) {
                                process.Start();
                                process.WaitForExit();
                                if (process.ExitCode != 0)
                                    throw new Exception("hdiutil detach encountered a fatal error:\n" + process.StandardError.ReadToEnd());
                            }
                        } catch (Exception e) {
                            Console.Error.WriteLine("Error unmounting Julia dmg in installer finally clause");
                            Console.Error.WriteLine(e);
                        }
                    }

                    if (File.Exists(dmgPath))
                        File.Delete(dmgPath);

                    if (Directory.Exists(mount))
                        Directory.Delete(mount);
                }

                string launcher = Path.Combine(root, "launch-local-julia.sh");
                if (File.Exists(launcher))
                    File.Delete(launcher);
                File.WriteAllText(launcher, @"
#!/bin/sh
ROOTDIR=$(dirname ""$0"")
export JULIA_DEPOT_PATH=""${ROOTDIR}/julia-depot""
if [ ! -z ""${XDG_CONFIG_HOME}"" ]; then
    export AHORN_GLOBALENV=""${XDG_CONFIG_HOME}/Ahorn/env""
else
    export AHORN_GLOBALENV=""${HOME}/.config/Ahorn/env""
fi
export AHORN_ENV=""${ROOTDIR}/ahorn-env""
""${ROOTDIR}/julia/bin/julia"" $@
"
                    .TrimStart().Replace("\r\n", "\n")
                );

                ProcessHelper.Read("chmod", $"a+x \"{launcher}\"", out _);


            } else {
                throw new PlatformNotSupportedException($"Unsupported platform: {PlatformHelper.Current}");
            }
        }

    }
}
