using System;
using System.Collections;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

namespace Olympus {
    public static class CmdTasks {
        public static readonly Dictionary<string, CmdTask> All = new Dictionary<string, CmdTask>();

        public static void Add(CmdTask task) {
            All[task.ID] = task;
        }

        public static void Remove(CmdTask task) {
            All.Remove(task.ID);
        }

        public static CmdTask Remove(string id) {
            if (All.TryGetValue(id, out CmdTask task)) {
                All.Remove(id);
                return task;
            }

            return null;
        }

        public static CmdTask Get(string id)
            => All.TryGetValue(id, out CmdTask task) ? task : null;
    }

    public class CmdTask : IDisposable {

        [ThreadStatic]
        public static int Update;

        public readonly string ID;

        public IEnumerator Enumerator;
        public readonly Stack<IEnumerator> Stack = new Stack<IEnumerator>();
        public readonly List<object> Queue = new List<object>();
        public readonly Task Task;

        public readonly ManualResetEvent Event = new ManualResetEvent(false);
        public readonly WaitHandle[] EventWaitHandles;

        public object Current;
        public string Status;
        public bool Alive;

        public CmdTask(string id, IEnumerator enumerator) {
            EventWaitHandles = new WaitHandle[] { Event };
            ID = id;
            Enumerator = enumerator;
            Status = "running";
            Alive = true;
            Step();
            Task = Task.Run(Run);
        }

        private bool Step() {
            Restep:
            try {
                if (Enumerator.MoveNext()) {
                    if (Status == "interrupted") return false;

                    object current = Enumerator.Current;
                    if (current is IEnumerator pass) {
                        Stack.Push(Enumerator);
                        Enumerator = pass;
                        goto Restep;
                    }
                    if (Current != current) {
                        lock (Queue) {
                            if (Update > 0) {
                                Update--;
                                if (Queue.Count > 0)
                                    Queue[Queue.Count - 1] = current;
                                else
                                    Queue.Add(current);
                            } else {
                                Queue.Add(current);
                            }
                            Event.Set();
                        }
                        Current = current;
                    }
                    return true;
                } else if (Stack.Count > 0) {
                    Enumerator = Stack.Pop();
                    goto Restep;
                } else {
                    Status = "done";
                    return false;
                }
            } catch (Exception e) {
                Console.Error.WriteLine($"[sharp] Task {ID} failed: {e}");
                Status = "error";
                return false;
            }
        }

        private void Run() {
            while (Alive = Step()) ;
            try {
                Event.Set();
            } catch {
            }
        }

        public object Dequeue() {
            lock (Queue) {
                if (Queue.Count == 0)
                    return Current;
                object rv = Queue[0];
                Queue.RemoveAt(0);
                return rv;
            }
        }

        public object[] DequeueAll(int max) {
            lock (Queue) {
                if (Queue.Count == 0)
                    return new object[0];

                object[] rv;

                if (max <= 0 || max <= Queue.Count) {
                    rv = Queue.ToArray();
                    Queue.Clear();
                    return rv;
                }

                rv = new object[max];
                for (int i = 0; i < max; i++)
                    rv[i] = Queue[i];
                Queue.RemoveRange(0, max);
                return rv;
            }
        }

        public object[] Wait(bool skip) {
            lock (Queue) {
                if (Queue.Count > 0) {
                    if (skip) {
                        int count = Alive || Queue.Count > 0 ? 1 : 0;
                        Queue.Clear();
                        return new object[] { Status, count, Current };
                    } else {
                        return new object[] { Status, Queue.Count, Dequeue() };
                    }
                }
            }

            if (Alive && Queue.Count == 0)
                WaitHandle.WaitAny(EventWaitHandles);

            lock (Queue) {
                if (skip) {
                    int count = Alive || Queue.Count > 0 ? 1 : 0;
                    Queue.Clear();
                    if (Alive)
                        Event.Reset();
                    return new object[] { Status, count, Current };

                } else {
                    if (Alive && Queue.Count <= 1)
                        Event.Reset();
                    return new object[] { Status, Queue.Count, Dequeue() };
                }
            }
        }

        public object[] WaitBatch(int max) {
            lock (Queue) {
                if (Queue.Count > 0) {
                    object[] rv = DequeueAll(max);
                    return new object[] { Status, Queue.Count, rv };
                }
            }

            if (Alive && Queue.Count == 0)
                WaitHandle.WaitAny(EventWaitHandles);

            lock (Queue) {
                object[] rv = DequeueAll(max);
                if (Alive && Queue.Count <= 0)
                    Event.Reset();
                return new object[] { Status, Queue.Count, rv };
            }
        }

        public void Dispose() {
            if (Alive) {
                Console.Error.WriteLine($"[sharp] Task {ID} was interrupted while running");
                Status = "interrupted";
                Alive = false;
                Event.Set();
            }

            Event.Dispose();
        }

    }
}
