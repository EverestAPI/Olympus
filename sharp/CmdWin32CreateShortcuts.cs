#if WIN32
using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.ComTypes;
using System.Text;

namespace Olympus {
    public class CmdWin32CreateShortcuts : Cmd<string, string> {

        public override string Run(string exepath) {
            CreateShortcut(exepath, Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory), "Olympus.lnk"));
            CreateShortcut(exepath, Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.StartMenu), "Olympus.lnk"));
            return null;
        }

        public static void CreateShortcut(string exepath, string lnkpath) {
            IShellLink link = (IShellLink) new ShellLink();
            link.SetDescription("Launch Olympus");
            link.SetPath(Path.Combine(Path.GetDirectoryName(exepath), "love.exe"));
            link.SetArguments("\"" + Path.Combine(Path.GetDirectoryName(exepath), "olympus.love") + "\"");
            link.SetIconLocation(Path.Combine(Path.GetDirectoryName(exepath), "icon.ico"), 0);
            link.SetWorkingDirectory(Directory.GetParent(exepath).FullName);
            ((IPersistFile) link).Save(lnkpath, false);
        }

        [ComImport]
        [Guid("00021401-0000-0000-C000-000000000046")]
        internal class ShellLink {
        }

        [ComImport]
        [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
        [Guid("000214F9-0000-0000-C000-000000000046")]
        internal interface IShellLink {
            void GetPath([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszFile, int cchMaxPath, out IntPtr pfd, int fFlags);
            void GetIDList(out IntPtr ppidl);
            void SetIDList(IntPtr pidl);
            void GetDescription([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszName, int cchMaxName);
            void SetDescription([MarshalAs(UnmanagedType.LPWStr)] string pszName);
            void GetWorkingDirectory([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszDir, int cchMaxPath);
            void SetWorkingDirectory([MarshalAs(UnmanagedType.LPWStr)] string pszDir);
            void GetArguments([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszArgs, int cchMaxPath);
            void SetArguments([MarshalAs(UnmanagedType.LPWStr)] string pszArgs);
            void GetHotkey(out short pwHotkey);
            void SetHotkey(short wHotkey);
            void GetShowCmd(out int piShowCmd);
            void SetShowCmd(int iShowCmd);
            void GetIconLocation([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszIconPath, int cchIconPath, out int piIcon);
            void SetIconLocation([MarshalAs(UnmanagedType.LPWStr)] string pszIconPath, int iIcon);
            void SetRelativePath([MarshalAs(UnmanagedType.LPWStr)] string pszPathRel, int dwReserved);
            void Resolve(IntPtr hwnd, int fFlags);
            void SetPath([MarshalAs(UnmanagedType.LPWStr)] string pszFile);
        }

    }
}
#endif
