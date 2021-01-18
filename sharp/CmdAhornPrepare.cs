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
    public unsafe class CmdAhornPrepare : Cmd<string, bool, CmdAhornGetInfo.Info> {

        public override CmdAhornGetInfo.Info Run(string rootPath, bool forceLocal) {
            AhornHelper.RootPath = rootPath;
            AhornHelper.ForceLocal = forceLocal;
            AhornHelper.FindJulia(true);
            AhornHelper.FindAhorn(true);
            if (!Directory.Exists(AhornHelper.RootPath))
                Directory.CreateDirectory(AhornHelper.RootPath);
            return new CmdAhornGetInfo.Info();
        }

    }
}
