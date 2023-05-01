local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local fs = require("fs")
local registry = require("registry")
local subprocess = require("subprocess")
local threader = require("threader")
local scener = require("scener")
local config = require("config")
local sharp = require("sharp")
local alert = require("alert")
local modupdater = require("modupdater")
local mainmenu = scener.preload("mainmenu")
require("love.system")

local scene = {
    name = "Everest Installer"
}


local root = uie.column({
    uie.row({

        mainmenu.createInstalls(),

        uie.paneled.column({
            uie.label("Versions", ui.fontBig),
            uie.panel({
                uie.label({{ 1, 1, 1, 1 },
[[Use the newest version for more features and bugfixes.
Use the latest ]], { 0.3, 0.8, 0.5, 1 }, "stable", { 1, 1, 1, 1 }, " or ", { 0.8, 0.7, 0.3, 1 }, "beta", { 1, 1, 1, 1 }, [[ version if you hate updating.]]}),
            }):with({
                style = {
                    patch = false
                }
            }):with(uiu.fillWidth),

            uie.column({

                uie.scrollbox(
                    uie.list({
                    }):with({
                        grow = false
                    }):with(uiu.fillWidth):with(function(list)
                        list.selected = list.children[1] or false
                    end):as("versions")
                ):with(uiu.fill),

                uie.paneled.row({
                    uie.label("Loading"),
                    uie.spinner():with({
                        width = 16,
                        height = 16
                    })
                }):with({
                    clip = false,
                    cacheable = false
                }):with(uiu.bottombound):with(uiu.rightbound):as("loadingVersions")

            }):with({
                clip = false
            }):with(uiu.fillWidth):with(uiu.fillHeight(true)):as("versionsParent")
        }):with(uiu.fillWidth(true)):with(uiu.fillHeight),

    }):with({
        clip = false
    }):with(uiu.fillWidth):with(uiu.fillHeight(true)),

    uie.row({
        uie.buttonGreen(uie.row({ uie.icon("download"):with({ scale = 21 / 256 }), uie.label("Install") }):with({
            clip = false,
            cacheable = false
        }):with(uiu.styleDeep), function()
            local install = scene.root:findChild("installs").selected
            install = install and install.data
            
            local version = scene.root:findChild("versions").selected
            version = version and version.data

            -- Check for any version before 1.4.0.0
            local minorVersion = install and install.versionCeleste and tonumber(install.versionCeleste:match("^1%.(%d+)%."))

            if install.versionCeleste == nil then
                -- getting the version of Celeste failed, and the "version" is the error message that is displayed in the installation list.
                local errorMessage = install.version
                if errorMessage:sub(1, 4) == "? - " then
                    errorMessage = errorMessage:sub(5)
                end
                alert({
                    body = string.format("Detecting the Celeste version failed:\n%s\n\nCheck the path of your install by selecting \"Manage\" in the main menu.", errorMessage),
                    buttons = {
                        { "Attempt Installation Anyway", function(container)
                            container:close("OK")
                            scene.install()
                        end },
                        { "Cancel", function(container)
                            container:close("OK")
                        end }
                    }
                })
            elseif minorVersion ~= nil and minorVersion < 4 then
                alert({
                    body = [[
Your current version of Celeste is outdated.
Please update to the latest version before installing Everest.]],
                    buttons = {
                        { "Attempt Installation Anyway", function(container)
                            container:close("OK")
                            scene.install()
                        end },
                        { "Cancel", function(container)
                            container:close("OK")
                        end }
                    }
                })
            elseif not install.versionEverest and fs.isFile(install.entry.path .. "/Celeste.dll") then
                alert({
                    body = [[
Residual files from a .NET Core build have been detected.
These files could cause the installation of older Everest versions to fail.
They should be removed before attempting to install Everest.
]],
                    buttons = {
                        { "Remove Residual Files", function(container)
                            container:close("OK")
                            scene.uninstall()
                        end },
                        { "Attempt Installation Anyway", function(container)
                            container:close("OK")
                            scene.install()
                        end },
                        { "Cancel", function(container)
                            container:close("OK")
                        end }
                    }
                })
            elseif love.system.getOS() == "Windows" and string.find(install.version, "xna") ~= nil and
            not (registry.getKey([[HKLM\SOFTWARE\WOW6432Node\Microsoft\XNA\Framework\v4.0\Installed]]) or
            registry.getKey([[HKLM\SOFTWARE\Microsoft\XNA\Framework\v4.0\Installed]])) then
                alert({
                    body = [[
It is required to install XNA before installing Everest.
If this copy of Celeste comes from Steam, run Celeste normally to install XNA.
Otherwise, manually install XNA using the button below.]],
                    buttons = {
                        { "Install XNA", function(container)
                            container:close("OK")
                            utils.openURL("https://www.microsoft.com/en-ca/download/details.aspx?id=20914")
                        end },
                        { "Attempt Installation Anyway", function(container)
                            container:close("OK")
                            scene.install()
                        end },
                        { "Cancel", function(container)
                            container:close("OK")
                        end }
                    }
                })
            elseif version ~= "manual" and version.branch == "core" then
                procFile, _ = io.popen("dotnet --list-runtimes")
                
                if procFile then
                    runtimeOutput = procFile:read("*all")
                    procFile:close()
                else
                    runtimeOutput = nil
                end

                if not (runtimeOutput and runtimeOutput:match("Microsoft.NETCore.App 7.")) then
                    alert({
                        body = [[
    It is required to install the .NET 7.0 Runtime before installing .NET Core versions of Everest.
    Click the button below to download the installer.
    Alternatively, you can manually install the runtime, then attempt the installation again.]],
                        buttons = {
                            { "Install Runtime", function(container)
                                container:close("OK")
                                if love.system.getOS() == "Windows" then
                                    arch = os.getenv("PROCESSOR_ARCHITEW6432") or os.getenv("PROCESSOR_ARCHITECTURE")
                                    if arch and arch:match("64") then
                                        utils.openURL("https://dotnet.microsoft.com/en-us/download/dotnet/thank-you/runtime-7.0.5-windows-x64-installer")
                                    else
                                        utils.openURL("https://dotnet.microsoft.com/en-us/download/dotnet/thank-you/runtime-7.0.5-windows-x86-installer")
                                    end
                                elseif love.system.getOS() == "Linux" then
                                    utils.openURL("https://learn.microsoft.com/en-us/dotnet/core/install/linux?WT.mc_id=dotnet-35129-website")
                                elseif love.system.getOS() == "OS X" then
                                    utils.openURL("https://dotnet.microsoft.com/en-us/download/dotnet/thank-you/runtime-7.0.5-macos-x64-installer")
                                else
                                    utils.openURL("https://dotnet.microsoft.com/en-us/download/dotnet/7.0")
                                end
                            end },
                            { "Attempt Installation Anyway", function(container)
                                container:close("OK")
                                scene.install()
                            end },
                            { "Cancel", function(container)
                                container:close("OK")
                            end }
                        }
                    })
                else
                    scene.install()
                end
            else
                scene.install()
            end
        end):hook({
            update = function(orig, self, ...)
                local root = scene.root
                local selected = root:findChild("installs").selected
                selected = selected and selected.data
                selected = selected and selected.version
                self.enabled = selected and root:findChild("versions").selected
                self.text = (selected and selected:match("%+")) and "Update" or "Install"
                orig(self, ...)
            end
        }):with({
            clip = false,
            cacheable = false
        }):with(uiu.fillWidth(true)):with(utils.important(24, function(self) return self.parent.enabled end)):as("install"),

        uie.button("Uninstall", function()
            alert({
                force = true,
                body = [[
Uninstalling Everest will keep all your mods intact,
unless you manually delete them, fully reinstall Celeste,
or load into a modded save file in vanilla Celeste.

Holding right on the title screen lets you turn off Everest
until you start up the game again, which is "speedrun-legal" too.

If even uninstalling Everest doesn't bring the expected result,
please go to your game manager's library and let it verify the game's files.
Steam, EGS and the itch.io app let you do that without a full reinstall.]],
                buttons = {
                    { "Uninstall anyway", function(container)
                        scene.uninstall()
                        container:close("OK")
                    end },
                    { "Keep Everest" }
                }
            })
        end):hook({
            update = function(orig, self, ...)
                local root = scene.root
                local selected = root:findChild("installs").selected
                selected = selected and selected.data
                selected = selected and selected.version
                selected = selected and selected:match("%+")
                self.enabled = selected
                orig(self, ...)
            end
        }):with(uiu.rightbound):as("uninstall")
    }):with({
        clip = false
    }):with(uiu.fillWidth):with(uiu.bottombound)

})
scene.root = root


