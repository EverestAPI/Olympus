using System;
using System.Collections;
using System.Diagnostics;
using System.IO;
using System.Text.RegularExpressions;
using System.Threading;

namespace Olympus {
    public class CmdAhornRunJuliaTask : Cmd<string, bool?, IEnumerator> {

        public static readonly Regex EscapeCmdRegex = new Regex("\u001B....|\\^\\[\\[.25.||?\\[.25.|\\^\\[\\[2K|?\\[2K|\\^M");
        public static readonly Regex EscapeDashRegex = new Regex(@"─+");

        public override bool LogRun => false;

        public override IEnumerator Run(string script, bool? localDepot) {
            string tmpFilename = null;
            try {
                using (ManualResetEvent timeout = new ManualResetEvent(false))
                using (Process process = AhornHelper.NewJulia(out tmpFilename, script, localDepot)) {
                    process.Start();

                    bool dead = false;
                    bool deadByTimeout = false;
                    int timeoutThreadID = 0;
                    int lineID = 0;
                    WaitHandle[] timeoutHandle = new WaitHandle[] { timeout };
                    Thread killer = null;

                    for (string line; (line = process.StandardOutput.ReadLine()) != null;) {
                        if (line.StartsWith("#OLYMPUS# ")) {
                            line = line.Substring("#OLYMPUS# ".Length);
                            if (line == "TIMEOUT START") {
                                if (killer == null) {
                                    timeoutThreadID++;
                                    timeout.Reset();
                                    killer = new Thread(() => {
                                        int timeoutThreadIDCurrent = timeoutThreadID;
                                        int lineIDCurrent = lineID;
                                        try {
                                            while (!dead && timeoutThreadID == timeoutThreadIDCurrent) {
                                                int waited = WaitHandle.WaitAny(timeoutHandle, 15 * 60 * 1000);
                                                timeout.Reset();
                                                if (waited == WaitHandle.WaitTimeout && !dead && timeoutThreadID == timeoutThreadIDCurrent && lineID == lineIDCurrent) {
                                                    dead = true;
                                                    deadByTimeout = true;
                                                    process.Kill();
                                                    return;
                                                }
                                                lineIDCurrent = lineID;
                                            }
                                        } catch {
                                        }
                                    }) {
                                        Name = $"Olympus Julia watchdog thread {process}",
                                        IsBackground = true
                                    };
                                    killer.Start();
                                }

                            } else if (line == "TIMEOUT END") {
                                timeoutThreadID++;
                                killer = null;
                                timeout.Set();

                            } else {
                                process.Kill();
                                throw new Exception("Unexpected #OLYMPUS# command:" + line);
                            }
                        } else {
                            lineID++;
                            timeout.Set();
                            line = Escape(line, out bool update);
                            if (line != null)
                                yield return Status(DateTime.Now.ToString("[HH:mm:ss] ") + line, false, "", update);
                        }
                    }

                    process.WaitForExit();
                    dead = true;
                    timeout.Set();
                    killer?.Join();
                    if (deadByTimeout)
                        throw new Exception("Julia timed out:\n" + process.StandardError.ReadToEnd());
                    if (process.ExitCode != 0)
                        throw new Exception("Julia encountered a fatal error:\n" + process.StandardError.ReadToEnd());
                }
            } finally {
                if (!string.IsNullOrEmpty(tmpFilename) && File.Exists(tmpFilename))
                    File.Delete(tmpFilename);
            }
        }

        public static string Escape(string line, out bool update) {
            line = EscapeCmdRegex.Replace(line, "");
            line = EscapeDashRegex.Replace(line, "-");
            update = line.StartsWith("#") && line.EndsWith("%");

            if (line.StartsWith("┌ Debug: "))
                line = line.Substring("┌ Debug: ".Length);

            if (line.StartsWith("└ @ "))
                return null;

            return line;
        }

    }
}
