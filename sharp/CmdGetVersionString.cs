using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Olympus {
    public class CmdGetVersionString : Cmd<string, string> {
        public override string Run(string path) {
            return "Unknown Version";
        }
    }
}
