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

            if (!File.Exists(game.StartInfo.FileName)) {
                Console.Error.WriteLine($"Can't start Celeste: {game.StartInfo.FileName} not found!");
                return "missing";
            }

            Environment.CurrentDirectory = game.StartInfo.WorkingDirectory = Path.GetDirectoryName(game.StartInfo.FileName);

            // Everest versions 1550 + 700 or newer support nextLaunchIsVanilla.txt
            if (args.Trim() == "--vanilla") {
                Version version = CmdGetVersionString.GetVersion(root).Item3;
                if (version == null || version.Minor == 0 || version.Minor >= (1550 + 700)) {
                    try {
                        File.WriteAllText(Path.Combine(root, "nextLaunchIsVanilla.txt"), "This file was created by Olympus and will be deleted automatically.");
                        args = "";
                        Console.Error.WriteLine("nextLaunchIsVanilla.txt created");
                    } catch (Exception e) {
                        Console.Error.WriteLine($"Failed to create nextLaunchIsVanilla.txt: {e}");
                    }
                }
            }

            if (!string.IsNullOrEmpty(args))
                game.StartInfo.Arguments = args;

            Console.Error.WriteLine($"Starting Celeste process: {game.StartInfo.FileName} {(string.IsNullOrEmpty(args) ? "(without args)" : args)}");

            game.Start();
            return null;
        }

    }
}
