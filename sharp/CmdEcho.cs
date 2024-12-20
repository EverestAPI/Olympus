
namespace Olympus {
    public class CmdEcho : Cmd<string, string> {
        public override bool LogRun => false;
        public override string Run(string data) {
            return data;
        }
    }
}
