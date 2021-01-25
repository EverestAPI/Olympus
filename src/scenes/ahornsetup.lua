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
    }):with(uiu.fill):with(uiu.at(0, 0)):as("mainholder"),

    uie.group({
        uie.column({
            uie.label("Ahorn Log", ui.fontBig),
            uie.scrollbox(
                uie.column({

                    uie.label("ahornsetup.lua machine broke, please fix."),

                }):with({
                    style = {
                        bg = {},
                        padding = 0
                    },
                    locked = true
                }):hook({
                    layoutLateLazy = function(orig, self)
                        self:layoutLate()
                    end,

                    layoutLate = function(orig, self)
                        orig(self)
                        if self.locked then
                            self.y = -self.height
                        end
                    end
                }):with(uiu.fillWidth):as("loglist")
            ):hook({
                onScroll = function(orig, self, ...)
                    scene.loglist.locked = false
                    orig(self, ...)
                end
            }):with(uiu.fillWidth):with(uiu.fillHeight(true)),

            uie.row({
                uie.button("Unlock button broke", function(self)
                    scene.loglist.locked = not scene.loglist.locked
                end):hook({
                    update = function(orig, self, ...)
                        local textPrev = self.label.text
                        local text = scene.loglist.locked and "Unlock scroll" or "Lock scroll"
                        if textPrev ~= text then
                            self.label.text = text
                            self.parent:reflowDown()
                        end

                        orig(self, ...)
                    end
                }),

                uie.button("Clear", function()
                    local loglist = scene.loglist
                    loglist.children = {}
                    loglist:reflow()
                end):with(uiu.fillWidth(true)),

                uie.button("Close", function()
                    scene.running = nil
                    scene.reload()
                end):with({
                    style = {
                        normalBG = { 0.4, 0.2, 0.2, 0.8 },
                        hoveredBG = { 0.6, 0.3, 0.3, 0.9 },
                        pressedBG = { 0.6, 0.2, 0.2, 0.9 }
                    }
                }):with(uiu.rightbound):as("logclose")
            }):with({
                style = {
                    bg = {},
                    padding = 0
                },
                clip = false
            }):with(uiu.fillWidth):with(uiu.bottombound)
        }):with(uiu.fill)
    }):with({
        style = {
            padding = 16
        }
    }):with(uiu.fill):with(uiu.at(0, 0)):as("logholder"),

}):with({
    cacheable = false,
    _fullroot = true
})
scene.root = root


scene.mainholder = scene.root:findChild("mainholder")
scene.logholder = scene.root:findChild("logholder")
scene.loglist = scene.root:findChild("loglist")
scene.logclose = scene.root:findChild("logclose")


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

