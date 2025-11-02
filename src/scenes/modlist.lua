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
    -- the list of displayed mods, in the order they are displayed (mod object = { info = modinfo, row = uirow, visible = bool })
    modlist = {},
    -- mod name -> list[mod object]
    -- used to handle multiple versions of the same mod
    modsByName = {},
    -- mod path -> mod object
    modsByPath = {},
    -- mod name -> list of mod names that this mod depends on
    modDependencies = {},
    -- mod name -> list of mod names that depend on this mod
    modDependents = {},
    -- mod path -> mod name
    modPathToName = {},
    onlyShowEnabledMods = false,
    onlyShowFavoriteMods = false,
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

-- writes the favorites to disk
local function writeFavorites()
    local contents = "# This is the favorite list. Lines starting with # are ignored.\n\n"

    for _, mod in pairs(scene.modlist) do
        if mod.row:findChild("favoriteHeart"):getValue() then
            contents = contents .. fs.filename(mod.info.Path) .. "\n"
        end
    end

    local root = config.installs[config.install].path
    fs.write(fs.joinpath(root, "Mods", "favorites.txt"), contents)
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
            -- only show favorite mods
            (not scene.onlyShowFavoriteMods
                or mod.info.IsFavorite)
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
    local themeColors = uie.modNameLabelColors().style
    local color = themeColors.normalColor

    if info.IsFavorite then
        color = themeColors.favoriteColor
    else
        local isDependencyOfFavorite = false
        local isDependency = false

        for _, dep in ipairs(scene.modDependents[info.Name] or {}) do
             for _, mod in pairs(scene.modsByName[dep] or {}) do
                if mod.info.IsFavorite then
                    isDependencyOfFavorite = true
                elseif not mod.info.IsBlacklisted then
                    isDependency = true
                end
            end
        end

        if isDependencyOfFavorite then
            color = themeColors.dependencyOfFavoriteColor
        elseif isDependency then
            color = themeColors.dependencyColor
        end
    end

    color = {color[1], color[2], color[3], info.IsBlacklisted and 0.5 or 1}

    if info.Name then
        if info.GameBananaTitle then
            -- Maddie's Helping Hand
            -- MaxHelpingHand 1.4.5 ∙ Filename.zip
            return {
                color,
                info.GameBananaTitle .. "\n",
                themeColors.disabledColor,
                info.Name .. " " .. (info.Version or "?.?.?.?") .. " ∙ " .. fs.filename(info.Path)
            }
        else
            -- MaxHelpingHand
            -- 1.4.5 ∙ Filename.zip
            return {
                color,
                info.Name .. "\n",
                themeColors.disabledColor,
                (info.Version or "?.?.?.?") .. " ∙ " .. fs.filename(info.Path)
            }
        end
    else
        -- Filename.zip
        return {
            color,
            fs.filename(info.Path) .. "\n",
            themeColors.disabledColor,
            "[No mod info available]"
        }
    end
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
        local depOptions = scene.modsByName[depName]
        if depOptions then
            -- if any of the options is enabled, we're good
            local disabled = true
            for _, dep in pairs(depOptions) do
                if not dep.info.IsBlacklisted then
                    disabled = false
                    break
                end
            end
            if disabled and not dependenciesToEnable[depName] then
                dependenciesToEnable[depName] = depOptions[1] -- can't really take an informed decision there...
            end
            for _, subdep in ipairs(scene.modDependencies[depName] or {}) do
                if not tried[subdep] then
                    tried[subdep] = true
                    table.insert(queue, subdep)
                end
            end
        end
    end

    return dependenciesToEnable
end

local function updateLabelTextForMod(mod)
    mod.row:findChild("title"):setText(getLabelTextFor(mod.info))
end

local function updateLabelTextForDependencies(mod)
    for _, depName in ipairs(scene.modDependencies[mod.info.Name] or {}) do
        local depOptions = scene.modsByName[depName] or {}
        for _, dep in pairs(depOptions) do
            updateLabelTextForMod(dep)
        end
    end
end

local function updateWarningButtonForMod(mod)
    if mod.info.IsBlacklisted then
        mod.row:findChild("warningButton"):setValue(false)
        mod.row:findChild("warningButton"):setEnabled(false)
    else
        local disabledDependencies = findDependenciesToEnable(mod)
        local hasDisabledDependencies = next(disabledDependencies) ~= nil
        mod.row:findChild("warningButton"):setValue(hasDisabledDependencies)
        mod.row:findChild("warningButton"):setEnabled(hasDisabledDependencies)
    end
