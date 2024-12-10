# Olympus - Cross-platform Celeste Mod Manager

### License: MIT

----

[![Build Status](https://dev.azure.com/EverestAPI/Olympus/_apis/build/status/EverestAPI.Olympus?branchName=main)](https://dev.azure.com/EverestAPI/Olympus/_build?definitionId=4)

<a href="https://discord.gg/6qjaePQ"><img align="right" alt="Mt. Celeste Climbing Association" src="https://discordapp.com/api/guilds/403698615446536203/embed.png?style=banner2" /></a>

[**Check the website for installation / usage instructions.**](https://everestapi.github.io/)

**Work in progress!**

## Dependencies
- [LÖVE](https://love2d.org/)
- [dkjson](https://github.com/LuaDist/dkjson)
- [lua-yaml](https://github.com/exosite/lua-yaml)
- [nativefiledialog](https://github.com/Vexatos/nativefiledialog/tree/master/lua)
- [luajit-request](https://github.com/LPGhatguy/luajit-request)
- [libcurl](https://curl.haxx.se/libcurl/)
- [LuaCOM](https://github.com/davidm/luacom)
- [LuaSQLite3](http://lua.sqlite.org/index.cgi/home)
- [lua-subprocess](https://github.com/0x0ade/lua-subprocess)
- [profile.lua](https://bitbucket.org/itraykov/profile.lua/src/master/)
- [moonshine](https://github.com/vrld/moonshine)
- [xml2lua](https://github.com/manoelcampos/xml2lua)
- [patchy](https://github.com/excessive/patchy)
- [OlympUI](https://github.com/EverestAPI/OlympUI)
- Shared code between Olympus and [Lönn](https://github.com/CelestialCartographers/Loenn)

## Local setup

- Make sure you cloned the repository with `--recurse-submodules`: `src/luajit-request`, `src/moonshine` and `src/ui` should not be empty.
- Create a `love` folder in the repository. (`love` is gitignored, so no worries about that :sweat_smile:)
- Compile the C# part in the `sharp` folder: you can do this with Visual Studio or by running `dotnet build Olympus.Sharp.sln` in the `sharp` folder.
- Make a symbolic link in `love/sharp` that leads to `sharp/bin/Debug/net452` (or copy-paste the folder :stuck_out_tongue: this is more tedious if you plan to make changes to the C# project, though.)
- Download a built Olympus version ([Windows](https://maddie480.ovh/celeste/download-olympus?branch=stable&platform=windows), [Linux](https://maddie480.ovh/celeste/download-olympus?branch=stable&platform=linux)) and extract everything from it, except the `sharp` folder, into `love`.
- If on Windows, install [LÖVE](https://www.love2d.org/): take the zipped version and extract it in the `love` folder. **Be sure to install the 32-bit version!**
- Run Olympus by running `debug.bat` on Windows, or by going to the `src` folder and running `../love/love --console .` on Linux.

**Note:** for Linux, a `build-and-run.sh` script is present on this repository to set up the `love` directory, build Olympus.Sharp, and run Olympus.