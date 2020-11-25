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
using System.Threading;
using System.Threading.Tasks;

namespace Olympus {
    public unsafe class CmdInstallEverest : Cmd<string, string, IEnumerator> {
        public override IEnumerator Run(string root, string artifact) {
            for (int i = 0; i <= 200; i++) {
                yield return new object[] { $"aaaaa {i}", i / 200f, "monomod" };
                Thread.Sleep(20);
            }
        }
    }
}
