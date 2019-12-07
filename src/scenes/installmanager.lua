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

    uie.row({
        uie.label("Loading"),
        uie.spinner():with({
            width = 16,
            height = 16
        })
    }):with({
        clip = false,
        cacheable = false
    }):with(uiu.bottombound):with(uiu.rightbound):as("loadingInstalls")

})
scene.root = root


function scene.load()
    threader.routine(function()
        local utilsAsync = threader.wrap("utils")
        local finderAsync = threader.wrap("celestefinder")

        local listMain = root:findChild("installs")

        local listManual = root:findChild("listManual")
        if listManual then
            listManual:removeSelf()
        end

        local listFound = root:findChild("listFound")
        if listFound then
            listFound:removeSelf()
        end


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

        listManual:addChild(uie.button("Browse"))


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
                        uie.column({
                            uie.label(entry.name),
                            uie.label(entry.type),
                            uie.label(entry.path)
                        }):with({
                            style = {
                                bg = {},
                                padding = 0,
                            }
                        }):with(uiu.fillWidth(-1, true)),

                        uie.column({
                            uie.button("Add"),
                            --uie.button("Remove")
                        }):with({
                            style = {
                                bg = {},
                                padding = 0,
                            }
                        }):with(uiu.rightbound)
                    }):with(uiu.fillWidth)
                )
            end
        end

        threader.await()
        threader.await()
        root:findChild("loadingInstalls"):removeSelf()
    end)

end


function scene.enter()

end


return scene