end

local function updateWarningButtonForDependents(mod)
    for _, depName in ipairs(scene.modDependents[mod.info.Name] or {}) do
        local depOptions = scene.modsByName[depName] or {}
        for _, dep in pairs(depOptions) do
            updateWarningButtonForMod(dep)
        end
    end
end

local function handleModEnabledStateChange(mod, enabling)
    mod.row:findChild("toggleCheckbox"):setValue(enabling)
    mod.info.IsBlacklisted = not enabling
    updateLabelTextForMod(mod)
    updateLabelTextForDependencies(mod)
    updateWarningButtonForMod(mod)
    updateWarningButtonForDependents(mod)
end

-- enable mods on the UI
local function enableMods(mods)
    for _, mod in pairs(mods) do
        if mod.info.IsBlacklisted then
            handleModEnabledStateChange(mod, true)
        end
    end

    updateEnabledModCountLabel()
    writeBlacklist()
end

local function enableMod(mod)
    -- we could use mod.info.Name, but that might be nil for mods without everest.yaml, and enableMods() doesn't care
    enableMods({["name"] = mod})
end

-- disable mods on the UI, optionally including favorites
local function disableMods(mods, alsoDisableFavorites)
    for _, mod in pairs(mods) do
        if not mod.info.IsBlacklisted and (alsoDisableFavorites or not mod.info.IsFavorite) then
            handleModEnabledStateChange(mod, false)
        end
    end

    updateEnabledModCountLabel()
    writeBlacklist()
end

local function disableMod(mod)
    -- we could use mod.info.Name, but that might be nil for mods without everest.yaml, and disableMods() doesn't care
    -- this function should only be used for explicitly disabling one mod, so we should disable it even if it's a favorite
    disableMods({["name"] = mod}, true)
end

-- builds the confirmation message body for toggling mods, including a potentially-long list of mods in a scrollbox
local function getConfirmationMessageBodyForModToggling(dependenciesToToggle, message)
    local modList = ''
    -- TODO: this isn't alphabetized anymore (not sure if it was before?)
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

local function dictLength(dict)
    local count = 0
    for _, _ in pairs(dict) do
        count = count + 1
    end
    return count
end

-- checks whether the mod that was just enabled has dependencies that are disabled, and prompts to enable them if so
-- returns nothing if the mod has no name
local function checkDisabledDependenciesOfEnabledMod(mod)
    if not mod.info.Name then
        return
    end

    local dependenciesToToggle = findDependenciesToEnable(mod)
    local numDependencies = dictLength(dependenciesToToggle)

    if numDependencies > 0 then
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
                        enableMods(dependenciesToToggle)
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
                        container:close()
                    end
                }
            }
        })
    end
end

-- similar to the above checkDisabledDependenciesOfEnabledMod, but has no "Cancel" button and is meant to be called from the warning button
-- returns nothing if the mod has no name
local function checkDisabledDependenciesOfEnabledModFromWarning(info)
    if not info.Name then
        return
    end

    local mod = scene.modsByPath[info.Path]
    local dependenciesToToggle = findDependenciesToEnable(mod)
    local numDependencies = dictLength(dependenciesToToggle)

    if numDependencies > 0 then
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
                        enableMods(dependenciesToToggle)
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

-- lists all dependents of the given mod that should be disabled because they are going to miss it as a dependency, optionally excluding favorites
-- returns a table of dependent name -> mod object
local function findDependentsToDisable(mod, excludeFavorites)
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
        local depOptions = scene.modsByName[depName] or {}
        for _, dep in pairs(depOptions) do
            if not dep.info.IsBlacklisted and not (excludeFavorites and dep.info.IsFavorite) and not dependentsToDisable[depName] then
                dependentsToDisable[depName] = dep
            end
        end
        for _, subdep in ipairs(scene.modDependents[depName] or {}) do
            if not tried[subdep] then
                tried[subdep] = true
                table.insert(queue, subdep)
            end
        end
    end

    return dependentsToDisable
end

