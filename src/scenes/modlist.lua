local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local fs = require("fs")
local threader = require("threader")
local scener = require("scener")
local config = require("config")
local sharp = require("sharp")
local alert = require("alert")
local notify = require("notify")
local modupdater = require("modupdater")

local scene = {
    name = "Mod Manager",
    -- mod name -> mod object { info = modinfo, row = uirow, visible = bool }
    modlist = {},
    -- mod name -> list of mod names that this mod depends on
    modDependencies = {},
    -- mod name -> list of mod names that depend on this mod
    modDependents = {},
    -- mod path -> mod name
    modPathToName = {},
    onlyShowEnabledMods = false,
    search = ""
}

scene.loadingID = 0


local root = uie.column({
    uie.scrollbox(
        uie.column({
        }):with({
            style = {
                padding = 16
            }
        }):with({
            cacheable = false
        }):with(uiu.fillWidth):as("mods")
    ):with({
        style = {
            barPadding = 16,
        },
        clip = false,
        cacheable = false
    }):with(uiu.fill):as("scrollbox"),

}):with({
    cacheable = false,
    _fullroot = true
})

root:findChild("scrollbox").handleY:hook({
    layoutLate = function(orig, self)
        orig(self)

        self.expandBy = 0
        if self.isNeeded and self.height < 20 then
            -- make the handle bigger so that it's easier to hit with the mouse!
            self.expandBy = 20 - self.height
            self.height = 20
            self.realY = uiu.round(self.realY - self.expandBy * (self.realY / self.parent.height))
        end
    end,

    onDrag = function(orig, self, x, y, dx, dy)
        -- adapt the scrolling speed to the bigger handle, so that it doesn't "slip" behind the mouse
        dy = dy + dy * self.expandBy / self.parent.height
        orig(self, x, y, dx, dy)
    end
})

scene.root = root


-- finds a mod from modlist by its path
local function findModByPath(path)
    local modName = scene.modPathToName[path]
    if modName then
        return scene.modlist[modName]
    end
    return nil
end

-- creates alert with error message
local function displayErrorMessage(text)
    alert({
        body = string.format(text),
        buttons = {
            {
                "Close",
            },
        }
    })
end

-- writes the blacklist to disk, making the enabled/disabled mods actually take effect
local function writeBlacklist()
    local contents = "# This is the blacklist. Lines starting with # are ignored.\n# File generated through the \"Manage Installed Mods\" screen in Olympus\n\n"

    for _, mod in pairs(scene.modlist) do
        if mod.row:findChild("toggleCheckbox"):getValue() then
            contents = contents .. "# "
        end
        contents = contents .. fs.filename(mod.info.Path) .. "\n"
    end

    local root = config.installs[config.install].path
    fs.write(fs.joinpath(root, "Mods", "blacklist.txt"), contents)
end

-- shows or hides mods depending on search and "only show enabled mods" checkbox
local function refreshVisibleMods()
    local list = root:findChild("mods")

    local modIndex = 3 -- the 2 first elements are the header, and the search field

    for _, mod in pairs(scene.modlist) do
        -- a mod is visible if the search is part of the filename or mod ID (case-insensitive) or if there is no search at all
        local newVisible =
            -- only show enabled mods
            (not scene.onlyShowEnabledMods
                or not mod.info.IsBlacklisted)
            and
            -- search terms
            (scene.search == ""
                or string.find(string.lower(fs.filename(mod.info.Path)), scene.search, 1, true)
                or (mod.info.Name and string.find(string.lower(mod.info.Name), scene.search, 1, true))
                or (mod.info.GameBananaTitle and string.find(string.lower(mod.info.GameBananaTitle), scene.search, 1, true)))

        if mod.visible and not newVisible then
            -- remove from list
            list:removeChild(mod.row)

        elseif not mod.visible and newVisible then
            -- add back to list
            list:addChild(mod.row, modIndex)
        end

        mod.visible = newVisible

        if newVisible then
            modIndex = modIndex + 1
        end
    end
