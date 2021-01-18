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


function scene.installJulia(beta)
    local function install()
        local installer = scener.push("installer")
        installer.sharpTask("ahornInstallJulia", beta):calls(function(task, last)
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

    if beta then
        alert({
            body = [[
You are about to install a beta version of Julia.
It hasn't been tested a lot and can be slower and buggier.
Use it at your own risk, or go back and install a non-beta version.
Do you want to continue?]],
            buttons = {
                {
                    "Yes",
                    function(container)
                        install()
                        container:close("OK")
                    end
                },
                { "No" }
            }
        })
    else
        return install()
    end
end


function scene.installAhorn()
    local installer = scener.push("installer")
    installer.sharpTask("ahornInstallAhorn"):calls(function(task, last)
        if not last then
            return
        end

        installer.update("Ahorn successfully installed", 1, "done")
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


function scene.installAhornAlert()
    alert({
        body = [[
Please note that installing Ahorn WILL TAKE A LONG TIME.
At some points it will look as if the installation is hanging.
It's working hard in the background, no matter how slow it is.
DON'T CLOSE OLYMPUS OR IT WILL CONTINUE INSTALLING IN THE BACKGROUND.

If you really need to cancel the installation process:
]] .. (
(love.system.getOS() == "Windows" and "Open Task Manager and force-close julia.exe") or
(love.system.getOS() == "macOS" and "Open the Activity Monitor and force-close the Julia process.") or
(love.system.getOS() == "Linux" and "You probably know your way around htop and kill.") or
("... Good luck killing the Julia process.")),
        buttons = {
            {
                "Install!",
                function(container)
                    scene.installAhorn()
                    container:close("OK")
                end
            },
            { "Back" }
        }
    })
end


function scene.launchAhorn()
    return threader.routine(function()
        local launching = sharp.ahornLaunch()
        local container = alert([[
Ahorn is now starting in the background.
It might take a few minutes until it appears.
A popup window will appear here if it crashes.
You can close this window.]])

        local rv = launching:result()
        if not rv then
            container:close()
            alert({
                body = [[
Ahorn has crashed unexpectedly.

You can ask for help in the Celeste Discord server.
An invite can be found on the Everest website.

Please drag and drop your files into the #modding_help channel.
Before uploading, check your logs for sensitive info (f.e. your username).]],
                buttons = {
                    scene.info.AhornIsLocal and
                    { "Open Olympus-Ahorn folder", function(container)
                        utils.openFile(scene.info.RootPath)
                    end } or
                    { "Open Ahorn folder", function(container)
                        utils.openFile(fs.dirname(scene.info.AhornGlobalEnvPath))
                    end },

                    { "Open Olympus log folder", function(container)
                        utils.openFile(fs.getStorageDir())
                    end },

                    { "Open Everest Website", function(container)
                        utils.openURL("https://everestapi.github.io/")
                        container:close("website")
                    end },

                    { "Close" },
                }
            })
        end
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
        scene.info = info
        status:removeSelf()

        mainlist:addChild(uie.column({
            uie.label("General info", ui.fontBig),
            uie.label("THIS IS STILL IN ACTIVE DEVELOPMENT. Please ping 0x0ade in the Celestecord if things go wrong."),
            uie.row({
                uie.column({
                    uie.label([[
Olympus can install and launch Ahorn for you.
This function isn't officially supported by the Ahorn developers.
Feel free to visit the Ahorn GitHub page for more info.]]),
                    uie.button("Open https://github.com/CelestialCartographers/Ahorn", function()
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
Current mode: ]] .. (config.ahorn.forceLocal and "Isolated-only mode." or "Isolated + existing installations.")
                    ),
                    uie.button(config.ahorn.forceLocal and "Enable finding system-wide Julia and Ahorn" or "Only use isolated Julia and Ahorn", function()
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
            }):with(uiu.fillWidth),

            uie.button("Open the Olympus isolated Ahorn folder", function()
                utils.openFile(info.RootPath)
            end):with(uiu.fillWidth)
        }):with(uiu.fillWidth))

        local function btnInstall(icon, text, cb)
            return uie.button(
                uie.row({ uie.icon(icon):with({ scale = 21 / 256 }), uie.label(type(text) == "function" and text() or text) }):with({
                    style = {
                        bg = {},
                        padding = 0
                    },
                    clip = false,
                    cacheable = false
                }):hook(type(text) ~= "function" and {} or {
                    update = function(orig, self, ...)
                        self.children[2].text = text()
                        orig(self, ...)
                    end
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

        local function btnInstallJulia()
            local text = "Install Julia " .. tostring(info.JuliaVersionRecommended)
            local textBeta = "Install Julia " .. tostring(info.JuliaVersionBetaRecommended)
            return btnInstall(
                "download",
                function()
                    return (love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")) and textBeta or text
                end,
                function()
                    scene.installJulia((love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")) and text ~= textBeta)
                end
            )
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
                btnInstallJulia()
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
                not info.JuliaIsLocal and btnInstallJulia()
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
]] .. ((info.JuliaIsLocal or config.ahorn.forceLocal) and "Ahorn will be installed into the isolated environment." or "Ahorn will be installed for your system-wide installation of Julia.")
                ),
                info.JuliaPath and btnInstall("download", "Install Ahorn", scene.installAhornAlert)
            }):with(uiu.fillWidth))

        else
            mainlist:addChild(uie.column({
                uie.label("Ahorn", ui.fontBig),
                uie.label(string.format([[
Found installation path: %s
Found version: %s]],
                    tostring(info.AhornPath), tostring(info.AhornVersion))
                ),
                btnInstall("mainmenu/ahorn", "Launch Ahorn", function()
                    scene.launchAhorn()
                end)
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
