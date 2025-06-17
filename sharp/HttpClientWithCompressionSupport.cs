using System;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Net.Sockets;
using System.Threading;
using System.Threading.Tasks;

namespace Olympus {
    public class CmdSetOlympusVersion : Cmd<string, string> {
        public override string Run(string version) {
            HttpClientWithCompressionSupport.Version = version;
            return "ok";
        }
    }

    /// <summary>
    /// An HttpClient that supports compressed responses to save bandwidth, and uses IPv4 to work around issues for some users.
    /// </summary>
    public class HttpClientWithCompressionSupport : HttpClient {
        public static string Version = "ERROR";

        private static readonly Func<SocketsHttpConnectionContext, CancellationToken, ValueTask<Stream>> connectCallback = async delegate(SocketsHttpConnectionContext ctx, CancellationToken token) {
            if (ctx.DnsEndPoint.AddressFamily != AddressFamily.Unspecified && ctx.DnsEndPoint.AddressFamily != AddressFamily.InterNetwork) {
                throw new InvalidOperationException("no IPv4 address");
            }

            Socket socket = new Socket(SocketType.Stream, ProtocolType.Tcp) { NoDelay = true };
            try {
                await socket.ConnectAsync(new DnsEndPoint(ctx.DnsEndPoint.Host, ctx.DnsEndPoint.Port, AddressFamily.InterNetwork), token).ConfigureAwait(false);
                return new NetworkStream(socket, true);
            }
            catch (Exception) {
                socket.Dispose();
                throw;
            }
        };

        private static readonly SocketsHttpHandler compressedHandler = new SocketsHttpHandler {
            AutomaticDecompression = DecompressionMethods.All,
            ConnectCallback = connectCallback
        };

        private static readonly SocketsHttpHandler regularHandler = new SocketsHttpHandler {
            AutomaticDecompression = DecompressionMethods.None,
            ConnectCallback = connectCallback
        };

        public HttpClientWithCompressionSupport(bool enableCompression = true) : base(enableCompression ? compressedHandler : regularHandler, disposeHandler: false) {
            DefaultRequestHeaders.Add("User-Agent", $"Olympus/{Version}");
        }
    }
}
