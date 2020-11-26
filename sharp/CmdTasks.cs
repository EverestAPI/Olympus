using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;

namespace Olympus {
    public static partial class CmdTasks {
        public static readonly Dictionary<string, CmdTask> All = new Dictionary<string, CmdTask>();

        public static void Add(CmdTask task) {
            All[task.ID] = task;
        }

        public static void Remove(CmdTask task) {
            All.Remove(task.ID);
        }

        public static CmdTask Get(string id)
            => All.TryGetValue(id, out CmdTask task) ? task : null;
    }

    public class CmdTask {

        public readonly string ID;

        public IEnumerator Enumerator;
        public Stack<IEnumerator> Stack = new Stack<IEnumerator>();
        public readonly Task Task;

        public object Current { get; private set; }
        public string Status { get; private set; }

        public CmdTask(string id, IEnumerator enumerator) {
            ID = id;
            Enumerator = enumerator;
            Status = "running";
            Step();
            Task = Task.Run(Run);
        }

        private bool Step() {
            Restep:
            try {
                if (Enumerator.MoveNext()) {
                    object current = Enumerator.Current;
                    if (current is IEnumerator pass) {
                        Stack.Push(Enumerator);
                        Enumerator = pass;
                        goto Restep;
                    }
                    Current = current;
                    return true;
                } else if (Stack.Count > 0) {
                    Enumerator = Stack.Pop();
                    goto Restep;
                } else {
                    Status = "done";
                    return false;
                }
            } catch {
                Status = "error";
                return false;
            }
        }

        private void Run() {
            while (Step()) ;
        }

    }
}
