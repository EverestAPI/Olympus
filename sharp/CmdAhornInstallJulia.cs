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
    public unsafe class CmdAhornInstallJulia : Cmd<bool, IEnumerator> {

        public static readonly string Version = "1.5.3";
        public static readonly string VersionBeta = "1.6.0-beta1";

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
                string zipPath = Path.Combine(tmp, $"juliadownload.zip");
                if (File.Exists(zipPath))
                    File.Delete(zipPath);

                string url;

                if (PlatformHelper.Is(Platform.Bits64)) {
                    url = beta ?
                        "https://julialang-s3.julialang.org/bin/winnt/x64/1.6/julia-1.6.0-beta1-win64.zip" :
                        "https://julialang-s3.julialang.org/bin/winnt/x64/1.5/julia-1.5.3-win64.zip";
                } else {
                    url = beta ?
                        "https://julialang-s3.julialang.org/bin/winnt/x86/1.6/julia-1.6.0-beta1-win32.zip" :
                        "https://julialang-s3.julialang.org/bin/winnt/x86/1.5/julia-1.5.3-win32.zip";
                }

                try {
                    yield return Status($"Downloading {url}", false, "download", false);
                    using (FileStream zipStream = File.Open(zipPath, FileMode.Create, FileAccess.ReadWrite, FileShare.ReadWrite | FileShare.Delete)) {
                        yield return Download(url, 0, zipStream);

                        zipStream.Seek(0, SeekOrigin.Begin);

                        yield return Status("Unzipping Julia", false, "download", false);
                        using (ZipArchive zip = new ZipArchive(zipStream, ZipArchiveMode.Read)) {
                            yield return Unpack(zip, julia, beta ? "julia-b84990e1ac/" : "julia-1.5.3/");
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
                string tarPath = Path.Combine(tmp, $"juliadownload.tar.gz");
                if (File.Exists(tarPath))
                    File.Delete(tarPath);

                string url;

                string lsPath = AhornHelper.GetProcessOutput("which", "ls", out _).Trim().Split('\n').FirstOrDefault()?.Trim();
                bool musl = !string.IsNullOrEmpty(lsPath) && AhornHelper.GetProcessOutput("ldd", lsPath, out _).Contains("musl");

                if (PlatformHelper.Is(Platform.ARM)) {
                    url = beta ?
                        "https://julialang-s3.julialang.org/bin/linux/aarch64/1.6/julia-1.6.0-beta1-linux-aarch64.tar.gz" :
                        "https://julialang-s3.julialang.org/bin/linux/aarch64/1.5/julia-1.5.3-linux-aarch64.tar.gz";
                } else if (musl) {
                    url = beta ?
                        "https://julialang-s3.julialang.org/bin/musl/x64/1.6/julia-1.6.0-beta1-musl-x86_64.tar.gz" :
                        "https://julialang-s3.julialang.org/bin/musl/x64/1.5/julia-1.5.3-musl-x86_64.tar.gz";
                } else if (PlatformHelper.Is(Platform.Bits64)) {
                    url = beta ?
                        "https://julialang-s3.julialang.org/bin/linux/x64/1.6/julia-1.6.0-beta1-linux-x86_64.tar.gz" :
                        "https://julialang-s3.julialang.org/bin/linux/x64/1.5/julia-1.5.3-linux-x86_64.tar.gz";
                } else {
                    url = beta ?
                        "https://julialang-s3.julialang.org/bin/linux/x86/1.6/julia-1.6.0-beta1-linux-i686.tar.gz" :
                        "https://julialang-s3.julialang.org/bin/linux/x86/1.5/julia-1.5.3-linux-i686.tar.gz";
                }

                try {
                    yield return Status($"Downloading {url}", false, "download", false);
                    using (FileStream tarStream = File.Open(tarPath, FileMode.Create, FileAccess.ReadWrite, FileShare.ReadWrite | FileShare.Delete)) {
                        yield return Download(url, 0, tarStream);

                        tarStream.Seek(0, SeekOrigin.Begin);
                    }

                    yield return Status("Extracting Julia", false, "download", false);
                    yield return Status("", false, "download", false);
                    using (Process process = AhornHelper.NewProcess("tar", $"-xvf \"{tarPath}\" -C \"{root}\"")) {
                        process.Start();
                        for (string line = null; (line = process.StandardOutput.ReadLine()) != null;)
                            yield return Status(line, false, "", true);
                        process.WaitForExit();
                        if (process.ExitCode != 0)
                            throw new Exception("tar encountered a fatal error.");
                        yield return Status("Julia archive extracted", false, "", true);
                    }

                    yield return Status("Moving Julia", false, "", false);
                    Directory.Move(Path.Combine(root, beta ? "julia-1.6.0-beta1" : "julia-1.5.3"), julia);

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

                AhornHelper.GetProcessOutput("chmod", $"a+x \"{launcher}\"", out _);


            } else if (PlatformHelper.Is(Platform.MacOS)) {
                throw new NotImplementedException();


            } else {
                throw new PlatformNotSupportedException($"Unsupported platform: {PlatformHelper.Current}");
            }
        }

    }
}
