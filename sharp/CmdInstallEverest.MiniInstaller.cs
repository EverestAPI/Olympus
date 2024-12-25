using MonoMod.Utils;
using System;
using System.Collections;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Text;
using System.Threading;

namespace Olympus {
    public partial class CmdInstallEverest : Cmd<string, string, string, string, IEnumerator> {
        public static bool CheckNativeMiniInstaller(ZipArchive zip, string prefix = "")
            => zip.GetEntry($"{prefix}MiniInstaller.exe") == null;

        public static IEnumerator Install(string root, bool isNative) {
            Environment.CurrentDirectory = root;

            yield return StatusSilent($"Starting {(isNative ? "native" : "legacy")} MiniInstaller", false, "monomod", false);

            using (MiniInstallerBridge bridge = new MiniInstallerBridge {
                IsNative = isNative,
                Encoding = Console.Error.Encoding,
                Root = root
            }) {
                bridge.LogEvent = new ManualResetEvent(false);
                WaitHandle[] waitHandle = new WaitHandle[] { bridge.LogEvent };

                Thread thread = new Thread(() => {
                    try {
                        StartMiniInstaller(bridge);
                        bridge.IsDone = true;
                        bridge.WriteLine("MiniInstaller finished");

                    } catch (Exception e) {
                        bridge.Exception = e;
                        bridge.IsDone = true;
                        bridge.WriteLine("MiniInstaller died a brutal death");

                        Console.Error.WriteLine(e);
                    }
                }) {
                    Name = "MiniInstaller"
                };

                thread.Start();

                string lastSent = null;
                while (!bridge.IsDone && thread.IsAlive) {
                    WaitHandle.WaitAny(waitHandle, 1000);
                    bridge.LogEvent.Reset();
                    if (lastSent != bridge.LastLogLine) {
                        lastSent = bridge.LastLogLine;
                        yield return StatusSilent(lastSent, false, "monomod", false);
                    }
                }

                thread.Join();

                if (bridge.Exception != null)
                    throw new Exception("MiniInstaller died a brutal death", bridge.Exception);
            }
        }

        private static void StartMiniInstaller(MiniInstallerBridge bridge) {
            if (bridge.IsNative) {
                // This build ships with native MiniInstaller binaries
                StartNativeMiniInstaller(bridge);
            } else {
                StartLegacyMiniInstaller(bridge);
            }
        }

        private static void StartNativeMiniInstaller(MiniInstallerBridge bridge) {
            string installerPath = Path.Combine(bridge.Root,
                PlatformHelper.Is(Platform.Windows) ?
                    (PlatformHelper.Is(Platform.Bits64) ? "MiniInstaller-win64.exe" : "MiniInstaller-win.exe") :
                    PlatformHelper.Is(Platform.Linux) ? "MiniInstaller-linux" :
                        PlatformHelper.Is(Platform.MacOS) ? "MiniInstaller-osx" :
                            throw new Exception("Unknown OS platform")
                );

            if (!File.Exists(installerPath))
                throw new Exception("Couldn't find MiniInstaller executable");

            StartMiniInstallerProcess(bridge, installerPath);
        }

        private static void StartLegacyMiniInstaller(MiniInstallerBridge bridge) {
            if (PlatformHelper.Is(Platform.Windows)) {
                StartMiniInstallerProcess(bridge, Path.Combine(bridge.Root, "MiniInstaller.exe"));
                return;
            }

            string monoKickstartPathFrom = Path.Combine(bridge.Root, PlatformHelper.Is(Platform.Bits64) ? "Celeste.bin.x86_64" : "Celeste.bin.x86");
            string monoKickstartPathTo = Path.Combine(bridge.Root, PlatformHelper.Is(Platform.Bits64) ? "MiniInstaller.bin.x86_64" : "MiniInstaller.bin.x86");

            if (PlatformHelper.Is(Platform.MacOS)) {
                monoKickstartPathFrom = Path.Combine(bridge.Root, "..", "MacOS", "Celeste");
                monoKickstartPathTo = Path.Combine(bridge.Root, "MiniInstaller.bin.osx");
            }

            if (!File.Exists(monoKickstartPathTo)) {
                if (!File.Exists(monoKickstartPathFrom)) {
                    throw new Exception("Cannot find MonoKickstart executable");
                }

                bridge.WriteLine($"Copying MonoKickstart: {monoKickstartPathFrom} -> {monoKickstartPathTo}");
                File.Copy(monoKickstartPathFrom, monoKickstartPathTo);
            }

            StartMiniInstallerProcess(bridge, monoKickstartPathTo);
        }

        private static void StartMiniInstallerProcess(MiniInstallerBridge bridge, string installerPath) {
#if !WIN32
            bridge.WriteLine($"Ensuring {installerPath} is executable");
            ProcessHelper.MakeExecutable(installerPath);
#endif

            bridge.WriteLine($"Running MiniInstaller executable: {installerPath}");

            using (Process proc = new Process {
                StartInfo = new ProcessStartInfo() {
                    FileName = installerPath,
                    UseShellExecute = false,
                    RedirectStandardInput = true,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    CreateNoWindow = true,
                }
            }) {
                proc.HandleLaunchWrapper("MINIINSTALLER");

                proc.OutputDataReceived += (o, e) => bridge.WriteLine(e.Data);
                proc.ErrorDataReceived += (o, e) => bridge.WriteLine(e.Data);

                proc.Start();
                proc.BeginOutputReadLine();
                proc.BeginErrorReadLine();

                proc.WaitForExit();

                if (proc.ExitCode != 0)
                    throw new Exception($"MiniInstaller process died: {proc.ExitCode}");
            }
        }

        class MiniInstallerBridge : MarshalByRefObject, IDisposable {
            public bool IsNative { get; set; }
            public Encoding Encoding { get; set; }
            public string Root { get; set; }
            public string LastLogLine { get; set; }
            public ManualResetEvent LogEvent;
            public bool IsDone { get; set; }
            public Exception Exception { get; set; }

            public void Write(string value) => Console.Error.Write(value);
            public void WriteLine(string value) {
                Console.Error.WriteLine(value);
                LastLogLine = value;
                LogEvent?.Set();
            }
            public void Write(char value) => Console.Error.Write(value);
            public void Write(char[] buffer, int index, int count) => Console.Error.Write(buffer, index, count);
            public void Flush() => Console.Error.Flush();
            public void Close() {
                // Console.Error.Close();
            }

            public void Dispose() {
                LogEvent?.Dispose();
            }
        }

        class MiniInstallerBridgeWriter : TextWriter {
            private readonly MiniInstallerBridge Bridge;
            public MiniInstallerBridgeWriter(MiniInstallerBridge bridge) {
                Bridge = bridge;
            }
            public override Encoding Encoding => Bridge.Encoding;
            public override void Write(string value) => Bridge.Write(value);
            public override void WriteLine(string value) => Bridge.WriteLine(value);
            public override void Write(char value) => Bridge.Write(value);
            public override void Write(char[] buffer, int index, int count) => Bridge.Write(buffer, index, count);
            public override void Flush() => Bridge.Flush();
            public override void Close() => Bridge.Close();
        }

        class MiniInstallerFakeInReader : TextReader {
            public override int Peek() => 1;
            public override int Read() => '\n';
            public override string ReadToEnd() => "\n";
        }

    }
}
