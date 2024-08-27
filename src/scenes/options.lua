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
        id = "minimal",
        bg = false,
        bgBlur = false,
        bgSnow = false,
    } },
}


local updatepaths = {
    { text = "Stable (Default)", data = "stable" },
    { text = "Development", data = "stable,main" }
}

local updateModsOnStartupOptions = {
    { text = "All Mods", data = "all" },
    { text = "Enabled Mods Only", data = "enabled" },
    { text = "Disabled (Default)", data = "none" }
}

local useOpenGLOptions = {
    { text = "Enabled", data = "enabled" },
    { text = "Disabled (Default)", data = "disabled" }
}

local closeAfterOneClickInstallOptions = {
    { text = "Enabled", data = "enabled" },
    { text = "Disabled (Default)", data = "disabled" }
}

-- Keep in sync with https://github.com/EverestAPI/Everest/blob/dev/Celeste.Mod.mm/Mod/Core/CoreModuleSettings.cs :: CreateMirrorPreferencesEntry
local mirrorPreferences = {
    { text = "Disabled (Default)", data = "gb,jade,otobot,wegfan" },
    { text = "Germany (0x0a.de)", data = "jade,otobot,wegfan,gb" },
    { text = "China (weg.fan)", data = "wegfan,otobot,jade,gb" },
    { text = "N. America (celestemods.com)", data = "otobot,jade,wegfan,gb" }
}

