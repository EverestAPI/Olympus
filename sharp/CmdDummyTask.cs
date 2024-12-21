using System.Collections;
using System.Threading;

namespace Olympus {
    public class CmdDummyTask : Cmd<int, int, IEnumerator> {

        public override IEnumerator Run(int count, int sleep) {
            for (int i = 0; i <= count; i++) {
                yield return Status("Test #" + i, i / (float) count, "", false);
                Thread.Sleep(sleep);
            }
        }

    }
}
