using System;
using System.Diagnostics;
using System.IO;

namespace Olympus {
    public static class ProcessHelper {

        public static Process Wrap(string name, string args) {
            Process process = new Process();

            process.StartInfo.FileName = name;
            process.StartInfo.Arguments = args;

            process.StartInfo.UseShellExecute = false;
            process.StartInfo.CreateNoWindow = true;
            process.StartInfo.RedirectStandardOutput = true;
            process.StartInfo.StandardOutputEncoding = Program.UTF8NoBOM;
            process.StartInfo.RedirectStandardError = true;
            process.StartInfo.StandardErrorEncoding = Program.UTF8NoBOM;

            return process;
        }

        public static string Read(string name, string args, out string err) {
            try {
                using (Process process = Wrap(name, args)) {
                    process.Start();
                    process.WaitForExit();
                    err = process.StandardError.ReadToEnd().Trim();
                    return process.StandardOutput.ReadToEnd().Trim();
                }
            } catch (Exception e) {
                Console.Error.WriteLine($"Reading from process \"{name}\" \"{args}\" failed:");
                Console.Error.WriteLine(e);
                err = "";
                return "";
            }
        }

        public static string ReadTimeout(string name, string args, int timeout, out string err) {
            // FIXME: WaitForExit isn't brutal enough on macOS. Maybe use a separate thread?
            // Test needed for macOS: The function was changed by a contributer that does not have a MacBook.
            try {
                using (Process process = Wrap(name, args)) {
                    process.Start();
                    string result = process.StandardOutput.ReadToEnd().Trim();
                    err = process.StandardError.ReadToEnd().Trim();
                    process.WaitForExit(timeout);
                    return result;
                }
            } catch (Exception e) {
                Console.Error.WriteLine($"Reading from process \"{name}\" \"{args}\" failed:");
                Console.Error.WriteLine(e);
                err = "";
                return "";
            }
        }

        public static int RunAs(string name, string args) {
            Process process = new Process();

            process.StartInfo.FileName = name;
            process.StartInfo.Arguments = args;
            process.StartInfo.Verb = "RunAs";

            process.Start();
            process.WaitForExit();
            return process.ExitCode;
        }

#if !WIN32
        public static string CreateNoOutputWrapper(string commandLine) {
            string path = Path.Combine(Path.GetTempPath(), "olympus_" + Path.GetRandomFileName() + ".sh");
            File.WriteAllText(path,
                "#!/bin/sh\n"
                + commandLine + " > /dev/null 2>&1\n"
                + $"rm \"{path}\"");
            MakeExecutable(path);
            return path;
        }

        public static void MakeExecutable(string fullPath) {
            Process chmod = new Process();
            chmod.StartInfo.FileName = "chmod";
            chmod.StartInfo.Arguments = "+x \"" + fullPath + "\"";
            chmod.Start();
            chmod.WaitForExit();
        }
#endif
    }
}
