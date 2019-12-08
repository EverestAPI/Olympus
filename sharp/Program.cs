using System;
using System.Collections.Generic;
using System.Diagnostics;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Olympus {
    public class Program {

        public static void Main(string[] args) {
            Process parentProc = null;

            if (args.Length != 1) {
                Console.WriteLine(@"{""__init"": ""no parent pid""}");
                Console.Out.Flush();
                // return;

            } else {
                try {
                    parentProc = Process.GetProcessById(int.Parse(args[0]));
                } catch {
                    Console.WriteLine(@"{""__error"": ""zombie process""}");
                    Console.Out.Flush();
                    return;
                }

                Console.WriteLine(@"{""__init"": ""just fine""}");
                Console.Out.Flush();
            }


            Dictionary<string, Cmd> cmds = new Dictionary<string, Cmd>();
            foreach (Type type in typeof(Cmd).Assembly.GetTypes()) {
                if (!typeof(Cmd).IsAssignableFrom(type) || type.IsAbstract)
                    continue;

                Cmd cmd = (Cmd) Activator.CreateInstance(type);
                cmds[cmd.ID] = cmd;
            }


            JsonSerializer serializer = new JsonSerializer();

            while (!(parentProc?.HasExited ?? false)) {
                using (JsonTextWriter writer = new JsonTextWriter(Console.Out)) {
                    try {
                        using (JsonTextReader reader = new JsonTextReader(Console.In)) {
                            reader.SupportMultipleContent = true;

                            reader.Read();
                            // Commands from Olympus come in pairs of two objects:

                            // Command ID
                            string id = serializer.Deserialize<string>(reader);
                            if (!cmds.TryGetValue(id, out Cmd cmd)) {
                                reader.Read();
                                reader.Skip();
                                Console.WriteLine(@"{""__error"": ""cmd id not found""}");
                                Console.Out.Flush();
                            }

                            // Payload
                            reader.Read();
                            try {
                                object input = serializer.Deserialize(reader, cmd.InputType);
                                object output = cmd.Run(input);
                                serializer.Serialize(writer, output, cmd.OutputType);
                                writer.Flush();
                                Console.WriteLine();
                                Console.Out.Flush();

                            } catch (Exception e) {
                                writer.WriteStartObject();
                                writer.WritePropertyName("__error");
                                writer.WriteValue("cmd failed running: " + e);
                                writer.WriteEndObject();
                                writer.Flush();
                                Console.WriteLine();
                                Console.Out.Flush();
                            }
                        }

                    } catch (Exception e) {
                        writer.WriteStartObject();
                        writer.WritePropertyName("__error");
                        writer.WriteValue("cmd failed parsing: " + e);
                        writer.WriteEndObject();
                        writer.Flush();
                        Console.WriteLine();
                        Console.Out.Flush();
                    }
                }
            }
        }

    }
}
