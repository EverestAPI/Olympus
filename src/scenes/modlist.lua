local log = require('logger')('modlist')

local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local fs = require("fs")
local threader = require("threader")
local config = require("config")
local sharp = require("sharp")
local alert = require("alert")
local notify = require("notify")
local modinstaller = require("modinstaller")
local modupdater = require("modupdater")
local lang = require("lang")

local scene = {
    name = lang.get("mod_manager"),
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
    search = "",
    categoryFilter = "",
    selectedPreset = nil,
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
        body = text,
        buttons = {
            {
                lang.get("close"),
            },
        }
    })
end

local defaultPresetsContent = "# This is the file used to save mod presets.\n# File generated through the \"Manage Installed Mods\" screen in Olympus\n\n"

local function getPresetsPath()
    local root = config.installs[config.install].path
    return fs.joinpath(root, "Mods", "modpresets.txt")
end

local function readPresetsFile(create)
    local path = getPresetsPath()
    local contents = fs.read(path)

    if not contents then
        if not create then
            return nil
        end

        contents = defaultPresetsContent
        fs.write(path, contents)
    end

    contents = contents:gsub("\r\n", "\n"):gsub("\r", "\n")
    if contents ~= "" and contents:sub(-1) ~= "\n" then
        contents = contents .. "\n"
    end

    return contents
end

local function makeModSet(mods)
    local set = {}

    for _, filename in ipairs(mods) do
        set[filename] = true
    end

    return set
end

