using Mono.Cecil;
using Mono.Cecil.Cil;
using MonoMod.Utils;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Olympus {
    public class CmdEcho : Cmd<string, string> {
        public override string Run(string data) {
            return data;
        }
    }
}
