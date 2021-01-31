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

local modes = {
    { text = "Let Olympus manage Julia and Ahorn", data = "local" },
    { text = "Use system-wide Julia and Ahorn if existing", data = "system" },
}
if love.system.getOS() == "Windows" then
    table.insert(modes, 1, { text = "Use pre-bundled Ahorn-VHD (fast, experimental)", data = "vhd" })
end

local themes = {
    { text = "System (default)", data = "" }
}
if love.system.getOS() == "Linux" then
    table.insert(themes, { text = "Adwaita", data = "Adwaita" })
    table.insert(themes, { text = "Adwaita:dark", data = "Adwaita:dark" })
else
    table.insert(themes, { text = "GTK light", data = "Adwaita|CSD" })
    table.insert(themes, { text = "GTK dark", data = "Adwaita:dark|CSD" })
    table.insert(themes, { text = "GTK light mixed with system", data = "Adwaita" })
    table.insert(themes, { text = "GTK dark mixed with system", data = "Adwaita:dark" })
end


local root = uie.column({
    uie.row({

        uie.scrollbox(
            uie.column({

                uie.column({
                    uie.label("About", ui.fontBig),

                    uie.label([[
Olympus can install and launch Ahorn for you.
Ahorn is the community map editor for Celeste.
This function isn't officially supported by the Ahorn developers.
Feel free to visit the Ahorn GitHub page for more info.]]),
                    uie.button("Open https://github.com/CelestialCartographers/Ahorn", function()
                        utils.openURL("https://github.com/CelestialCartographers/Ahorn")
                    end):with(uiu.fillWidth),
                }):with(uiu.fillWidth),

                uie.column({
                    uie.label("Options", ui.fontBig),

                    uie.label([[
Olympus can manage Julia and Ahorn in an isolated folder.
It can also use your existing system-wide Julia and Ahorn installs.]]),
                    uie.dropdown(
                        modes,
                        function(self, value)
                            config.ahorn.mode = value
                            config.save()
                            scene.reload()
                        end
                    ):hook({
                        update = function(orig, self, ...)
                            self.enabled = not scene.reloading
                            orig(self, ...)
                        end
                    }):with(function(self)
                        for i = 1, #modes do
                            if config.ahorn.mode == modes[i].data then
                                self.selected = self:getItem(i)
                                self.text = self.selected.text
                                return
                            end
                        end
                        self.selected = self:getItem(1)
                        self.text = "???"
                    end):with(uiu.fillWidth),

                    uie.button("Open the Olympus Ahorn folder", function()
                        utils.openFile(scene.info.RootPath)
                    end):hook({
                        update = function(orig, self, ...)
                            self.enabled = not scene.reloading
                            orig(self, ...)
                        end
                    }):with(uiu.fillWidth),

                    uie.group({}),

                    uie.label([[
Ahorn will use the following theme:]]),
                    uie.dropdown(
                        themes,
                        function(self, value)
                            config.ahorn.theme = value
                            config.save()
                        end
                    ):with(function(self)
                        for i = 1, #themes do
                            if config.ahorn.theme == themes[i].data then
                                self.selected = self:getItem(i)
                                self.text = self.selected.text
                                return
                            end
                        end
                        self.selected = self:getItem(1)
                        self.text = tostring(config.ahorn.theme or "???")
                    end):with(uiu.fillWidth),

                    uie.group({}),
                    uie.label("Check the Olympus config.json for more advanced settings.")
                }):with(uiu.fillWidth),

            }):with({
                style = {
                    padding = 0,
                    bg = {},
                },
                clip = false,
                cacheable = false
            }):with(uiu.fillWidth):as("infolist")
        ):with({
            width = 500,
            clip = false,
            cacheable = false
        }):with(uiu.fillHeight),


        uie.scrollbox(
            uie.column({

                uie.column({
                    uie.label("ahornsetup.lua machine broke, please fix."),
                }):with(uiu.fillWidth),

            }):with({
                style = {
                    padding = 0,
                    bg = {},
                },
                clip = false,
                cacheable = false
            }):with(uiu.fillWidth):as("mainlist")
        ):with({
            clip = false,
            cacheable = false
        }):with(uiu.fillWidth(true)):with(uiu.fillHeight)

    }):with({
        style = {
            bg = {},
            padding = 16
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
                            self.y = self.parent.height - self.height
                            self.realY = self.parent.height - self.height
                        end
                    end
                }):with(uiu.fillWidth):as("loglist")
            ):hook({
                onScroll = function(orig, self, mx, my, dx, dy, raw, ...)
                    local child = self.children[1]
                    local y1 = child.y
                    orig(self, mx, my, dx, dy, raw, ...)
                    local y2 = child.y
                    if my and (not raw or dy > 0 or self.children[1].locked) then
                        self.children[1].locked = (raw and dy > 0 or dy < 0) and y1 == y2
                    end
                end
            }):with(uiu.fillWidth):with(uiu.fillHeight(true)),

            uie.row({
                uie.button("", function(self)
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
                    loglist.y = 0
                    loglist.realY = 0
                    loglist.locked = true
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


function scene.sharpTaskScreen(cmd, message)
    local installer = scener.push("installer")
    installer.sharpTask(cmd):calls(function(task, last)
        if not last then
            return
        end

        installer.update(message, 1, "done")
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

function scene.sharpTaskScreenGen(cmd, message)
    return function()
        return scene.sharpTaskScreen(cmd, message)
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


function scene.installAhornVHD()
    local installer = scener.push("installer")
    installer.sharpTask("ahornInstallAhornVHD"):calls(function(task, last)
        if not last then
            return
        end

        installer.update("Ahorn-VHD successfully installed", 1, "done")
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
At
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
                    scene.sharpTaskScreen("ahornInstallAhorn")
                    container:close("OK")
                end
            },
            { "Back" }
        }
    })
end

function scene.forceUpdateAhornAlert()
    alert({
        body = [[
Checking for updates will also install updates.

Just like installing Ahorn, IT WILL TAKE A LONG TIME.
Olympus will detect hangs and abort too slow installation processes.
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
                    scene.sharpTaskScreen("ahornInstallAhorn")
                    container:close("OK")
                end
            },
            { "Back" }
        }
    })
end

function scene.updateAhornAlert(installed, found)
    alert({
        body = string.format([[
Olympus has found a possibly newer version of Ahorn.

Detected installed version:
%s

Latest available version:
%s

Just like installing Ahorn, IT WILL TAKE A LONG TIME.
Olympus will detect hangs and abort too slow installation processes.
DON'T CLOSE OLYMPUS OR IT WILL CONTINUE UPDATING IN THE BACKGROUND.

If you really need to cancel the installation process:
]] .. (
(love.system.getOS() == "Windows" and "Open Task Manager and force-close julia.exe") or
(love.system.getOS() == "macOS" and "Open the Activity Monitor and force-close the Julia process.") or
(love.system.getOS() == "Linux" and "You probably know your way around htop and kill.") or
("... Good luck killing the Julia process.")),
            installed, found),
        buttons = {
            {
                "Install updates",
                function(container)
                    scene.sharpTaskScreen("ahornInstallAhorn")
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
        loglist.y = 0
        loglist.realY = 0
        loglist.locked = true
        loglist:reflow()

        loglist:addChild(uie.label([[
Ahorn is now starting in the background.
It might take a few minutes until it appears.
Information will appear here if it crashes.
You can close Olympus. Ahorn will continue running.]]))

        loglist:addChild(uie.label("----------------------------------------------"))

        local task = sharp.ahornLaunch(config.ahorn.theme):result()

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
Ahorn has finished. No fatal errors were detected.
Press the close button in the bottom right corner to close this log.]]))
        end

        scene.logclose.enabled = true
    end)
end


local reloadRequested
function scene.reload()
    if scene.reloading then
        reloadRequested = true
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

        local info = sharp.ahornPrepare(config.ahorn.rootPath, config.ahorn.vhdPath, config.ahorn.vhdMountPath, config.ahorn.mode):result()
        scene.info = info
        status:removeSelf()

        local function btnRow(important, items)
            if not items then
                important, items = true, important
            end

            local itemcount = #items
            local row = uie.row(uiu.map(items, function(item, i)
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
                ):with((not important or i > 1) and {} or {
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

                return btn
            end)):with({
                style = {
                    bg = {},
                    padding = 0
                },
                clip = false,
                cacheable = false
            }):with(uiu.fillWidth)

            if important then
                row = row:with(utils.important(24))
            end

            return row
        end

        local function btnInstallJulia()
            local text, textBeta

            if love.system.getOS() == "Windows" then
                text = string.format("Install Julia %s from scratch", tostring(info.JuliaVersionRecommended))
                textBeta = string.format("Install Julia %s from scratch", tostring(info.JuliaVersionBetaRecommended))

            else
                text = string.format("Install Julia %s", tostring(info.JuliaVersionRecommended))
                textBeta = string.format("Install Julia %s", tostring(info.JuliaVersionBetaRecommended))
            end

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

        local function filecount(path)
            local count = 0
            for sub in fs.dir(info.VHDMountPath) do
                if sub ~= "." and sub ~= ".." then
                    count = count + 1
                end
            end
            return count
        end

        if config.ahorn.mode == "vhd" and not fs.isFile(info.VHDPath) then
            mainlist:addChild(uie.column({
                uie.label("Ahorn-VHD not found", ui.fontBig),
                uie.label(string.format([[
Olympus couldn't find Ahorn-VHD.

Ahorn-VHD is a virtual hard disk with everything needed to run Ahorn.
It comes with its own version of Julia and other files prebundled.

This will also download the latest version of Ahorn into the VHD.
Installing / updating Ahorn is a slow process and it will look as if it's hanging.
Don't close Olympus! Julia.exe might continue running in the background.

This might not work on too old computers.
If that's the case, or if you want to use your existing Ahorn install,
please change how Olympus manages Julia and Ahorn in the options panel.

Loading ("attaching" / "mounting") the virtual hard disk
might open a window asking for administrator permissions.

Ahorn-VHD will be downloaded to:
%s]],
                    tostring(info.VHDPath)
                )),
                btnRow({
                    { "download", "Download Ahorn-VHD", scene.sharpTaskScreenGen("ahornInstallAhornVHD") }
                })
            }):with(uiu.fillWidth))

        elseif config.ahorn.mode == "vhd" and filecount(info.VHDMountPath) < 1 then
            mainlist:addChild(uie.column({
                uie.label("Ahorn-VHD not loaded", ui.fontBig),
                uie.label(string.format([[
Olympus was able to find Ahorn-VHD at:
%s

Ahorn-VHD isn't loaded right now.
Loading ("attaching" / "mounting") the virtual hard disk
might open a window asking for administrator permissions.

Ahorn-VHD will be loaded to:
%s]],
                    tostring(info.VHDPath), tostring(info.VHDMountPath)
                )),
                btnRow({
                    { "disk_mount", "Load Ahorn-VHD", scene.sharpTaskScreenGen("ahornMountAhornVHD") }
                })
            }):with(uiu.fillWidth))

        else
            if config.ahorn.mode == "vhd" then
                mainlist:addChild(uie.column({
                    uie.label("Ahorn-VHD", ui.fontBig),
                    uie.label(string.format([[
Olympus was able to find Ahorn-VHD at:
%s]],
                        tostring(info.VHDPath)
                    )),
                    uie.label(string.format([[
Ahorn-VHD is loaded into:
%s]],
                        tostring(info.VHDMountPath)
                    )),
                    btnRow(false, {
                        { "disk_unmount", "Unload Ahorn-VHD", scene.sharpTaskScreenGen("ahornUnmountAhornVHD") }
                    })
                }):with(uiu.fillWidth))
            end

            if not info.JuliaPath then
                mainlist:addChild(uie.column({
                    uie.label("Julia not found", ui.fontBig),
                    uie.label([[
Ahorn uses the Julia programming language,
similar to how Minecraft uses the Java programming language.

You can install Julia system-wide yourself.
Version 1.3+ is the minimum requirement.

Olympus can manage a separate Julia installation for you.]]
                    ),
                    config.ahorn.mode ~= "vhd" and btnInstallJulia()
                }):with(uiu.fillWidth))

            elseif not info.JuliaVersion then
                mainlist:addChild(uie.column({
                    uie.label("Julia not recognized", ui.fontBig),
                    uie.label(string.format([[
Ahorn uses the Julia programming language,
similar to how Minecraft uses the Java programming language.

The currently installed version of Julia isn't working as expected.
Found installation path:
%s

Olympus can manage a separate Julia installation for you.
Version 1.3+ is the minimum requirement.]],
                        tostring(info.JuliaPath)
                    )),
                    not info.JuliaIsLocal and config.ahorn.mode ~= "vhd" and btnInstallJulia()
                }):with(uiu.fillWidth))

            else
                mainlist:addChild(uie.column({
                    uie.label("Julia", ui.fontBig),
                    uie.label(string.format([[
Ahorn uses the Julia programming language,
similar to how Minecraft uses the Java programming language.

Found installation path:
%s
Found version: %s]],
                        tostring(info.JuliaPath), tostring(info.JuliaVersion)
                    )),
                }):with(uiu.fillWidth))
            end

            if not info.AhornPath then
                mainlist:addChild(uie.column({
                    uie.label("Ahorn not found", ui.fontBig),
                    uie.label(string.format([[
Olympus can download Ahorn and start the installation process for you.
%s]],
                        (info.JuliaIsLocal or config.ahorn.mode ~= "system") and "Ahorn will be managed by Olympus." or "Ahorn will be installed system-wide."
                    )),
                    info.JuliaPath and btnRow({
                        { "download", "Install Ahorn", scene.installAhornAlert }
                    })
                }):with(uiu.fillWidth))

            else
                mainlist:addChild(uie.column({
                    uie.label("Ahorn", ui.fontBig),
                    uie.label(string.format([[
Found installation path:
%s
Found version: %s]],
                        tostring(info.AhornPath), tostring(info.AhornVersion)
                    )),
                    btnRow({
                        { "mainmenu/ahorn", "Launch Ahorn", scene.launchAhorn },
                        { "update", "Check for updates", scene.forceUpdateAhornAlert }
                    }):with(function(row)
                        local btn = row.children[2]
                        scene.latestGet:calls(function(thread, latest)
                            local installedHash, installedHashType = tostring(info.AhornVersion or ""):match("(.*) %((.*)%)")

                            if installedHashType == "git" then
                                latest = latest and latest.sha
                            elseif installedHashType == "pkg" then
                                latest = latest and latest.commit
                                latest = latest and latest.tree
                                latest = latest and latest.sha
                            else
                                latest = nil
                            end

                            if not installedHash or not latest then
                                return
                            end

                            if installedHash ~= latest then
                                btn.children[1].children[1].image = uiu.image("download")
                                btn.children[1].children[2].text = "Install updates"
                                btn.cb = function()
                                    scene.updateAhornAlert(installedHash, latest)
                                end
                                btn:with(utils.important(24))
                            end
                        end)
                    end)
                }):with(uiu.fillWidth))
            end
        end

        loading:removeSelf()
        scene.reloading = nil
        if reloadRequested then
            reloadRequested = false
            return scene.reload():result()
        end
    end)
    return scene.reloading
end


function scene.load()
    scene.latestGet = threader.routine(function()
        scene.latest = threader.wrap("utils").downloadJSON("https://api.github.com/repos/CelestialCartographers/Ahorn/commits/master"):result()
        return scene.latest
    end)
end


function scene.enter()
    scene.reload()
end


return scene
