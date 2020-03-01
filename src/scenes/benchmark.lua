local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local threader = require("threader")

local scene = {}


local root = uie.column({
    uie.image("header"),

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
    ):with(uiu.fillWidth):with(uiu.fillHeight(true)),

})
scene.root = root


function scene.load()

end


function scene.enter()

end


return scene
