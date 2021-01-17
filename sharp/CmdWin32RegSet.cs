using Microsoft.Win32;
using Mono.Cecil;
using Mono.Cecil.Cil;
using MonoMod.Utils;
using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.ComTypes;
using System.Text;
using System.Threading.Tasks;

namespace Olympus {
    public class CmdWin32RegSet : Cmd<string, object, bool> {
        public override bool LogRun => false;
        public override bool Run(string key, object value) {
            int indexOfSlash = key.LastIndexOf('\\');
            if (indexOfSlash == -1)
                return false;

            try {
                using (RegistryKey regkey = Win32RegHelper.OpenOrCreateKey(key.Substring(0, indexOfSlash), true))
                    regkey.SetValue(key.Substring(indexOfSlash + 1), value);
            } catch (Exception e) {
                Console.Error.WriteLine($"Cannot set registry value: {key} = {value}");
                Console.Error.WriteLine(e);
            }
            return true;
        }
    }
}
