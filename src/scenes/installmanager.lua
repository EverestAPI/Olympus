local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local threader = require("threader")
local fs = require("fs")
local config = require("config")

local scene = {}


local root = uie.column({
    uie.scrollbox(
        uie.column({
        }):with({
            style = {
                bg = {},
                padding = 0,
            }
        }):with(uiu.fillWidth):as("installs")
    ):with(uiu.fillWidth):with(uiu.fillHeight),

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

        installs[#installs + 1] = entry
        config.installs = installs

        scene.reloadAll():await()
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
            }):with({
                style = {
                    bg = { 0.1, 0.1, 0.1, 0.6 },
                }
            }):with(uiu.fillWidth)

            listMain:addChild(listManual:as("listManual"))
        end

        local installs = config.installs or {}

        if #installs > 0 then
            listManual:addChild(uie.label("Your Installations:"))
            for i = 1, #installs do
                local entry = installs[i]

                listManual:addChild(
                    uie.row({
                        uie.image("store/" .. entry.type):with({
                            scale = 48 / 128
                        }),

                        uie.label(entry.path):with({
                            y = 14
                        }),

                        uie.button("Remove", function()
                            table.remove(installs, i)
                            scene.reloadAll()
                        end):with({
                            y = 6
                        }):with(uiu.rightbound)
                    }):with(uiu.fillWidth)
                )
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

        local found = threader.wrap("finder").findAll():result()

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
                }):with({
                    style = {
                        bg = { 0.1, 0.1, 0.1, 0.6 },
                    }
                }):with(uiu.fillWidth)

                listMain:addChild(listFound:as("listFound"))
            end

            listFound:addChild(
                uie.row({
                    uie.image("store/" .. entry.type):with({
                        scale = 48 / 128
                    }),

                    uie.label(entry.path):with({
                        y = 14
                    }),

                    uie.button("Add", function()
                        local installs = config.installs or {}
                        installs[#installs + 1] = entry
                        config.installs = installs
                        scene.reloadAll()
                    end):with({
                        y = 6
                    }):with(uiu.rightbound)
                }):with(uiu.fillWidth)
            )

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

    return threader.routine(threader.await, {
        scene.reloadManual(),
        scene.reloadFound()
    }):calls(function()
        loading:removeSelf()
    end)
end


function scene.load()

end


function scene.enter()
    scene.reloadAll()
end


return scene
