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
local lang = require("lang")

local scene = {
    name = lang.get("options")
}


local themes = {}
for i, file in ipairs(love.filesystem.getDirectoryItems("data/themes")) do
    local name = file:match("^(.+)%.json$")
    if name then
        local theme = utils.loadJSON("data/themes/" .. name .. ".json")
        themes[#themes + 1] = {
            text = (name == "default" and lang.get("theme_dark") or (
                    name == "light" and lang.get("theme_light") or (
                    theme.__name or tostring(theme)))),
            data = name,
            theme = theme
        }
    end
end


local bgs = {
    { text = lang.get("random_default"), data = 0 }
}
for i = 1, #background.bgs do
    bgs[i + 1] = {
        text = lang.get("background") .. i,
        data = i,
        bg = background.bgs[i]
    }
end


local qualities = {
    { text = lang.get("high_default"), data = {
        id = "high",
        bg = true,
        bgBlur = true,
        bgSnow = true,
    } },
    { text = lang.get("medium"), data = {
        id = "medium",
        bg = true,
        bgBlur = true,
        bgSnow = false,
    } },
    { text = lang.get("low"), data = {
        id = "low",
        bg = true,
        bgBlur = false,
        bgSnow = false,
    } },
    { text = lang.get("minimal"), data = {
        id = "minimal",
        bg = false,
        bgBlur = false,
        bgSnow = false,
    } },
}


local updatepaths = {
    { text = lang.get("stable_default"), data = "stable" },
    { text = lang.get("development"), data = "stable,main" }
}

local updateModsOnStartupOptions = {
    { text = lang.get("all_mods"), data = "all" },
    { text = lang.get("enabled_mods_only"), data = "enabled" },
    { text = lang.get("disabled_default"), data = "none" }
}

local useOpenGLOptions = {
    { text = lang.get("enabled"), data = "enabled" },
    { text = lang.get("disabled_default"), data = "disabled" }
}

local closeAfterOneClickInstallOptions = {
    { text = lang.get("enabled"), data = "enabled" },
    { text = lang.get("disabled_default"), data = "disabled" }
}

-- Keep in sync with https://github.com/EverestAPI/Everest/blob/dev/Celeste.Mod.mm/Mod/Core/CoreModuleSettings.cs :: CreateMirrorPreferencesEntry
local mirrorPreferences = {
    { text = lang.get("disabled_default"), data = "gb,jade,risingsunlight,otobot,wegfan" },
    { text = lang.get("germany_0x0a_de"), data = "jade,risingsunlight,otobot,wegfan,gb" },
    { text = lang.get("china_weg_fan"), data = "wegfan,otobot,jade,risingsunlight,gb" },
    { text = lang.get("n_america_celestemods_com"), data = "otobot,jade,risingsunlight,wegfan,gb" },
    { text = lang.get("france_risingsunlight"), data = "risingsunlight,jade,otobot,wegfan,gb" },
}

local apiMirrors = {
    { text = lang.get("enabled"), data = true },
    { text = lang.get("disabled_default"), data = false }
}

local imageMirrors = {
    { text = lang.get("_x0a_de_default"), data = "jade" },
    { text = lang.get("celestemods_com"), data = "otobot" },
    { text = lang.get("disabled"), data = "none" }
}

local languages = {
    { text = "English (Default)", data = "en" },
    { text = "Français (French)", data = "fr" },
    { text = "简体中文（Simplified Chinese)", data = "zh" },
    { text = "한국어 (Korean)", data = "ko" },
}

local uiScales = {
    { text = "125%", data = 1.25 },
    { text = lang.get("ui_scale_default"), data = 1 },
    { text = "75%", data = 0.75 },
    { text = "50%", data = 0.5 },
    { text = "25%", data = 0.25 },
}


