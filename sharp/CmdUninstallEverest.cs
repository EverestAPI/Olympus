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

        public override IEnumerator Run(string root, string artifactBase) {
            yield return Status("Uninstalling Everest", false, "backup");

            string origdir = Path.Combine(root, "orig");
            if (!Directory.Exists(origdir)) {
                yield return Status("Backup (orig) folder not found", 1f, "error");
                throw new Exception($"Backup folder not found: {origdir}");
            }

            int i = 0;
            string[] origs = Directory.GetFiles(origdir);
            foreach (string orig in origs) {
                string name = Path.GetFileName(orig);
                yield return Status($"Reverting #{i} / {origs.Length}: {name}", i / (float) origs.Length, "backup");
                i++;

                string to = Path.Combine(root, name);
                string toParent = Path.GetDirectoryName(to);
                Console.Error.WriteLine($"{orig} -> {to}");

                if (!Directory.Exists(toParent))
                    Directory.CreateDirectory(toParent);

                if (File.Exists(to))
                    File.Delete(to);

                File.Copy(orig, to);
            }

            yield return Status($"Reverted {origs.Length} files", 1f, "done");
        }

    }
}
