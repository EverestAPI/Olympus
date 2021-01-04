using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Olympus {
    public static class Program {

        public static string RootPath;

        public static void Main(string[] args) {
            CultureInfo.DefaultThreadCurrentCulture = CultureInfo.InvariantCulture;
            CultureInfo.DefaultThreadCurrentUICulture = CultureInfo.InvariantCulture;

            RootPath = Path.GetDirectoryName(Environment.CurrentDirectory);
            Console.Error.WriteLine(RootPath);

            if (Type.GetType("Mono.Runtime") != null) {
                // Mono hates HTTPS.
                ServicePointManager.ServerCertificateValidationCallback = (sender, certificate, chain, sslPolicyErrors) => {
                    return true;
                };
            }

            // Enable TLS 1.2 to fix connecting to GitHub.
            ServicePointManager.SecurityProtocol |= SecurityProtocolType.Tls12;

            if (args.Length == 1 && args[0] == "--test") {
                new CmdGetUWPPackagePath().Run("MattMakesGamesInc.Celeste_79daxvg0dq3v6");
                return;
            }

            if (args.Length == 0) {
                AllocConsole();
                Console.WriteLine("0");
                Console.WriteLine(@"""no parent pid - interactive debug mode""");
                Console.WriteLine(@"null");
                Console.Out.Flush();
                Cmds.Init();
                MainLoop(null, Console.In, Console.Out, true, '\n');
                Console.Error.WriteLine("[sharp] Goodbye");
                Console.In.ReadLine();
                return;
            }

            Process parentProc = null;
            int parentProcID = 0;

            TcpListener listener = new TcpListener(IPAddress.Loopback, 0);
            List<Thread> threads = new List<Thread>();
            listener.Start();

            Console.WriteLine($"{((IPEndPoint) listener.LocalEndpoint).Port}");

            try {
                parentProc = Process.GetProcessById(parentProcID = int.Parse(args[0]));
            } catch {
                Console.WriteLine(@"null");
                Console.WriteLine(@"{""error"": ""invalid parent id""}\n");
                Console.Out.Flush();
                return;
            }

            bool debug = false;
            bool verbose = false;

            for (int i = 1; i < args.Length; i++) {
                string arg = args[i];
                if (arg == "--debug") {
                    debug = true;
                } else if (arg == "--verbose") {
                    verbose = true;
                }
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

                        Thread thread = new Thread(() => {
                            try {
                                using (Stream stream = client.GetStream())
                                using (StreamReader reader = new StreamReader(stream))
                                using (StreamWriter writer = new StreamWriter(stream))
                                    MainLoop(parentProc, reader, writer, verbose);
                            } catch (Exception e) {
                                if (e is ObjectDisposedException)
                                    Console.Error.WriteLine($"[sharp] Failed communicating with {ep}: {e.GetType()}: {e.Message}");
                                else
                                    Console.Error.WriteLine($"[sharp] Failed communicating with {ep}: {e}");
                                client.Close();

                            }
                        }) {
                            IsBackground = true
                        };

                        threads.Add(thread);
                        thread.Start();

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

        public static void MainLoop(Process parentProc, TextReader reader, TextWriter writer, bool verbose, char delimiter = '\0') {
            JsonSerializer jsonSerializer = new JsonSerializer();

            using (JsonTextWriter jsonWriter = new JsonTextWriter(writer)) {
                try {
                    // JsonTextReader would be neat here but Newtonsoft.Json is unaware of NetworkStreams and tries to READ PAST STRINGS
                    while (!(parentProc?.HasExited ?? false)) {
                        // Commands from Olympus come in pairs of two objects:

                        if (verbose)
                            Console.Error.WriteLine("[sharp] Awaiting next command");

                        // Unique ID
                        string uid = JsonConvert.DeserializeObject<string>(reader.ReadTerminatedString(delimiter));
                        if (verbose)
                            Console.Error.WriteLine($"[sharp] Receiving command {uid}");
                        jsonSerializer.Serialize(jsonWriter, uid, typeof(string));
                        jsonWriter.Flush();
                        writer.WriteLine();
                        writer.Flush();

                        // Command ID
                        string cid = JsonConvert.DeserializeObject<string>(reader.ReadTerminatedString(delimiter)).ToLowerInvariant();
                        Cmd cmd = Cmds.Get(cid);
                        if (cmd == null) {
                            reader.ReadTerminatedString(delimiter);
                            Console.Error.WriteLine($"[sharp] Unknown command {cid}");
                            writer.WriteLine(@"null");
                            writer.Flush();
                            jsonWriter.WriteStartObject();
                            jsonWriter.WritePropertyName("error");
                            jsonWriter.WriteValue("cmd failed running: not found: " + cid);
                            jsonWriter.WriteEndObject();
                            jsonWriter.Flush();
                            writer.WriteLine();
                            writer.Flush();
                            continue;
                        }

                        if (verbose)
                            Console.Error.WriteLine($"[sharp] Parsing args for {cid}");

                        // Payload
                        object input = JsonConvert.DeserializeObject(reader.ReadTerminatedString(delimiter), cmd.InputType);
                        object output;
                        try {
                            if (verbose || cmd.LogRun)
                                Console.Error.WriteLine($"[sharp] Executing {cid}");
                            output = cmd.Run(input);

                        } catch (Exception e) {
                            Console.Error.WriteLine($"[sharp] Failed running {cid}: {e}");
                            writer.WriteLine(@"null");
                            writer.Flush();
                            jsonWriter.WriteStartObject();
                            jsonWriter.WritePropertyName("error");
                            jsonWriter.WriteValue("cmd failed running: " + e);
                            jsonWriter.WriteEndObject();
                            jsonWriter.Flush();
                            writer.WriteLine();
                            writer.Flush();
                            continue;
                        }

                        if (output is IEnumerator enumerator) {
                            CmdTasks.Add(new CmdTask(uid, enumerator));
                            output = uid;
                        }

                        jsonSerializer.Serialize(jsonWriter, output, cmd.OutputType);
                        jsonWriter.Flush();
                        writer.WriteLine();
                        writer.WriteLine(@"null");
                        writer.Flush();
                    }

                } catch (Exception e) {
                    if (e is IOException)
                        Console.Error.WriteLine($"[sharp] Failed parsing: {e.GetType()}: {e.Message}");
                    else
                        Console.Error.WriteLine($"[sharp] Failed parsing: {e}");
                    writer.WriteLine(@"null");
                    writer.Flush();
                    jsonWriter.WriteStartObject();
                    jsonWriter.WritePropertyName("error");
                    jsonWriter.WriteValue("cmd failed parsing: " + e);
                    jsonWriter.WriteEndObject();
                    jsonWriter.Flush();
                    writer.WriteLine();
                    writer.Flush();
                }
            }
        }

        [DllImport("kernel32")]
        public static extern bool AllocConsole();

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

    }
}
