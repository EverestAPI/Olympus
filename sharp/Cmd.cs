using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Olympus {
    public abstract class Cmd {
        public virtual string ID => GetType().Name.Substring(3);
        public abstract Type InputType { get; }
        public abstract Type OutputType { get; }
        public abstract object Run(object input);
    }

    public abstract class Cmd<TInput, TOutput> : Cmd where TInput : class where TOutput : class {
        public override Type InputType => typeof(TInput);
        public override Type OutputType => typeof(TOutput);
        public override object Run(object input) {
            return Run((TInput) input);
        }
        public abstract TOutput Run(TInput input);
    }

    public sealed class Nothing {
    }
}
