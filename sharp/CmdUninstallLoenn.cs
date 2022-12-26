using System.Collections;
using System.IO;

namespace Olympus {
    public class CmdUninstallLoenn : Cmd<string, IEnumerator> {

        public override IEnumerator Run(string root) {
            yield return Status("Uninstalling Lönn", false, "", false);
            Directory.Delete(root, true);
        }
    }
}
