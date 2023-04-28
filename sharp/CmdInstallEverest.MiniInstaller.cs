using Mono.Cecil;
using Mono.Cecil.Cil;
using MonoMod.RuntimeDetour;
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
    public unsafe partial class CmdInstallEverest : Cmd<string, string, string, string, IEnumerator> {

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
                    AppDomain nest = null;
                    try {
                        AppDomainSetup nestInfo = new AppDomainSetup();
                        // nestInfo.ApplicationBase = Path.GetDirectoryName(root);
                        nestInfo.ApplicationBase = Path.GetDirectoryName(Assembly.GetEntryAssembly().Location);
                        nestInfo.LoaderOptimization = LoaderOptimization.SingleDomain;

                        nest = AppDomain.CreateDomain(
                            AppDomain.CurrentDomain.FriendlyName + " - MiniInstaller",
                            AppDomain.CurrentDomain.Evidence,
                            nestInfo,
                            AppDomain.CurrentDomain.PermissionSet
                        );

                        ((MiniInstallerProxy) nest.CreateInstanceAndUnwrap(
                            typeof(MiniInstallerProxy).Assembly.FullName,
                            typeof(MiniInstallerProxy).FullName
                        )).Boot(bridge);

                        AppDomain.Unload(nest);

                        bridge.IsDone = true;
                        bridge.WriteLine("MiniInstaller finished");

                    } catch (Exception e) {
                        bridge.Exception = e;

                        string msg = "MiniInstaller died a brutal death";

                        if (nest != null) {
                            try {
                                AppDomain.Unload(nest);
                            } catch {
                                msg = "MiniInstaller has become a zombie";
                            }
                        }

                        bridge.IsDone = true;
                        bridge.WriteLine(msg);
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

        class MiniInstallerProxy : MarshalByRefObject {
            public void Boot(MiniInstallerBridge bridge) {
                string installerPath = Path.Combine(bridge.Root, "MiniInstaller.exe");

                if (bridge.IsNative) {
                    // This build ships with native MiniInstaller binaries
                    BootNative(bridge);
                    return;
                }

                // .NET hates it when strong-named dependencies get updated.
                AppDomain.CurrentDomain.AssemblyResolve += (asmSender, asmArgs) => {
                    AssemblyName asmName = new AssemblyName(asmArgs.Name);
                    if (!asmName.Name.StartsWith("Mono.Cecil"))
                        return null;

                    Assembly asm = AppDomain.CurrentDomain.GetAssemblies().FirstOrDefault(other => other.GetName().Name == asmName.Name);
                    if (asm != null)
                        return asm;

                    return Assembly.LoadFrom(Path.Combine(Path.GetDirectoryName(bridge.Root), asmName.Name + ".dll"));
                };

                Assembly installerAssembly = Assembly.LoadFrom(installerPath);
                Type installerType = installerAssembly.GetType("MiniInstaller.Program");

                // Fix MonoMod dying when running with a debugger attached because it's running without a console.
                bool loadedRuntimeDetour = false;
                using (new Hook(
                    typeof(Console).GetMethod("ReadKey", BindingFlags.Public | BindingFlags.Static, null, new Type[] { }, null),
                    new Func<ConsoleKeyInfo>(() => {
                        return new ConsoleKeyInfo('\n', ConsoleKey.Enter, false, false, false);
                    })
                ))
                // Fix old versions of MiniInstaller loading HookGen without RuntimeDetour.
                using (new Hook(
                    installerType.GetMethod("LazyLoadAssembly", BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static, null, new Type[] { typeof(string) }, null),
                    new Func<Func<string, Assembly>, string, Assembly>((orig, path) => {
                        if (path.EndsWith("MonoMod.RuntimeDetour.dll"))
                            loadedRuntimeDetour = true;
                        else if (path.EndsWith("MonoMod.RuntimeDetour.HookGen.exe") && !loadedRuntimeDetour) {
                            Console.Error.WriteLine("HACKFIX: Loading MonoMod.RuntimeDetour.dll before MonoMod.RuntimeDetour.HookGen.exe");
                            orig(path.Substring(0, path.Length - 4 - 8) + ".dll");
                        }
                        return orig(path);
                    })
                )) {

                    TextWriter origOut = Console.Out;
                    TextReader origIn = Console.In;
                    using (TextWriter bridgeWriter = new MiniInstallerBridgeWriter(bridge))
                    using (TextReader fakeReader = new MiniInstallerFakeInReader()) {
                        Console.SetOut(bridgeWriter);
                        Console.SetIn(fakeReader);

                        try {
                            object exitObject = installerAssembly.EntryPoint.Invoke(null, new object[] { new string[] { } });
                            if (exitObject != null && exitObject is int && ((int) exitObject) != 0)
                                throw new Exception($"Return code != 0, but {exitObject}");

                        } finally {
                            Console.SetOut(origOut);
                            Console.SetIn(origIn);

                            // MiniInstaller can pollute this process with env vars which trip up Everest's runtime relinker.
                            Environment.SetEnvironmentVariable("MONOMOD_DEPDIRS", "");
                            Environment.SetEnvironmentVariable("MONOMOD_MODS", "");
                            Environment.SetEnvironmentVariable("MONOMOD_DEPENDENCY_MISSING_THROW", "");
                        }
                    }

                }
            }

            private void BootNative(MiniInstallerBridge bridge) {
                string installerPath = Path.Combine(bridge.Root,
                    PlatformHelper.Is(Platform.Windows) ?
                        (PlatformHelper.Is(Platform.Bits64) ? "MiniInstaller-win64.exe" : "MiniInstaller-win.exe") :
                    PlatformHelper.Is(Platform.Linux)   ? "MiniInstaller-linux" :
                    PlatformHelper.Is(Platform.MacOS)   ? "MiniInstaller-osx" :
                    throw new Exception("Unknown OS platform")
                );

                if (!File.Exists(installerPath))
                    throw new Exception("Couldn't find MiniInstaller executable");

                if (PlatformHelper.Is(Platform.Linux) || PlatformHelper.Is(Platform.MacOS)) {
                    // Make MiniInstaller executable
                    Process chmodProc = Process.Start(new ProcessStartInfo("chmod", $"u+x \"{installerPath}\""));
                    chmodProc.WaitForExit();
                    if (chmodProc.ExitCode != 0)
                        throw new Exception("Failed to set MiniInstaller executable flag");
                }
                    
                using (Process proc = new Process() { StartInfo = new ProcessStartInfo() {
                    FileName = installerPath,
                    UseShellExecute = false,
                    RedirectStandardInput = true,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true
                }}) {
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
