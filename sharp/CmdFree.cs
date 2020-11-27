using Mono.Cecil;
using Mono.Cecil.Cil;
using MonoMod.Utils;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;

namespace Olympus {
    public unsafe class CmdFree : Cmd<string, string> {
        public override bool LogRun => false;
        public override string Run(string id) {
            return CmdTasks.Remove(id)?.Status;
        }
    }
}
