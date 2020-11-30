local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local threader = require("threader")
local scener = require("scener")
local alert = require("alert")
local config = require("config")
local sharp = require("sharp")
local themer = require("themer")
local background = require("background")

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


local bgs = {
    { text = "Random (Default)", data = 0 }
}
for i = 1, #background.bgs do
    bgs[i + 1] = { text = "Background #" .. i, data = i }
end


local root = uie.column({
    uie.scrollbox(
        uie.column({

            uie.column({
                uie.label("Options", ui.fontBig),

                uie.row({

                    uie.column({
                        uie.label("Theme"),
                        uie.dropdown(themes, function(self, value)
                            themer.apply((value == "default" or not value) and themer.default or utils.loadJSON("data/themes/" .. value .. ".json"))
                            config.theme = value
                            config.save()
                        end):with(function(self)
                            for i = 1, #themes do
                                if config.theme == themes[i].data then
                                    self.selected = self:getItem(i)
                                    self.text = self.selected.text
                                    break
                                end
                            end
                        end)
                    }):with(uiu.fillWidth(4.5)),

                    uie.column({
                        uie.label("Background"),
                        uie.dropdown(bgs, function(self, value)
                            config.bg = value
                            config.save()
                            background.refresh()
                        end):with(function(self)
                            self.selected = self:getItem(config.bg + 1)
                            self.text = self.selected.text
                        end)
                    }):with(uiu.fillWidth(4.5)):with(uiu.at(4.5, 0))

                }):with({
                    style = {
                        bg = {},
                        padding = 0,
                        radius = 0
                    },
                    clip = false,
                    cacheable = false
                }):with(uiu.fillWidth),

                uie.row({

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
