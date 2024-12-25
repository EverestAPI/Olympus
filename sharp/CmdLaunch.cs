using System;
using System.Diagnostics;
using System.IO;

namespace Olympus {
    public class CmdLaunch : Cmd<string, string, bool, string> {

        public override bool Taskable => true;

        public override string Run(string root, string args, bool force) {
            if (!force && !string.IsNullOrEmpty(Cmds.Get<CmdGetRunningPath>().Run(root, "Celeste")))
                return "running";

            Environment.SetEnvironmentVariable("LOCAL_LUA_DEBUGGER_VSCODE", "0");

            Process game = new Process();
#if WIN32
            game.StartInfo.UseShellExecute = true;
#endif

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
            if (args?.Trim() == "--vanilla") {
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

            // Steam flatpak detection
            // Default game path: /home/USER/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/Celeste
            if (Environment.OSVersion.Platform == PlatformID.Unix && game.StartInfo.FileName.Contains("com.valvesoftware.Steam")) {
                game.StartInfo.FileName = "xdg-open";
                args = "steam://run/504230";
                // args won't work but launch vanilla will work because it uses nextLaunchIsVanilla.txt
            }

            if (!string.IsNullOrEmpty(args))
                game.StartInfo.Arguments = args;

            game.HandleLaunchWrapper("CELESTE");

            // Flatpak detection
            // or string.Equals(Environment.GetEnvironmentVariable("container"), "flatpak");
            bool isFlatpak = File.Exists("./flatpak-info");
            if (isFlatpak) {
                if (!string.IsNullOrEmpty(args))
                    game.StartInfo.Arguments = string.Join(" ", "\"" + game.StartInfo.FileName + "\"", args);
                else
                    game.StartInfo.Arguments = game.StartInfo.FileName;
                game.StartInfo.FileName = Path.Combine(Program.RootDirectory, "flatpak-wrapper");
            }

            Console.Error.WriteLine($"Starting Celeste process: {game.StartInfo.FileName} {(string.IsNullOrEmpty(args) ? "(without args)" : args)}");

#if !WIN32
            if (!isFlatpak) {
                game.StartInfo.Arguments = $"\"{game.StartInfo.FileName}\" {game.StartInfo.Arguments}";
                game.StartInfo.FileName = ProcessHelper.CreateNoOutputWrapper(game.StartInfo.Arguments);
            }
#endif

            game.Start();
            return null;
        }

    }
}
