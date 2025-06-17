using System;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;

namespace Olympus {
    public class CmdWebGet : Cmd<string, byte[]> {
        public override bool LogRun => false;
        public override bool Taskable => true;

        public override byte[] Run(string url) {
            try {
                using (HttpClient wc = new HttpClientWithCompressionSupport()) {
                    HttpRequestMessage request = new HttpRequestMessage(HttpMethod.Get, url);
                    request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("*/*"));
                    return wc.Send(request).Content.ReadAsByteArrayAsync().Result;
                }
            } catch (Exception e) {
                throw new Exception($"Failed downloading {url}", e);
            }
        }
    }
}
