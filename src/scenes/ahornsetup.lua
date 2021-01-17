local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local fs = require("fs")
local threader = require("threader")
local scener = require("scener")
local alert = require("alert")
local config = require("config")
local sharp = require("sharp")
local themer = require("themer")
local background = require("background")
local updater = require("updater")

local scene = {
    name = "Ahorn Setup"
}


local nobg = {
    style = {
        bg = {},
        padding = 0,
        radius = 0
    },
    clip = false,
    cacheable = false
}


scene.loadingID = 0


local root = uie.column({
    uie.scrollbox(
        uie.column({

            uie.column({
                uie.label("ahornsetup.lua machine broke, please fix."),
            }):with(uiu.fillWidth),

        }):with({
            style = {
                bg = {},
                padding = 16
            },
            cacheable = false
        }):with(uiu.fillWidth):as("mainlist")
    ):with({
        style = {
            barPadding = 16,
        },
        clip = false,
        cacheable = false
    }):with(uiu.fill),

}):with({
    cacheable = false,
    _fullroot = true
})
scene.root = root


function scene.installJulia()
    local installer = scener.push("installer")
    installer.sharpTask("ahornInstallJulia"):calls(function(task, last)
        if not last then
            return
        end

        installer.update("Julia successfully installed", 1, "done")
        installer.done({
            {
                "OK",
                function()
                    scener.pop()
                end
            }
        })
    end)
end


function scene.reload()
    if scene.reloading then
        return scene.reloading
    end

    scene.reloading = threader.routine(function()
        local mainlist = root:findChild("mainlist")
        mainlist.children = {}
        mainlist:reflow()

        local loading = uie.row({
            uie.label("Loading"),
            uie.spinner():with({
                width = 16,
                height = 16
            })
        }):with({
            clip = false,
            cacheable = false
        }):with(uiu.bottombound(16)):with(uiu.rightbound(16)):as("loadingMods")
        scene.root:addChild(loading)

        local status = uie.column({
            uie.label("Checking Ahorn installation status..."),
        }):with(uiu.fillWidth)
        mainlist:addChild(status)

        local info = sharp.ahornPrepare(config.ahorn.rootPath, config.ahorn.forceLocal):result()
        status:removeSelf()

        mainlist:addChild(uie.column({
            uie.label("General info", ui.fontBig),
            uie.row({
                uie.column({
                    uie.label([[
Olympus can install and launch Ahorn for you.

This function isn't officially supported by the Ahorn developers.
Feel free to visit the Ahorn GitHub page for more info.]]),
                    uie.button("Open website", function()
                        utils.openURL("https://github.com/CelestialCartographers/Ahorn")
                    end):with(uiu.fillWidth)
                }):with({
                    style = {
                        bg = {},
                        padding = 0
                    },
                    clip = false
                }):with(uiu.fillWidth(4.5)):with(uiu.at(0, 0)),

                uie.column({
                    uie.label([[
Olympus can install Julia and Ahorn into an isolated environment.
It can also use your existing system-wide Julia and Ahorn installs.

Current mode: ]] .. (config.ahorn.forceLocal and "Isolated mode." or "Olympus tries to use existing installations.")
                    ),
                    uie.button(config.ahorn.forceLocal and "Enable using existing system-wide installations" or "Only use the isolated environment", function()
                        config.ahorn.forceLocal = not config.ahorn.forceLocal
                        config.save()
                        scene.reload()
                    end):with(uiu.fillWidth)
                }):with({
                    style = {
                        bg = {},
                        padding = 0
                    },
                    clip = false
                }):with(uiu.fillWidth(4.5)):with(uiu.at(4.5, 0))

            }):with({
                style = {
                    bg = {},
                    padding = 0
                },
                clip = false
            }):with(uiu.fillWidth)
        }):with(uiu.fillWidth))

        local function btnInstall(text, cb)
            return uie.button(
                uie.row({ uie.icon("download"):with({ scale = 21 / 256 }), uie.label(text) }):with({
                    style = {
                        bg = {},
                        padding = 0
                    },
                    clip = false,
                    cacheable = false
                }):with(uiu.styleDeep), function()
                    cb()
                end
            ):with({
                style = {
                    normalBG = { 0.2, 0.4, 0.2, 0.8 },
                    hoveredBG = { 0.3, 0.6, 0.3, 0.9 },
                    pressedBG = { 0.2, 0.6, 0.2, 0.9 }
                },
                clip = false,
                cacheable = false
            }):with(uiu.fillWidth):with(utils.important(24))
        end

        if not info.JuliaPath then
            mainlist:addChild(uie.column({
                uie.label("Julia not found", ui.fontBig),
                uie.label([[
Ahorn uses the Julia programming language, similar to how Minecraft uses the Java programming language.
No supported installation of Julia was found on your computer.

You can either install Julia yourself, or Olympus can install it into an isolated environment.
As of the time of writing this, version 1.3+ is the minimum requirement.]]
                ),
                btnInstall("Install Julia " .. tostring(info.JuliaVersionRecommended), scene.installJulia)
            }):with(uiu.fillWidth))

        elseif not info.JuliaVersion then
            mainlist:addChild(uie.column({
                uie.label("Julia not recognized", ui.fontBig),
                uie.label(string.format([[
Ahorn uses the Julia programming language, similar to how Minecraft uses the Java programming language.
The currently installed version of Julia isn't working as expected.
Found installation path: %s

Olympus can download and set up an isolated Julia environment for you.
As of the time of writing this, version 1.3+ is the minimum requirement.]],
                    tostring(info.JuliaPath)
                )),
                btnInstall("Install Julia " .. tostring(info.JuliaVersionRecommended), scene.installJulia)
            }):with(uiu.fillWidth))

        else
            mainlist:addChild(uie.column({
                uie.label("Julia", ui.fontBig),
                uie.label(string.format([[
Ahorn uses the Julia programming language, similar to how Minecraft uses the Java programming language.
Found installation path: %s
Found version: %s]],
                    tostring(info.JuliaPath), tostring(info.JuliaVersion))
                ),
            }):with(uiu.fillWidth))
        end


        if not info.AhornPath then
            mainlist:addChild(uie.column({
                uie.label("Ahorn not found", ui.fontBig),
                uie.label([[
No supported installation of Ahorn was found.
Olympus can download Ahorn and start the installation process for you.
Please note that this installs Ahorn into the isolated environment.]]
                ),
                btnInstall("Install Ahorn", scene.installAhorn)
            }):with(uiu.fillWidth))

        else
            mainlist:addChild(uie.column({
                uie.label("Ahorn", ui.fontBig),
                uie.label(string.format([[
Found installation path: %s
Found version: %s]],
                    tostring(info.AhornPath), tostring(info.AhornVersion))
                ),
            }):with(uiu.fillWidth))
        end


        loading:removeSelf()
        scene.reloading = nil
    end)
    return scene.reloading
end


function scene.load()
end


function scene.enter()
    scene.reload()
end


return scene
