using System;
using System.Diagnostics;
using System.IO;

namespace Olympus {
    public class CmdRestart : Cmd<string, string> {

        public override string Run(string exe) {
            Environment.SetEnvironmentVariable("LOCAL_LUA_DEBUGGER_VSCODE", "0");
            Environment.SetEnvironmentVariable("OLYMPUS_RESTARTER_PID", Process.GetCurrentProcess().Id.ToString());

            Process process = new Process();

#if WIN32
            process.StartInfo.Arguments = "\"" + exe + "\"";
            process.StartInfo.FileName = Path.Combine(Path.GetDirectoryName(exe), "love.exe");
#else
            if (Path.GetExtension(exe) == ".love") {
                if (File.Exists(Path.ChangeExtension(exe, ".sh")))
                    exe = Path.ChangeExtension(exe, ".sh");
                else if (File.Exists(Path.ChangeExtension(exe, null)))
                    exe = Path.ChangeExtension(exe, null);
            }

            process.StartInfo.FileName = exe;
#endif

            Environment.CurrentDirectory = process.StartInfo.WorkingDirectory = Path.GetDirectoryName(exe);

            Console.Error.WriteLine($"Starting Olympus process: {exe}");
            process.Start();
            return null;
        }

    }
}
