using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using YamlDotNet.Serialization;
using YamlDotNet.Serialization.ObjectFactories;

namespace Olympus {
    public static class Extensions {

        public static bool ReadLineUntil(this TextReader reader, string wanted) {
            for (string line; (line = reader.ReadLine()?.TrimEnd()) != null;)
                if (line == wanted)
                    return true;
            return false;
        }

    }
}
