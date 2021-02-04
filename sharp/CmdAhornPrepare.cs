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
    public unsafe class CmdAhornPrepare : Cmd<string, string, string, string, CmdAhornGetInfo.Info> {

        public override bool Taskable => true;

        public override CmdAhornGetInfo.Info Run(string rootPath, string vhdPath, string vhdMountPath, string mode) {
            // Make sure that the default Olympus Ahorn root folder exists.
            AhornHelper.Mode = AhornHelperMode.System;
            AhornHelper.RootPath = null;
            if (!Directory.Exists(AhornHelper.RootPath))
                Directory.CreateDirectory(AhornHelper.RootPath);

            AhornHelper.RootPath = string.IsNullOrEmpty(rootPath) ? rootPath : Path.GetFullPath(rootPath);
            AhornHelper.VHDPath = string.IsNullOrEmpty(vhdPath) ? vhdPath : Path.GetFullPath(vhdPath);
            AhornHelper.VHDMountPath = string.IsNullOrEmpty(vhdMountPath) ? vhdMountPath : Path.GetFullPath(vhdMountPath);
            if (!Enum.TryParse(mode, true, out AhornHelper.Mode))
                AhornHelper.Mode = AhornHelperMode.System;

            AhornHelper.FindJulia(false);
            AhornHelper.FindAhorn(false);
            if (!Directory.Exists(AhornHelper.RootPath))
                Directory.CreateDirectory(AhornHelper.RootPath);

            return new CmdAhornGetInfo.Info();
        }

    }
}
