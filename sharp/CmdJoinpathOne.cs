using System.IO;

namespace Olympus {
    public class CmdJoinpathOne : Cmd<string, string, string> {
        public override string Run(string input1, string input2) {
            return Path.Combine(input1, input2);
        }
    }
}
