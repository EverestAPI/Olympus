local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local fs = require("fs")
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
            data = name,
            theme = theme
        }
    end
end


local bgs = {
    { text = "Random (Default)", data = 0 }
}
for i = 1, #background.bgs do
    bgs[i + 1] = {
        text = "Background #" .. i,
        data = i,
        bg = background.bgs[i]
    }
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


local themePickerEntries = {}
for i = 1, #themes do
    local name = themes[i].data
    local text = themes[i].text
    local theme = (name == "default" or not name) and themer.default or themes[i].theme

    local bigbtn = uie.button(
        uie.group({
            uie.label(text, ui.fontBig):with(themer.skin(theme, false)),

            uie.row({
                uie.column({
                    uie.label([[
This is your current theme.
The quick brown fox jumps]]),

                    uie.list(uiu.map(uiu.listRange(1, 3), function(i)
                        return string.format("Item %i!", i)
                    end)):with(function(self)
                        local children = self.children
                        for i = 1, #children do
                            children[i].interactive = 0
                            children[i].owner = self
                        end
                        children[1].selected = true
                    end):with(uiu.fillWidth)
                }),

                uie.column({
                    uie.label([[
This is the new theme.
over the lazy dog.]]),

                    uie.list(uiu.map(uiu.listRange(1, 3), function(i)
                        return string.format("Item %i!", i)
                    end)):with(function(self)
                        local children = self.children
                        for i = 1, #children do
                            children[i].interactive = 0
                            children[i].owner = self
                        end
                        children[1].selected = true
                    end):with(uiu.fillWidth)
                }):with(themer.skin(theme))
            }):with(nobg):with(uiu.rightbound)

        }):with(uiu.fillWidth),
        function()
            themer.apply(theme)
            config.theme = name
            config.save()
            scene.root:findChild("themeDropdown"):updateSelected()
        end
    ):with({
        height = 100
    }):with(uiu.fillWidth):with(themer.skin(theme, false))

    themePickerEntries[#themePickerEntries + 1] = bigbtn
end

scene.themePicker = uie.scrollbox(
    uie.column(themePickerEntries):with(nobg):with(uiu.fillWidth)
):with({
    clip = true,
    cacheable = false
}):with(uiu.fillWidth):with(uiu.fillHeight(true))


local bgPickerEntries = {}
for i = 1, #bgs do
    local id = bgs[i].data
    local text = bgs[i].text
    local bg = bgs[i].bg

    local bigbtn = uie.button(
        uie.group({
            uie.label(text, ui.fontBig),

            bg and uie.image(bg):with({

            }):with(uiu.rightbound)

        }):with(uiu.fillWidth),
        function()
            config.bg = id
            config.save()
            background.refresh()
            scene.root:findChild("bgDropdown"):updateSelected()
        end
    ):with(uiu.fillWidth)

    bgPickerEntries[#bgPickerEntries + 1] = bigbtn
end

scene.bgPicker = uie.scrollbox(
    uie.column(bgPickerEntries):with(nobg):with(uiu.fillWidth)
):with({
    clip = true,
    cacheable = false
}):with(uiu.fillWidth):with(uiu.fillHeight(true))


local root = uie.column({
    uie.scrollbox(
        uie.column({

            uie.column({
                uie.label("Options", ui.fontBig),

                uie.row({

                    uie.column({
                        uie.label("Theme"),
                        uie.dropdown(themes):with({
                            onClick = function(self)
                                local container = alert({
                                    title = "Select your theme",
                                    body = scene.themePicker,
                                    big = true
                                })
                                local btns = container:findChild("buttons")
                                btns:with(uiu.fillWidth)
                                btns.children[1]:with(uiu.fillWidth)
                            end
                        }):with(function(self)
                            function self.updateSelected(self)
                                for i = 1, #themes do
                                    if config.theme == themes[i].data then
                                        self.selected = self:getItem(i)
                                        self.text = self.selected.text
                                        break
                                    end
                                end
                            end

                            self:updateSelected()
                        end):as("themeDropdown")
                    }):with(nobg):with(uiu.fillWidth(8.25)),

                    uie.column({
                        uie.label("Background"),
                        uie.dropdown(bgs):with({
                            onClick = function(self)
                                local container = alert({
                                    title = "Select your background",
                                    body = scene.bgPicker,
                                    big = true
                                })
                                local btns = container:findChild("buttons")
                                btns:with(uiu.fillWidth)
                                btns.children[1]:with(uiu.fillWidth)
                            end
                        }):with(function(self)
                            function self.updateSelected(self)
                                self.selected = self:getItem(config.bg + 1)
                                self.text = self.selected.text
                            end

                            self:updateSelected()
                        end):as("bgDropdown")
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

                    uie.button("Open installation folder", function()
                        utils.openFile(fs.getsrc())
                    end):with(uiu.fillWidth(4.5)),

                    uie.button("Open log and config folder", function()
                        utils.openFile(fs.getStorageDir())
                    end):with(uiu.fillWidth(4.5)):with(uiu.at(4.5)),


                }):with(nobg):with(uiu.fillWidth),

            }):with(uiu.fillWidth),

            uie.column({
                uie.label("Updates", ui.fontBig),

                uie.label("Update machine broke, please fix."):as("changelog"),

                uie.button("Install"):with({
                    enabled = false
                }):with(uiu.fillWidth):as("updatebtn")

            }):with(uiu.fillWidth)

        }):with({
            style = {
                bg = {},
                padding = 16,
            }
        }):with(uiu.fillWidth):as("categories")
    ):with({
        style = {
            barPadding = 16,
        },
        clip = false,
        cacheable = false
    }):with(uiu.fillWidth):with(uiu.fillHeight(true))
}):with({
    cacheable = false,
    _fullroot = true
})
scene.root = root


function scene.load()

end


function scene.enter()

end


return scene
