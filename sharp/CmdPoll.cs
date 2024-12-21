
namespace Olympus {
    public class CmdPoll : Cmd<string, object> {
        public override bool LogRun => false;
        public override object Run(string id) {
            return CmdTasks.Get(id)?.Current;
        }
    }
}
