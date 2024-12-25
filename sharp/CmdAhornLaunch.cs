using System;
using System.Collections;
using System.Diagnostics;
using System.IO;

namespace Olympus {
    public class CmdAhornLaunch : Cmd<string, IEnumerator> {

        public override IEnumerator Run(string theme) {
            yield return "Initializing...";

            Environment.SetEnvironmentVariable("AHORN_GTK_CSD", null);
            Environment.SetEnvironmentVariable("AHORN_GTK_THEME", null);

            if (!string.IsNullOrEmpty(theme)) {
                if (theme.EndsWith("|CSD")) {
                    theme = theme.Substring(0, theme.Length - 4);
                    Environment.SetEnvironmentVariable("AHORN_GTK_CSD", "1");
                }
                Environment.SetEnvironmentVariable("AHORN_GTK_THEME", theme);
            }

            string tmpFilename = null;
            try {
                using (Process process = AhornHelper.NewJulia(out tmpFilename, @"
env = ENV[""AHORN_ENV""]
globalenv = ENV[""AHORN_GLOBALENV""]

logfilePath = joinpath(mkpath(dirname(globalenv)), ""error.log"")

println(""Logging to "" * logfilePath)

logfile = open(logfilePath, ""w"")
println(logfile, ""Running Ahorn via Olympus."")

flush(stdout)
flush(stderr)

stdoutReal = stdout
(rd, wr) = redirect_stdout()
redirect_stderr(stdout)

@async while !eof(rd)
    data = String(readavailable(rd))
    print(stdoutReal, data)
    flush(stdoutReal)
    print(logfile, data)
    flush(logfile)
end

# Required because Gtk.jl likes to ENV[""GTK_CSD""] = 0 on Windows.
@eval(Base, setindex!(env::EnvDict, v::Int64, k::AbstractString) = k === ""GTK_CSD"" ? false : env[k] = string(v))

csd = get(ENV, ""AHORN_GTK_CSD"", nothing)
if csd !== nothing
    ENV[""GTK_CSD""] = csd
end

theme = get(ENV, ""AHORN_GTK_THEME"", nothing)
if theme !== nothing
    ENV[""GTK_THEME""] = theme
end

using Logging
logger = SimpleLogger(stdout, Logging.Debug)
loggerPrev = Logging.global_logger(logger)

using Pkg
Pkg.activate(env)

install_or_update(url::String, pkg::String) = if ""Ahorn"" ∈ keys(Pkg.Types.Context().env.project.deps)
    println(""Updating $pkg..."")
    Pkg.update(pkg)
else
    println(""Adding $pkg..."")
    Pkg.add(PackageSpec(url = url))
end

if Base.find_package(""Ahorn"") === nothing
    try
        println(""#OLYMPUS# TIMEOUT START"")

        Pkg.instantiate()

        install_or_update(""https://github.com/CelestialCartographers/Maple.git"", ""Maple"")
        install_or_update(""https://github.com/CelestialCartographers/Ahorn.git"", ""Ahorn"")

        Pkg.instantiate()
        Pkg.API.precompile()

        println(""#OLYMPUS# TIMEOUT END"")
    catch e
        println(""FATAL ERROR"")
        println(sprint(showerror, e, catch_backtrace()))
        exit(1)
    end
end

Logging.global_logger(loggerPrev)

using Ahorn
Ahorn.displayMainWindow()
"
                )) {

                    process.Start();
                    for (string line; (line = process.StandardOutput.ReadLine()) != null;)
                        yield return CmdAhornRunJuliaTask.Escape(line, out _);
                    process.WaitForExit();
                    yield return process.ExitCode == 0;
                }
            } finally {
                if (!string.IsNullOrEmpty(tmpFilename) && File.Exists(tmpFilename))
                    File.Delete(tmpFilename);
            }
        }

    }
}
