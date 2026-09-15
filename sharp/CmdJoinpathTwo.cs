using System.IO;

namespace Olympus {
    public class CmdJoinpathTwo : Cmd<string, string, string, string> {
        public override string Run(string input1, string input2, string input3) {
            return Path.Combine(input1, input2, input3);
        }
    }
}
