local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local threader = require("threader")

local scene = {}


local root = uie.column({
    uie.image("header"),

    uie.row({

        uie.scrollbox(
            uie.list(
                uiu.map(uiu.listRange(2000, 1, -1), function(i)
                    return { text = string.format("%i%s", i, i % 7 == 0 and " (something)" or ""), data = i }
                end)
            ):with({
                grow = false
            }):with(uiu.fillWidth):with(function(list)
                list.selected = list.children[1]
            end):as("versions")
        ):with(uiu.fillWidth(4.25)):with(uiu.fillHeight),

        uie.scrollbox(
            uie.list(
                uiu.map(uiu.listRange(2000, 1, -1), function(i)
                    return { text = string.format("%i%s", i, i % 7 == 0 and " (something)" or ""), data = i }
                end)
            ):with({
                grow = false
            }):with(uiu.fillWidth):with(function(list)
                list.selected = list.children[1]
            end):as("versions")
        ):with(uiu.fillWidth(4.25)):with(uiu.fillHeight):with(uiu.at(0.25 + 8)),

        uie.scrollbox(
            uie.list(
                uiu.map(uiu.listRange(2000, 1, -1), function(i)
                    return { text = string.format("%i%s", i, i % 7 == 0 and " (something)" or ""), data = i }
                end)
            ):with({
                grow = false
            }):with(uiu.fillWidth):with(function(list)
                list.selected = list.children[1]
            end):as("versions")
        ):with(uiu.fillWidth(4.25)):with(uiu.fillHeight):with(uiu.at(0.5 + 8)),

        uie.scrollbox(
            uie.list(
                uiu.map(uiu.listRange(2000, 1, -1), function(i)
                    return { text = string.format("%i%s", i, i % 7 == 0 and " (something)" or ""), data = i }
                end)
            ):with({
                grow = false
            }):with(uiu.fillWidth):with(function(list)
                list.selected = list.children[1]
            end):as("versions")
        ):with(uiu.fillWidth(0.25)):with(uiu.fillHeight):with(uiu.at(0.75 + 8)),

    }):with(uiu.fillWidth):with(uiu.fillHeight(true)),

})
scene.root = root


function scene.load()

end


function scene.enter()

end


return scene
