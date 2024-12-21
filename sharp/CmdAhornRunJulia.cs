
namespace Olympus {
    public class CmdAhornRunJulia : Cmd<string, bool?, string> {
        public override bool LogRun => false;
        public override bool Taskable => true;
        public override string Run(string script, bool? localDepot) {
            return AhornHelper.GetJuliaOutput(script, out _, localDepot);
        }
    }
}
