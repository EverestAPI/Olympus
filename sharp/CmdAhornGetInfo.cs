
namespace Olympus {
    public class CmdAhornGetInfo : Cmd<CmdAhornGetInfo.Info> {

        public override Info Run() {
            return new Info();
        }

        public class Info {

            public string Mode = AhornHelper.Mode.ToString();

            public string RootPath = AhornHelper.RootPath;
            public string VHDPath = AhornHelper.VHDPath;
            public string VHDMountPath = AhornHelper.VHDMountPath;

            public string JuliaPath = AhornHelper.JuliaPath;
            public bool JuliaIsLocal = AhornHelper.JuliaIsLocal;
            public string JuliaVersion = AhornHelper.GetJuliaVersion();
            public string JuliaVersionRecommended = CmdAhornInstallJulia.Version;
            public string JuliaVersionBetaRecommended = CmdAhornInstallJulia.VersionBeta;

            public string AhornGlobalEnvPath = AhornHelper.AhornGlobalEnvPath;
            public string AhornEnvPath = AhornHelper.AhornEnvPath;
            public string AhornPath = AhornHelper.AhornPath;
            public bool AhornIsLocal = AhornHelper.AhornIsLocal;
            public string AhornVersion = AhornHelper.GetVersion("Ahorn");

            public string MapleVersion = AhornHelper.GetVersion("Maple");

        }

    }
}
