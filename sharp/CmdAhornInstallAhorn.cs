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
    public unsafe class CmdAhornInstallAhorn : Cmd<IEnumerator> {
        public override bool LogRun => false;
        public override IEnumerator Run() {
            return Cmds.Get<CmdAhornRunJuliaTask>().Run(@"
env = ENV[""AHORN_ENV""]

logfilePath = joinpath(dirname(env), ""log-install-ahorn.txt"")
println(""Logging to "" * logfilePath)
logfile = open(logfilePath, ""w"")

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


if VERSION < v""1.3""
    println(""Outdated version of Julia - $VERSION installed, 1.3+ needed."")
    exit(1)
end

using Logging
logger = SimpleLogger(stdout, Logging.Debug)
loggerPrev = Logging.global_logger(logger)

using Pkg
Pkg.activate(ENV[""AHORN_ENV""])

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

try
    println(""#OLYMPUS# TIMEOUT START"")

    Pkg.instantiate()

    install_or_update(""https://github.com/CelestialCartographers/Maple.git"", ""Maple"")
    install_or_update(""https://github.com/CelestialCartographers/Ahorn.git"", ""Ahorn"")

    Pkg.instantiate()
    Pkg.API.precompile()

    import Ahorn

    println(""#OLYMPUS# TIMEOUT END"")
catch e
    println(""FATAL ERROR"")
    println(sprint(showerror, e, catch_backtrace()))
    exit(1)
end

exit(0)
", null);
        }
    }
}