function scene.install()
    if scene.installing then
        return scene.installing
    end

    scene.installing = threader.routine(function()
        local install = root:findChild("installs").selected
        install = install and install.data

        local version = root:findChild("versions").selected
        version = version and version.data

        if not install or not version then
            scene.installing = nil
            return
        end

        local installer = scener.push("installer")
        installer.onLeave = function()
            scene.installing = nil
        end

        local mainDownload, olympusMetaDownload, olympusBuildDownload
        if version == "manual" then
            installer.update("Select your Everest .zip file", false, "")

            local path = fs.openDialog("zip"):result()
            if not path then
                installer.update("Installation canceled", 1, "error")
                installer.done(false, {
                    {
                        "Retry",
                        function()
                            scener.pop()
                            scene.install()
                        end
                    },
                    {
                        "OK",
                        function()
                            scener.pop()
                        end
                    }
                })
                return
            end

            mainDownload = ""
            olympusMetaDownload = ""
            olympusBuildDownload = "file://" .. path

        else
            installer.update(string.format("Preparing installation of Everest %s", version.version), false, "")
            mainDownload = version.mainDownload
            olympusMetaDownload = version.olympusMetaDownload
            olympusBuildDownload = version.olympusBuildDownload
        end

        installer.sharpTask("installEverest", install.entry.path, mainDownload, olympusMetaDownload, olympusBuildDownload):calls(function(task, last)
            if not last then
                return
            end

            if version == "manual" then
                installer.update("Everest successfully installed", 1, "done")
            else
                installer.update(string.format("Everest %s successfully installed", version.version), 1, "done")
            end
            installer.done({
                {
                    "Launch",
                    function()
                        modupdater.updateAllModsThenRunGame(install.entry.path)
                        scener.pop(2)
                    end
                },
                {
                    "OK",
                    function()
                        scener.pop(2)
                    end
                }
            })
        end)

    end)
    return scene.installing
