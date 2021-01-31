using Mono.Cecil;
using Mono.Cecil.Cil;
using MonoMod.Utils;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
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
    public unsafe class CmdAhornLaunch : Cmd<string, IEnumerator> {
        
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

@eval(Pkg, can_fancyprint(io::IO) = true)

@eval(Pkg.PlatformEngines, download_real = download)
downloadSig = string(methods(Pkg.PlatformEngines.download).ms[1])
if     startswith(downloadSig, ""download(url::AbstractString, dest::AbstractString) in Pkg.PlatformEngines"")
    @eval(Pkg.PlatformEngines, download(url::AbstractString, dest::AbstractString) = (println(""Downloading $url""); download_real(url::AbstractString, dest::AbstractString)))
elseif startswith(downloadSig, ""download(url::AbstractString, dest::AbstractString; verbose, auth_header) in Pkg.PlatformEngines"")
    @eval(Pkg.PlatformEngines, download(url::AbstractString, dest::AbstractString, verbose::Bool = false, auth_header::Union{Pair{String,String}, Nothing} = nothing) = (println(""Downloading $url""); download_real(url::AbstractString, dest::AbstractString, true, auth_header)))
elseif startswith(downloadSig, ""download(url::AbstractString, dest::AbstractString; verbose, headers, auth_header) in Pkg.PlatformEngines"")
    @eval(Pkg.PlatformEngines, download(url::AbstractString, dest::AbstractString, verbose::Bool = false, headers::Vector{Pair{String,String}} = Pair{String,String}[], auth_header::Union{Pair{String,String}, Nothing} = nothing) = (println(""Downloading $url""); download_real(url::AbstractString, dest::AbstractString, true, headers, auth_header)))
end

@eval(Pkg.Operations, install_git_real = install_git)
installGitSig = string(methods(Pkg.Operations.install_git).ms[1].sig)
if     installGitSig == ""Tuple{typeof(Pkg.Operations.install_git),Pkg.Types.Context,Base.UUID,String,Base.SHA1,Array{String,1},Union{Nothing, VersionNumber},String}""
    @eval(Pkg.Operations, install_git(ctx::Pkg.Types.Context, uuid::Base.UUID, name::String, hash::Base.SHA1, urls::Array{String,1}, version::Union{Nothing, VersionNumber}, version_path::String)::Nothing = (println(""Downloading artifact $name via git""); install_git_real(ctx, uuid, name, hash, urls, version, version_path)))
elseif installGitSig == ""Tuple{typeof(Pkg.Operations.install_git), Pkg.Types.Context, Base.UUID, String, Base.SHA1, Vector{String}, Union{Nothing, VersionNumber}, String}""
    @eval(Pkg.Operations, install_git(ctx::Pkg.Types.Context, uuid::Base.UUID, name::String, hash::Base.SHA1, urls::Vector{String}, version::Union{Nothing, VersionNumber}, version_path::String)::Nothing = (println(""Downloading artifact $name via git""); install_git_real(ctx, uuid, name, hash, urls, version, version_path)))
elseif installGitSig == ""Tuple{typeof(Pkg.Operations.install_git), IO, Base.UUID, String, Base.SHA1, Vector{String}, Union{Nothing, VersionNumber}, String}""
    @eval(Pkg.Operations, install_git(io::IO, uuid::UUID, name::String, hash::SHA1, urls::Set{String}, version::Union{VersionNumber,Nothing}, version_path::String)::Nothing = (println(""Downloading artifact $name via git""); install_git_real(io, uuid, name, hash, urls, version, version_path)))
end

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

                    /*/
                    process.StartInfo.UseShellExecute = true;
                    process.StartInfo.CreateNoWindow = false;
                    process.StartInfo.RedirectStandardOutput = false;
                    process.StartInfo.RedirectStandardError = false;
                    /**/

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
