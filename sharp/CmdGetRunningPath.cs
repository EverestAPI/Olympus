using MonoMod.Utils;
using System;
using System.Diagnostics;
using System.IO;
using System.Linq;

namespace Olympus {
    public class CmdGetRunningPath : Cmd<string, string, string> {

        public override bool Taskable => true;

        public override string Run(string root, string procname) {
            procname = procname.ToLowerInvariant();

            if (PlatformHelper.Is(Platform.Unix)) {
                // macOS lacks procfs and this sucks but oh well.
                // FIXME: This can hang on some macOS machines, but running ps in terminal works?! Further debugging required!
                if (PlatformHelper.Is(Platform.MacOS))
                    return null;

                string path = ProcessHelper.ReadTimeout(
                    "ps",
                    "-wweo args",
                    1000,
                    out _
                ).Trim().Split('\n').FirstOrDefault(p => (string.IsNullOrEmpty(root) || p.Contains(root)) && p.ToLowerInvariant().Contains(procname))?.Trim();

                if (string.IsNullOrEmpty(path))
                    return null;

                int indexOfCeleste = path.ToLowerInvariant().IndexOf(procname, StringComparison.InvariantCulture);
                int indexOfEnd = path.LastIndexOf(Path.DirectorySeparatorChar, indexOfCeleste);
                if (indexOfEnd < 0)
                    indexOfEnd = path.Length;
                return path.Substring(0, indexOfEnd);
            }

            string procsuffix = Path.DirectorySeparatorChar + procname + ".exe";
            try {
                foreach (Process p in Process.GetProcesses()) {
                    try {
                        if (!p.ProcessName.ToLowerInvariant().Contains(procname))
                            continue;
                        string path = p.MainModule?.FileName;
                        if (!string.IsNullOrEmpty(path) &&
                            (string.IsNullOrEmpty(root) || path.Contains(root)) &&
                            path.ToLowerInvariant().EndsWith(procsuffix) &&
                            (path = path.Substring(0, path.Length - procsuffix.Length)).ToLowerInvariant().Contains(procname)) {
                            return path;
                        }
                    } catch {
                    } finally {
                        try {
                            p.Dispose();
                        } catch { }
                    }
                }
            } catch {
            }

            return null;
        }

    }
}
