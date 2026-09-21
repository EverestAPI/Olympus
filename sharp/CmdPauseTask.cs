
namespace Olympus {
    public class CmdPauseTask : Cmd<string, string> {
        public override bool LogRun => false;
        public override string Run(string id) {
            CmdTask task = CmdTasks.Get(id);
            task?.Pause();
            return task?.Status;
        }
    }
}
