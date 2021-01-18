using Mono.Cecil;
using Mono.Cecil.Cil;
using MonoMod.Utils;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Net;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;

namespace Olympus {
    public unsafe class CmdWebGet : Cmd<string, byte[]> {
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
