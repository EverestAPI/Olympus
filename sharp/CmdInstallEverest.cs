using Mono.Cecil;
using Mono.Cecil.Cil;
using MonoMod.Utils;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Drawing;
using System.Globalization;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Net;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace Olympus {
    public unsafe class CmdInstallEverest : Cmd<string, string, IEnumerator> {

        public override IEnumerator Run(string root, string artifactBase) {
            for (int i = 0; i <= 100; i++) {
                yield return new object[] { $"Warmup #{i}", i / 100f, "" };
                Thread.Sleep(20);
            }

            // Only new builds offer olympus-meta and olympus-build artifacts.
            yield return new object[] { "Downloading metadata", false, "" };

            int size;

            try {
                byte[] zipData;
                using (WebClient wc = new WebClient())
                    zipData = wc.DownloadData(artifactBase + "olympus-meta");
                using (MemoryStream zipStream = new MemoryStream(zipData))
                using (ZipArchive zip = new ZipArchive(zipStream)) {
                    using (Stream sizeStream = zip.GetEntry("olympus-meta/size.txt").Open())
                    using (StreamReader sizeReader = new StreamReader(sizeStream))
                        size = int.Parse(sizeReader.ReadToEnd().Trim());
                }

            } catch (Exception) {
                size = 0;
            }

            if (size == 0) {
                yield return new object[] { "Failed to load metadata - too old build?", 1f, "error" };
                yield break;
            }

            yield return new object[] { "Downloading build", false, "download" };

            using (MemoryStream wrapStream = new MemoryStream()) {
                yield return Download(artifactBase + "olympus-build", size, wrapStream);

                yield return new object[] { "Unzipping", false, "download" };
                using (ZipArchive wrap = new ZipArchive(wrapStream)) {
                    using (Stream zipStream = wrap.GetEntry("olympus-build/build.zip").Open())
                    using (ZipArchive zipMain = new ZipArchive(zipStream)) {
                    }
                }
            }
        }

        public static IEnumerator Download(string url, long length, Stream copy) {
            // The following blob of code mostly comes from the old Everest.Installer, which inherited it from the old ETGMod.Installer.

            yield return new object[] { $"Downloading {Path.GetFileName(url)}", false, "download" };

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
                            yield return new object[] { $"Downloading: {((int) Math.Floor(100D * Math.Min(1D, pos / (double) length)))}% @ {speed} KiB/s", (float) ((pos / progressScale) / (double) progressSize), "download" };
                        } else {
                            yield return new object[] { $"Downloading: {((int) Math.Floor(pos / 1000D))}KiB @ {speed} KiB/s", false, "download" };
                        }
                    } while (read > 0);

                }
            }

            string logTime = (DateTime.Now - timeStart).TotalSeconds.ToString(CultureInfo.InvariantCulture);
            logTime = logTime.Substring(0, Math.Min(logTime.IndexOf('.') + 3, logTime.Length));
            yield return new object[] { $"Downloaded {pos} bytes in {logTime} seconds.", 1f, "download" };
        }

    }
}
