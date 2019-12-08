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
            listManual:addChild(uie.label("Manual:"))
            listManual:findChild("manualTitle").text = "Manual:"
            for i = 1, #manual do
                local entry = manual[i]

                listManual:addChild(
                    uie.column({
                        uie.label(entry.name),
                        uie.label(entry.type),
                        uie.label(entry.path)
                    }):with(uiu.fillWidth)
                )
            end

        else
            listManual:addChild(uie.label("Your installations list is empty."))
        end

        listManual:addChild(uie.button("Browse", function()
            
        end))
    end)
end

function scene.reloadFound()
    return threader.routine(function()
        local finderAsync = threader.wrap("finder")

        local listMain = root:findChild("installs")

        local listFound = root:findChild("listFound")
        if listFound then
            listFound:removeSelf()
        end

        local found = finderAsync.findAll():result()

        if #found > 0 then
            listFound = uie.column({
                uie.label("Found:")
            }):with({
                style = {
                    bg = { 0.1, 0.1, 0.1, 0.6 },
                }
            }):with(uiu.fillWidth)

            listMain:addChild(listFound:as("listFound"))

            for i = 1, #found do
                local entry = found[i]

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
            end
        end

    end)
end

function scene.load()
    threader.routine(function()
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
