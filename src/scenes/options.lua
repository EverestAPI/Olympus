local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local threader = require("threader")
local scener = require("scener")
local alert = require("alert")
local config = require("config")
local sharp = require("sharp")
local themer = require("themer")
local background = require("background")
local updater = require("updater")

local scene = {
    name = "Options"
}


local nobg = {
    style = {
        bg = {},
        padding = 0,
        radius = 0
    },
    clip = false,
    cacheable = false
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


local qualities = {
    { text = "High (Default)", data = {
        id = "high",
        bg = true,
        bgBlur = true,
        bgSnow = true,
    } },
    { text = "Medium", data = {
        id = "medium",
        bg = true,
        bgBlur = true,
        bgSnow = false,
    } },
    { text = "Low", data = {
        id = "low",
        bg = true,
        bgBlur = false,
        bgSnow = false,
    } },
    { text = "Minimal", data = {
        id = "low",
        bg = false,
        bgBlur = false,
        bgSnow = false,
    } },
}


local updatepaths = {
    { text = "Stable (Default)", data = "stable" },
    { text = "Development", data = "stable,main" }
}


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
                    }):with(nobg):with(uiu.fillWidth(8.25)),

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
                    }):with(nobg):with(uiu.fillWidth(8 + 1 / 5)):with(uiu.at(1 / 5, 0)),

                    uie.column({
                        uie.label("Quality"),
                        uie.dropdown(qualities, function(self, value)
                            config.quality = value
                            config.save()
                        end):with(function(self)
                            for i = 1, #qualities do
                                if config.quality.id == qualities[i].data.id then
                                    self.selected = self:getItem(i)
                                    self.text = self.selected.text
                                    return
                                end
                            end
                            self.selected = self:getItem(1)
                            self.text = "???"
                        end)
                    }):with(nobg):with(uiu.fillWidth(8 + 1 / 5)):with(uiu.at(2 / 5, 0)),

                    uie.column({
                        uie.label("Vertical Sync"),
                        uie.dropdown({
                            { text = "Enabled (Default)", data = true },
                            { text = "Disabled", data = false },
                        }, function(self, value)
                            config.vsync = value
                            config.save()
                            love.window.setVSync(value and 1 or 0)
                        end):with(function(self)
                            self.selected = self:getItem(config.vsync and 1 or 2)
                            self.text = self.selected.text
                        end)
                    }):with(nobg):with(uiu.fillWidth(8 + 1 / 5)):with(uiu.at(3 / 5, 0)),

                    uie.column({
                        uie.label("Updates"),
                        uie.dropdown(updatepaths, function(self, value)
                            config.updates = value
                            config.save()
                            updater.check()
                        end):with(function(self)
                            for i = 1, #updatepaths do
                                if config.updates == updatepaths[i].data then
                                    self.selected = self:getItem(i)
                                    self.text = self.selected.text
                                    return
                                end
                            end
                            self.selected = self:getItem(1)
                            self.text = "???"
                        end)
                    }):with(nobg):with(uiu.fillWidth(8 + 1 / 5)):with(uiu.at(4 / 5, 0)),

                }):with(nobg):with(uiu.fillWidth),

                uie.row({

                }):with(nobg):with(uiu.fillWidth)

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
