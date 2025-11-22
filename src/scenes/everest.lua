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
local lang = require("lang")
require("love.system")

local scene = {
    name = lang.get("everest_installer")
}


local root = uie.column({
    uie.row({

        mainmenu.createInstalls(),

        uie.paneled.column({
            uie.row({
                uie.label(lang.get("versions"), ui.fontBig),
                uie.button(lang.get("reload_versions_list"), function()
                    local list = scene.root:findChild("versions")
                    list.children = {}
                    list:reflow()
                    scene.load()
                end):with(uiu.rightbound):as("reloadVersionsList"),
            }):with(uiu.fillWidth):as("titlebar"),
            uie.panel({
                uie.label({{ 1, 1, 1, 1 },
lang.get("use_the_newest_version_for_more_features"), { 0.3, 0.8, 0.5, 1 }, "stable", { 1, 1, 1, 1 }, lang.get("or_"), { 0.8, 0.7, 0.3, 1 }, "beta", { 1, 1, 1, 1 }, lang.get("version_if_you_hate_updating")}),
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
            }):with({
                clip = false
            }):with(uiu.fillWidth):with(uiu.fillHeight(true)):as("versionsParent")
        }):with(uiu.fillWidth(true)):with(uiu.fillHeight),

    }):with({
        clip = false
    }):with(uiu.fillWidth):with(uiu.fillHeight(true)),

    uie.row({
        uie.buttonGreen(uie.row({ uie.icon("download"):with({ scale = 21 / 256 }), uie.label(lang.get("install")) }):with({
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
                        { lang.get("attempt_installation_anyway"), function(container)
                            container:close(lang.get("ok"))
                            scene.install()
                        end },
                        { lang.get("cancel"), function(container)
                            container:close(lang.get("ok"))
                        end }
                    }
                })
            elseif minorVersion ~= nil and minorVersion < 4 then
                alert({
                    body = lang.get("your_current_version_of_celeste_is_outda"),
                    buttons = {
                        { lang.get("attempt_installation_anyway"), function(container)
                            container:close(lang.get("ok"))
                            scene.install()
                        end },
                        { lang.get("cancel"), function(container)
                            container:close(lang.get("ok"))
                        end }
                    }
                })
            elseif not install.versionEverest and fs.isFile(install.entry.path .. "/Celeste.dll") then
                alert({
                    body = lang.get("residual_files_from_a_net_core_build_hav"),
                    buttons = {
                        { lang.get("remove_residual_files"), function(container)
                            container:close(lang.get("ok"))
                            scene.uninstall()
                        end },
                        { lang.get("attempt_installation_anyway"), function(container)
                            container:close(lang.get("ok"))
                            scene.install()
                        end },
                        { lang.get("cancel"), function(container)
                            container:close(lang.get("ok"))
                        end }
                    }
                })
            elseif love.system.getOS() == "Windows" and string.find(install.version, "xna") ~= nil and
            not (registry.getKey([[HKLM\SOFTWARE\WOW6432Node\Microsoft\XNA\Framework\v4.0\Installed]]) or
            registry.getKey([[HKLM\SOFTWARE\Microsoft\XNA\Framework\v4.0\Installed]])) then
                alert({
                    body = lang.get("it_is_required_to_install_xna_before_ins"),
                    buttons = {
                        { lang.get("install_xna"), function(container)
                            container:close(lang.get("ok"))
                            utils.openURL("https://www.microsoft.com/en-ca/download/details.aspx?id=20914")
                        end },
                        { lang.get("attempt_installation_anyway"), function(container)
                            container:close(lang.get("ok"))
                            scene.install()
                        end },
                        { lang.get("cancel"), function(container)
                            container:close(lang.get("ok"))
                        end }
                    }
                })

            -- Build 4415 is the first one to use Piton, so a runtime check isn't required anymore
            elseif version ~= "manual" and version.isNative and version.build and version.build < 4415 then
                procFile, _ = io.popen("dotnet --list-runtimes")

                if not procFile then
                    -- Fallback to the default installation path
                    local dotnetPath = nil
                    if love.system.getOS() == "Windows" then
                        arch = os.getenv("PROCESSOR_ARCHITEW6432") or os.getenv("PROCESSOR_ARCHITECTURE")
                        if arch and arch:match("64") then
                            dotnetPath = os.getenv("ProgramFiles") .. "\\dotnet"
                        else
                            dotnetPath = os.getenv("ProgramFiles(x86)") .. "\\dotnet"
                        end
                    elseif love.system.getOS() == "Linux" then
                        dotnetPath = "/usr/share/dotnet"
                    elseif love.system.getOS() == "OS X" then
                        dotnetPath = "/usr/local/share/dotnet"
                    end
                    procFile, _ = io.popen(dotnetPath .. fs.dirSeparator .. "dotnet --list-runtimes")
                end

                if procFile then
                    runtimeOutput = procFile:read("*all")
                    procFile:close()
                else
                    runtimeOutput = nil
                end

                if not (runtimeOutput and runtimeOutput:match("Microsoft.NETCore.App 7.")) then
                    alert({
                        body = lang.get("it_is_required_to_install_the_net_7_0_ru"),
                        buttons = {
                            { lang.get("install_runtime"), function(container)
                                container:close(lang.get("ok"))
                                if love.system.getOS() == "Windows" then
                                    arch = os.getenv("PROCESSOR_ARCHITEW6432") or os.getenv("PROCESSOR_ARCHITECTURE")
                                    if arch and arch:match("64") then
                                        utils.openURL("https://dotnet.microsoft.com/en-us/download/dotnet/thank-you/runtime-7.0.9-windows-x64-installer")
                                    else
                                        utils.openURL("https://dotnet.microsoft.com/en-us/download/dotnet/thank-you/runtime-7.0.9-windows-x86-installer")
                                    end
                                elseif love.system.getOS() == "Linux" then
                                    utils.openURL("https://learn.microsoft.com/en-us/dotnet/core/install/linux?WT.mc_id=dotnet-35129-website")
                                elseif love.system.getOS() == "OS X" then
                                    utils.openURL("https://dotnet.microsoft.com/en-us/download/dotnet/thank-you/runtime-7.0.9-macos-x64-installer")
                                else
                                    utils.openURL("https://dotnet.microsoft.com/en-us/download/dotnet/7.0")
                                end
                            end },
                            { "Attempt Installation Anyway", function(container)
                                container:close(lang.get("ok"))
                                scene.install()
                            end },
                            { lang.get("cancel"), function(container)
                                container:close(lang.get("ok"))
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
                self.text = (selected and selected:match("%+")) and lang.get("update") or lang.get("install")
                orig(self, ...)
            end
        }):with({
            clip = false,
            cacheable = false
        }):with(uiu.fillWidth(true)):with(utils.important(24, function(self) return self.parent.enabled end)):as("install"),

        uie.button(lang.get("uninstall"), function()
            alert({
                force = true,
                body = lang.get("uninstall_dialog"),
                buttons = {
                    { lang.get("uninstall_anyway"), function(container)
                        scene.uninstall()
                        container:close(lang.get("ok"))
                    end },
                    { lang.get("keep_everest") }
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
            installer.update(lang.get("select_your_everest_zip_file"), false, "")

            local path = fs.openDialog("zip"):result()
            if not path then
                installer.update(lang.get("installation_canceled"), 1, "error")
                installer.done(false, {
                    {
                        lang.get("retry"),
                        function()
                            scener.pop()
                            scene.install()
                        end
                    },
                    {
                        lang.get("ok"),
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
            installer.update(string.format(lang.get("preparing_installation_of_everest_s"), version.version), false, "")
            mainDownload = version.mainDownload
            olympusMetaDownload = version.olympusMetaDownload
            olympusBuildDownload = version.olympusBuildDownload
        end

        installer.sharpTask("installEverest", install.entry.path, mainDownload, olympusMetaDownload, olympusBuildDownload):calls(function(task, last)
            if not last then
                return
            end

            if version == "manual" then
                installer.update(lang.get("everest_successfully_installed"), 1, "done")
            else
                installer.update(string.format(lang.get("everest_s_successfully_installed"), version.version), 1, "done")
            end
            installer.done({
                {
                    lang.get("launch"),
                    function()
                        modupdater.updateAllMods(install.entry.path)
                        scener.pop(2)
                    end
                },
                {
                    lang.get("ok"),
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
    installer.update(lang.get("preparing_uninstallation_of_everest"), false, "backup")

    installer.sharpTask("uninstallEverest", install.entry.path):calls(function(task, last)
        if not last then
            return
        end

        installer.update(lang.get("everest_successfully_uninstalled"), 1, "done")
        installer.done({
            {
                lang.get("launch"),
                function()
                    sharp.launch(install.entry.path)
                    scener.pop(2)
                end
            },
            {
                lang.get("ok"),
                function()
                    scener.pop(2)
                end
            }
        })
    end)

end


function scene.load()

    threader.routine(function()
        -- remove the displayed error if we are retrying after the versions list loading failed
        local previousError = root:findChild("error")
        if previousError then
            previousError:removeSelf()
        end

        root:findChild("reloadVersionsList").enabled = false

        -- display a lang.get("loading") spinner
        root:findChild("versionsParent"):addChild(
            uie.paneled.row({
                uie.label(lang.get("loading")),
                uie.spinner():with({
                    width = 16,
                    height = 16
                })
            }):with({
                clip = false,
                cacheable = false
            }):with(uiu.bottombound):with(uiu.rightbound):as("loadingVersions")
        )

        local buildsTask = threader.wrap("utils").downloadJSON(
            config.apiMirror
            and "https://everestapi.github.io/updatermirror/everest_versions.json"
            or "https://maddie480.ovh/celeste/everest-versions"
        )

        local list = root:findChild("versions")

        local manualItem = uie.listItem(lang.get("select_zip_from_disk"), "manual"):with(uiu.fillWidth)

        local builds, buildsError = buildsTask:result()
        if not builds then
            root:findChild("loadingVersions"):removeSelf()
            root:findChild("versionsParent"):addChild(uie.paneled.row({
                uie.label(lang.get("error_downloading_builds_list") .. tostring(buildsError)),
            }):with({
                clip = false,
                cacheable = false
            }):with(uiu.bottombound):with(uiu.rightbound):as("error"))
            list:addChild(manualItem)
            root:findChild("reloadVersionsList").enabled = true
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

            local info = " ∙ " .. (build.isNative and "core" or "legacy") .. " ∙ " .. os.date("%Y-%m-%d %H:%M:%S", utils.dateToTimestamp(build.date))

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
                        uie.label(lang.get("newest"))
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
                        uie.label(lang.get("pinned"))
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

        root:findChild("reloadVersionsList").enabled = true
    end)

end


function scene.enter()
    mainmenu.reloadInstalls(scene)
end


return scene