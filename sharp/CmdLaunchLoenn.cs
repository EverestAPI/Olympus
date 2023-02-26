using MonoMod.Utils;
using System;
using System.Diagnostics;
using System.IO;

namespace Olympus {
    public class CmdLaunchLoenn : Cmd<string, string> {

        public override bool Taskable => true;

        public override string Run(string root) {
            Process loenn = new Process();

            if (PlatformHelper.Is(Platform.Windows)) {
                loenn.StartInfo.FileName = Path.Combine(root, "Lönn.exe");
            } else if (PlatformHelper.Is(Platform.Linux)) {
                // use Olympus's own love2d
                loenn.StartInfo.FileName = Path.Combine(Program.RootDirectory, "love");
                loenn.StartInfo.Arguments = "Lönn.love";
                loenn.StartInfo.UseShellExecute = true;
            } else {
                // run the app
                loenn.StartInfo.FileName = "open";
                loenn.StartInfo.Arguments = "Lönn.app";
                loenn.StartInfo.UseShellExecute = true;
            }

            loenn.StartInfo.WorkingDirectory = root;

            Console.Error.WriteLine($"Starting Loenn process: {loenn.StartInfo.FileName} {loenn.StartInfo.Arguments} (in {root})");

            loenn.Start();
            return null;
        }

    }
}
