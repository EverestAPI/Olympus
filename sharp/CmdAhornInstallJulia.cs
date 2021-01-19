using Mono.Cecil;
using Mono.Cecil.Cil;
using MonoMod.Utils;
using System;
using System.Collections;
using System.Collections.Generic;
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
                string zipPath = Path.Combine(tmp, $"juliadownload.zip.part");
                if (File.Exists(zipPath))
                    File.Delete(zipPath);

                string url;

                if (beta) {
                    url = PlatformHelper.Is(Platform.Bits64) ?
                    "https://julialang-s3.julialang.org/bin/winnt/x64/1.6/julia-1.6.0-beta1-win64.zip" :
                    "https://julialang-s3.julialang.org/bin/winnt/x86/1.6/julia-1.6.0-beta1-win32.zip";

                } else {
                    url = PlatformHelper.Is(Platform.Bits64) ?
                    "https://julialang-s3.julialang.org/bin/winnt/x64/1.5/julia-1.5.3-win64.zip" :
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
                File.WriteAllText(launcher, $"@echo off\r\nset \"JULIA_DEPOT_PATH={Path.Combine(root, "julia-depot")}\"\r\nset \"AHORN_GLOBALENV={AhornHelper.AhornGlobalEnvPath}\"\r\nset \"AHORN_ENV={AhornHelper.AhornEnvPath}\"\r\n.\\julia\\bin\\julia.exe");


            } else if (PlatformHelper.Is(Platform.Linux)) {
                throw new NotImplementedException();


            } else if (PlatformHelper.Is(Platform.MacOS)) {
                throw new NotImplementedException();


            } else {
                throw new PlatformNotSupportedException($"Unsupported platform: {PlatformHelper.Current}");
            }
        }

    }
}