end


function scene.uninstall()
    local install = root:findChild("installs").selected
    install = install and install.data

    if not install then
        return
    end

    local installer = scener.push("installer")
    installer.update("Preparing uninstallation of Everest", false, "backup")

    installer.sharpTask("uninstallEverest", install.entry.path):calls(function(task, last)
        if not last then
            return
        end

        installer.update("Everest successfully uninstalled", 1, "done")
        installer.done({
            {
                "Launch",
                function()
                    sharp.launch(install.entry.path)
                    scener.pop(2)
                end
            },
            {
                "OK",
                function()
                    scener.pop(2)
                end
            }
        })
    end)

end


function scene.load()

    threader.routine(function()
        local utilsAsync = threader.wrap("utils")
        local buildsTask = utilsAsync.download("https://everestapi.github.io/everestupdater.txt")
        local url, buildsError = buildsTask:result()

        if url then
            url = utils.trim(url)
            if string.match(url, "?") then url = url .. "&" else url = url .. "?" end
            url = url .. "supportsNativeBuilds=true"

            buildsTask = utilsAsync.downloadJSON(url)
        end

        local list = root:findChild("versions")

        local manualItem = uie.listItem("Select .zip from disk", "manual"):with(uiu.fillWidth)

        local builds, buildsError = buildsTask:result()
        if not builds then
            root:findChild("loadingVersions"):removeSelf()
            root:findChild("versionsParent"):addChild(uie.paneled.row({
                uie.label("Error downloading builds list: " .. tostring(buildsError)),
            }):with({
                clip = false,
                cacheable = false
            }):with(uiu.bottombound):with(uiu.rightbound):as("error"))
            list:addChild(manualItem)
            return
        end

        local firstStable, firstBeta
        local pinSpacer

        for bi = 1, #builds do
            local build = builds[bi]

            local versionNumber = tostring(build.version)

            local branch = build.branch
            if branch ~= "dev" then
                versionNumber = versionNumber .. " (" .. branch .. ")"
            end

            local info = " ∙ " .. os.date("%Y-%m-%d %H:%M:%S", utils.dateToTimestamp(build.date))

            if build.author then
                info = info .. " ∙ " .. build.author
            end

            if build.description then
                info = info .. "\n" .. build.description
            end

            if #info ~= 0 then
                text = { { 1, 1, 1, 1 }, versionNumber, { 1, 1, 1, 0.5 }, info }
            end

            local pin = false

            ::readd::

            local item = uie[branch == "stable" and "listItemGreen" or branch == "beta" and "listItemYellow" or "listItem"](text, build):with(uiu.fillWidth)
            item.label.wrap = true

            local index = nil

            if branch == "stable" then
                if not firstStable then
                    firstStable = item
                    if firstBeta then
                        index = 2
                    else
                        index = 1
                    end
                end

            elseif branch == "beta" then
                if not firstBeta then
                    firstBeta = item
                    if firstStable then
                        index = 2
                    else
                        index = 1
                    end
                end
            end

            if index then
                if not pinSpacer then
                    pinSpacer = true
                    list:addChild(uie.row({
                        uie.label("Newest")
                    }):with({
                        style = {
                            padding = 4
                        }
                    }), 1)
                    list:addChild(uie.row({
                        uie.icon("pin"):with({
                            scale = 16 / 256,
                            y = 2
                        }),
                        uie.label("Pinned")
                    }):with({
                        style = {
                            padding = 4
                        }
                    }), 1)
                end

                index = index + 1
                pin = true
            end

            if pin then
                item:addChild(uie.icon("pin"):with({
                    scale = 16 / 256,
                    y = 2
                }), 1)
            end

            list:addChild(item, index)
            if index then
                goto readd
            end
        end

        root:findChild("loadingVersions"):removeSelf()
        list:addChild(manualItem)
    end)

end


function scene.enter()
    mainmenu.reloadInstalls(scene)
end


return scene
