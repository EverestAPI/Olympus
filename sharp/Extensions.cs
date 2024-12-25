using System;
using System.Diagnostics;
using System.IO;

namespace Olympus {
    public static class Extensions {

        public static bool ReadLineUntil(this TextReader reader, string wanted) {
            for (string line; (line = reader.ReadLine()?.TrimEnd()) != null;)
                if (line == wanted)
                    return true;
            return false;
        }

        public static void HandleLaunchWrapper(this Process proc, string wrapperName) {
            // Handle launch wrappers
            string wrapper = Environment.GetEnvironmentVariable($"OLYMPUS_{wrapperName}_WRAPPER");
            if (!string.IsNullOrEmpty(wrapper)) {
                proc.StartInfo.Arguments = $"\"{proc.StartInfo.FileName}\" {proc.StartInfo.Arguments}";
                proc.StartInfo.FileName = wrapper;
            }
        }

    }
}
