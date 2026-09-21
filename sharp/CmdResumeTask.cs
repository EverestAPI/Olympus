
namespace Olympus {
    public class CmdResumeTask : Cmd<string, string> {
        public override bool LogRun => false;
        public override string Run(string id) {
            CmdTask task = CmdTasks.Get(id);
            task?.Resume();
            return task?.Status;
        }
    }
}
