
namespace Olympus {
    public class CmdStatus : Cmd<string, object[]> {
        public override bool LogRun => false;
        public override object[] Run(string id) {
            CmdTask task = CmdTasks.Get(id);
            if (task == null)
                return new object[0];
            return new object[] { task.Status, task.Queue.Count };
        }
    }
}
