using Mono.Cecil;
using Mono.Cecil.Cil;
using MonoMod.Utils;
using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Olympus {
    public class CmdScanDragAndDrop : Cmd<string, string> {
        public override string Run(string path) {
            if (path.EndsWith(".zip")) {
                try {
                    using (FileStream stream = File.Open(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete))
                    using (ZipArchive zip = new ZipArchive(stream, ZipArchiveMode.Read)) {
                        if (zip.GetEntry("everest.yaml") != null || zip.GetEntry("everest.yml") != null)
                            return "mod";

                        if (zip.GetEntry("olympus-build/build.zip") != null || zip.GetEntry("main/MiniInstaller.exe") != null)
                            return "everest";
                    }
                } catch (Exception e) {
                    Console.Error.WriteLine($"ZIP cannot be scanned: {path}");
                    Console.Error.WriteLine(e);
                }
            }

            return "unknown";
        }
    }
}
