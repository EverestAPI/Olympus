using System;
using System.Globalization;
using System.Linq;


namespace Olympus {
    static class Program {
        static void Main(string[] args) {
            CultureInfo.DefaultThreadCurrentCulture = CultureInfo.InvariantCulture;
            CultureInfo.DefaultThreadCurrentUICulture = CultureInfo.InvariantCulture;

            Console.WriteLine($"Olympus Uninstaller {typeof(Program).Assembly.GetName().Version}");
            new CmdWin32AppUninstall().Run(quiet: args.Contains("--quiet"));
        }
    }
}
