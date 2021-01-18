using System;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Net;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;

namespace Olympus {
    public static partial class Cmds {
        public static readonly Dictionary<string, Cmd> All = new Dictionary<string, Cmd>();
        public static readonly Dictionary<Type, Cmd> AllByType = new Dictionary<Type, Cmd>();

        public static void Init() {
            foreach (Type type in typeof(Cmd).Assembly.GetTypes()) {
                if (!typeof(Cmd).IsAssignableFrom(type) || type.IsAbstract)
                    continue;

                Cmd cmd = (Cmd) Activator.CreateInstance(type);
                All[cmd.ID.ToLowerInvariant()] = cmd;
                AllByType[type] = cmd;
            }
        }

        public static Cmd Get(string id)
            => All.TryGetValue(id, out Cmd cmd) ? cmd : null;

        public static T Get<T>(string id) where T : Cmd
            => All.TryGetValue(id, out Cmd cmd) ? (T) cmd : null;

        public static T Get<T>() where T : Cmd
            => AllByType.TryGetValue(typeof(T), out Cmd cmd) ? (T) cmd : null;
    }

    public abstract class Cmd {
        public virtual string ID => GetType().Name.Substring(3);
        public abstract Type InputType { get; }
        public abstract Type OutputType { get; }
        public virtual bool LogRun => true;
        public virtual bool Taskable => false;
        public abstract object Run(object input);

        public static object[] Status(string text, float progress, string shape) {
            Console.Error.WriteLine(text);
            return StatusSilent(text, progress, shape);
        }

        public static object[] Status(string text, bool progress, string shape) {
            Console.Error.WriteLine(text);
            return StatusSilent(text, progress, shape);
        }

        public static object[] StatusSilent(string text, float progress, string shape) {
            return new object[] { text, progress, shape };
        }

        public static object[] StatusSilent(string text, bool progress, string shape) {
            return new object[] { text, progress, shape };
        }

        public static IEnumerator Download(string url, long length, Stream copy) {
            // The following blob of code mostly comes from the old Everest.Installer, which inherited it from the old ETGMod.Installer.

            yield return Status($"Downloading {Path.GetFileName(url)}", false, "download");

            DateTime timeStart = DateTime.Now;
            int pos = 0;
            using (WebClient wc = new WebClient()) {
                using (Stream input = wc.OpenRead(url)) {
                    if (length == 0) {
                        if (input.CanSeek) {
                            // Mono
                            length = input.Length;
                        } else {
                            // .NET
                            try {
                                HttpWebRequest request = (HttpWebRequest) WebRequest.Create(url);
                                request.Method = "HEAD";
                                using (HttpWebResponse response = (HttpWebResponse) request.GetResponse())
                                    length = response.ContentLength;
                            } catch (Exception) {
                                length = 0;
                            }
                        }
                    }

                    long progressSize = length;
                    int progressScale = 1;
                    while (progressSize > int.MaxValue) {
                        progressScale *= 10;
                        progressSize = length / progressScale;
                    }

                    DateTime timeLast = timeStart;

                    byte[] buffer = new byte[4096];
                    int read = 0;
                    int readForSpeed = 0;
                    int speed = 0;
                    int count = 0;
                    do {
                        count = buffer.Length;
                        read = input.Read(buffer, 0, count);
                        copy.Write(buffer, 0, read);
                        pos += read;
                        readForSpeed += read;

                        TimeSpan td = DateTime.Now - timeLast;
                        if (td.TotalMilliseconds > 100) {
                            speed = (int) ((readForSpeed / 1024D) / td.TotalSeconds);
                            readForSpeed = 0;
                            timeLast = DateTime.Now;
                        }

                        if (length > 0) {
                            yield return StatusSilent($"Downloading: {((int) Math.Floor(100D * Math.Min(1D, pos / (double) length)))}% @ {speed} KiB/s", (float) ((pos / progressScale) / (double) progressSize), "download");
                        } else {
                            yield return StatusSilent($"Downloading: {((int) Math.Floor(pos / 1000D))}KiB @ {speed} KiB/s", false, "download");
                        }
                    } while (read > 0);

                }
            }

            string logTime = (DateTime.Now - timeStart).TotalSeconds.ToString(CultureInfo.InvariantCulture);
            logTime = logTime.Substring(0, Math.Min(logTime.IndexOf('.') + 3, logTime.Length));
            yield return Status($"Downloaded {pos} bytes in {logTime} seconds.", 1f, "download");
        }


        public static IEnumerator Unpack(ZipArchive zip, string root, string prefix = "") {
            int count = string.IsNullOrEmpty(prefix) ? zip.Entries.Count : zip.Entries.Count(entry => entry.FullName.StartsWith(prefix));
            int i = 0;

            foreach (ZipArchiveEntry entry in zip.Entries) {
                string name = entry.FullName;
                if (string.IsNullOrEmpty(name) || name.EndsWith("/"))
                    continue;

                if (!string.IsNullOrEmpty(prefix)) {
                    if (!name.StartsWith(prefix))
                        continue;
                    name = name.Substring(prefix.Length);
                }

                yield return Status($"Unzipping #{i} / {count}: {name}", i / (float) count, "download");
                i++;

                string to = Path.Combine(root, name);
                string toParent = Path.GetDirectoryName(to);
                Console.Error.WriteLine($"{name} -> {to}");

                if (!Directory.Exists(toParent))
                    Directory.CreateDirectory(toParent);

                if (File.Exists(to))
                    File.Delete(to);

                using (FileStream fs = File.OpenWrite(to))
                using (Stream compressed = entry.Open())
                    compressed.CopyTo(fs);
            }

            yield return Status($"Unzipped {count} files", 1f, "download");
        }

    }

