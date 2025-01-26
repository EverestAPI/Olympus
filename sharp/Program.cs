using System;
using System.Collections;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Olympus {
    public static class Program {

        public static string RootDirectory;
        public static string ConfigDirectory;

        public static readonly Encoding UTF8NoBOM = new UTF8Encoding(false);

        public static Dictionary<string, Message> Cache = new Dictionary<string, Message>();

#if !WIN32
        [DllImport("libc")]
        private static extern void sigemptyset(IntPtr set);
        [DllImport("libc")]
        private static extern void sigprocmask(int how, IntPtr newSet, IntPtr oldSet);

#if MACOS
        private const int SIG_SETMASK = 3;
#else
        private const int SIG_SETMASK = 2;
#endif
#endif

        public static void Main(string[] args) {
            bool debug = false;
            bool verbose = false;

#if !WIN32
            // some things (notably love2d here: https://github.com/love2d/love/blob/main/src/modules/thread/threads.cpp#L163)
            // might be turning off signals, which leads to zombie child processes because Olympus.Sharp never gets notified that they ended!
            IntPtr set = Marshal.AllocHGlobal(64);
            sigemptyset(set);
            sigprocmask(SIG_SETMASK, set, IntPtr.Zero);
            Marshal.FreeHGlobal(set);
#endif

            for (int i = 1; i < args.Length; i++) {
                string arg = args[i];
                if (arg == "--debug") {
                    debug = true;
                } else if (arg == "--verbose") {
                    verbose = true;
#if WIN32
                } else if (arg == "--console") {
                    AllocConsole();
#endif
                }
            }

            CultureInfo.DefaultThreadCurrentCulture = CultureInfo.InvariantCulture;
            CultureInfo.DefaultThreadCurrentUICulture = CultureInfo.InvariantCulture;

            RootDirectory = Path.GetDirectoryName(Environment.CurrentDirectory);
            ConfigDirectory = Environment.GetEnvironmentVariable("OLYMPUS_CONFIG");
            if (string.IsNullOrEmpty(ConfigDirectory) || !Directory.Exists(ConfigDirectory))
                ConfigDirectory = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Olympus");
            Console.Error.WriteLine(RootDirectory);

            if (Type.GetType("Mono.Runtime") != null) {
                // Mono hates HTTPS.
                ServicePointManager.ServerCertificateValidationCallback = (sender, certificate, chain, sslPolicyErrors) => {
                    return true;
                };
            }

            // Enable TLS 1.2 to fix connecting to GitHub.
            ServicePointManager.SecurityProtocol |= SecurityProtocolType.Tls12;

#if WIN32
            if (args.Length >= 1 && args[0] == "--uninstall") {
                new CmdWin32AppUninstall().Run(args.Length >= 2 && args[1] == "--quiet");
                return;
            }
#endif

            Process parentProc = null;
            int parentProcID = 0;

            TcpListener listener = new TcpListener(IPAddress.Loopback, 0);
            List<Thread> threads = new List<Thread>();
            listener.Start();

            Console.WriteLine($"{((IPEndPoint) listener.LocalEndpoint).Port}");

            try {
                parentProc = Process.GetProcessById(parentProcID = int.Parse(args.Last()));
            } catch {
                Console.Error.WriteLine("[sharp] Invalid parent process ID");
            }

            if (debug) {
                Debugger.Launch();
                Console.WriteLine(@"""debug""");

            } else {
                Console.WriteLine(@"""ok""");
            }

            Console.WriteLine(@"null");
            Console.Out.Flush();

            if (parentProc != null) {
                Thread killswitch = new Thread(() => {
                    try {
                        while (!parentProc.HasExited && parentProc.Id == parentProcID) {
                            Thread.Yield();
                            Thread.Sleep(1000);
                        }
                        Environment.Exit(0);
                    } catch {
                        Environment.Exit(-1);
                    }
                }) {
                    Name = "Killswitch",
                    IsBackground = true
                };
                killswitch.Start();
            }

            Cmds.Init();

            try {
                while ((parentProc != null && !parentProc.HasExited && parentProc.Id == parentProcID) || parentProc == null) {
                    TcpClient client = listener.AcceptTcpClient();
                    try {
                        string ep = client.Client.RemoteEndPoint.ToString();
                        Console.Error.WriteLine($"[sharp] New TCP connection: {ep}");

                        client.Client.SetSocketOption(SocketOptionLevel.Socket, SocketOptionName.ReceiveTimeout, 1000);
                        Stream stream = client.GetStream();

                        MessageContext ctx = new MessageContext();

                        lock (Cache)
                            foreach (Message msg in Cache.Values)
                                ctx.Reply(msg);

                        Thread threadW = new Thread(() => {
                            try {
                                using (StreamWriter writer = new StreamWriter(stream, UTF8NoBOM))
                                    WriteLoop(parentProc, ctx, writer, verbose);
                            } catch (Exception e) {
                                if (e is ObjectDisposedException)
                                    Console.Error.WriteLine($"[sharp] Failed writing to {ep}: {e.GetType()}: {e.Message}");
                                else
                                    Console.Error.WriteLine($"[sharp] Failed writing to {ep}: {e}");
                                client.Close();
                            } finally {
                                ctx.Dispose();
                            }
                        }) {
                            Name = $"Write Thread for Connection {ep}",
                            IsBackground = true
                        };

                        Thread threadR = new Thread(() => {
                            try {
                                using (StreamReader reader = new StreamReader(stream, UTF8NoBOM))
                                    ReadLoop(parentProc, ctx, reader, verbose);
                            } catch (Exception e) {
                                if (e is ObjectDisposedException)
                                    Console.Error.WriteLine($"[sharp] Failed reading from {ep}: {e.GetType()}: {e.Message}");
                                else
                                    Console.Error.WriteLine($"[sharp] Failed reading from {ep}: {e}");
                                client.Close();
                            } finally {
                                ctx.Dispose();
                            }
                        }) {
                            Name = $"Read Thread for Connection {ep}",
                            IsBackground = true
                        };

                        threads.Add(threadW);
                        threads.Add(threadR);
                        threadW.Start();
                        threadR.Start();

                    } catch (ThreadAbortException) {

                    } catch (Exception e) {
                        Console.Error.WriteLine($"[sharp] Failed listening for TCP connection:\n{e}");
                        client.Close();
                    }
                }

            } catch (ThreadAbortException) {

            } catch (Exception e) {
                Console.Error.WriteLine($"[sharp] Failed listening for TCP connection:\n{e}");
            }

            Console.Error.WriteLine("[sharp] Goodbye");

        }

        public static void WriteLoop(Process parentProc, MessageContext ctx, StreamWriter writer, bool verbose, char delimiter = '\0') {
            JsonSerializer jsonSerializer = new JsonSerializer() {
                Formatting = Formatting.None,
                NullValueHandling = NullValueHandling.Ignore
            };

            using (JsonTextWriter jsonWriter = new JsonTextWriter(writer)) {
                for (Message msg = null; !(parentProc?.HasExited ?? false) && (msg = ctx.WaitForNext()) != null;) {
                    if (msg.Value is IEnumerator enumerator) {
                        Console.Error.WriteLine($"[sharp] New CmdTask: {msg.UID}");
                        CmdTasks.Add(new CmdTask(msg.UID, enumerator));
                        msg.Value = msg.UID;
                    }

                    byte[] data = msg.Value as byte[];
                    if (data != null) {
                        msg.RawSize = data.Length;
                        msg.Value = null;
                    }

                    jsonSerializer.Serialize(jsonWriter, msg);
                    jsonWriter.Flush();
                    writer.Write(delimiter);
                    writer.Write('\n');
                    writer.Flush();

                    if (data != null) {
                        writer.BaseStream.Write(data, 0, data.Length);
                        writer.BaseStream.Flush();
                    }
                }
            }
        }


        public static void ReadLoop(Process parentProc, MessageContext ctx, StreamReader reader, bool verbose, char delimiter = '\0') {
            // JsonTextReader would be neat here but Newtonsoft.Json is unaware of NetworkStreams and tries to READ PAST STRINGS
            while (!(parentProc?.HasExited ?? false)) {
                // Commands from Olympus come in pairs of two objects:

                if (verbose)
                    Console.Error.WriteLine("[sharp] Awaiting next command");

                // Unique ID
                string uid = JsonConvert.DeserializeObject<string>(reader.ReadTerminatedString(delimiter));
                if (verbose)
                    Console.Error.WriteLine($"[sharp] Receiving command {uid}");

                // Command ID
                string cid = JsonConvert.DeserializeObject<string>(reader.ReadTerminatedString(delimiter)).ToLowerInvariant();
                if (cid == "_ack") {
                    reader.ReadTerminatedString(delimiter);
                    if (verbose)
                        Console.Error.WriteLine($"[sharp] Ack'd command {uid}");
                    lock (Cache)
                        if (Cache.ContainsKey(uid)) {
                            Cache.Remove(uid);
                        } else {
                            Console.Error.WriteLine($"[sharp] Ack'd command that was already ack'd {uid}");
                        }
                    continue;
                }

                if (cid == "_stop") {
                    // Let's hope that everyone knows how to handle this.
                    Environment.Exit(0);
                    continue;
                }

                Message msg = new Message() {
                    UID = uid,
                    CID = cid
                };

                Cmd cmd = Cmds.Get(cid);
                if (cmd == null) {
                    reader.ReadTerminatedString(delimiter);
                    Console.Error.WriteLine($"[sharp] Unknown command {cid}");
                    msg.Error = "cmd failed running: not found: " + cid;
                    ctx.Reply(msg);
                    continue;
                }

                if (verbose)
                    Console.Error.WriteLine($"[sharp] Parsing args for {cid}");

                // Payload
                string inputJson = reader.ReadTerminatedString(delimiter);
                object input = cmd.InputType == null ? null : cmd.ParseInputTuple(JObject.Parse(inputJson));
                object output;
                try {
                    if (verbose || cmd.LogRun)
                        Console.Error.WriteLine($"[sharp] Executing {cid}");
                    if (cmd.Taskable) {
                        output = Task.Run(() => cmd.Run(input));
                    } else {
                        output = cmd.Run(input);
                    }

                } catch (Exception e) {
                    Console.Error.WriteLine($"[sharp] Failed running {cid}: {e}");
                    msg.Error = "cmd failed running: " + e;
                    ctx.Reply(msg);
                    continue;
                }

                if (output is Task<object> task) {
                    task.ContinueWith(t => {
                        if (task.Exception != null) {
                            Exception e = task.Exception;
                            Console.Error.WriteLine($"[sharp] Failed running task {cid}: {e}");
                            msg.Error = "cmd task failed running: " + e;
                            ctx.Reply(msg);
                            return;
                        }

                        msg.Value = t.Result;
                        lock (Cache)
                            Cache[uid] = msg;
                        ctx.Reply(msg);
                    });

                } else {
                    msg.Value = output;
                    lock (Cache)
                        Cache[uid] = msg;
                    ctx.Reply(msg);
                }
            }
        }

#if WIN32
        [DllImport("kernel32")]
        public static extern bool AllocConsole();
#endif

        public static string ReadTerminatedString(this TextReader reader, char delimiter) {
            StringBuilder sb = new StringBuilder();
            char c;
            while ((c = (char) reader.Read()) != delimiter) {
                if (c < 0) {
                    // TODO: handle network stream end?
                    continue;
                }
                sb.Append(c);
            }
            return sb.ToString();
        }


        public class MessageContext : IDisposable {

            public readonly ManualResetEvent Event = new ManualResetEvent(false);
            public readonly WaitHandle[] EventWaitHandles;

            public readonly ConcurrentQueue<Message> Queue = new ConcurrentQueue<Message>();

            public bool Disposed;

            public MessageContext() {
                EventWaitHandles = new WaitHandle[] { Event };
            }

            public void Reply(Message msg) {
                Queue.Enqueue(msg);

                try {
                    Event.Set();
                }
                catch {
                }
            }

            public Message WaitForNext() {
                if (Queue.TryDequeue(out Message msg))
                    return msg;

                while (!Disposed) {
                    try {
                        WaitHandle.WaitAny(EventWaitHandles, 2000);
                    } catch {
                    }

                    if (Queue.TryDequeue(out msg)) {
                        if (Queue.Count == 0) {
                            try {
                                Event.Reset();
                            } catch {
                            }
                        }

                        return msg;
                    }
                }

                return null;
            }

            public void Dispose() {
                if (Disposed)
                    return;
                Disposed = true;

                Event.Set();
                Event.Dispose();
            }
        }

        public class Message {
            [NonSerialized]
            public string CID;
            public string UID;
            public object Value;
            public string Error;
            public long? RawSize;
        }
    }
}