end

-- updates the "X enabled mod(s)" label next to the "enable all" and "disable all" buttons
local function updateEnabledModCountLabel()
    local enabledModCount = 0

    for _, mod in pairs(scene.modlist) do
        if mod.row:findChild("toggleCheckbox"):getValue() then
            enabledModCount = enabledModCount + 1
        end
    end

    scene.root:findChild("enabledModCountLabel"):setText(string.format(
        "%s enabled %s",
        enabledModCount == 0 and "No" or enabledModCount,
        enabledModCount == 1 and "mod" or "mods"
    ))
end

-- gives the text for a given mod
local function getLabelTextFor(info)
    local grey = { 1, 1, 1, 0.5 }
    local white = { 1, 1, 1, 1 }

    if info.Name then
        if info.GameBananaTitle then
            -- Maddie's Helping Hand
            -- MaxHelpingHand 1.4.5 ∙ Filename.zip
            return {
                info.IsBlacklisted and grey or white,
                info.GameBananaTitle .. "\n",
                grey,
                info.Name .. " " .. (info.Version or "?.?.?.?") .. " ∙ " .. fs.filename(info.Path)
            }
        else
            -- MaxHelpingHand
            -- 1.4.5 ∙ Filename.zip
            return {
                info.IsBlacklisted and grey or white,
                info.Name .. "\n",
                grey,
                (info.Version or "?.?.?.?") .. " ∙ " .. fs.filename(info.Path)
            }
        end
    else
        -- Filename.zip
        return {
            info.IsBlacklisted and grey or white,
            fs.filename(info.Path)
        }
    end
end

-- enable a mod on the UI (writeBlacklist needs to be called afterwards to write the change to disk)
local function enableMod(mod)
    if mod.info.IsBlacklisted then
        mod.row:findChild("toggleCheckbox"):setValue(true)
        mod.info.IsBlacklisted = false
        mod.row:findChild("title"):setText(getLabelTextFor(mod.info))
        updateEnabledModCountLabel()

        if scene.onlyShowEnabledMods then
            refreshVisibleMods()
        end
    end
end

-- disable a mod on the UI (writeBlacklist needs to be called afterwards to write the change to disk)
local function disableMod(mod)
    if not mod.info.IsBlacklisted then
        mod.row:findChild("toggleCheckbox"):setValue(false)
        mod.info.IsBlacklisted = true
        mod.row:findChild("title"):setText(getLabelTextFor(mod.info))
        updateEnabledModCountLabel()

        if scene.onlyShowEnabledMods then
            refreshVisibleMods()
        end
    end
end

-- simple "table contains element" function
local function contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

-- builds the confirmation message body for toggling mods, including a potentially-long list of mods in a scrollbox
local function getConfirmationMessageBodyForModToggling(dependenciesToToggle, message)
    local modList = ''
    for _, mod in pairs(dependenciesToToggle) do
        modList = modList
            .. (modList == '' and '' or '\n')
            .. '- ' ..
            (
                (mod.info.GameBananaTitle and mod.info.GameBananaTitle ~= mod.info.Name)
                and (mod.info.GameBananaTitle .. ' ∙ ')
                or ''
            )
            .. mod.info.Name
    end

    return uie.column({
        uie.label(message),
        uie.scrollbox(uie.label(modList))
            :with(uiu.hook({
                calcSize = function (orig, self, width, height)
                    uie.group.calcSize(self)
                end
            }))
            :with({ maxHeight = 300 })
    })
end

