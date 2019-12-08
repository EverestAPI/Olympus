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
            type = "exe,/"

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

        local installs = config.installs or {}

        for i = 1, #installs do
            if installs[i].path == path then
                return
            end
        end

        installs[#installs + 1] = {
            type = "manual",
            path = path
        }
        config.installs = installs

        scene.load():await()
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

        local manual = config.installs or {}

        if #manual > 0 then
            listManual:addChild(uie.label("Your Installations:"))
            for i = 1, #manual do
                local entry = manual[i]

                listManual:addChild(
                    uie.row({
                        uie.image("store/" .. entry.type):with({
                            scale = 48 / 128
                        }),

                        uie.label(entry.path):with({
                            y = 14
                        }),

                        uie.button("Uhh"):with({
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
        local finderAsync = threader.wrap("finder")

        local listMain = root:findChild("installs")

        local listFound = root:findChild("listFound")
        if listFound then
            listFound:removeSelf()
            listFound = nil
        end

        local found = finderAsync.findAll():result()

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

            fs.normalize(entry.path)

            listFound:addChild(
                uie.row({
                    uie.image("store/" .. entry.type):with({
                        scale = 48 / 128
                    }),

                    uie.label(entry.path):with({
                        y = 14
                    }),

                    uie.button("Add"):with({
                        y = 6
                    }):with(uiu.rightbound)
                }):with(uiu.fillWidth)
            )

            ::next::
        end

    end)
end


function scene.load()
    return threader.routine(function()
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

        threader.await({
            scene.reloadManual(),
            scene.reloadFound()
        })

        loading:removeSelf()
    end)

end


function scene.enter()

end


return scene
