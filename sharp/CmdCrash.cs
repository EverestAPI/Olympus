using System;

namespace Olympus {
    public class CmdCrash : Cmd<bool> {
        public override bool Run() {
            throw new Exception("Crashed as requested!");
        }
    }
}