-- lists all dependencies of the given mods that can be disabled because no enabled mod depends on them anymore, excluding favorites
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
        local depOptions = scene.modsByName[depName] or {}
        for _, dep in pairs(depOptions) do
            if not dep.info.IsBlacklisted and not dep.info.IsFavorite and not dependenciesThatCanBeDisabled[depName] then
                -- check if any mod requires this mod, including favorites
                local enabledDependents = findDependentsToDisable(dep, false)
                if not next(enabledDependents) then
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
    end

    return dependenciesThatCanBeDisabled
end

-- checks whether enabled mods that were dependencies of now-disabled mods can be disabled as well, and prompts to disable them if so
local function checkEnabledDependenciesOfDisabledMods(newlyDisabledMods)
    local dependenciesThatCanBeDisabled = findDependenciesThatCanBeDisabled(newlyDisabledMods)
    local numDependencies = dictLength(dependenciesThatCanBeDisabled)

    if numDependencies > 0 then
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
                        disableMods(dependenciesThatCanBeDisabled, false)
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
-- returns nothing if the mod has no name
local function checkEnabledDependentsOfDisabledMod(mod)
    if not mod.info.Name then
        return
    end

    -- find dependents to disable, excluding favorites
    local dependentsToToggle = findDependentsToDisable(mod, true)
    local numDependents = dictLength(dependentsToToggle)

    if numDependents > 0 then
        alert({
            body = getConfirmationMessageBodyForModToggling(dependentsToToggle, string.format(
                "%s other %s on this mod.\nDo you want to disable %s as well?",
                numDependents,
                numDependents == 1 and "mod depends" or "mods depend",
                numDependents == 1 and "it" or "them"
            )),
            buttons = {
                {
                    "Yes",
                    function(container)
                        -- disable them all!
                        disableMods(dependentsToToggle, false)
                        container:close()

                        dependentsToToggle[mod.info.Name] = mod
                        checkEnabledDependenciesOfDisabledMods(dependentsToToggle)
                    end
                },
                {
                    "No",
                    function(container)
                        container:close()
                        checkEnabledDependenciesOfDisabledMods({[mod.info.Name] = mod})
                    end
                },
                {
                    "Cancel",
                    function(container)
                        -- re-enable the mod
                        enableMod(mod)
                        container:close()
                    end
                }
            }
        })
    else
        checkEnabledDependenciesOfDisabledMods({[mod.info.Name] = mod})
    end
end

-- called whenever a mod is enabled or disabled
local function toggleMod(info, newState)
    local mod = scene.modsByPath[info.Path]
    if newState then
        enableMod(mod)
        checkDisabledDependenciesOfEnabledMod(mod)
    else
        disableMod(mod)
        checkEnabledDependentsOfDisabledMod(mod)
    end
end

-- called when a mod is to be deleted, prompting the user for confirmation
local function deleteMod(info)
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

-- called whenever a mod is favorited or unfavorited
local function toggleFavorite(info, newState)
    local mod = scene.modsByPath[info.Path]
    if mod.info.IsFavorite ~= newState then
        mod.info.IsFavorite = newState
        updateLabelTextForMod(mod)
        updateLabelTextForDependencies(mod)
        writeFavorites()
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

-- disables all mods then enables mods from preset
local function applyPreset(name, disableAll)
    if disableAll then
        -- still don't disable favorites
        disableMods(scene.modsByPath, false)
    end
    name = name:gsub("%p", "%%%1") -- escape special characters
    local root = config.installs[config.install].path
    local contents = fs.read(fs.joinpath(root, "Mods", "modpresets.txt"))
    if not contents then
        return
    end
    local presetMods = contents:match("%*%*" .. name .. "\n([^*]*)") -- gets a string with all preset .zip mod file names
    local missingMods = ""

    for filename in presetMods:gmatch("([^\n]*)\n") do -- splits the string after every newline into mod filenames
        local path = fs.joinpath(root, "Mods", filename)
        local mod = scene.modsByPath[path]
        if mod then
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
    if not name then
        displayErrorMessage("Something went wrong, deleted preset's name is nil!")
        return
    end
    if #name == 0 then
        displayErrorMessage("Something went wrong, deleted preset's name is empty!")
        return
    end

    local root = config.installs[config.install].path
    local contents = fs.read(fs.joinpath(root, "Mods", "modpresets.txt"))
    if contents then
        name = name:gsub("%p", "%%%1") -- escape special characters
        contents = contents:gsub("%*%*(" .. name .. "\n[^*]*)","", 1)
        fs.write(fs.joinpath(root, "Mods", "modpresets.txt"), contents)
    end
