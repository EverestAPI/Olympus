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
redirect_stderr(stdout)

if VERSION < v""1.3""
    println(""Outdated version of Julia - $VERSION installed, 1.3+ needed."")
    exit(1)
end

using Pkg

Pkg.activate(ENV[""AHORN_ENV""])

isinstalled(pkg::String) = any(x -> x.name == pkg && x.is_direct_dep, values(Pkg.dependencies()))

install_or_update(url::String, pkg::String) = try 
    if Pkg.installed()[pkg] !== nothing
        println(""Updating $pkg..."")
        Pkg.update(pkg)
    end
catch err
    println(""Installing $pkg..."")
    Pkg.add(PackageSpec(url = url))
end

install_or_update(""https://github.com/CelestialCartographers/Maple.git"", ""Maple"")
install_or_update(""https://github.com/CelestialCartographers/Ahorn.git"", ""Ahorn"")

Pkg.instantiate()
Pkg.API.precompile()

import Ahorn

", null);
        }
    }
}
