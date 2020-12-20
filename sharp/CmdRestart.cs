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

            if (exe.EndsWith(".love")) {
                string sh = exe.Substring(0, exe.Length - 4) + "sh";
                if (File.Exists(sh))
                    exe = sh;
            }

            process.StartInfo.FileName = exe;
            Environment.CurrentDirectory = process.StartInfo.WorkingDirectory = Path.GetDirectoryName(exe);

            Console.WriteLine($"Starting Olympus process: {exe}");
            process.Start();
            return null;
        }

    }
}
