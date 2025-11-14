#if WIN32
using Microsoft.Win32;
using System;

namespace Olympus {
    public class CmdWin32RegSet : Cmd<string, object, bool> {
        private static readonly Logger log = new Logger(nameof(CmdWin32RegSet));

        public override bool LogRun => false;
        public override bool Run(string key, object value) {
            int indexOfSlash = key.LastIndexOf('\\');
            if (indexOfSlash == -1)
                return false;

            try {
                using (RegistryKey regkey = Win32RegHelper.OpenOrCreateKey(key.Substring(0, indexOfSlash), true))
                    regkey.SetValue(key.Substring(indexOfSlash + 1), value);
            } catch (Exception e) {
                log.Error($"Cannot set registry value: {key} = {value}: " + e);
            }
            return true;
        }
    }
}
#endif