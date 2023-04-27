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
    public unsafe class CmdUninstallEverest : Cmd<string, string, IEnumerator> {

        private static readonly string[] OldEverestFileNames = new string[] {
            "apphosts", "everest-lib",
            "lib64-win-x64", "lib64-win-x86", "lib64-linux", "lib64-osx",
            "Celeste.dll", "Celeste.xml",
            "Celeste.Mod.mm.dll", "Celeste.Mod.mm.pdb", "Celeste.Mod.mm.xml", "Celeste.Mod.mm.deps.json",
            "NETCoreifier.dll", "NETCoreifier.pdb", "NETCoreifier.deps.json",
            "MiniInstaller.exe", "MiniInstaller-win.exe", "MiniInstaller-linux", "MiniInstaller-osx", "MiniInstaller-win.exe.manifest",
            "MiniInstaller.dll", "MiniInstaller.pdb", "MiniInstaller.runtimeconfig.json", "MiniInstaller.deps.json"
        };

        public override IEnumerator Run(string root, string artifactBase) {
            yield return Status("Uninstalling Everest", false, "backup", false);

            string origdir = Path.Combine(root, "orig");
            if (!Directory.Exists(origdir)) {
                yield return Status("Backup (orig) folder not found", 1f, "error", false);
                throw new Exception($"Backup folder not found: {origdir}");
            }

            int i = 0;
            string[] origs = Directory.GetFileSystemEntries(origdir);

            List<string> revertEntries = new List<string>(); 
            foreach (string orig in origs) {
                string name = Path.GetFileName(orig);
                
                // Ignore the Content and Saves folder - it is either a symlink or a 1-to-1 copy
                if (Path.GetFileName(orig) == "Content" || Path.GetFileName(orig) == "Saves")
                    continue;

                // Ignore non-file/directory entries and symlinks
                // The symlink check is usually not good enough, but it works for our purposes
                // (the Celeste files should *not* have reparse points)
                if (!File.Exists(orig) && !Directory.Exists(orig))
                    continue;

                if (File.Exists(orig) && new FileInfo(orig).Attributes.HasFlag(FileAttributes.ReparsePoint))
                    continue;

                if (Directory.Exists(orig) && new DirectoryInfo(orig).Attributes.HasFlag(FileAttributes.ReparsePoint))
                    continue;

                revertEntries.Add(orig);
            }

            yield return Status($"Reverting {revertEntries.Count} files", 0f, "backup", false);

            foreach (string orig in revertEntries) {
                string name = Path.GetFileName(orig);
                yield return Status($"Reverting #{i} / {revertEntries.Count}: {name}", i / (float) revertEntries.Count, "backup", true);
                i++;

                string to = Path.Combine(root, name);
                string toParent = Path.GetDirectoryName(to);
                Console.Error.WriteLine($"{orig} -> {to}");

                if (!Directory.Exists(toParent))
                    Directory.CreateDirectory(toParent);

                if (File.Exists(orig)) {
                    if (File.Exists(to))
                        File.Delete(to);

                    File.Copy(orig, to);
                } else {
                    if (Directory.Exists(to))
                        Directory.Delete(to, true);

                    void CopyDirectory(DirectoryInfo src, DirectoryInfo dst) {
                        foreach (FileInfo file in src.GetFiles())
                            file.CopyTo(Path.Combine(dst.FullName, file.Name));

                        foreach (DirectoryInfo dir in src.GetDirectories())
                            CopyDirectory(dir, dst.CreateSubdirectory(dir.Name));
                    }

                    Directory.CreateDirectory(to);
                    CopyDirectory(new DirectoryInfo(orig), new DirectoryInfo(to));
                }
            }

            yield return Status($"Reverted {revertEntries.Count} files", 1f, "done", true);

            yield return Status($"Removing old Everest files", 0f, "backup", false);

            foreach (string name in OldEverestFileNames) {
                string path = Path.Combine(root, name);

                if (File.Exists(path))
                    File.Delete(path);
                else if (Directory.Exists(path))
                    Directory.Delete(path, true);
            }

            foreach (string file in Directory.GetFiles(root)) {
                string ext = Path.GetExtension(file);
                if(Path.GetFileName(file).StartsWith("MonoMod.") && (ext == ".dll" || ext == ".pdb" || ext == ".xml" || ext == ".json"))
                    File.Delete(file);
            }
        }

    }
}
