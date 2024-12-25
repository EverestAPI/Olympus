using MonoMod.Utils;
using System.Collections;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;

namespace Olympus {
    public class CmdInstallLoenn : Cmd<string, string, IEnumerator> {

        public override IEnumerator Run(string installPath, string downloadLink) {
            using (MemoryStream wrapStream = new MemoryStream()) {
                yield return Download(downloadLink, 0, wrapStream);
                wrapStream.Seek(0, SeekOrigin.Begin);

                using (ZipArchive wrap = new ZipArchive(wrapStream, ZipArchiveMode.Read)) {
                    yield return Unpack(wrap, installPath);
                }

#if MACOS
                // make Lönn actually executable
                ProcessHelper.MakeExecutable(installPath + "/Lönn.app/Contents/MacOS/love");
                ProcessHelper.MakeExecutable(installPath + "/Lönn.app/Contents/MacOS/Lönn.sh");
#endif
            }
        }
    }
}