local extradatas = {
    { text = "Noto Sans CJK (~50 MB)", info = "Chinese, Japanese, Korean font files.", path = "olympus-extra-cjk.zip", url = "https://0x0a.de/olympus-extra/olympus-extra-cjk.zip" }
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
                uie.panel({
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
                    })
                }),

                uie.panel({
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
                    })
                }):with(themer.skin(theme))
            }):with(uiu.rightbound)

        }):with(uiu.fillWidth),
        function()
            themer.apply(theme)
            config.theme = name
            config.save()
            scene.root:findChild("themeDropdown"):updateSelected()
        end
    ):with({
        height = 100,
        clip = true,
        clipPadding = 1
    }):with(uiu.fillWidth):with(themer.skin(theme, false))

    themePickerEntries[#themePickerEntries + 1] = bigbtn
end

scene.themePicker = uie.scrollbox(
    uie.column(themePickerEntries):with(uiu.fillWidth)
):with({
    clip = false,
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
    uie.column(bgPickerEntries):with(uiu.fillWidth)
):with({
    clip = true,
    cacheable = false
}):with(uiu.fillWidth):with(uiu.fillHeight(true))

local optioncount = 4
local root = uie.column({
    uie.scrollbox(
        uie.column({

            uie.paneled.column({
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
                                self.selectedData = config.theme
                            end

                            self:updateSelected()
                        end):with(uiu.fillWidth):as("themeDropdown")
                    }):with(uiu.fillWidth(8 + 1 / optioncount)):with(uiu.at(0 / optioncount, 0)),

                    uie.column({
                        uie.label("Background image"),
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
                                self.selectedIndex = config.bg + 1
                            end

                            self:updateSelected()
                        end):with(uiu.fillWidth):as("bgDropdown")
                    }):with(uiu.fillWidth(8 + 1 / optioncount)):with(uiu.at(1 / optioncount, 0)),

                    uie.column({
                        uie.label("Quality"),
                        uie.dropdown(qualities, function(self, value)
                            config.quality = value
                            config.save()
                        end):with(function(self)
                            for i = 1, #qualities do
                                if config.quality.id == qualities[i].data.id then
                                    self.selectedIndex = i
                                    return
                                end
                            end
                            self.text = "???"
                        end):with(uiu.fillWidth)
                    }):with(uiu.fillWidth(8 + 1 / optioncount)):with(uiu.at(2 / optioncount, 0)),

                    uie.column({
                        uie.label("Gradient"),
                        uie.dropdown({
                            { text = "Enabled (Default)", data = 1 },
                            { text = "Low", data = 0.5 },
                            { text = "Disabled", data = 0 },
                        }, function(self, value)
                            config.overlay = value
                            config.save()
                        end):with({
                            selectedIndex = config.overlay <= 0 and 3 or config.overlay <= 0.5 and 2 or 1
                        }):with(uiu.fillWidth)
                    }):with(uiu.fillWidth(8 + 1 / optioncount)):with(uiu.at(3 / optioncount, 0)),

                }):with(uiu.fillWidth),

                uie.row({
                    uie.column({
                        uie.label("Parallax"),
                        uie.dropdown({
                            { text = "Enabled (Default)", data = 1 },
                            { text = "Medium", data = 0.5 },
                            { text = "Low", data = 0.2 },
                            { text = "Disabled", data = 0 },
                        }, function(self, value)
                            config.parallax = value
                            config.save()
                        end):with({
                            selectedIndex = config.parallax <= 0 and 4 or config.parallax <= 0.2 and 3 or config.parallax <= 0.5 and 2 or 1
                        }):with(uiu.fillWidth)
                    }):with(uiu.fillWidth(8 + 1 / optioncount)):with(uiu.at(0 / optioncount, 0)),

                    uie.column({
                        uie.label("Vertical Sync"),
                        uie.dropdown({
                            { text = "Enabled (Default)", data = true },
                            { text = "Disabled", data = false },
                        }, function(self, value)
                            config.vsync = value
                            config.save()
                            love.window.setVSync(value and 1 or 0)
                        end):with({
                            selectedIndex = config.vsync and 1 or 2
                        }):with(uiu.fillWidth)
                    }):with(uiu.fillWidth(8 + 1 / optioncount)):with(uiu.at(1 / optioncount, 0)),

                    uie.column({
                        uie.label("Updates"),
                        uie.dropdown(updatepaths, function(self, value)
                            config.updates = value
                            config.save()
                            updater.check()
                        end):with({
                            placeholder = "???",
                            selectedData = config.updates
                        }):with(uiu.fillWidth)
                    }):with(uiu.fillWidth(8 + 1 / optioncount)):with(uiu.at(2 / optioncount, 0)),

                    uie.column({
                        uie.label("Update Mods on Startup"),
                        uie.dropdown(updateModsOnStartupOptions, function(self, value)
                            config.updateModsOnStartup = value
                            config.save()
                        end):with({
                            placeholder = "???",
                            selectedData = config.updateModsOnStartup
                        }):with(uiu.fillWidth)
                    }):with(uiu.fillWidth(8 + 1 / optioncount)):with(uiu.at(3 / optioncount, 0)),

                }):with(uiu.fillWidth),

                uie.row({
                    uie.column({
                        uie.label("Use OpenGL"),
                        uie.dropdown(useOpenGLOptions, function(self, value)
                            config.useOpenGL = value
                            config.save()
                        end):with({
                            placeholder = "???",
                            selectedData = config.useOpenGL
                        }):with(uiu.fillWidth)
                    }):with(uiu.fillWidth(8 + 1 / optioncount)):with(uiu.at(0 / optioncount, 0)),

                    uie.column({
                        uie.label("Close after One-Click Install"),
                        uie.dropdown(closeAfterOneClickInstallOptions, function(self, value)
                            config.closeAfterOneClickInstall = value
                            config.save()
                        end):with({
                            placeholder = "???",
                            selectedData = config.closeAfterOneClickInstall
                        }):with(uiu.fillWidth)
                    }):with(uiu.fillWidth(8 + 1 / optioncount)):with(uiu.at(1 / optioncount, 0)),

                    uie.column({
                        uie.label("Use Mirror by Default"),
                        uie.dropdown(mirrorPreferences, function(self, value)
                            config.mirrorPreferences = value
                            config.save()
                        end):with({
                            placeholder = "???",
                            selectedData = config.mirrorPreferences
                        }):with(uiu.fillWidth)
                    }):with(uiu.fillWidth(8 + 1 / optioncount)):with(uiu.at(2 / optioncount, 0)),

                }):with(uiu.fillWidth),

                uie.group({}),


                uie.row({

                    uie.button("Open installation folder", function()
                        utils.openFile(fs.getsrc())
                    end):with(uiu.fillWidth(4 + 1 / 3)),

                    uie.button("Open log and config folder", function()
                        utils.openFile(fs.getStorageDir())
                    end):with(uiu.fillWidth(8 + 1 / 3)):with(uiu.at(4 + 1 / 3)),

                    uie.button("Download extra data", function()
                        local btns = {}

                        for i = 1, #extradatas do
                            local data = extradatas[i]
                            btns[#btns + 1] = uie.button(
                                { { 1, 1, 1, 1 }, data.text .. "\n", { 1, 1, 1, 0.5 }, data.info},
                                function(self)
                                    local installer = scener.push("installer")
                                    installer.sharpTask("installExtraData", data.url, data.path):calls(function(task, last)
                                        if not last then
                                            return
                                        end

                                        installer.update(string.format("Extra data %s successfully installed", data.path), 1, "done")
                                        installer.done({
                                            {
                                                "Restart Olympus",
                                                function()
                                                    sharp.restart(love.filesystem.getSource()):result()
                                                    love.event.quit()
                                                end
                                            }
                                        })
                                    end)
                                    self:getParent("container"):close("OK")
                                end
                            ):with({
                                enabled = not fs.isFile(fs.joinpath(fs.getsrc(), data.path))
                            })
                        end

                        alert({
                            body = uie.scrollbox(
                                uie.column(btns)
                            ),
                            init = function(container)
                                btns[#btns + 1] = uie.button("Close", function()
                                    container:close("Close")
                                end)
                                container:findChild("buttons"):removeSelf()

                                local body = container:findChild("body")
                                body:with({
                                    calcSize = uie.group.calcSize
                                })
                                container:hook({
                                    awake = function(orig, self)
                                        orig(self)
                                        self:layoutLazy()
                                        self:layoutLateLazy()
                                        local el = body.children[1]
                                        local children = el.children
                                        local widest = 0
                                        for i = 1, #children do
                                            local width = children[i].width
                                            if width > widest then
                                                widest = width
                                            end
                                        end
                                        for i = 1, #children do
                                            if children[i].width < widest then
                                                children[i]:with(uiu.fillWidth):reflow()
                                            end
                                        end
                                        self:reflowDown()
                                        self:reflow()
                                    end
                                })
                            end
                        })
                    end):with(uiu.fillWidth(4 + 1 / 3)):with(uiu.at(4 + 2 / 3)),


                }):with(uiu.fillWidth),

            }):with(uiu.fillWidth),

            updater.available and uie.paneled.column({
                uie.label("Updates", ui.fontBig),

                uie.label("Update machine broke, please fix."):as("changelog"),

                uie.button("Install"):with({
                    enabled = false
                }):with(uiu.fillWidth):as("updatebtn")

            }):with(uiu.fillWidth)

        }):with({
            style = {
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
