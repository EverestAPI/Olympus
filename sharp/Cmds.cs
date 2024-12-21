using Newtonsoft.Json.Linq;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Net;
using System.Net.Sockets;

namespace Olympus {
    public static class Cmds {
        public static readonly Dictionary<string, Cmd> All = new Dictionary<string, Cmd>();
        public static readonly Dictionary<Type, Cmd> AllByType = new Dictionary<Type, Cmd>();

        public static void Init() {
            // find -name 'Cmd*.cs' | sed 's,./,new ,' | sed 's/.cs/(),/' | sort
            // then delete all red lines (such as new Cmds())
            Cmd[] cmds = {
                new CmdAhornGetInfo(),
                new CmdAhornInstallAhorn(),
                new CmdAhornInstallAhornVHD(),
                new CmdAhornInstallJulia(),
                new CmdAhornLaunch(),
                new CmdAhornMountAhornVHD(),
                new CmdAhornPrepare(),
                new CmdAhornRunJulia(),
                new CmdAhornRunJuliaTask(),
                new CmdAhornUnmountAhornVHD(),
                new CmdCrash(),
                new CmdDummyTask(),
                new CmdEcho(),
                new CmdFree(),
                new CmdGetEnv(),
                new CmdGetLoennLatestVersion(),
                new CmdGetModIdToNameMap(),
                new CmdGetRunningPath(),
                new CmdGetVersionString(),
                new CmdInstallEverest(),
                new CmdInstallExtraData(),
                new CmdInstallLoenn(),
                new CmdInstallMod(),
                new CmdInstallOlympus(),
                new CmdLaunch(),
                new CmdLaunchLoenn(),
                new CmdModList(),
                new CmdPoll(),
                new CmdPollWait(),
                new CmdPollWaitBatch(),
                new CmdRestart(),
                new CmdScanDragAndDrop(),
                new CmdStatus(),
                new CmdUninstallEverest(),
                new CmdUninstallLoenn(),
                new CmdUpdateAllMods(),
                new CmdWebGet(),
#if WIN32
                new CmdGetUWPPackagePath(),
                new CmdWin32AppAdd(),
                new CmdWin32RegGet(),
                new CmdWin32RegSet(),
#endif
            };

            foreach (Cmd cmd in cmds) {
                All[cmd.ID.ToLowerInvariant()] = cmd;
                AllByType[cmd.GetType()] = cmd;
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

        public static object[] Status(string text, float progress, string shape, bool update) {
            Console.Error.WriteLine(text);
            return StatusSilent(text, progress, shape, update);
        }

        public static object[] Status(string text, bool progress, string shape, bool update) {
            Console.Error.WriteLine(text);
            return StatusSilent(text, progress, shape, update);
        }

        public static object[] StatusSilent(string text, float progress, string shape, bool update) {
            if (update)
                CmdTask.Update++;
            return new object[] { text, progress, shape, update };
        }

        public static object[] StatusSilent(string text, bool progress, string shape, bool update) {
            if (update)
                CmdTask.Update++;
            return new object[] { text, progress, shape, update };
        }


        public static IEnumerator Try(IEnumerator inner, Exception[] ea) {
            bool moveNext;
            do {
                try {
                    moveNext = inner.MoveNext();
                } catch (Exception e) {
                    moveNext = false;
                    ea[0] = e;
                }
                if (!moveNext)
                    yield break;
                yield return inner.Current;
            } while (true);
        }


        public static HttpWebResponse Connect(string url) {
            HttpWebRequest req = (HttpWebRequest) WebRequest.Create(url);
            req.Timeout = 10000;
            req.ReadWriteTimeout = 10000;
            req.UserAgent = "Olympus";

            // disable IPv6 for this request, as it is known to cause "the request has timed out" issues for some users
            req.ServicePoint.BindIPEndPointDelegate = delegate(ServicePoint servicePoint, IPEndPoint remoteEndPoint, int retryCount) {
                if (remoteEndPoint.AddressFamily != AddressFamily.InterNetwork) {
                    throw new InvalidOperationException("no IPv4 address");
                }
                return new IPEndPoint(IPAddress.Any, 0);
            };

            return (HttpWebResponse) req.GetResponse();
        }

        public static IEnumerator Download(string url, long length, Stream copy) {
            // The following blob of code mostly comes from the old Everest.Installer, which inherited it from the old ETGMod.Installer.

            yield return Status($"Downloading {Path.GetFileName(url)}", false, "download", false);

            yield return Status("", false, "download", false);

            DateTime timeStart = DateTime.Now;
            int pos = 0;

            using (HttpWebResponse res = Connect(url)) {
                using (Stream input = res.GetResponseStream()) {
                    if (length == 0) {
                        if (input.CanSeek) {
                            // Mono
                            length = input.Length;
                        } else {
                            // .NET
                            try {
                                HttpWebRequest reqHEAD = (HttpWebRequest) WebRequest.Create(url);
                                reqHEAD.Method = "HEAD";
                                using (HttpWebResponse resHEAD = (HttpWebResponse) reqHEAD.GetResponse())
                                    length = resHEAD.ContentLength;
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
                            yield return StatusSilent($"Downloading: {((int) Math.Floor(100D * Math.Min(1D, pos / (double) length)))}% @ {speed} KiB/s", (float) ((pos / progressScale) / (double) progressSize), "download", true);
                        } else {
                            yield return StatusSilent($"Downloading: {((int) Math.Floor(pos / 1000D))}KiB @ {speed} KiB/s", false, "download", true);
                        }
                    } while (read > 0);

                }
            }

            string logTime = (DateTime.Now - timeStart).TotalSeconds.ToString(CultureInfo.InvariantCulture);
            logTime = logTime.Substring(0, Math.Min(logTime.IndexOf('.') + 3, logTime.Length));
            yield return Status($"Downloaded {pos} bytes in {logTime} seconds.", 1f, "download", true);
        }


        public static IEnumerator Unpack(ZipArchive zip, string root, string prefix = "") {
            int count = string.IsNullOrEmpty(prefix) ? zip.Entries.Count : zip.Entries.Count(entry => entry.FullName.StartsWith(prefix));
            int i = 0;

            yield return Status($"Unzipping {count} files", 0f, "download", false);

            foreach (ZipArchiveEntry entry in zip.Entries) {
                string name = entry.FullName;
                if (string.IsNullOrEmpty(name) || name.EndsWith("/"))
                    continue;

                if (!string.IsNullOrEmpty(prefix)) {
                    if (!name.StartsWith(prefix))
                        continue;
                    name = name.Substring(prefix.Length);
                }

                yield return Status($"Unzipping #{i} / {count}: {name}", i / (float) count, "download", true);
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

            yield return Status($"Unzipped {count} files", 1f, "download", true);
        }

        public abstract object ParseInputTuple(JObject tuple);

        protected static T GetValue<T>(JObject tuple, string key) {
            if (!tuple.TryGetValue(key, out JToken value)) return default;
            if (value.Type == JTokenType.Null) return default;
            return value.Value<T>();
        }
    }

    public abstract class Cmd<TOutput> : Cmd {
        public override Type InputType => null;
        public override Type OutputType => typeof(TOutput);
        public override object ParseInputTuple(JObject tuple) {
            return null;
        }
        public override object Run(object input) {
            return Run();
        }
        public abstract TOutput Run();
    }

    public abstract class Cmd<TInput, TOutput> : Cmd {
        public override Type InputType => typeof(Tuple<TInput>);
        public override Type OutputType => typeof(TOutput);
        public override object ParseInputTuple(JObject tuple) {
            return new Tuple<TInput>(
                GetValue<TInput>(tuple, "Item1")
            );
        }
        public override object Run(object input) {
            var t = (Tuple<TInput>) input;
            return Run(t.Item1);
        }
        public abstract TOutput Run(TInput input);
    }

    public abstract class Cmd<TInput1, TInput2, TOutput> : Cmd {
        public override Type InputType => typeof(Tuple<TInput1, TInput2>);
        public override Type OutputType => typeof(TOutput);
        public override object ParseInputTuple(JObject tuple) {
            return new Tuple<TInput1, TInput2>(
                GetValue<TInput1>(tuple, "Item1"),
                GetValue<TInput2>(tuple, "Item2")
            );
        }
        public override object Run(object input) {
            var t = (Tuple<TInput1, TInput2>) input;
            return Run(t.Item1, t.Item2);
        }
        public abstract TOutput Run(TInput1 input1, TInput2 input2);
    }

    public abstract class Cmd<TInput1, TInput2, TInput3, TOutput> : Cmd {
        public override Type InputType => typeof(Tuple<TInput1, TInput2, TInput3>);
        public override Type OutputType => typeof(TOutput);
        public override object ParseInputTuple(JObject tuple) {
            return new Tuple<TInput1, TInput2, TInput3>(
                GetValue<TInput1>(tuple, "Item1"),
                GetValue<TInput2>(tuple, "Item2"),
                GetValue<TInput3>(tuple, "Item3")
            );
        }
        public override object Run(object input) {
            var t = (Tuple<TInput1, TInput2, TInput3>) input;
            return Run(t.Item1, t.Item2, t.Item3);
        }
        public abstract TOutput Run(TInput1 input1, TInput2 input2, TInput3 input3);
    }

    public abstract class Cmd<TInput1, TInput2, TInput3, TInput4, TOutput> : Cmd {
        public override Type InputType => typeof(Tuple<TInput1, TInput2, TInput3, TInput4>);
        public override Type OutputType => typeof(TOutput);
        public override object ParseInputTuple(JObject tuple) {
            return new Tuple<TInput1, TInput2, TInput3, TInput4>(
                GetValue<TInput1>(tuple, "Item1"),
                GetValue<TInput2>(tuple, "Item2"),
                GetValue<TInput3>(tuple, "Item3"),
                GetValue<TInput4>(tuple, "Item4")
            );
        }
        public override object Run(object input) {
            var t = (Tuple<TInput1, TInput2, TInput3, TInput4>) input;
            return Run(t.Item1, t.Item2, t.Item3, t.Item4);
        }
        public abstract TOutput Run(TInput1 input1, TInput2 input2, TInput3 input3, TInput4 input4);
    }

    public abstract class Cmd<TInput1, TInput2, TInput3, TInput4, TInput5, TOutput> : Cmd {
        public override Type InputType => typeof(Tuple<TInput1, TInput2, TInput3, TInput4, TInput5>);
        public override Type OutputType => typeof(TOutput);
        public override object ParseInputTuple(JObject tuple) {
            return new Tuple<TInput1, TInput2, TInput3, TInput4, TInput5>(
                GetValue<TInput1>(tuple, "Item1"),
                GetValue<TInput2>(tuple, "Item2"),
                GetValue<TInput3>(tuple, "Item3"),
                GetValue<TInput4>(tuple, "Item4"),
                GetValue<TInput5>(tuple, "Item5")
            );
        }
        public override object Run(object input) {
            var t = (Tuple<TInput1, TInput2, TInput3, TInput4, TInput5>) input;
            return Run(t.Item1, t.Item2, t.Item3, t.Item4, t.Item5);
        }
        public abstract TOutput Run(TInput1 input1, TInput2 input2, TInput3 input3, TInput4 input4, TInput5 input5);
    }
}
