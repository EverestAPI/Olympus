using System;

namespace Olympus {
    public class CmdGetEnv : Cmd<string, string> {
        public override string Run(string input) {
            return Environment.GetEnvironmentVariable(input);
        }
    }
}