-- lists all dependencies of the given mod that should be enabled for this mod to work
-- returns a table of dependency name -> mod object
local function findDependenciesToEnable(mod)
    local queue = {}
    local tried = {}
    local dependenciesToEnable = {}

    for _, depName in ipairs(scene.modDependencies[mod.info.Name] or {}) do
        if not tried[depName] then
            tried[depName] = true
            table.insert(queue, depName)
        end
    end

    while #queue > 0 do
        local depName = table.remove(queue, 1)
        local dep = scene.modlist[depName]
        if dep ~= nil then
            if dep.info.IsBlacklisted and dependenciesToEnable[depName] == nil then
                dependenciesToEnable[depName] = dep
            end
            for _, subdep in ipairs(scene.modDependencies[dep.info.Name] or {}) do
                if not tried[subdep] then
                    tried[subdep] = true
                    table.insert(queue, subdep)
                end
            end
        end
    end
    
    return dependenciesToEnable
end

local function dictLength(dict)
    local count = 0
    for _, _ in pairs(dict) do
        count = count + 1
    end
    return count
end

-- checks whether the mod that was just enabled has dependencies that are disabled, and prompts to enable them if so
local function checkDisabledDependenciesOfEnabledMod(mod)
    local dependenciesToToggle = findDependenciesToEnable(mod)
    local numDependencies = dictLength(dependenciesToToggle)

    if next(dependenciesToToggle) ~= nil then
        alert({
            body = getConfirmationMessageBodyForModToggling(dependenciesToToggle, string.format(
                "This mod depends on %s other disabled %s.\nDo you want to enable %s as well?",
                numDependencies,
                numDependencies == 1 and "mod" or "mods",
                numDependencies == 1 and "it" or "them"
            )),
            buttons = {
                {
                    "Yes",
                    function(container)
                        -- enable all the dependencies!
                        for _, depToToggle in pairs(dependenciesToToggle) do
                            enableMod(depToToggle)
                        end

                        writeBlacklist()
                        container:close()
                    end
                },
                {
                    "No"
                },
                {
                    "Cancel",
                    function(container)
                        -- re-disable the mod
                        disableMod(mod)
                        writeBlacklist()
                        container:close()
                    end
                }
            }
        })
    end
end

-- lists all dependents of the given mod that should be disabled because they are going to miss it as a dependency
-- returns a table of dependent name -> mod object
local function findDependentsToDisable(mod)
    local queue = {}
    local tried = {}
    local dependentsToDisable = {}

    for _, depName in ipairs(scene.modDependents[mod.info.Name] or {}) do
        if not tried[depName] then
            tried[depName] = true
            table.insert(queue, depName)
        end
    end

    while #queue > 0 do
        local depName = table.remove(queue, 1)
        local dep = scene.modlist[depName]
        if not dep.info.IsBlacklisted and dependentsToDisable[depName] == nil then
            dependentsToDisable[depName] = dep
        end
        for _, subdep in ipairs(scene.modDependents[dep.info.Name] or {}) do
            if not tried[subdep] then
                tried[subdep] = true
                table.insert(queue, subdep)
            end
        end
    end
    
    return dependentsToDisable
end

-- lists all dependencies of the given mods that can be disabled because no enabled mod depends on them anymore
local function findDependenciesThatCanBeDisabled(newlyDisabledMods)
    local queue = {}
    local tried = {}
    local dependenciesThatCanBeDisabled = {}

    for modName, _ in pairs(newlyDisabledMods) do
        for _, subdep in ipairs(scene.modDependencies[modName] or {}) do
            if not tried[subdep] then
                tried[subdep] = true
                table.insert(queue, subdep)
            end
        end
    end

    while #queue > 0 do
        local depName = table.remove(queue, 1)
        local dep = scene.modlist[depName]
        if dep ~= nil and not dep.info.IsBlacklisted and dependenciesThatCanBeDisabled[depName] == nil then
            local enabledDependents = findDependentsToDisable(dep)
            if next(enabledDependents) == nil then
                dependenciesThatCanBeDisabled[depName] = dep
                for _, subdep in ipairs(scene.modDependencies[depName] or {}) do
                    if not tried[subdep] then
                        tried[subdep] = true
                        table.insert(queue, subdep)
                    end
                end
            end
        end
    end

    return dependenciesThatCanBeDisabled
