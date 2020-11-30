local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local threader = require("threader")
local scener = require("scener")
local alert = require("alert")
local config = require("config")
local sharp = require("sharp")
local themer = require("themer")

local scene = {
    name = "Options"
}


local themes = {}
for i, file in ipairs(love.filesystem.getDirectoryItems("data/themes")) do
    local name = file:match("^(.+)%.json$")
    if name then
        local theme = utils.loadJSON("data/themes/" .. name .. ".json")
        themes[#themes + 1] = {
            text = theme.__name or tostring(theme),
            data = name
        }
    end
end


local root = uie.column({
    uie.scrollbox(
        uie.column({

            uie.column({
                uie.label("Options", ui.fontBig),

                uie.row({
                    uie.label("Theme"),
                    uie.dropdown(themes, function(self, value)
                        themer.apply(utils.loadJSON("data/themes/" .. value .. ".json"))
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
