using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Olympus {
    public class CmdGetVersions : Cmd<string, string[]> {
        public override string[] Run(string path) {
            return new string[2] { path, "OH NO!" };
        }
    }
}