function scene.updateAhornAlert()
    alert({
        body = [[
Checking for updates will also install updates.

Just like installing Ahorn, IT WILL TAKE A LONG TIME.
At some points it will look as if it is hanging.
It's working hard in the background, no matter how slow it is.
DON'T CLOSE OLYMPUS OR IT WILL CONTINUE UPDATING IN THE BACKGROUND.

If you really need to cancel the installation process:
]] .. (
(love.system.getOS() == "Windows" and "Open Task Manager and force-close julia.exe") or
(love.system.getOS() == "macOS" and "Open the Activity Monitor and force-close the Julia process.") or
(love.system.getOS() == "Linux" and "You probably know your way around htop and kill.") or
("... Good luck killing the Julia process.")),
        buttons = {
            {
                "Check and install updates",
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
    if scene.running then
        return scene.running
    end

    scene.running = threader.routine(function()
        scene.reload():result()

        scene.logclose.enabled = false

        local loglist = scene.loglist
        loglist.children = {}

        loglist:addChild(uie.label([[
Ahorn is now starting in the background.
It might take a few minutes until it appears.
Information will appear here if it crashes.
You can close Olympus. Ahorn will continue running.]]))

        loglist:addChild(uie.label("----------------------------------------------"))

        local task = sharp.ahornLaunch():result()

        local batch
        local last
        repeat
            batch = sharp.pollWaitBatch(task):result()
            local all = batch[3]
            for i = 1, #all do
                local line = all[i]
                if line ~= nil then
                    if type(line) == "string" and last ~= line then
                        last = line
                        loglist:addChild(uie.label(line):with({ wrap = true }):with(uiu.fillWidth))
                    end
                else
                    print("ahornsetup.launchAhorn encountered nil on poll", task)
                end
            end
        until batch[1] ~= "running" and batch[2] == 0

        if not sharp.poll(task):result() then
            loglist:addChild(uie.label("----------------------------------------------"))
            loglist:addChild(uie.label([[
Ahorn has crashed unexpectedly.

You can ask for help in the Celeste Discord server.
An invite can be found on the Everest website.

Please drag and drop your files into the #modding_help channel.
Before uploading, check your logs for sensitive info (f.e. your username).]]))

            loglist:addChild(
                uie.row({
                    uie.button("Open Ahorn folder", function() utils.openFile(fs.dirname(scene.info.AhornGlobalEnvPath)) end),
                    uie.button("Open Everest Website", function() utils.openURL("https://everestapi.github.io/") end),
                }):with({
                    style = {
                        bg = {}
                    },
                    clip = false
                })
            )

        else
            loglist:addChild(uie.label("----------------------------------------------"))
            loglist:addChild(uie.label([[
Ahorn has finished without an error code.
Press the close button in the bottom right corner to close this log.]]))
        end

        scene.logclose.enabled = true
    end)
end


function scene.reload()
    if scene.reloading then
        return scene.reloading
    end

    scene.reloading = threader.routine(function()
        if scene.running then
            scene.mainholder:removeSelf()
            scene.root:addChild(scene.logholder)
            scene.reloading = nil
            return
        end

        scene.logholder:removeSelf()
        scene.root:addChild(scene.mainholder)

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

        local function btnRow(items)
            local itemcount = #items
            return uie.row(uiu.map(items, function(item, i)
                local icon = item[1]
                local text = item[2]
                local cb = item[3]
                local btn = uie.button(
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
                ):with(i > 1 and {} or {
                    style = {
                        normalBG = { 0.2, 0.4, 0.2, 0.8 },
                        hoveredBG = { 0.3, 0.6, 0.3, 0.9 },
                        pressedBG = { 0.2, 0.6, 0.2, 0.9 }
                    },
                    clip = false,
                    cacheable = false
                })

                if itemcount == 1 then
                    btn = btn:with(uiu.fillWidth)
                else
                    btn = btn:with(uiu.fillWidth(1 / itemcount + 4)):with(uiu.at((i == 1 and 0 or 4) + (i - 1) / itemcount, 0))
                end

                if i == 1 then
                    btn = btn:with(utils.important(24))
                end

                return btn
            end)):with({
                style = {
                    bg = {},
                    padding = 0
                },
                clip = false,
                cacheable = false
            }):with(uiu.fillWidth):with(utils.important(24))
        end

        local function btnInstallJulia()
            local text = "Install Julia " .. tostring(info.JuliaVersionRecommended)
            local textBeta = "Install Julia " .. tostring(info.JuliaVersionBetaRecommended)
            return btnRow({
                {
                    "download",
                    function()
                        return (love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")) and textBeta or text
                    end,
                    function()
                        scene.installJulia((love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")) and text ~= textBeta)
                    end
                }
            })
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
                info.JuliaPath and btnRow({
                    { "download", "Install Ahorn", scene.installAhornAlert }
                })
            }):with(uiu.fillWidth))

        else
            mainlist:addChild(uie.column({
                uie.label("Ahorn", ui.fontBig),
                uie.label(string.format([[
Found installation path: %s
Found version: %s]],
                    tostring(info.AhornPath), tostring(info.AhornVersion))
                ),
                btnRow({
                    { "mainmenu/ahorn", "Launch Ahorn", scene.launchAhorn },
                    { "download", "Check for updates", scene.updateAhornAlert }
                })
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
