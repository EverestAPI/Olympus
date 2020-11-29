local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local threader = require("threader")
local scener = require("scener")
local alert = require("alert")
local config = require("config")
local sharp = require("sharp")

local scene = {
    name = "Options"
}


local root = uie.column({
    uie.scrollbox(
        uie.column({

            uie.column({
                uie.label("Options", ui.fontBig),

                uie.row({
                    uie.label("Theme"),
                    uie.dropdown({
                        "Dark (Default)",
                        "Light"
                    }, function(self, value)
                        -- TODO
                    end):with(uiu.rightbound)
                }):with(uiu.fillWidth)

            }):with(uiu.fillWidth)

        }):with({
            style = {
                bg = {},
                padding = 0,
            }
        }):with(uiu.fillWidth):as("categories")
    ):with({
        clip = false,
        cacheable = false
    }):with(uiu.fillWidth):with(uiu.fillHeight(true))
})
scene.root = root


function scene.load()

end


function scene.enter()

end


return scene
