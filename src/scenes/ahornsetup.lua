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
            uie.label("Gathering Ahorn installation status..."),
        }):with(uiu.fillWidth)
        mainlist:addChild(status)

        local info = sharp.ahornGetInfo():result()
        status:removeSelf()

        local function btnInstallJulia()
            return uie.button(
                uie.row({ uie.icon("download"):with({ scale = 21 / 256 }), uie.label("Install Julia " .. tostring(info.JuliaVersionRecommended)) }):with({
                    style = {
                        bg = {},
                        padding = 0
                    },
                    clip = false,
                    cacheable = false
                }):with(uiu.styleDeep), function()
                    scene.installJulia()
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

        local function btnInstallAhorn()
            return uie.button(
                uie.row({ uie.icon("download"):with({ scale = 21 / 256 }), uie.label("Install Ahorn") }):with({
                    style = {
                        bg = {},
                        padding = 0
                    },
                    clip = false,
                    cacheable = false
                }):with(uiu.styleDeep), function()
                    scene.installAhorn()
                end
            ):with({
                style = {
                    normalBG = { 0.2, 0.4, 0.2, 0.8 },
                    hoveredBG = { 0.3, 0.6, 0.3, 0.9 },
                    pressedBG = { 0.2, 0.6, 0.2, 0.9 }
                },
                clip = false,
                cacheable = false,
                enabled = info.JuliaVersion and true or false
            }):with(uiu.fillWidth):with(utils.important(24, function() return info.JuliaVersion end))
        end

        if not info.JuliaPath then
            mainlist:addChild(uie.column({
                uie.label("Julia not found", ui.fontBig),
                uie.label([[
No supported installation of Julia was found.
Ahorn is programmed in the Julia programming language and thus needs Julia to be installed.

You can either install Julia yourself, or Olympus can install it into an isolated environment.
As of the time of writing this, version 1.3+ is the minimum requirement.]]
                ),
                btnInstallJulia()
            }):with(uiu.fillWidth))

        elseif not info.JuliaVersion then
            mainlist:addChild(uie.column({
                uie.label("Julia not recognized", ui.fontBig),
                uie.label(string.format([[
The currently installed version of Julia isn't working as expected.
Found installation path: %s

Olympus can download and set up an isolated Julia environment for you.
As of the time of writing this, version 1.3+ is the minimum requirement.]],
                    tostring(info.JuliaPath)
                )),
                btnInstallJulia()
            }):with(uiu.fillWidth))

        else
            mainlist:addChild(uie.column({
                uie.label("Julia", ui.fontBig),
                uie.label(string.format([[
Found version: %s
Found installation path: %s]],
                    tostring(info.JuliaPath), tostring(info.JuliaVersion))
                ),
            }):with(uiu.fillWidth))
        end


        if not info.AhornPath then
            mainlist:addChild(uie.column({
                uie.label("Ahorn not found", ui.fontBig),
                uie.label([[
No supported installation of Ahorn was found.
Olympus can download Ahorn and start the installation process for you.]]
                ),
                btnInstallAhorn()
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
