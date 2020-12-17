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
            Environment.CurrentDirectory = Path.GetDirectoryName(exe);

            Process process = new Process();

            process.StartInfo.FileName = exe;
            process.StartInfo.WorkingDirectory = Path.GetDirectoryName(exe);

            process.Start();
            return null;
        }

    }
}
