
namespace Olympus {
    public class CmdFree : Cmd<string, string> {
        public override bool LogRun => false;
        public override string Run(string id) {
            CmdTask task = CmdTasks.Remove(id);
            string status = task?.Status;
            task?.Dispose();
            return status;
        }
    }
}
