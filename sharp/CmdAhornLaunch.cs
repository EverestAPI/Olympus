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
    public unsafe class CmdAhornLaunch : Cmd<bool> {
        
        public override bool Taskable => true;

        public override bool Run() {
            string tmpFilename = null;
            try {
                using (Process process = AhornHelper.NewJulia(out tmpFilename, @"
env = ENV[""AHORN_ENV""]

logout = open(joinpath(dirname(env), ""output.log""), ""w"")
redirect_stdout(logout)
println(logout, ""Running Ahorn via Olympus. See error.log for STDERR."")

logerr = open(joinpath(dirname(env), ""error.log""), ""w"")
redirect_stderr(logerr)
println(logerr, ""Running Ahorn via Olympus. See output.log for STDOUT."")

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
"
                )) {

                    /*
                    process.StartInfo.UseShellExecute = true;
                    process.StartInfo.CreateNoWindow = false;
                    process.StartInfo.RedirectStandardOutput = false;
                    process.StartInfo.RedirectStandardError = false;
                    */

                    process.Start();
                    process.WaitForExit();
                    return process.ExitCode == 0;
                }
            } finally {
                if (!string.IsNullOrEmpty(tmpFilename) && File.Exists(tmpFilename))
                    File.Delete(tmpFilename);
            }
        }

    }
}
