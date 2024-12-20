using System;
using System.Collections;
using System.IO;

namespace Olympus {
    public class CmdInstallExtraData : Cmd<string, string, IEnumerator> {

        public override IEnumerator Run(string url, string path) {
            string pathOrig = path;
            path = Path.Combine(Program.RootDirectory, path);
            if (!path.StartsWith(Program.RootDirectory)) {
                yield return Status("Invalid path.", 1f, "error", false);
                throw new Exception($"Invalid path: {pathOrig}");
            }

            if (File.Exists(path)) {
                yield return Status($"Deleting existing {path}", false, "", false);
                File.Delete(path);

            }

            yield return Status($"Downloading {url} to {path}", false, "download", false);
            string tmp = path + ".part";
            if (File.Exists(tmp))
                File.Delete(tmp);
            using (FileStream stream = File.Open(tmp, FileMode.Create, FileAccess.ReadWrite, FileShare.None))
                yield return Download(url, 0, stream);
            File.Move(tmp, path);
        }

    }
}
