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
    public unsafe partial class CmdLaunch : Cmd<string, string, string> {

        public override string Run(string root, string args) {
            Environment.SetEnvironmentVariable("LOCAL_LUA_DEBUGGER_VSCODE", "0");

            Process game = new Process();

            // Unix-likes use the wrapper script
            if (Environment.OSVersion.Platform == PlatformID.Unix ||
                Environment.OSVersion.Platform == PlatformID.MacOSX) {
                game.StartInfo.FileName = Path.Combine(root, "Celeste");
            } else {
                game.StartInfo.FileName = Path.Combine(root, "Celeste.exe");
            }

            game.StartInfo.WorkingDirectory = root;

            if (!string.IsNullOrEmpty(args))
                game.StartInfo.Arguments = args;

            game.Start();
            return null;
        }

    }
}