end

-- checks whether enabled mods that were dependencies of now-disabled mods can be disabled as well, and prompts to disable them if so
local function checkEnabledModsDependingOnDisabledMods(newlyDisabledMods)
    local dependenciesThatCanBeDisabled = findDependenciesThatCanBeDisabled(newlyDisabledMods)
    local numDependencies = dictLength(dependenciesThatCanBeDisabled)

    if next(dependenciesThatCanBeDisabled) ~= nil then
        alert({
            body = getConfirmationMessageBodyForModToggling(dependenciesThatCanBeDisabled, string.format(
                "%s other %s no longer required for any enabled mod.\nDo you want to disable %s as well?",
                numDependencies,
                numDependencies == 1 and "mod is" or "mods are",
                numDependencies == 1 and "it" or "them"
            )),
            buttons = {
                {
                    "Yes",
                    function(container)
                        -- disable them all!
                        for _, depToToggle in pairs(dependenciesThatCanBeDisabled) do
                            disableMod(depToToggle)
                        end

                        writeBlacklist()
                        container:close()
                    end
                },
                {
                    "No"
                }
            }
        })
    end
end

-- checks whether enabled mods depend on the mod that was just disabled, and prompts to disable them if so
local function checkEnabledModsDependingOnDisabledMod(mod)
    local dependenciesToToggle = findDependentsToDisable(mod)
    local numDependencies = dictLength(dependenciesToToggle)

    if next(dependenciesToToggle) ~= nil then
        alert({
            body = getConfirmationMessageBodyForModToggling(dependenciesToToggle, string.format(
                "%s other %s on this mod.\nDo you want to disable %s as well?",
                numDependencies,
                numDependencies == 1 and "mod depends" or "mods depend",
                numDependencies == 1 and "it" or "them"
            )),
            buttons = {
                {
                    "Yes",
                    function(container)
                        -- disable them all!
                        for _, depToToggle in pairs(dependenciesToToggle) do
                            disableMod(depToToggle)
                        end

                        writeBlacklist()
                        container:close()

                        dependenciesToToggle[mod.info.Name] = mod
                        checkEnabledModsDependingOnDisabledMods(dependenciesToToggle)
                    end
                },
                {
                    "No",
                    function(container)
                        container:close()
                        checkEnabledModsDependingOnDisabledMods({[mod.info.Name] = mod})
                    end
                },
                {
                    "Cancel",
                    function(container)
                        -- re-enable the mod
                        enableMod(mod)
                        writeBlacklist()
                        container:close()
                    end
                }
            }
        })
    else
        checkEnabledModsDependingOnDisabledMods({[mod.info.Name] = mod})
    end
end

-- called whenever a mod is enabled or disabled
local function toggleMod(info, newState)
    local mod = scene.modlist[info.Name]
    if newState then
        enableMod(mod)
        writeBlacklist()
        checkDisabledDependenciesOfEnabledMod(mod)
    else
        disableMod(mod)
        writeBlacklist()
        checkEnabledModsDependingOnDisabledMod(mod)
    end
end

-- method to be used in :with(...) in order to center an item vertically
local function verticalCenter(el)
    return uiu.hook(el, {
        layoutLateLazy = function(orig, self)
            -- Always reflow this child whenever its parent gets reflowed.
            self:layoutLate()
            self:repaint()
        end,

        layoutLate = function(orig, self)
            local parent = self.parent
            self.realY = math.floor((parent.height - (parent.style:get("padding") or 0) - self.height) / 2)
            orig(self)
        end
    })
end

-- loops through modlist and calls enableMod() on every mod
local function enableAllMods()
    for _, mod in pairs(scene.modlist) do
        enableMod(mod)
    end
end

-- loops through modlist and calls disableMod() on every mod
local function disableAllMods()
    for _, mod in pairs(scene.modlist) do
        disableMod(mod)
    end
end

