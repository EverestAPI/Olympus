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
    public unsafe class CmdLaunch : Cmd<string, string, string> {

        public override string Run(string root, string args) {
            Environment.SetEnvironmentVariable("LOCAL_LUA_DEBUGGER_VSCODE", "0");
            Environment.CurrentDirectory = root;

            Process game = new Process();

            // Unix-likes use a MonoKickstart wrapper script / launch binary.
            if (Environment.OSVersion.Platform == PlatformID.Unix ||
                Environment.OSVersion.Platform == PlatformID.MacOSX) {
                game.StartInfo.FileName = Path.Combine(root, "Celeste");
                // 1.3.3.0 splits Celeste into two, so to speak.
                if (!File.Exists(game.StartInfo.FileName) && Path.GetFileName(root) == "Resources")
                    game.StartInfo.FileName = Path.Combine(Path.GetDirectoryName(root), "MacOS", "Celeste");
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
