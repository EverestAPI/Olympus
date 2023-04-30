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
    public unsafe class CmdRestart : Cmd<string, string> {

        public override string Run(string exe) {
            Environment.SetEnvironmentVariable("LOCAL_LUA_DEBUGGER_VSCODE", "0");
            Environment.SetEnvironmentVariable("OLYMPUS_RESTARTER_PID", Process.GetCurrentProcess().Id.ToString());

            Process process = new Process();

            if (Path.GetExtension(exe) == ".love") {
                if (File.Exists(Path.ChangeExtension(exe, ".sh")))
                    exe = Path.ChangeExtension(exe, ".sh");
                else if (File.Exists(Path.ChangeExtension(exe, null)))
                    exe = Path.ChangeExtension(exe, null);
            }

            process.StartInfo.FileName = exe;
            Environment.CurrentDirectory = process.StartInfo.WorkingDirectory = Path.GetDirectoryName(exe);

            Console.Error.WriteLine($"Starting Olympus process: {exe}");
            process.Start();
            return null;
        }

    }
}
