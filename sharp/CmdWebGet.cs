using System;
using System.Net;

namespace Olympus {
    public class CmdWebGet : Cmd<string, byte[]> {
        public override bool LogRun => false;
        public override bool Taskable => true;

        public override byte[] Run(string url) {
            try {
                using (WebClient wc = new WebClient()) {
                    wc.Headers.Set(HttpRequestHeader.UserAgent, $"Everest.Olympus.Sharp");
                    wc.Headers.Set(HttpRequestHeader.Accept, "*/*");
                    return wc.DownloadData(url);
                }
            } catch (Exception e) {
                throw new Exception($"Failed downloading {url}", e);
            }
        }
    }
}