end

-- reads modpresets.txt and returns a list of all preset names
local function readPresetsList()
    local root = config.installs[config.install].path
    local contents = fs.read(fs.joinpath(root, "Mods", "modpresets.txt"))

    if contents then
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
    if not name then
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
    if names then
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

function scene.item(info)
    if not info then
        return nil
    end

    local item = uie.paneled.row({
        uie.label(getLabelTextFor(info)):as("title"),

        uie.row({
            uie.warning(false, function(warning, newState)
                checkDisabledDependenciesOfEnabledModFromWarning(info)
            end)
                :with(verticalCenter)
                :with({
                    enabled = false
                })
                :as("warningButton"),

            uie.heart(info.IsFavorite, function(heart, newState)
                toggleFavorite(info, newState)
            end)
                :with(verticalCenter)
                :with({
                    enabled = false
                })
                :as("favoriteHeart"),

            uie.checkbox("Enabled", not info.IsBlacklisted, function(checkbox, newState)
                toggleMod(info, newState)
            end)
                :with(verticalCenter)
                :with({
                    enabled = false
                })
                :as("toggleCheckbox"),

            uie.button("Delete", function()
                deleteMod(info)
            end)
                :with({
                    enabled = info.IsFile
                })
                :with(verticalCenter)

        }):with({
            clip = false,
            cacheable = false,
            style = {
                spacing = 16
            }
        }):with(uiu.rightbound)
        :with(uiu.fillHeight)

    }):with(uiu.fillWidth)

    return item
end

function scene.reload()
    local loadingID = scene.loadingID + 1
    scene.loadingID = loadingID

    scene.modlist = {}
    scene.modsByName = {}
    scene.modsByPath = {}
    scene.modDependencies = {}
    scene.modDependents = {}
    scene.modPathToName = {}
    scene.onlyShowEnabledMods = false
    scene.onlyShowFavoriteMods = false
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
                uie.checkbox("Only show enabled", false, function(checkbox, newState)
                    scene.onlyShowEnabledMods = newState
                    refreshVisibleMods()
                end):with({ enabled = false }):with(verticalCenter):as("onlyShowEnabledModsCheckbox"),
                uie.checkbox("Only show favorites", false, function(checkbox, newState)
                    scene.onlyShowFavoriteMods = newState
                    refreshVisibleMods()
                end):with({ enabled = false }):with(verticalCenter):as("onlyShowFavoriteModsCheckbox"),
                uie.row({
                    uie.label(""):with(verticalCenter):as("enabledModCountLabel"),
                    uie.button("Enable All", function()
                        enableMods(scene.modsByPath)
                        writeBlacklist()
                    end):with({ enabled = false }):as("enableAllButton"),
                    uie.button("Disable All", function()
                        -- don't disable favorites
                        disableMods(scene.modsByPath, false)
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

                    local mod = { info = info, row = row, visible = true }
                    table.insert(scene.modlist, mod)
                    scene.modsByPath[info.Path] = mod

                    if info.Name then
                        if not scene.modsByName[info.Name] then
                            scene.modsByName[info.Name] = {}
                        end
                        table.insert(scene.modsByName[info.Name], mod)
                        if not scene.modDependencies[info.Name] then
                            scene.modDependencies[info.Name] = {}
                        end
                        for _, depName in ipairs(info.Dependencies or {}) do
                            table.insert(scene.modDependencies[info.Name], depName)
                            if not scene.modDependents[depName] then
                                scene.modDependents[depName] = {}
                            end
                            table.insert(scene.modDependents[depName], info.Name)
                        end
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
        scene.root:findChild("onlyShowFavoriteModsCheckbox"):setEnabled(true)
        searchField:setEnabled(true)
        for _, mod in pairs(scene.modlist) do
            mod.row:findChild("toggleCheckbox"):setEnabled(true)
            mod.row:findChild("favoriteHeart"):setEnabled(true)
            updateLabelTextForMod(mod)
            updateWarningButtonForMod(mod)
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
