using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Reflection;
using System.Threading;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Olympus {
    public class Program {

        public static void Main(string[] args) {
            CultureInfo.DefaultThreadCurrentCulture = CultureInfo.InvariantCulture;
            CultureInfo.DefaultThreadCurrentUICulture = CultureInfo.InvariantCulture;

            Process parentProc = null;
            int parentProcID = 0;

            TcpListener listener = new TcpListener(IPAddress.Loopback, 0);
            List<Thread> threads = new List<Thread>();
            listener.Start();

            Console.WriteLine($"{((IPEndPoint) listener.LocalEndpoint).Port}");

            if (args.Length == 0) {
                Console.WriteLine(@"""no parent pid""");
                Console.WriteLine(@"null");
                Console.Out.Flush();
                // return;

            } else {
                try {
                    parentProc = Process.GetProcessById(parentProcID = int.Parse(args[0]));
                } catch {
                    Console.WriteLine(@"null");
                    Console.WriteLine(@"{""error"": ""invalid parent id""}\n");
                    Console.Out.Flush();
                    return;
                }

                bool debug = false;

                for (int i = 1; i < args.Length; i++) {
                    string arg = args[i];
                    if (arg == "--debug") {
                        debug = true;
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
            }

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
                        Console.Error.WriteLine($"[sharp] New TCP connection: {client.Client.RemoteEndPoint}");

                        client.Client.SetSocketOption(SocketOptionLevel.Socket, SocketOptionName.ReceiveTimeout, 1000);

                        Thread thread = new Thread(() => {
                            JsonSerializer jsonSerializer = new JsonSerializer();

                            try {
                                using (Stream stream = client.GetStream())
                                using (TextWriter writer = new StreamWriter(stream))
                                using (JsonTextWriter jsonWriter = new JsonTextWriter(writer)) {
                                    try {
                                        using (JsonTextReader jsonReader = new JsonTextReader(new StreamReader(stream)) {
                                            SupportMultipleContent = true
                                        }) {
                                            while (!(parentProc?.HasExited ?? false)) {
                                                // Commands from Olympus come in pairs of two objects:

                                                Console.Error.WriteLine("[sharp] Awaiting next command");

                                                // Unique ID
                                                jsonReader.Read();
                                                string uid = jsonSerializer.Deserialize<string>(jsonReader).ToLowerInvariant();
                                                Console.Error.WriteLine($"[sharp] Receiving command {uid}");
                                                jsonSerializer.Serialize(jsonWriter, uid, typeof(string));
                                                jsonWriter.Flush();
                                                writer.WriteLine();
                                                writer.Flush();

                                                // Command ID
                                                jsonReader.Read();
                                                string cid = jsonSerializer.Deserialize<string>(jsonReader).ToLowerInvariant();
                                                Cmd cmd = Cmds.Get(cid);
                                                if (cmd == null) {
                                                    jsonReader.Read();
                                                    jsonReader.Skip();
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

                                                Console.Error.WriteLine($"[sharp] Parsing args for {cid}");

                                                // Payload
                                                jsonReader.Read();
                                                object input = jsonSerializer.Deserialize(jsonReader, cmd.InputType);
                                                object output;
                                                try {
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

                                                jsonSerializer.Serialize(jsonWriter, output, cmd.OutputType);
                                                jsonWriter.Flush();
                                                writer.WriteLine();
                                                writer.WriteLine(@"null");
                                                writer.Flush();
                                            }
                                        }

                                    } catch (Exception e) {
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

                            } catch (Exception e) {
                                Console.Error.WriteLine($"[sharp] Failed communicating: {e}");
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

    }
}
