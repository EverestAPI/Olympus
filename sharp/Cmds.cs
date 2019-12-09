using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;

namespace Olympus {
    public static partial class Cmds {
        public static readonly Dictionary<string, Cmd> All = new Dictionary<string, Cmd>();

        public static void Init() {
            foreach (Type type in typeof(Cmd).Assembly.GetTypes()) {
                if (!typeof(Cmd).IsAssignableFrom(type) || type.IsAbstract)
                    continue;

                Cmd cmd = (Cmd) Activator.CreateInstance(type);
                All[cmd.ID.ToLowerInvariant()] = cmd;
            }
        }

        public static Cmd Get(string id)
            => All.TryGetValue(id, out Cmd cmd) ? cmd : null;
    }

    public abstract class Cmd {
        public virtual string ID => GetType().Name.Substring(3);
        public abstract Type InputType { get; }
        public abstract Type OutputType { get; }
        public abstract object Run(object input);
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
