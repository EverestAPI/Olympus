using MonoMod.Utils;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace Olympus {
    static class Program {

        public static string InstallDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "Olympus");
        public static string MainPath = Path.Combine(InstallDir, "main.exe");
        public static string ConfigDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Olympus");
        public static string LogPath = Path.Combine(ConfigDir, "log-launcher.txt");

        public static string[] Args;

        [STAThread]
        static void Main(string[] args) {
            CultureInfo.DefaultThreadCurrentCulture = CultureInfo.InvariantCulture;
            CultureInfo.DefaultThreadCurrentUICulture = CultureInfo.InvariantCulture;

            Args = args;

            if (!Directory.Exists(InstallDir))
                Directory.CreateDirectory(InstallDir);
            if (!Directory.Exists(ConfigDir))
                Directory.CreateDirectory(ConfigDir);

            Environment.SetEnvironmentVariable("LOCAL_LUA_DEBUGGER_VSCODE", "0");
            Environment.CurrentDirectory = InstallDir;

            if (File.Exists(LogPath))
                File.Delete(LogPath);

            using (Stream fileStream = new FileStream(LogPath, FileMode.OpenOrCreate, FileAccess.Write, FileShare.ReadWrite | FileShare.Delete))
            using (StreamWriter fileWriter = new StreamWriter(fileStream, Console.OutputEncoding))
            using (LogWriter logWriter = new LogWriter {
                STDOUT = Console.Out,
                File = fileWriter
            }) {
                try {
                    Console.SetOut(logWriter);

                    AppDomain.CurrentDomain.UnhandledException += UnhandledExceptionHandler;

                    Console.WriteLine($"Olympus Launcher {typeof(Program).Assembly.GetName().Version}");

                    if (StartMain()) {
                        Console.WriteLine("Quitting early");
                        return;
                    }

                    Console.WriteLine("Starting up form");

                    // Application.SetHighDpiMode(HighDpiMode.SystemAware);
                    DynDll.ResolveDynDllImports(typeof(DpiUtils));
                    if (DpiUtils.SetProcessDpiAwarenessContext != null) {
                        DpiUtils.SetProcessDpiAwarenessContext(DpiUtils.DPI_AWARENESS_CONTEXT.DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
                    } else if (DpiUtils.SetProcessDpiAwareness != null) {
                        DpiUtils.SetProcessDpiAwareness(DpiUtils.PROCESS_DPI_AWARENESS.Process_Per_Monitor_DPI_Aware);
                    } else if (DpiUtils.SetProcessDPIAware != null) {
                        DpiUtils.SetProcessDPIAware();
                    }
                    
                    Application.EnableVisualStyles();
                    Application.SetCompatibleTextRenderingDefault(false);
                    Application.SetUnhandledExceptionMode(UnhandledExceptionMode.CatchException);
                    Application.Run(new OlympusForm());
                } finally {
                    if (logWriter.STDOUT != null) {
                        Console.SetOut(logWriter.STDOUT);
                        logWriter.STDOUT = null;
                    }
                }
            }
        }

        public static bool StartMain() {
            if (!File.Exists(MainPath)) {
                Console.WriteLine($"Tried to start {MainPath} but not found.");
                return false;
            }

            Console.WriteLine($"Starting up {MainPath}");
            Process process = new Process();
            process.StartInfo.FileName = MainPath;
            process.StartInfo.WorkingDirectory = InstallDir;
            process.StartInfo.Arguments = string.Join(" ", Args.Select(arg => {
                arg = Regex.Replace(arg, @"(\\*)" + "\"", @"$1\$0");
                arg = Regex.Replace(arg, @"^(.*\s.*?)(\\*)$", "\"$1$2$2\"");
                return arg;
            }));
            process.Start();
            return true;
        }

        private static void UnhandledExceptionHandler(object sender, UnhandledExceptionEventArgs e) {
            (e.ExceptionObject as Exception ?? new Exception($"Unknown unhandled exception: {e.ExceptionObject?.ToString() ?? "null"}")).LogDetailed();
        }

    }
}