    public abstract class Cmd<TOutput> : Cmd {
        public override Type InputType => null;
        public override Type OutputType => typeof(TOutput);
        public override object Run(object input) {
            return Run();
        }
        public abstract TOutput Run();
    }

    public abstract class Cmd<TInput, TOutput> : Cmd {
        public override Type InputType => typeof(Tuple<TInput>);
        public override Type OutputType => typeof(TOutput);
        public override object Run(object input) {
            var t = (Tuple<TInput>) input;
            return Run(t.Item1);
        }
        public abstract TOutput Run(TInput input);
    }

    public abstract class Cmd<TInput1, TInput2, TOutput> : Cmd {
        public override Type InputType => typeof(Tuple<TInput1, TInput2>);
        public override Type OutputType => typeof(TOutput);
        public override object Run(object input) {
            var t = (Tuple<TInput1, TInput2>) input;
            return Run(t.Item1, t.Item2);
        }
        public abstract TOutput Run(TInput1 input1, TInput2 input2);
    }

    public abstract class Cmd<TInput1, TInput2, TInput3, TOutput> : Cmd {
        public override Type InputType => typeof(Tuple<TInput1, TInput2, TInput3>);
        public override Type OutputType => typeof(TOutput);
        public override object Run(object input) {
            var t = (Tuple<TInput1, TInput2, TInput3>) input;
            return Run(t.Item1, t.Item2, t.Item3);
        }
        public abstract TOutput Run(TInput1 input1, TInput2 input2, TInput3 input3);
    }

    public abstract class Cmd<TInput1, TInput2, TInput3, TInput4, TOutput> : Cmd {
        public override Type InputType => typeof(Tuple<TInput1, TInput2, TInput3, TInput4>);
        public override Type OutputType => typeof(TOutput);
        public override object Run(object input) {
            var t = (Tuple<TInput1, TInput2, TInput3, TInput4>) input;
            return Run(t.Item1, t.Item2, t.Item3, t.Item4);
        }
        public abstract TOutput Run(TInput1 input1, TInput2 input2, TInput3 input3, TInput4 input4);
    }

    public abstract class Cmd<TInput1, TInput2, TInput3, TInput4, TInput5, TOutput> : Cmd {
        public override Type InputType => typeof(Tuple<TInput1, TInput2, TInput3, TInput4, TInput5>);
        public override Type OutputType => typeof(TOutput);
        public override object Run(object input) {
            var t = (Tuple<TInput1, TInput2, TInput3, TInput4, TInput5>) input;
            return Run(t.Item1, t.Item2, t.Item3, t.Item4, t.Item5);
        }
        public abstract TOutput Run(TInput1 input1, TInput2 input2, TInput3 input3, TInput4 input4, TInput5 input5);
    }

    public abstract class Cmd<TInput1, TInput2, TInput3, TInput4, TInput5, TInput6, TOutput> : Cmd {
        public override Type InputType => typeof(Tuple<TInput1, TInput2, TInput3, TInput4, TInput5, TInput6>);
        public override Type OutputType => typeof(TOutput);
        public override object Run(object input) {
            var t = (Tuple<TInput1, TInput2, TInput3, TInput4, TInput5, TInput6>) input;
            return Run(t.Item1, t.Item2, t.Item3, t.Item4, t.Item5, t.Item6);
        }
        public abstract TOutput Run(TInput1 input1, TInput2 input2, TInput3 input3, TInput4 input4, TInput5 input5, TInput6 input6);
    }

    public abstract class Cmd<TInput1, TInput2, TInput3, TInput4, TInput5, TInput6, TInput7, TOutput> : Cmd {
        public override Type InputType => typeof(Tuple<TInput1, TInput2, TInput3, TInput4, TInput5, TInput6, TInput7>);
        public override Type OutputType => typeof(TOutput);
        public override object Run(object input) {
            var t = (Tuple<TInput1, TInput2, TInput3, TInput4, TInput5, TInput6, TInput7>) input;
            return Run(t.Item1, t.Item2, t.Item3, t.Item4, t.Item5, t.Item6, t.Item7);
        }
        public abstract TOutput Run(TInput1 input1, TInput2 input2, TInput3 input3, TInput4 input4, TInput5 input5, TInput6 input6, TInput7 input7);
    }

    public abstract class Cmd<TInput1, TInput2, TInput3, TInput4, TInput5, TInput6, TInput7, TInput8, TOutput> : Cmd {
        public override Type InputType => typeof(Tuple<TInput1, TInput2, TInput3, TInput4, TInput5, TInput6, TInput7, TInput8>);
        public override Type OutputType => typeof(TOutput);
        public override object Run(object input) {
            var t = (Tuple<TInput1, TInput2, TInput3, TInput4, TInput5, TInput6, TInput7, TInput8>) input;
            return Run(t.Item1, t.Item2, t.Item3, t.Item4, t.Item5, t.Item6, t.Item7, t.Rest);
        }
        public abstract TOutput Run(TInput1 input1, TInput2 input2, TInput3 input3, TInput4 input4, TInput5 input5, TInput6 input6, TInput7 input7, TInput8 input8);
    }
}