-- disables all mods then enables mods from preset
local function applyPreset(name, disableAll)
    if disableAll then
        disableAllMods()
    end
    name = name:gsub("%p", "%%%1") -- escape special characters
    local root = config.installs[config.install].path
    local contents = fs.read(fs.joinpath(root, "Mods", "modpresets.txt"))
    if contents == nil then
        return
    end
    local presetMods = contents:match("%*%*" .. name .. "\n([^*]*)") -- gets a string with all preset .zip mod file names
    local missingMods = ""

    for filename in presetMods:gmatch("([^\n]*)\n") do -- splits the string after every newline into mod filenames
        local path = fs.joinpath(root, "Mods", filename)
        local mod = findModByPath(path)
        if mod ~= nil then
            enableMod(mod)
        else
            if missingMods ~= "" then
                missingMods = missingMods .. ", "
            end
            missingMods = missingMods .. filename
        end
    end
    if missingMods ~= "" then
        displayErrorMessage("Some mods couldn't be loaded, make sure they are installed: \n" .. missingMods)
    end
    writeBlacklist()
end

-- deletes preset from modpresets.txt
local function deletePreset(name)
    if name == nil then
        displayErrorMessage("Something went wrong, deleted preset's name is nil!")
        return
    end
    if #name == 0 then
        displayErrorMessage("Something went wrong, deleted preset's name is empty!")
        return
    end

    local root = config.installs[config.install].path
    local contents = fs.read(fs.joinpath(root, "Mods", "modpresets.txt"))
    if contents ~= nil then
        name = name:gsub("%p", "%%%1") -- escape special characters
        contents = contents:gsub("%*%*(" .. name .. "\n[^*]*)","", 1)
        fs.write(fs.joinpath(root, "Mods", "modpresets.txt"), contents)
    end
end

