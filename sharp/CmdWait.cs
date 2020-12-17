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
    public unsafe class CmdWait : Cmd<string, bool?, object[]> {
        public override bool LogRun => false;
        public override object[] Run(string id, bool? skip) {
            return CmdTasks.Get(id)?.Wait(skip ?? false);
        }
    }
}