local function readPresets(create)
    local presets = {}
    local header = {}
    local currentPreset = nil
    local contents = readPresetsFile(create)

    if not contents then
        return presets, ""
    end

    for line in contents:gmatch("([^\n]*)\n") do
        if line:sub(1, 2) == "**" then
            currentPreset = {
                name = line:sub(3),
                mods = {},
                modSet = {}
            }
            presets[#presets + 1] = currentPreset

        elseif currentPreset then
            if line ~= "" and not line:match("^%s*#") and not currentPreset.modSet[line] then
                currentPreset.mods[#currentPreset.mods + 1] = line
                currentPreset.modSet[line] = true
            end

        else
            header[#header + 1] = line
        end
    end

    local headerText = table.concat(header, "\n")
    if headerText ~= "" then
        headerText = headerText .. "\n"
    end

    return presets, headerText
end

local function backupPresetsFile()
    local path = getPresetsPath()
    local backupPath = path .. ".bak"

    if fs.read(backupPath) then
        return
    end

    local contents = fs.read(path)
    if contents then
        fs.write(backupPath, contents)
    end
end

local function writePresets(presets, header)
    backupPresetsFile()

    local contents = header
    if not contents or contents == "" then
        contents = defaultPresetsContent
    end
    if contents:sub(-1) ~= "\n" then
        contents = contents .. "\n"
    end
    if contents:sub(-2) ~= "\n\n" then
        contents = contents .. "\n"
    end

    for _, preset in ipairs(presets) do
        contents = contents .. "**" .. preset.name .. "\n"

        local seen = {}
        for _, filename in ipairs(preset.mods) do
            if filename ~= "" and not seen[filename] then
                contents = contents .. filename .. "\n"
                seen[filename] = true
            end
        end
    end

    fs.write(getPresetsPath(), contents)
end

local function findPreset(presets, name)
    for i, preset in ipairs(presets) do
        if preset.name == name then
            return preset, i
        end
    end
end

local function getEnabledPresetMods()
    local mods = {}
    local seen = {}

    for _, mod in ipairs(scene.modlist) do
        if mod.row:findChild("toggleCheckbox"):getValue() then
            local filename = fs.filename(mod.info.Path)
            if not seen[filename] then
                mods[#mods + 1] = filename
                seen[filename] = true
            end
        end
    end

    return mods
end

local function getEnabledModSet()
    local set = {}
    local count = 0

    for _, filename in ipairs(getEnabledPresetMods()) do
        set[filename] = true
        count = count + 1
    end

    return set, count
end

local function getInstalledPresetModSet(preset)
    local root = config.installs[config.install].path
    local set = {}
    local count = 0
    local missing = {}

    for _, filename in ipairs(preset.mods) do
        if scene.modsByPath[fs.joinpath(root, "Mods", filename)] then
            set[filename] = true
            count = count + 1
        else
            missing[#missing + 1] = filename
        end
    end

    return set, count, missing
end

local function setsEqual(left, leftCount, right, rightCount)
    if leftCount ~= rightCount then
        return false
    end

    for key, _ in pairs(left) do
        if not right[key] then
            return false
        end
    end

    return true
end

local updatePresetStatusLabel

local function setPresetMods(name, mods, create)
    if not name then
        displayErrorMessage(lang.get("something_went_wrong_name_is_nil"))
        return false
    end
    if #name == 0 then
        displayErrorMessage(lang.get("preset_name_can_t_be_empty"))
        return false
    end

    local presets, header = readPresets()
    local preset = findPreset(presets, name)

    if not preset then
        if not create then
            displayErrorMessage(string.format(lang.get("preset_not_found"), name))
            return false
        end

        preset = { name = name, mods = {}, modSet = {} }
        presets[#presets + 1] = preset
    end

    preset.mods = {}
    preset.modSet = {}
    for _, filename in ipairs(mods) do
        if filename ~= "" and not preset.modSet[filename] then
            preset.mods[#preset.mods + 1] = filename
            preset.modSet[filename] = true
        end
    end

    writePresets(presets, header)
    scene.selectedPreset = name
    updatePresetStatusLabel()
    return true
end

local function renamePreset(oldName, newName)
    if not newName then
        displayErrorMessage(lang.get("something_went_wrong_name_is_nil"))
        return false
    end
    if #newName == 0 then
        displayErrorMessage(lang.get("preset_name_can_t_be_empty"))
        return false
    end

    local presets, header = readPresets()
    local preset = findPreset(presets, oldName)

    if not preset then
        displayErrorMessage(string.format(lang.get("preset_not_found"), oldName))
        return false
    end

    if oldName ~= newName and findPreset(presets, newName) then
        displayErrorMessage(string.format(lang.get("preset_already_exists"), newName))
        return false
    end

    preset.name = newName
    writePresets(presets, header)

    if scene.selectedPreset == oldName then
        scene.selectedPreset = newName
    end

    updatePresetStatusLabel()
    return true
end

local function getPresetStatusText()
    local presets = readPresets()
    local enabledSet, enabledCount = getEnabledModSet()

    if enabledCount == 0 then
        return lang.get("preset_none")
    end

    for _, preset in ipairs(presets) do
        local installedSet, installedCount = getInstalledPresetModSet(preset)
        if setsEqual(enabledSet, enabledCount, installedSet, installedCount) then
            scene.selectedPreset = preset.name
            return preset.name
        end
    end

    if scene.selectedPreset then
        local selected = findPreset(presets, scene.selectedPreset)
        if selected then
            local installedSet, installedCount = getInstalledPresetModSet(selected)
            local includesPreset = installedCount > 0

            for filename, _ in pairs(installedSet) do
                if not enabledSet[filename] then
                    includesPreset = false
                    break
                end
            end

            if includesPreset then
                return string.format(lang.get("preset_modified"), scene.selectedPreset)
            end

            return string.format(lang.get("preset_editing"), scene.selectedPreset)
        end
    end

    return lang.get("preset_custom")
end

updatePresetStatusLabel = function()
    local label = scene.root:findChild("presetStatusLabel")
    if label then
        label:setText(lang.get("preset") .. ": " .. getPresetStatusText())
    end
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
            and
            -- category filter
            (scene.categoryFilter == ""
                or (scene.categoryFilter == "nil" and mod.info.GameBananaCategory == nil)
                or scene.categoryFilter == mod.info.GameBananaCategory)

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
        lang.get("s_enabled_s"),
        enabledModCount == 0 and lang.get("no1") or enabledModCount,
        enabledModCount == 1 and lang.get("mod") or lang.get("mods")
    ))
    updatePresetStatusLabel()
end

-- gives the text for a given mod
local function getLabelTextFor(info)
    local themeColors = uie.modNameLabelColors().style
    local color = themeColors.normalColor

    local tooltip = nil
    if info.IsFavorite then
        color = themeColors.favoriteColor
        tooltip = lang.get("tooltip_favorite")
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
            tooltip = lang.get("tooltip_dependency_of_favorite")
        elseif isDependency then
            color = themeColors.dependencyColor
            tooltip = lang.get("tooltip_dependency")
        end
    end

    color = {color[1], color[2], color[3], info.IsBlacklisted and 0.5 or 1}
    tooltip = tooltip and { color, tooltip } or nil

    if info.Name then
        if info.GameBananaTitle then
            -- Maddie's Helping Hand
            -- MaxHelpingHand 1.4.5 ∙ Filename.zip
            return {
                color,
                info.GameBananaTitle .. "\n",
                themeColors.disabledColor,
                info.Name .. " " .. (info.Version or "?.?.?.?") .. " ∙ " .. fs.filename(info.Path)
            }, tooltip
        else
            -- MaxHelpingHand
            -- 1.4.5 ∙ Filename.zip
            return {
                color,
                info.Name .. "\n",
                themeColors.disabledColor,
                (info.Version or "?.?.?.?") .. " ∙ " .. fs.filename(info.Path)
            }, tooltip
        end
    else
        -- Filename.zip
        return {
            color,
            fs.filename(info.Path) .. "\n",
            themeColors.disabledColor,
            lang.get("no_mod_info_available")
        }, tooltip
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
    local label, tooltip = getLabelTextFor(mod.info)
    mod.row:findChild("title"):with({
        tooltipText = tooltip,
        tooltipWaitDuration = 0,
        interactive = tooltip and 1 or 0
    }):setText(label)
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
                lang.get("this_mod_depends_on_s_other_disabled_s_n"),
                numDependencies,
                numDependencies == 1 and lang.get("mod1") or lang.get("mods1"),
                numDependencies == 1 and lang.get("it") or lang.get("them")
            )),
            buttons = {
                {
                    lang.get("yes"),
                    function(container)
                        -- enable all the dependencies!
                        enableMods(dependenciesToToggle)
                        container:close()
                    end
                },
                {
                    lang.get("no")
                },
                {
                    lang.get("cancel"),
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
                lang.get("this_mod_depends_on_s_other_disabled_s_n"),
                numDependencies,
                numDependencies == 1 and lang.get("mod1") or lang.get("mods1"),
                numDependencies == 1 and lang.get("it") or lang.get("them")
            )),
            buttons = {
                {
                    lang.get("yes"),
                    function(container)
                        -- enable all the dependencies!
                        enableMods(dependenciesToToggle)
                        container:close()
                    end
                },
                {
                    lang.get("no")
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
                lang.get("s_other_s_no_longer_required_for_any_ena"),
                numDependencies,
                numDependencies == 1 and lang.get("mod_is") or lang.get("mods_are"),
                numDependencies == 1 and lang.get("it") or lang.get("them")
            )),
            buttons = {
                {
                    lang.get("yes"),
                    function(container)
                        -- disable them all!
                        disableMods(dependenciesThatCanBeDisabled, false)
                        container:close()
                    end
                },
                {
                    lang.get("no")
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
                lang.get("s_other_s_on_this_mod_ndo_you_want_to_di"),
                numDependents,
                numDependents == 1 and lang.get("mod_depends") or lang.get("mods_depend"),
                numDependents == 1 and lang.get("it") or lang.get("them")
            )),
            buttons = {
                {
                    lang.get("yes"),
                    function(container)
                        -- disable them all!
                        disableMods(dependentsToToggle, false)
                        container:close()

                        dependentsToToggle[mod.info.Name] = mod
                        checkEnabledDependenciesOfDisabledMods(dependentsToToggle)
                    end
                },
                {
                    lang.get("no"),
                    function(container)
                        container:close()
                        checkEnabledDependenciesOfDisabledMods({[mod.info.Name] = mod})
                    end
                },
                {
                    lang.get("cancel"),
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
        body = lang.get("are_you_sure_that_you_want_to_delete") .. fs.filename(info.Path) .. lang.get("you_will_need_to_redownload_the_mod_to_u"),
        buttons = {
            {
                lang.get("delete"),
                function(container)
                    fs.remove(info.Path)
                    scene.reload()
                    container:close(lang.get("ok"))
                end
            },
            { lang.get("keep") }
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

local function refreshPresetsUI(self)
    local container = self:getParent("modPresets")
    if container then
        container:close(lang.get("ok"))
        scene.displayPresetsUI()
    end
end

-- merges or switches to mods from preset
local function applyPreset(name, disableAll)
    local presets = readPresets()
    local preset = findPreset(presets, name)
    if not preset then
        displayErrorMessage(string.format(lang.get("preset_not_found"), name))
        return
    end

    if disableAll then
        for _, mod in pairs(scene.modsByPath) do
            if not mod.info.IsBlacklisted and not mod.info.IsFavorite then
                handleModEnabledStateChange(mod, false)
            end
        end
    end

    local root = config.installs[config.install].path
    local missingMods = {}

    for _, filename in ipairs(preset.mods) do
        local path = fs.joinpath(root, "Mods", filename)
        local mod = scene.modsByPath[path]
        if mod then
            if mod.info.IsBlacklisted then
                handleModEnabledStateChange(mod, true)
            end
        else
            missingMods[#missingMods + 1] = filename
        end
    end

    scene.selectedPreset = name
    updateEnabledModCountLabel()
    writeBlacklist()

    if #missingMods > 0 then
        displayErrorMessage(lang.get("some_mods_couldn_t_be_loaded_make_sure_t") .. table.concat(missingMods, ", "))
    end
end

-- deletes preset from modpresets.txt
local function deletePreset(name)
    if not name then
        displayErrorMessage(lang.get("something_went_wrong_deleted_preset_s_na"))
        return
    end
    if #name == 0 then
        displayErrorMessage(lang.get("something_went_wrong_deleted_preset_s_na"))
        return
    end

    local presets, header = readPresets()
    local _, index = findPreset(presets, name)

    if index then
        table.remove(presets, index)
        writePresets(presets, header)
    end

    if scene.selectedPreset == name then
        scene.selectedPreset = nil
    end

    updatePresetStatusLabel()
end

-- writes a new preset to a modpresets.txt, returns true if preset was created successfully and false if not
local function addPreset(name, parent)
    if not name then
        displayErrorMessage(lang.get("something_went_wrong_name_is_nil"))
        return false
    end
    if #name == 0 then
        displayErrorMessage(lang.get("preset_name_can_t_be_empty"))
        return false
    end

    local presets = readPresets()
    if findPreset(presets, name) then
        alert({
            body = lang.get("this_preset_already_exists_do_you_wish_t"),
            buttons = {
                {
                    lang.get("yes"),
                    function(container)
                        if setPresetMods(name, getEnabledPresetMods(), false) then
                            notify(string.format(lang.get("preset_updated"), name))
                            if parent then
                                parent:close(lang.get("ok"))
                                scene.displayPresetsUI()
                            end
                        end
                        container:close(lang.get("ok"))
                    end
                },
                {
                    lang.get("no"),
                },
            }
        })
        return false
    end

    if setPresetMods(name, getEnabledPresetMods(), true) then
        notify(string.format(lang.get("preset_created"), name))
        return true
    end

    return false
end

local function removeMissingPresetMods(name)
    local presets, header = readPresets()
    local preset = findPreset(presets, name)
    if not preset then
        displayErrorMessage(string.format(lang.get("preset_not_found"), name))
        return false
    end

    local root = config.installs[config.install].path
    local mods = {}
    local removed = 0

    for _, filename in ipairs(preset.mods) do
        if scene.modsByPath[fs.joinpath(root, "Mods", filename)] then
            mods[#mods + 1] = filename
        else
            removed = removed + 1
        end
    end

    if removed == 0 then
        notify(string.format(lang.get("no_missing_entries"), name))
        return false
    end

    preset.mods = mods
    preset.modSet = makeModSet(mods)
    writePresets(presets, header)
    updatePresetStatusLabel()
    notify(string.format(lang.get("preset_missing_removed"), removed, name))
    return true
end

local function displayRenamePresetUI(oldName, parent)
    local newName = oldName
    local field = uie.field(oldName, function(self, value, prev)
        newName = value
    end):with({
        width = 260,
        height = 24,
        placeholder = lang.get("new_preset_name"),
        enabled = true
    })

    alert({
        title = lang.get("preset_rename"),
        body = uie.column({
            field
        }),
        buttons = {
            {
                lang.get("preset_rename"),
                function(container)
                    if renamePreset(oldName, newName) then
                        notify(string.format(lang.get("preset_renamed"), oldName, newName))
                        container:close(lang.get("ok"))
                        if parent then
                            parent:close(lang.get("ok"))
                            scene.displayPresetsUI()
                        end
                    end
                end
            },
            { lang.get("cancel") }
        }
    })
end



-- builds the Mod Presets screen and returns it, use scene.displayPresetsUI() to show it
local function buildPresetsUI()
    local presets = readPresets(true)
    local presetsRow = {}
    local preset = ""

    local presetField = uie.field("", function(self, value, prev)
        preset = value
    end):with({
        width = 200,
        height = 24,
        placeholder = lang.get("new_preset_name"),
        enabled = true
    }):as("presetField")

    for _, presetInfo in ipairs(presets) do
        local presetName = presetInfo.name
        local _, _, missingMods = getInstalledPresetModSet(presetInfo)
        local meta = string.format(lang.get("preset_mod_count"), #presetInfo.mods)

        if #missingMods > 0 then
            meta = meta .. " - " .. string.format(lang.get("preset_missing_count"), #missingMods)
        end
        if scene.selectedPreset == presetName then
            meta = meta .. " - " .. lang.get("preset_selected")
        end

        local primaryActions = {
            uie.button(lang.get("preset_select"), function(self)
                applyPreset(presetName, true)
            end),
            uie.button(lang.get("preset_merge"), function(self)
                applyPreset(presetName, false)
            end)
        }

        local secondaryActions = {
            uie.button(lang.get("preset_update"), function(self)
                if setPresetMods(presetName, getEnabledPresetMods(), false) then
                    notify(string.format(lang.get("preset_updated"), presetName))
                    refreshPresetsUI(self)
                end
            end),
            uie.button(lang.get("preset_rename"), function(self)
                displayRenamePresetUI(presetName, self:getParent("modPresets"))
            end),
            uie.button(lang.get("delete"), function(self)
                alert({
                    body = lang.get("are_you_sure_that_you_want_to_delete") .. presetName .. lang.get("questionmark"),
                    buttons = {
                        {
                            lang.get("delete"),
                            function(container)
                                deletePreset(presetName)
                                container:close(lang.get("ok"))
                                refreshPresetsUI(self)
                            end
                        },
                        { lang.get("keep") }
                    }
                })
            end)
        }

        if #missingMods > 0 then
            table.insert(secondaryActions, 2, uie.button(lang.get("preset_remove_missing"), function(self)
                if removeMissingPresetMods(presetName) then
                    refreshPresetsUI(self)
                end
            end))
        end

        local presetRow = uie.paneled.row({
            uie.label(presetName .. "\n" .. meta):with(verticalCenter),
            uie.column({
                uie.row(primaryActions):with(uiu.rightbound),
                uie.row(secondaryActions):with(uiu.rightbound)
            }):with(uiu.rightbound)
        }):with(uiu.fillWidth)
        presetsRow[#presetsRow + 1] = presetRow
    end

    if #presetsRow == 0 then
        presetsRow[1] = uie.label(lang.get("no_presets"))
    end

    return uie.column({
        uie.paneled.row({
            uie.label(lang.get("create_preset_from_enabled")):with(verticalCenter),
            uie.row({
                presetField,
                uie.button(lang.get("add_preset"), function(self)
                    local success = addPreset(preset, self:getParent("modPresets"))
                    if success then
                        self:getParent("modPresets"):close(lang.get("ok"))
                        scene.displayPresetsUI()
                    end
                end)
            }):with(uiu.rightbound)
        }):with(uiu.fillWidth),
        uie.scrollbox(
            uie.column(presetsRow):with(uiu.fillWidth)
        )
            :with(uiu.hook({
                calcSize = function(orig, self, width, height)
                    uie.group.calcSize(self)
                end
            }))
            :with({
                maxHeight = 300
            })
            :with(uiu.fillWidth),
        uie.row({
            uie.button(lang.get("close"), function(self)
                self:getParent("modPresets"):close(lang.get("close"))
            end)
        }):with(uiu.rightbound)

    }):with({
        clip = false,
        cacheable = false
    }):with(uiu.fillWidth)
end

-- shows the Mod Presets screen
function scene.displayPresetsUI()
    alert({
        title = lang.get("mod_presets"),
        body = buildPresetsUI(),
        big = true,
        buttons = {},
        init = function (container)
            container.popup = false
        end

    }):as("modPresets")
end

local function addFilenamesToPreset(preset, filenames)
    local changed = 0

    for _, filename in ipairs(filenames) do
        if filename ~= "" and not preset.modSet[filename] then
            preset.mods[#preset.mods + 1] = filename
            preset.modSet[filename] = true
            changed = changed + 1
        end
    end

    return changed
end

local function presetHasDependency(preset, depOptions)
    for _, dep in ipairs(depOptions) do
        if preset.modSet[fs.filename(dep.info.Path)] then
            return true
        end
    end

    return false
end

local function collectMissingPresetDependencyMods(mod, presets)
    local dependencies = {}
    local queue = {}
    local tried = {}

    if not mod.info.Name then
        return dependencies
    end

    for _, depName in ipairs(scene.modDependencies[mod.info.Name] or {}) do
        if not tried[depName] then
            tried[depName] = true
            queue[#queue + 1] = depName
        end
    end

    while #queue > 0 do
        local depName = table.remove(queue, 1)
        local depOptions = scene.modsByName[depName]

        if depOptions then
            local missingFromAnyPreset = false
            for _, preset in ipairs(presets) do
                if not presetHasDependency(preset, depOptions) then
                    missingFromAnyPreset = true
                    break
                end
            end

            if missingFromAnyPreset and not dependencies[depName] then
                dependencies[depName] = depOptions[1]
            end
        end

        for _, subdep in ipairs(scene.modDependencies[depName] or {}) do
            if not tried[subdep] then
                tried[subdep] = true
                queue[#queue + 1] = subdep
            end
        end
    end

    return dependencies
end

local function getPresetFilenamesForMods(mods)
    local filenames = {}

    for _, mod in pairs(mods) do
        filenames[#filenames + 1] = fs.filename(mod.info.Path)
    end

    return filenames
end

local function promptPresetDependencies(mod, presets, withDependencies, withoutDependencies)
    local dependencies = collectMissingPresetDependencyMods(mod, presets)
    local numDependencies = dictLength(dependencies)

    if numDependencies == 0 then
        withoutDependencies()
        return
    end

    alert({
        body = getConfirmationMessageBodyForModToggling(dependencies, string.format(
            lang.get("this_mod_depends_on_s_other_s_add_to_preset"),
            numDependencies,
            numDependencies == 1 and lang.get("mod1") or lang.get("mods1"),
            numDependencies == 1 and lang.get("it") or lang.get("them")
        )),
        buttons = {
            {
                lang.get("add_dependencies"),
                function(container)
                    withDependencies(getPresetFilenamesForMods(dependencies))
                    container:close(lang.get("ok"))
                end
            },
            {
                lang.get("only_this_mod"),
                function(container)
                    withoutDependencies()
                    container:close(lang.get("ok"))
                end
            },
            { lang.get("cancel") }
        }
    })
end

local function enablePresetActionMods(filename, extraFilenames)
    local root = config.installs[config.install].path
    local mods = {}
    local mod = scene.modsByPath[fs.joinpath(root, "Mods", filename)]

    if mod then
        mods[#mods + 1] = mod
    end

    for _, modFilename in ipairs(extraFilenames or {}) do
        local extraMod = scene.modsByPath[fs.joinpath(root, "Mods", modFilename)]
        if extraMod then
            mods[#mods + 1] = extraMod
        end
    end

    enableMods(mods)

    if mods[1] then
        checkDisabledDependenciesOfEnabledMod(mods[1])
    end
end

local function setModInPreset(presetName, filename, add, extraFilenames)
    if not presetName then
        notify(lang.get("selected_preset_required"))
        return false
    end

    local presets, header = readPresets()
    local preset = findPreset(presets, presetName)

    if not preset then
        displayErrorMessage(string.format(lang.get("preset_not_found"), presetName))
        return false
    end

    if add then
        local filenames = { filename }
        for _, extraFilename in ipairs(extraFilenames or {}) do
            filenames[#filenames + 1] = extraFilename
        end

        local changed = addFilenamesToPreset(preset, filenames)
        if changed == 0 then
            enablePresetActionMods(filename, extraFilenames)
            notify(string.format(lang.get("mod_already_in_preset"), filename, presetName))
            return true
        end

        writePresets(presets, header)
        enablePresetActionMods(filename, extraFilenames)
        updatePresetStatusLabel()
        if #filenames > 1 then
            notify(string.format(lang.get("mod_and_deps_added_to_preset"), filename, presetName))
        else
            notify(string.format(lang.get("mod_added_to_preset"), filename, presetName))
        end
        return true
    end

    if not preset.modSet[filename] then
        notify(string.format(lang.get("mod_not_in_preset"), filename, presetName))
        return false
    end

    local mods = {}
    for _, modFilename in ipairs(preset.mods) do
        if modFilename ~= filename then
            mods[#mods + 1] = modFilename
        end
    end

    preset.mods = mods
    preset.modSet = makeModSet(mods)
    writePresets(presets, header)
    updatePresetStatusLabel()
    notify(string.format(lang.get("mod_removed_from_preset"), filename, presetName))
    return true
end

local function setModInAllPresets(filename, add, extraFilenames)
    local presets, header = readPresets()
    local changed = 0

    for _, preset in ipairs(presets) do
        if add then
            local filenames = { filename }
            for _, extraFilename in ipairs(extraFilenames or {}) do
                filenames[#filenames + 1] = extraFilename
            end
            if addFilenamesToPreset(preset, filenames) > 0 then
                changed = changed + 1
            end

        elseif not add and preset.modSet[filename] then
            local mods = {}
            for _, modFilename in ipairs(preset.mods) do
                if modFilename ~= filename then
                    mods[#mods + 1] = modFilename
                end
            end

            preset.mods = mods
            preset.modSet = makeModSet(mods)
            changed = changed + 1
        end
    end

    if changed == 0 then
        notify(lang.get("no_presets_to_update"))
        return false
    end

    writePresets(presets, header)
    if add then
        enablePresetActionMods(filename, extraFilenames)
    end
    updatePresetStatusLabel()

    if add then
        if extraFilenames and #extraFilenames > 0 then
            notify(string.format(lang.get("mod_and_deps_added_to_s_presets"), filename, changed))
        else
            notify(string.format(lang.get("mod_added_to_s_presets"), filename, changed))
        end
    else
        notify(string.format(lang.get("mod_removed_from_s_presets"), filename, changed))
    end

    return true
end

local function countPresetsWithMod(filename)
    local count = 0

    for _, preset in ipairs(readPresets()) do
        if preset.modSet[filename] then
            count = count + 1
        end
    end

    return count
end

function scene.displayModPresetUI(info)
    local filename = fs.filename(info.Path)
    local presets = readPresets()
    local selectedPreset = scene.selectedPreset and findPreset(presets, scene.selectedPreset)
    local mod = scene.modsByPath[info.Path]
    local container

    local function close()
        if container then
            container:close(lang.get("ok"))
        end
    end

    local function addToSelected(extraFilenames)
        if setModInPreset(scene.selectedPreset, filename, true, extraFilenames) then
            close()
        end
    end

    local function addToAll(extraFilenames)
        if setModInAllPresets(filename, true, extraFilenames) then
            close()
        end
    end

    local selectedActions = uie.row({
        uie.button(lang.get("add_to_selected_preset"), function()
            promptPresetDependencies(
                mod,
                { selectedPreset },
                addToSelected,
                function() addToSelected() end
            )
        end):with({ enabled = selectedPreset ~= nil }),
        uie.button(lang.get("remove_from_selected_preset"), function()
            if setModInPreset(scene.selectedPreset, filename, false) then
                close()
            end
        end):with({ enabled = selectedPreset ~= nil })
    })

    local allActions = uie.row({
        uie.button(lang.get("add_to_all_presets"), function()
            promptPresetDependencies(
                mod,
                presets,
                addToAll,
                function() addToAll() end
            )
        end),
        uie.button(lang.get("remove_from_all_presets"), function()
            local affected = countPresetsWithMod(filename)
            if affected == 0 then
                notify(lang.get("no_presets_to_update"))
                close()
                return
            end

            alert({
                body = string.format(lang.get("confirm_remove_mod_from_all_presets"), filename, affected),
                buttons = {
                    {
                        lang.get("remove"),
                        function(confirm)
                            setModInAllPresets(filename, false)
                            confirm:close(lang.get("ok"))
                            close()
                        end
                    },
                    { lang.get("keep") }
                }
            })
        end)
    })

    container = alert({
        title = lang.get("preset_actions"),
        body = uie.column({
            uie.label(filename),
            uie.label(lang.get("selected_preset") .. ": " .. (scene.selectedPreset or lang.get("preset_none"))),
            selectedActions,
            allActions
        }),
        buttons = {
            { lang.get("close") }
        }
    })
end

function scene.item(info)
    if not info then
        return nil
    end

    local label, tooltip = getLabelTextFor(info)
    local item = uie.paneled.row({
        uie.label(label):with({
            tooltipText = tooltip,
            tooltipWaitDuration = 0,
            interactive = tooltip and 1 or 0
        }):as("title"),

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

            uie.checkbox(lang.get("enabled"), not info.IsBlacklisted, function(checkbox, newState)
                toggleMod(info, newState)
            end)
                :with(verticalCenter)
                :with({
                    enabled = false
                })
                :as("toggleCheckbox"),

            uie.button(lang.get("preset"), function()
                scene.displayModPresetUI(info)
            end)
                :with({
                    enabled = false
                })
                :with(verticalCenter)
                :as("presetButton"),

            uie.button(lang.get("delete"), function()
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
    scene.categoryFilter = ""
    scene.selectedPreset = nil

    return threader.routine(function()
        local loading = scene.root:findChild("loadingMods")
        if loading then
            loading:removeSelf()
        end

        local loading = uie.paneled.row({
            uie.label(lang.get("loading")),
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
                    uie.label(lang.get("manage_installed_mods"), ui.fontBig),
                }),
                uie.label(""):with(verticalCenter):with(uiu.rightbound):as("presetStatusLabel"),
            }):with(uiu.fillWidth),
            uie.row({
                uie.button(lang.get("open_mods_folder"), function()
                    utils.openFile(fs.joinpath(root, "Mods"))
                end),
                uie.button(lang.get("install_mod_file"), function()
                    threader.routine(function()
                        local file = utils.promptForFile("zip")
                        if file then
                            modinstaller.install("file://" .. file)
                        end
                    end)
                end),
                uie.button(lang.get("edit_blacklist_txt"), function()
                    utils.openFile(fs.joinpath(root, "Mods", "blacklist.txt"))
                end),
                uie.button(lang.get("mod_presets"), function()
                    scene.displayPresetsUI()
                end),
                uie.buttonGreen(lang.get("update_all"), function()
                    modupdater.updateAllMods(root, nil, "all", scene.reload, true)
                end):with({ enabled = false }):with(uiu.rightbound):with(uiu.bottombound):as("updateAllButton"),
            }):with(uiu.fillWidth),
            uie.row({
                uie.label(lang.get("filter_list")):with(verticalCenter),
                uie.dropdown(
                    {{ text = lang.get("all_categories"), data = "" }},
                    function(self, value)
                        if value ~= scene.categoryFilter then
                            scene.categoryFilter = value
                            refreshVisibleMods()
                        end
                    end
                ):with({ enabled = false }):as("categoryFilterDropdown"),
                uie.checkbox(lang.get("only_show_enabled"), false, function(checkbox, newState)
                    scene.onlyShowEnabledMods = newState
                    refreshVisibleMods()
                end):with({ enabled = false }):with(verticalCenter):as("onlyShowEnabledModsCheckbox"),
                uie.checkbox(lang.get("only_show_favorites"), false, function(checkbox, newState)
                    scene.onlyShowFavoriteMods = newState
                    refreshVisibleMods()
                end):with({ enabled = false }):with(verticalCenter):as("onlyShowFavoriteModsCheckbox"),
                uie.row({
                    uie.label(""):with(verticalCenter):as("enabledModCountLabel"),
                    uie.button(lang.get("enable_all"), function()
                        enableMods(scene.modsByPath)
                        writeBlacklist()
                    end):with({ enabled = false }):as("enableAllButton"),
                    uie.button(lang.get("disable_all"), function()
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
            placeholder = lang.get("search_by_file_name_mod_title_or_everest"),
            enabled = false
        }):with(uiu.fillWidth)
        list:addChild(searchField)

        -- parameters: string root, bool readYamls, bool computeHashes, bool onlyUpdatable, bool excludeDisabled
        local task = sharp.modlist(root, true, false, false, false):result()

        local hasModsWithNoCategory = false
        local encounteredCategories = {}

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

                    -- add the category to the list if not present already
                    local category = info.GameBananaCategory
                    if category then
                        local found = false
                        for _, encounteredCategory in ipairs(encounteredCategories) do
                            if encounteredCategory == category then
                                found = true
                                break
                            end
                        end
                        if not found then
                            table.insert(encounteredCategories, category)
                        end
                    else
                        hasModsWithNoCategory = true
                    end
                else
                    log.warning("modlist.reload encountered nil on poll", task)
                end
            end
        until (batch[1] ~= "running" and batch[2] == 0) or scene.loadingID ~= loadingID

        local status = sharp.free(task)
        if status == "error" then
            notify(lang.get("an_error_occurred_while_loading_the_mod_"))
        end

        -- update the categories filter dropdown with: all, [encountered cats in alphabetical order], no category
        local categoryFilterOptions = {{ text = lang.get("all_categories"), data = "" }}
        table.sort(encounteredCategories)
        for _, category in ipairs(encounteredCategories) do
            table.insert(categoryFilterOptions, { text = category, data = category })
        end
        if hasModsWithNoCategory then
            table.insert(categoryFilterOptions, { text = lang.get("no_category"), data = "nil" })
        end
        local categoryFilterDropdown = scene.root:findChild("categoryFilterDropdown")
        categoryFilterDropdown._itemsCache = {}
        categoryFilterDropdown.data = categoryFilterOptions
        categoryFilterDropdown:setSelected(categoryFilterDropdown:getItem(1))
        categoryFilterDropdown:reflow()

        loading:removeSelf()

        -- make the enable/disable mod buttons/checkboxes usable now that the list was loaded
        scene.root:findChild("enableAllButton"):setEnabled(true)
        scene.root:findChild("disableAllButton"):setEnabled(true)
        scene.root:findChild("updateAllButton"):setEnabled(true)
        scene.root:findChild("onlyShowEnabledModsCheckbox"):setEnabled(true)
        scene.root:findChild("onlyShowFavoriteModsCheckbox"):setEnabled(true)
        scene.root:findChild("categoryFilterDropdown"):setEnabled(true)
        searchField:setEnabled(true)
        for _, mod in pairs(scene.modlist) do
            mod.row:findChild("toggleCheckbox"):setEnabled(true)
            mod.row:findChild("favoriteHeart"):setEnabled(true)
            mod.row:findChild("presetButton"):setEnabled(true)
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
