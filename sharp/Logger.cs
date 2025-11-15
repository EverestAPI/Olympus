using System;

namespace Olympus {
    public class Logger(string tag) {
        public void Debug(string msg) => log("dbg", msg);
        public void Info(string msg) => log("inf", msg);
        public void Warning(string msg) => log("wrn", msg);
        public void Error(string msg) => log("err", msg);

        private void log(string level, string msg) {
            Console.Error.WriteLine($"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] [{level}] [{tag}] {msg}");
        }
    }
}
