local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local threader = require("threader")
local scener = require("scener")
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
                padding = 0,
            }
        }):with(uiu.fillWidth):as("installs")
    ):with({
        clip = false,
        cacheable = false
    }):with(uiu.fillWidth):with(uiu.fillHeight(true)),

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

        local installs = config.installs or {}
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

        entry.name = string.format("Celeste #%d (%s)", #installs + 1, entry.type)
        installs[#installs + 1] = entry
        config.installs = installs
        config.save()
        scene.reloadAll()
    end)
end


function scene.createEntry(list, entry, manualIndex)
    return threader.routine(function()
        local version = sharp.getVersionString(entry.path):result() or ""

        local imgStatus, img
        imgStatus, img = pcall(uie.image, "store/" .. entry.type)
        if not imgStatus then
            imgStatus, img = pcall(uie.image, "store/manual")
        end

        local row = uie.row({
            (img and img:with({
                scale = 48 / 128
            }) or false),

            uie.column({
                manualIndex and uie.field(
                    entry.name,
                    function(value)
                        entry.name = value
                        config.save()
                    end
                ):with(uiu.fillWidth),
                uie.label(entry.path),
                uie.label({{1, 1, 1, 0.5}, version})
            }):with({
                style = {
                    bg = {},
                    padding = 0
                },

                clip = false,
                cacheable = false
            }):with(uiu.fillWidth(16, true)),

            uie.row({

                manualIndex and uie.button("↑", function()
                    local installs = config.installs
                    table.insert(installs, manualIndex - 1, table.remove(installs, manualIndex))
                    config.installs = installs
                    config.save()
                    scene.reloadAll()
                end):with({
                    enabled = manualIndex > 1
                }),

                manualIndex and uie.button("↓", function()
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
                        local installs = config.installs or {}
                        entry.name = string.format("Celeste #%d (%s)", #installs + 1, entry.type)
                        installs[#installs + 1] = entry
                        config.installs = installs
                        config.save()
                        scene.reloadAll()
                    end)
                )

            }):with({
                style = {
                    bg = {},
                    padding = 0
                },

                clip = false
            }):with(uiu.rightbound)

        }):with(uiu.fillWidth)

        list:addChild(row)
    end)
end


function scene.reloadManual()
    return threader.routine(function()
        local listMain = root:findChild("installs")

        local listManual = root:findChild("listManual")
        if listManual then
            listManual.children = {}
        else
            listManual = uie.column({
                uie.row({
                }):with({
                    style = {
                        bg = {},
                        padding = 0,
                    }
                }):with(uiu.fillWidth)
            }):with(uiu.fillWidth)

            listMain:addChild(listManual:as("listManual"))
        end

        local installs = config.installs or {}

        if #installs > 0 then
            listManual:addChild(uie.label("Your Installations:"))
            for i = 1, #installs do
                local entry = installs[i]
                scene.createEntry(listManual, entry, i):result()
            end

        else
            listManual:addChild(uie.label("Your installations list is empty."))
        end

        listManual:addChild(uie.button("Browse", scene.browse))
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

        local installs = config.installs or {}

        for i = 1, #found do
            local entry = found[i]

            for i = 1, #installs do
                if installs[i].path == entry.path then
                    goto next
                end
            end

            if not listFound then
                listFound = uie.column({
                    uie.label("Found:")
                }):with(uiu.fillWidth)

                listMain:addChild(listFound:as("listFound"))
            end

            scene.createEntry(listFound, entry, false):result()

            ::next::
        end

    end)
end


function scene.reloadAll()
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
    }):with(uiu.bottombound):with(uiu.rightbound):as("loadingInstalls")
    root:addChild(loading)

    local left = 2
    local function done()
        left = left - 1
        if left <= 0 then
            loading:removeSelf()
        end
    end

    scene.reloadManual():calls(done)
    scene.reloadFound():calls(done)
end


function scene.load()
    scene.reloadAll()
end


function scene.enter()

end


return scene