-- reads modpresets.txt and returns a list of all preset names
local function readPresetsList()
    local root = config.installs[config.install].path
    local contents = fs.read(fs.joinpath(root, "Mods", "modpresets.txt"))

    if contents ~= nil then
        local names = {}
        for substring in contents:gmatch("%*%*(.-)%\n") do
            names[#names+1] = substring
        end
        return names
    else -- create modpresets.txt if it doesnt exist
        fs.write(fs.joinpath(root, "Mods", "modpresets.txt"), "# This is the file used to save mod presets.\n# File generated through the \"Manage Installed Mods\" screen in Olympus\n\n")
        return readPresetsList()
    end
end

-- writes a new preset to a modpresets.txt, returns true if preset was created successfully and false if not
local function addPreset(name)
    if name == nil then
        displayErrorMessage("Something went wrong, name is nil!")
        return false
    end
    if #name == 0 then
        displayErrorMessage("Preset name can't be empty!")
        return false
    end

    -- check if name is already taken
    -- TODO: make this a table rather than scan
    local names = readPresetsList()
    if names ~= nil then
        for i, n in ipairs(names) do
            if n == name then
                alert({
                    body = "This preset already exists! Do you wish to override it?",
                    buttons = {
                        {
                            "Yes",
                            function (container)
                                deletePreset(name)
                                addPreset(name)
                                container:close("OK")
                            end
                        },
                        {
                            "No",
                        },
                    }
               })
               return false
            end
        end
    end
    local root = config.installs[config.install].path
    local contents = fs.read(fs.joinpath(root, "Mods", "modpresets.txt"))
    contents = contents .. "**" .. name .. "\n"

    for _, mod in pairs(scene.modlist) do
        if mod.row:findChild("toggleCheckbox"):getValue() then
            contents = contents .. fs.filename(mod.info.Path) .. "\n"
        end
    end

    fs.write(fs.joinpath(root, "Mods", "modpresets.txt"), contents)
    return true
end



-- builds the Mod Presets screen and returns it, use scene.displayPresetsUI() to show it
local function buildPresetsUI()
    local presets = readPresetsList()
    local presetsRow = {}
    local preset = ""

    local presetField = uie.field("", function(self, value, prev)
        preset = value
    end):with({
        width = 200,
        height = 24,
        placeholder = "New preset name",
        enabled = true
    }):as("presetField")

    for i = 1, #presets do
        local presetRow = uie.paneled.row({
            uie.label(presets[i]):with(verticalCenter),
            uie.row({
                uie.button("Add", function(self)
                    applyPreset(presets[i], false)
                end),
                uie.button("Replace", function(self)
                    applyPreset(presets[i], true)
                end),
                uie.button("Delete", function(self)
                    alert({
                        body = [[
Are you sure that you want to delete ]] .. presets[i] .. [[?]],
                        buttons = {
                            {
                                "Delete",
                                function(container)
                                    deletePreset(presets[i])
                                    container:close("OK")
                                    self:getParent("modPresets"):close("OK")
                                    scene.displayPresetsUI()
                                end
                            },
                            { "Keep" }
                        }
                    })
                end)
            }):with(uiu.rightbound)
        }):with(uiu.fillWidth)
        presetsRow[#presetsRow + 1] = presetRow
    end

    return uie.column({
        uie.paneled.row({
            uie.button("Edit modpresets.txt", function()
                local root = config.installs[config.install].path
                utils.openFile(fs.joinpath(root, "Mods", "modpresets.txt"))
            end),
            uie.row({
                presetField,
                uie.button("Add preset", function(self)
                    local success = addPreset(preset)
                    if success then
                        self:getParent("modPresets"):close("OK")
                        scene.displayPresetsUI()
                    end
                end)
            }):with(uiu.rightbound)
        }):with(uiu.fillWidth),
        uie.scrollbox(
            uie.column(presetsRow):with(uiu.fillWidth)
        ):with(uiu.fillWidth):with(uiu.fillHeight(true)),

    }):with({
        clip = false,
        cacheable = false
    }):with(uiu.fillWidth):with(uiu.fillHeight(true))
end

-- shows the Mod Presets screen
function scene.displayPresetsUI()
    alert({
        title = "Mod presets",
        body = buildPresetsUI(),
        big = true,
        buttons = {
            {
                "Close"
            }
        },
        init = function (container)
            container.popup = false
        end

    }):as("modPresets")
end


-- reads olympusfavorites.txt and returns a list of all favorite mod names
-- if olympusfavorites.txt doesn't exist, it creates it and returns an empty list
local function readFavoritesList()
    local root = config.installs[config.install].path
    local contents = fs.read(fs.joinpath(root, "Mods", "olympusfavorites.txt"))

    if contents ~= nil then
        local modNames = {}
        for line in contents:gmatch("[^\r\n]+") do
            if line ~= "" and not line:find("^#") then
                table.insert(modNames, line)
            end
        end
        return modNames
    else -- create olympusfavorites.txt if it doesnt exist
        local content = [[
# This is the file used to save favorite mods in Olympus (NOT Everest). Edit at your own risk.
# File generated through the "Manage Installed Mods" > "Favorites" screen in Olympus

]]
        fs.write(fs.joinpath(root, "Mods", "olympusfavorites.txt"), content)
        return {}
    end
end


-- builds the Favorites screen and returns it, use scene.displayFavoritesUI() to show it
local function buildFavoritesUI()
    -- TODO: complete
    local favorites = readFavoritesList()
    local favoritesRow = {}
    local favorite = ""

    for i = 1, #favorites do
        if favorites ~= nil then
            local presetRow = uie.paneled.row({
                uie.label(favorites[i]):with(verticalCenter),
                uie.row({
                    uie.button("Add", function(self)
                        applyPreset(favorites[i], false)
                    end),
                    uie.button("Replace", function(self)
                        applyPreset(favorites[i], true)
                    end),
                    uie.button("Delete", function(self)
                        alert({
                            body = [[
    Are you sure that you want to delete ]] .. favorites[i] .. [[?]],
                            buttons = {
                                {
                                    "Delete",
                                    function(container)
                                        deletePreset(favorites[i])
                                        container:close("OK")
                                        self:getParent("favorites"):close("OK")
                                        scene.displayPresetsUI()
                                    end
                                },
                                { "Keep" }
                            }
                        })
                    end)
                }):with(uiu.rightbound)
        }):with(uiu.fillWidth)
            presetsRow[#presetsRow + 1] = presetRow

        end
    end

    return uie.column({
        uie.paneled.row({
            uie.button("Edit olympusfavorites.txt", function()
                local root = config.installs[config.install].path
                utils.openFile(fs.joinpath(root, "Mods", "olympusfavorites.txt"))
            end),
            uie.row({
                presetField,
                uie.button("Add preset", function(self)
                    local success = addPreset(preset)
                    if success then
                        self:getParent("favorites"):close("OK")
                        scene.displayPresetsUI()
                    end
                end)
            }):with(uiu.rightbound)
        }):with(uiu.fillWidth),
        uie.scrollbox(
            uie.column(presetsRow):with(uiu.fillWidth)
        ):with(uiu.fillWidth):with(uiu.fillHeight(true)),

    }):with({
        clip = false,
        cacheable = false
    }):with(uiu.fillWidth):with(uiu.fillHeight(true))
end

-- shows the Favorites screen
function scene.displayFavoritesUI()
    alert({
        title = "Favorites",
        body = buildFavoritesUI(),
        big = true,
        buttons = {
            {
                "Close"
            }
        },
        init = function (container)
            container.popup = false
        end

    }):as("favorites")
end

function scene.item(info)
    if not info then
        return nil
    end

    local item = uie.paneled.row({
        uie.label(getLabelTextFor(info)):as("title"),

        uie.row({
            uie.checkbox("Enabled", not info.IsBlacklisted, function(checkbox, newState)
                toggleMod(info, newState)
            end)
                :with(verticalCenter)
                :with({
                    enabled = false,
                    style = {
                        padding = 8
                    }
                })
                :as("toggleCheckbox"),

            uie.button(
                "Delete",
                function()
                    alert({
                        body = [[
Are you sure that you want to delete ]] .. fs.filename(info.Path) .. [[?
You will need to redownload the mod to use it again.
Tip: Disabling the mod prevents Everest from loading it, and is as efficient as deleting it to reduce lag.]],
                        buttons = {
                            {
                                "Delete",
                                function(container)
                                    fs.remove(info.Path)
                                    scene.reload()
                                    container:close("OK")
                                end
                            },
                            { "Keep" }
                        }
                    })
                end
            ):with({
                enabled = info.IsFile
            })

        }):with({
            clip = false,
            cacheable = false
        }):with(uiu.rightbound)

    }):with(uiu.fillWidth)

    return item
end

function scene.reload()
    local loadingID = scene.loadingID + 1
    scene.loadingID = loadingID

    scene.modlist = {}
    scene.modDependencies = {}
    scene.modDependents = {}
    scene.modPathToName = {}
    scene.onlyShowEnabledMods = false
    scene.search = ""

    return threader.routine(function()
        local loading = scene.root:findChild("loadingMods")
        if loading then
            loading:removeSelf()
        end

        local loading = uie.paneled.row({
            uie.label("Loading"),
            uie.spinner():with({
                width = 16,
                height = 16
            })
        }):with({
            clip = false,
            cacheable = false
        }):with(uiu.bottombound(16)):with(uiu.rightbound(16)):as("loadingMods")
        scene.root:addChild(loading)

        local list = root:findChild("mods")
        list.children = {}
        list:reflow()

        local root = config.installs[config.install].path

        list:addChild(uie.paneled.column({
            uie.row({
                uie.column({
                    uie.label("Manage Installed Mods", ui.fontBig),
                    uie.label("This menu allows you to enable, disable or delete the mods you currently have installed."),
                }),
                uie.buttonGreen("Update All", function()
                    modupdater.updateAllMods(root, nil, "all", scene.reload, true)
                end):with({ enabled = false }):with(uiu.rightbound):with(uiu.bottombound):as("updateAllButton"),
            }):with(uiu.fillWidth),
            uie.row({
                uie.button("Open mods folder", function()
                    utils.openFile(fs.joinpath(root, "Mods"))
                end),
                uie.button("Edit blacklist.txt", function()
                    utils.openFile(fs.joinpath(root, "Mods", "blacklist.txt"))
                end),
                uie.button("Mod presets", function()
                    scene.displayPresetsUI()
                end),
                uie.button("Favorites", function()
                    scene.displayFavoritesUI()
                end),
                uie.checkbox("Only show enabled mods", false, function(checkbox, newState)
                    scene.onlyShowEnabledMods = newState
                    refreshVisibleMods()
                end):with({ enabled = false }):with(verticalCenter):as("onlyShowEnabledModsCheckbox"),
                uie.row({
                    uie.label(""):with(verticalCenter):as("enabledModCountLabel"),
                    uie.button("Enable All", function()
                        enableAllMods()
                        writeBlacklist()
                    end):with({ enabled = false }):as("enableAllButton"),
                    uie.button("Disable All", function()
                        disableAllMods()
                        writeBlacklist()
                    end):with({ enabled = false }):as("disableAllButton"),
                }):with(uiu.rightbound)
            }):with(uiu.fillWidth)
        }):with(uiu.fillWidth))

        local searchField = uie.field("", function(self, value, prev)
            scene.search = string.lower(value)
            refreshVisibleMods()
        end):with({
            placeholder = "Search by file name, mod title or everest.yaml ID",
            enabled = false
        }):with(uiu.fillWidth)
        list:addChild(searchField)

        -- parameters: string root, bool readYamls, bool computeHashes, bool onlyUpdatable, bool excludeDisabled
        local task = sharp.modlist(root, true, false, false, false):result()

        local batch
        repeat
            batch = sharp.pollWaitBatch(task):result()
            if scene.loadingID ~= loadingID then
                break
            end
            local all = batch[3]
            for i = 1, #all do
                local info = all[i]
                if info ~= nil then
                    if scene.loadingID ~= loadingID then
                        break
                    end
                    local row = scene.item(info)
                    list:addChild(row)
                    scene.modlist[info.Name] = { info = info, row = row, visible = true }
                    scene.modPathToName[info.Path] = info.Name
                    if scene.modDependencies[info.Name] == nil then
                        scene.modDependencies[info.Name] = {}
                    end
                    for _, depName in ipairs(info.Dependencies or {}) do
                        table.insert(scene.modDependencies[info.Name], depName)
                        if scene.modDependents[depName] == nil then
                            scene.modDependents[depName] = {}
                        end
                        table.insert(scene.modDependents[depName], info.Name)
                    end
                else
                    print("modlist.reload encountered nil on poll", task)
                end
            end
        until (batch[1] ~= "running" and batch[2] == 0) or scene.loadingID ~= loadingID

        local status = sharp.free(task)
        if status == "error" then
            notify("An error occurred while loading the mod list.")
        end

        loading:removeSelf()

        -- make the enable/disable mod buttons/checkboxes usable now that the list was loaded
        scene.root:findChild("enableAllButton"):setEnabled(true)
        scene.root:findChild("disableAllButton"):setEnabled(true)
        scene.root:findChild("updateAllButton"):setEnabled(true)
        scene.root:findChild("onlyShowEnabledModsCheckbox"):setEnabled(true)
        searchField:setEnabled(true)
        for _, mod in pairs(scene.modlist) do
            mod.row:findChild("toggleCheckbox"):setEnabled(true)
        end

        updateEnabledModCountLabel()
    end)
end

function scene.enter()
    scene.reload()
end

function scene.leave()
    scene.loadingID = scene.loadingID + 1
end


return scene
