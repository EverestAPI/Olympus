using Microsoft.Win32;


namespace Olympus {
    public static class Win32RegHelper {

        public static RegistryKey OpenOrCreateKey(string path, bool writable) {
            string[] parts = path.Split('\\');

            RegistryKey key;
            switch (parts[0].ToUpperInvariant()) {
                case "HKEY_CURRENT_USER":
                case "HKCU":
                    key = Registry.CurrentUser;
                    break;

                case "HKEY_LOCAL_MACHINE":
                case "HKLM":
                    key = Registry.LocalMachine;
                    break;

                case "HKEY_CLASSES_ROOT":
                case "HKCR":
                    key = Registry.ClassesRoot;
                    break;

                case "HKEY_USERS":
                    key = Registry.Users;
                    break;

                case "HKEY_CURRENT_CONFIG":
                    key = Registry.CurrentConfig;
                    break;

                default:
                    return null;
            }

            if (writable) {
                for (int i = 1; i < parts.Length && key != null; i++)
                    key = key.OpenSubKey(parts[i], true) ?? key.CreateSubKey(parts[i]);
            } else {
                for (int i = 1; i < parts.Length && key != null; i++)
                    key = key.OpenSubKey(parts[i], false);
            }

            return key;
        }

    }
}
