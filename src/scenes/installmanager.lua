local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local threader = require("threader")
local scener = require("scener")
local alert = require("alert")
local fs = require("fs")
local config = require("config")
local sharp = require("sharp")

local scene = {
    name = "Install Manager"
}


local root = uie.column({

    uie.scrollbox(
        uie.column({
        }):with({
            style = {
                bg = {},
                padding = 16,
            }
        }):with(uiu.fillWidth):as("installs")
    ):with({
        style = {
            barPadding = 16,
        },
        clip = false,
        cacheable = false
    }):with(uiu.fillWidth):with(uiu.fillHeight(true)),

}):with({
    cacheable = false,
    _fullroot = true
})
scene.root = root


function scene.browse()
    return threader.routine(function()
        local type = nil
        local userOS = love.system.getOS()

        if userOS == "Windows" then
            type = "exe"

        elseif userOS == "Linux" then
            type = "exe,bin.x86,bin.x86_64"

        elseif userOS == "OS X" then
            type = "app,exe,bin.osx"
        end

        local path = fs.openDialog(type):result()
        if not path then
            return
        end

        path = require("finder").fixRoot(fs.dirname(path))
        if not path then
            return
        end

        local foundT = threader.wrap("finder").findAll()

        local installs = config.installs
        for i = 1, #installs do
            if installs[i].path == path then
                return
            end
        end

        local entry = {
            type = "manual",
            path = path
        }

        local found = foundT:result()
        for i = 1, #found do
            if found[i].path == path then
                entry = found[i]
                break
            end
        end

        entry.name = string.format("%s (#%d)", entry.type, #installs + 1)
        installs[#installs + 1] = entry
        config.installs = installs
        config.save()
        scene.reloadAll()
    end)
end


function scene.createEntry(list, entry, manualIndex)
    local labelVersion = uie.label({{1, 1, 1, 0.5}, "Scanning..."})
    sharp.getVersionString(entry.path):calls(function(t, version)
        labelVersion.text = {{1, 1, 1, 0.5}, version or "???"}
    end)

    local imgStatus, img
    imgStatus, img = pcall(uie.icon, "store/" .. entry.type)
    if not imgStatus then
        imgStatus, img = pcall(uie.icon, "store/manual")
    end

    local row = uie.row({
        (img and img:with({
            scale = 48 / 128
        }) or false),

        uie.column({
            manualIndex and uie.field(
                entry.name,
                function(self, value)
                    entry.name = value
                    config.save()
                end
            ):with(uiu.fillWidth),
            uie.label(entry.path),
            labelVersion
        }):with({
            style = {
                bg = {},
                padding = 0
            },

            clip = false,
            cacheable = false
        }):with(uiu.fillWidth(8, true)),

        uie.column({

            uie.row({

                manualIndex and uie.button(uie.icon("up"), function()
                    local installs = config.installs
                    table.insert(installs, manualIndex - 1, table.remove(installs, manualIndex))
                    config.installs = installs
                    config.save()
                    scene.reloadAll()
                end):with({
                    enabled = manualIndex > 1
                }),

                manualIndex and uie.button(uie.icon("down"), function()
                    local installs = config.installs
                    table.insert(installs, manualIndex + 1, table.remove(installs, manualIndex))
                    config.installs = installs
                    config.save()
                    scene.reloadAll()
                end):with({
                    enabled = manualIndex < #config.installs
                }),

                entry.type ~= "debug" and (
                    manualIndex and
                    uie.button("Remove", function()
                        local installs = config.installs
                        table.remove(installs, manualIndex)
                        config.installs = installs
                        config.save()
                        scene.reloadAll()
                    end)

                    or
                    uie.button("Add", function()
                        local function add()
                            local installs = config.installs
                            entry.name = string.format("%s (#%d)", entry.type, #installs + 1)
                            installs[#installs + 1] = entry
                            config.installs = installs
                            config.save()
                            scene.reloadAll()
                        end

                        if entry.type == "uwp" then
                            alert({
                                force = true,
                                body = [[
The UWP version of Celeste is currently unsupported.
All game data is encrypted, even dialog text files are uneditable.
The game code itself is AOT-compiled - no existing code mods would work.
Even Ahorn currently can't load the necessary game data either.

Unless Everest gets rewritten or someone starts working on
a mod loader just for this special version, don't expect
anything to work in the near future, if at all.]],
                                buttons = {
                                    { "OK", function(container)
                                        if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
                                            add()
                                        end
                                        container:close("OK")
                                    end }
                                },
                                init = function(container)
                                    container:findChild("buttons").children[1]:hook({
                                        update = function(orig, self, dt)
                                            orig(self, dt)
                                            if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
                                                self.text = "I know what I'm doing."
                                            else
                                                self.text = "OK"
                                            end
                                        end
                                    })
                                end
                            })

                        else
                            add()
                        end
                    end):with(utils.important(24, function() return #config.installs == 0 end))
                )

            }):with({
                style = {
                    bg = {},
                    padding = 0
                },
                clip = false
            }):with(uiu.rightbound),

            uie.row({

                entry.type == "steam" and uie.button("Verify", function()
                    alert({
                        force = true,
                        body = [[
Verifying the file integrity will tell Steam to redownload
any modified files, uninstalling Everest in the process.

Don't use Olympus while Steam is downloading game files.
You will need to check the download progress yourself.

Do you want to continue?]],
                        buttons = {
                            {
                                "Yes",
                                function(container)
                                    utils.openURL("steam://validate/504230")
                                    container:close("yes")
                                end
                            },

                            { "No" },
                        }
                    })
                end),

                uie.button("Open", function()
                    utils.openFile(entry.path)
                end),

            }):with({
                style = {
                    bg = {},
                    padding = 0
                },
                clip = false
            }):with(uiu.rightbound)

        }):with({
            style = {
                bg = {},
                padding = 0
            },
            clip = false,
            cacheable = false
        }):with(uiu.rightbound)

    }):with(uiu.fillWidth)

    list:addChild(row)
end


function scene.reloadManual()
    return threader.routine(function()
        local listMain = root:findChild("installs")

        local listManual = root:findChild("listManual")
        if listManual then
            listManual.children = {}
        else
            listManual = uie.column({}):with(uiu.fillWidth)

            listMain:addChild(listManual:as("listManual"))
        end

        listManual:addChild(uie.label("Your Installations", ui.fontBig))
        threader.await()

        local installs = config.installs

        if #installs > 0 then
            for i = 1, #installs do
                local entry = installs[i]
                scene.createEntry(listManual, entry, i)
                threader.await()
            end

        else
            local info = uie.label([[
Olympus needs to know which Celeste installations you want to manage.
Automatically found installations will be listed below and can be added to this list.
Manually select Celeste.exe if no installations have been found automatically.]])
            listManual:addChild(info)

            local function handleFound(task, all)
                if #all > 0 then
                    info.text = [[
Olympus needs to know which Celeste installations you want to manage.
You can add automatically found installations from the list below to this one.
]]
                else
                    info.text = [[
Olympus needs to know which Celeste installations you want to manage.
No installations were found automatically. Manually select Celeste.exe to add it to Olympus.
]]
                end
            end

            local foundCached = require("finder").getCached()
            if foundCached then
                handleFound(nil, foundCached)
            else
                threader.wrap("finder").findAll():calls(handleFound)
            end
        end

        listManual:addChild(uie.button("Manually select Celeste.exe", scene.browse):with(utils.important(24, function() return #config.installs == 0 end)))
    end)
end


function scene.reloadFound()
    return threader.routine(function()
        local listMain = root:findChild("installs")

        local listFound = root:findChild("listFound")
        if listFound then
            listFound:removeSelf()
            listFound = nil
        end

        local found = threader.wrap("finder").findAll():result() or {}

        local installs = config.installs

        for i = 1, #found do
            local entry = found[i]

            for i = 1, #installs do
                if installs[i].path == entry.path then
                    goto next
                end
            end

            if not listFound then
                listFound = uie.column({
                    uie.label("Found", ui.fontBig)
                }):with(uiu.fillWidth)

                listMain:addChild(listFound:as("listFound"))
                threader.await()
            end

            scene.createEntry(listFound, entry, false)
            threader.await()

            ::next::
        end

    end)
end

local reloading = 0

function scene.reloadAll()
    if reloading > 0 then
        return
    end

    local loading = root:findChild("loading")
    if loading then
        loading:removeSelf()
    end

    loading = uie.row({
        uie.label("Loading"),
        uie.spinner():with({
            width = 16,
            height = 16
        })
    }):with({
        clip = false,
        cacheable = false
    }):with(uiu.bottombound(16)):with(uiu.rightbound(16)):as("loadingInstalls")
    root:addChild(loading)

    reloading = 2
    local function done()
        reloading = reloading - 1
        if reloading <= 0 then
            loading:removeSelf()
        end
    end

    local installs = root:findChild("installs")
    installs.children = {}

    scene.reloadManual():calls(done)
    scene.reloadFound():calls(done)
end


function scene.load()
    scene.reloadAll()
end


function scene.enter()

end


return scene
