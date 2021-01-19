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
    public unsafe class CmdAhornRunJuliaTask : Cmd<string, bool?, IEnumerator> {
        public override bool LogRun => false;
        public override IEnumerator Run(string script, bool? localDepot) {
            string tmpFilename = null;
            try {
                using (Process process = AhornHelper.NewJulia(out tmpFilename, script, localDepot)) {
                    process.Start();
                    for (string line = null; (line = process.StandardOutput.ReadLine()) != null;)
                        yield return Status(line, false, "", false);
                    process.WaitForExit();
                    if (process.ExitCode != 0)
                        throw new Exception("Julia encountered a fatal error.");
                }
            } finally {
                if (!string.IsNullOrEmpty(tmpFilename) && File.Exists(tmpFilename))
                    File.Delete(tmpFilename);
            }
        }
    }
}
