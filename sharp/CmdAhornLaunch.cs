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
    public unsafe class CmdAhornLaunch : Cmd<IEnumerator> {
        
        public override IEnumerator Run() {
            yield return "Initializing...";

            string tmpFilename = null;
            try {
                using (Process process = AhornHelper.NewJulia(out tmpFilename, @"
env = ENV[""AHORN_ENV""]
globalenv = ENV[""AHORN_GLOBALENV""]

logfilePath = joinpath(mkpath(dirname(globalenv)), ""error.log"")

println(""Logging to "" * logfilePath)

logfile = open(logfilePath, ""w"")
println(logfile, ""Running Ahorn via Olympus."")

flush(stdout)
flush(stderr)

stdoutReal = stdout
(rd, wr) = redirect_stdout()
redirect_stderr(stdout)

@async while !eof(rd)
    data = String(readavailable(rd))
    print(stdoutReal, data)
    flush(stdoutReal)
    print(logfile, data)
    flush(logfile)
end

using Pkg
Pkg.activate(env)

install_or_update(url::String, pkg::String) = if ""Ahorn"" ∈ keys(Pkg.Types.Context().env.project.deps)
    println(""Updating $pkg..."")
    Pkg.update(pkg)
else
    println(""Adding $pkg..."")
    Pkg.add(PackageSpec(url = url))
end

if Base.find_package(""Ahorn"") === nothing
    Pkg.instantiate()

    install_or_update(""https://github.com/CelestialCartographers/Maple.git"", ""Maple"")
    install_or_update(""https://github.com/CelestialCartographers/Ahorn.git"", ""Ahorn"")

    Pkg.instantiate()
    Pkg.API.precompile()
end

using Ahorn
Ahorn.displayMainWindow()
"
                )) {

                    /*/
                    process.StartInfo.UseShellExecute = true;
                    process.StartInfo.CreateNoWindow = false;
                    process.StartInfo.RedirectStandardOutput = false;
                    process.StartInfo.RedirectStandardError = false;
                    /**/

                    process.Start();
                    for (string line; (line = process.StandardOutput.ReadLine()) != null;)
                        yield return CmdAhornRunJuliaTask.Escape(line, out _);
                    process.WaitForExit();
                    yield return process.ExitCode == 0;
                }
            } finally {
                if (!string.IsNullOrEmpty(tmpFilename) && File.Exists(tmpFilename))
                    File.Delete(tmpFilename);
            }
        }

    }
}