local themePickerEntries = {}
for i = 1, #themes do
    local name = themes[i].data
    local text = themes[i].text
    if name == "default" then
        text = lang.get("theme_dark")
    elseif name == "light" then
        text = lang.get("theme_light")
    end
    local theme = (name == "default" or not name) and themer.default or themes[i].theme

    local bigbtn = uie.button(
        uie.group({
            uie.label(text, ui.fontBig):with(themer.skin(theme, false)),

            uie.row({
                uie.panel({
                    uie.column({
                        uie.label(lang.get("this_is_your_current_theme_the_quick_bro")),

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
                        uie.label(lang.get("this_is_the_new_theme_over_the_lazy_dog")),

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
                uie.label(lang.get("options"), ui.fontBig),

                uie.row({
                    uie.column({
                        uie.label(lang.get("theme")),
                        uie.dropdown(themes):with({
                            onClick = function(self)
                                local container = alert({
                                    title = lang.get("select_your_theme"),
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
                        uie.label(lang.get("background_image")),
                        uie.dropdown(bgs):with({
                            onClick = function(self)
                                local container = alert({
                                    title = lang.get("select_your_background"),
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
                        uie.label(lang.get("quality")),
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
                        uie.label(lang.get("gradient")),
                        uie.dropdown({
                            { text = lang.get("enabled_default"), data = 1 },
                            { text = lang.get("low"), data = 0.5 },
                            { text = lang.get("disabled"), data = 0 },
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
                        uie.label(lang.get("parallax")),
                        uie.dropdown({
                            { text = lang.get("enabled_default"), data = 1 },
                            { text = lang.get("medium"), data = 0.5 },
                            { text = lang.get("low"), data = 0.2 },
                            { text = lang.get("disabled"), data = 0 },
                        }, function(self, value)
                            config.parallax = value
                            config.save()
                        end):with({
                            selectedIndex = config.parallax <= 0 and 4 or config.parallax <= 0.2 and 3 or config.parallax <= 0.5 and 2 or 1
                        }):with(uiu.fillWidth)
                    }):with(uiu.fillWidth(8 + 1 / optioncount)):with(uiu.at(0 / optioncount, 0)),

                    uie.column({
                        uie.label(lang.get("vertical_sync")),
                        uie.dropdown({
                            { text = lang.get("enabled_default"), data = true },
                            { text = lang.get("disabled"), data = false },
                        }, function(self, value)
                            config.vsync = value
                            config.save()
                            love.window.setVSync(value and 1 or 0)
                        end):with({
                            selectedIndex = config.vsync and 1 or 2
                        }):with(uiu.fillWidth)
                    }):with(uiu.fillWidth(8 + 1 / optioncount)):with(uiu.at(1 / optioncount, 0)),

                    uie.column({
                        uie.label(lang.get("update_mods_on_startup")),
                        uie.dropdown(updateModsOnStartupOptions, function(self, value)
                            config.updateModsOnStartup = value
                            config.save()
                        end):with({
                            placeholder = "???",
                            selectedData = config.updateModsOnStartup
                        }):with(uiu.fillWidth)
                    }):with(uiu.fillWidth(8 + 1 / optioncount)):with(uiu.at(2 / optioncount, 0)),

                    uie.column({
                        uie.label(lang.get("use_opengl")),
                        uie.dropdown(useOpenGLOptions, function(self, value)
                            config.useOpenGL = value
                            config.save()
                        end):with({
                            placeholder = "???",
                            selectedData = config.useOpenGL
                        }):with(uiu.fillWidth)
                    }):with(uiu.fillWidth(8 + 1 / optioncount)):with(uiu.at(3 / optioncount, 0)),


                }):with(uiu.fillWidth),

                uie.row({
                    uie.column({
                        uie.label(lang.get("close_after_one_click_install")),
                        uie.dropdown(closeAfterOneClickInstallOptions, function(self, value)
                            config.closeAfterOneClickInstall = value
                            config.save()
                        end):with({
                            placeholder = "???",
                            selectedData = config.closeAfterOneClickInstall
                        }):with(uiu.fillWidth)
                    }):with(uiu.fillWidth(8 + 1 / optioncount)):with(uiu.at(0 / optioncount, 0)),

                    uie.column({
                        uie.label(lang.get("language")),
                        uie.dropdown(languages, function(self, value)
                            local old = config.language
                            config.language = value
                            config.save()
                            if old ~= value then
                                alert({
                                    body = uie.label(lang.get("restart_to_apply_changes_in_languages")),
                                    buttons = {{ lang.get("ok") }}
                                })
                            end
                        end):with({
                            placeholder = "???",
                            selectedData = config.language
                        }):with(uiu.fillWidth)
                    }):with(uiu.fillWidth(8 + 1 / optioncount)):with(uiu.at(1 / optioncount, 0)),

                    uie.column({
                        uie.label(lang.get("ui_scale")),
                        uie.dropdown(uiScales, function(self, value)
                            config.uiScale = value
                            config.save()
                            alert({
                                body = uie.label(lang.get("restart_to_apply_changes_in_ui_scale")),
                                buttons = {{ lang.get("ok") }}
                            })
                        end):with({
                            selectedData = config.uiScale
                        }):with(uiu.fillWidth)
                    }):with(uiu.fillWidth(8 + 1 / optioncount)):with(uiu.at(2 / optioncount, 0)),

                    uie.column(updater.available and {
                        uie.label(lang.get("updates")),
                        uie.dropdown(updatepaths, function(self, value)
                            config.updates = value
                            config.save()
                            updater.check()
                        end):with({
                            placeholder = "???",
                            selectedData = config.updates
                        }):with(uiu.fillWidth)
                    } or {}):with(uiu.fillWidth(8 + 1 / optioncount)):with(uiu.at(3 / optioncount, 0)),

                }):with(uiu.fillWidth),

                uie.group({}),


                uie.row({

                    uie.button(lang.get("open_installation_folder"), function()
                        utils.openFile(fs.getsrc())
                    end):with(uiu.fillWidth(8 + 1 / 3)),

                    uie.button(lang.get("open_log_and_config_folder"), function()
                        utils.openFile(fs.getStorageDir())
                    end):with(uiu.fillWidth(8 + 1 / 3)):with(uiu.at(1 / 3)),

                    uie.button(lang.get("connectivity_test"), function()
                        scener.push("gfwtest")
                    end):with(uiu.fillWidth(8 + 1 / 3)):with(uiu.at(2 / 3)),


                }):with(uiu.fillWidth),

            }):with(uiu.fillWidth),

            uie.paneled.column({
                uie.label(lang.get("mirrors"), ui.fontBig),

                uie.label({
{ 1, 1, 1, 1 }, lang.get("if_you_have_difficulty_downloading_mods_"), uie.greentext().style.color, lang.get("download_mirror"), { 1, 1, 1, 1 }, lang.get("can_help_if_mod_downloads_are_slow_or_ga"), uie.greentext().style.color, lang.get("api_mirror"), { 1, 1, 1, 1 }, lang.get("can_help_if_the_install_everest_or_downl"), uie.greentext().style.color, lang.get("image_mirror"), { 1, 1, 1, 1 }, lang.get("changes_where_the_mod_images_in_the_mod_")
                }),

                uie.row({
                    uie.column({
                        uie.label(lang.get("download_mirror")),
                        uie.dropdown(mirrorPreferences, function(self, value)
                            config.mirrorPreferences = value
                            config.save()
                        end):with({
                            placeholder = "???",
                            selectedData = config.mirrorPreferences
                        }):with(uiu.fillWidth)
                    }):with(uiu.fillWidth(8 + 1 / 3)):with(uiu.at(0 / 3, 0)),

                    uie.column({
                        uie.label(lang.get("api_mirror")),
                        uie.dropdown(apiMirrors, function(self, value)
                            config.apiMirror = value
                            config.save()
                        end):with({
                            placeholder = "???",
                            selectedData = config.apiMirror
                        }):with(uiu.fillWidth)
                    }):with(uiu.fillWidth(8 + 1 / 3)):with(uiu.at(1 / 3, 0)),

                    uie.column({
                        uie.label(lang.get("image_mirror")),
                        uie.dropdown(imageMirrors, function(self, value)
                            config.imageMirror = value
                            config.save()
                        end):with({
                            placeholder = "???",
                            selectedData = config.imageMirror
                        }):with(uiu.fillWidth)
                    }):with(uiu.fillWidth(8 + 1 / 3)):with(uiu.at(2 / 3, 0)),

                }):with(uiu.fillWidth),

            }):with(uiu.fillWidth),


            updater.available and uie.paneled.column({
                uie.label(lang.get("updates"), ui.fontBig),

                uie.row({
                    uie.label({ { 0.8, 0.5, 0.5, 1 }, lang.get("note_this_only_covers_olympus_1"), { 1, 1, 1, 1 }, lang.get("note_this_only_covers_olympus_2") }),
                    uie.icon("cogwheel"):with({ scale = 21 / 256 }),
                    uie.label(lang.get("note_this_only_covers_olympus_3"))
                }),

                uie.label("Update machine broke, please fix."):as("changelog"),

                uie.button(lang.get("install")):with({
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
