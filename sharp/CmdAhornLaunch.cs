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

logerrPath = joinpath(dirname(globalenv), ""error.log"")

println(""Logging to "" * logerrPath)

open(logerrPath, ""w"") do logerr
    println(logerr, ""Running Ahorn via Olympus."")
end

flush(stdout)
flush(stderr)

stdoutReal = stdout
redirect_stderr(stdoutReal)
(rd, wr) = redirect_stdout()

@async while true
    data = String(readavailable(rd))
    write(stdoutReal, data)
    open(logerrPath, ""a"", false) do logerr
        write(logerr, data)
    end
end

try
    using Pkg
    Pkg.activate(env)
    using Ahorn
    Ahorn.displayMainWindow()
catch e
    println(logerr, ""FATAL ERROR"")
    println(logerr, sprint(showerror, e, catch_backtrace()))
    exit(1)
end

exit(0)
"
                )) {

                    /*/
                    process.StartInfo.UseShellExecute = true;
                    process.StartInfo.CreateNoWindow = false;
                    process.StartInfo.RedirectStandardOutput = false;
                    process.StartInfo.RedirectStandardError = false;
                    /**/

                    process.Start();
                    for (string line = null; (line = process.StandardOutput.ReadLine()) != null;)
                        yield return line;
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
