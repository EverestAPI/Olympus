using Mono.Cecil;
using Mono.Cecil.Cil;
using MonoMod.Utils;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Drawing;
using System.Globalization;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Net;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace Olympus {
    public unsafe class CmdDummyTask : Cmd<int, int, IEnumerator> {

        public override IEnumerator Run(int count, int sleep) {
            for (int i = 0; i <= count; i++) {
                yield return Status("Test #" + i, i / (float) count, "");
                Thread.Sleep(sleep);
            }
        }

    }
}
