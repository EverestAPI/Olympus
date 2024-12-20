using YamlDotNet.Serialization;

namespace Olympus {
    public static class YamlHelper {
        public static readonly IDeserializer Deserializer = new DeserializerBuilder().IgnoreUnmatchedProperties().Build();
    }
}
