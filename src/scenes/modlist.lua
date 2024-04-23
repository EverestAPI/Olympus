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
    modlist = {},
    onlyShowEnabledMods = false,
    search = "",
    preset =  ""
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
    for i, mod in ipairs(scene.modlist) do
        if mod.info.Path == path then
            return mod
        end
    end
    return nil
end

-- creates alert with error message
local function displayErrorMessage(text)
    alert({
        body =   string.format(text),
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

    for i, mod in ipairs(scene.modlist) do
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

    for i, mod in ipairs(scene.modlist) do
        -- a mod is visible if the search is part of the filename or mod ID (case-insensitive) or if there is no search at all
        local newVisible =
            -- only show enabled mods
            (not scene.onlyShowEnabledMods
                or not mod.info.IsBlacklisted)
            and
            -- search terms
            (scene.search == ""
                or string.find(string.lower(fs.filename(mod.info.Path)), scene.search, 1, true)
                or (mod.info.Name and string.find(string.lower(mod.info.Name), scene.search, 1, true)))

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

    for i, mod in ipairs(scene.modlist) do
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
    return { info.IsBlacklisted and { 1, 1, 1, 0.5 } or { 1, 1, 1, 1 }, fs.filename(info.Path) .. "\n" .. (info.Name or "?"), { 1, 1, 1, 0.5 }, " ∙ " .. (info.Version or "?.?.?.?") }
end

-- enable a mod on the UI (writeBlacklist needs to be called afterwards to write the change to disk)
local function enableMod(row, info)
    if info.IsBlacklisted then
        row:findChild("toggleCheckbox"):setValue(true)
        info.IsBlacklisted = false
        row:findChild("title"):setText(getLabelTextFor(info))
        updateEnabledModCountLabel()

        if scene.onlyShowEnabledMods then
            refreshVisibleMods()
        end
    end
end

-- disable a mod on the UI (writeBlacklist needs to be called afterwards to write the change to disk)
local function disableMod(row, info)
    if not info.IsBlacklisted then
        row:findChild("toggleCheckbox"):setValue(false)
        info.IsBlacklisted = true
        row:findChild("title"):setText(getLabelTextFor(info))
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

-- recursively lists all dependencies of the given mod that should be enabled for this mod to work
local function findDependenciesToEnableRecursively(info, dependenciesFoundSoFar)
    if not info.Dependencies then
        -- the mod has no dependencies to check (probably missing or corrupted everest.yaml)
        return dependenciesFoundSoFar
    end

    for i, dep in ipairs(info.Dependencies) do
        local foundDependency = nil

        for j, mod in ipairs(scene.modlist) do
            if mod.info.Name == dep and (foundDependency == nil or not mod.info.IsBlacklisted) then
                foundDependency = mod

                if not mod.info.IsBlacklisted then
                    -- stop looking, we found an enabled mod that has the right mod ID
                    break
                end
            end
        end

        if foundDependency ~= nil and foundDependency.info.IsBlacklisted and not contains(dependenciesFoundSoFar, foundDependency) then
            -- add this dependency to the list of mods to enable, and check if we should enable any of its dependencies as well
            table.insert(dependenciesFoundSoFar, foundDependency)
            dependenciesFoundSoFar = findDependenciesToEnableRecursively(foundDependency.info, dependenciesFoundSoFar)
        end
    end

    return dependenciesFoundSoFar
end

-- checks whether the mod that was just enabled has dependencies that are disabled, and prompts to enable them if so
local function checkDisabledDependenciesOfEnabledMod(info, row)
    local dependenciesToToggle = findDependenciesToEnableRecursively(info, {})

    if next(dependenciesToToggle) ~= nil then
        alert({
            body = string.format(
                "This mod depends on %s other disabled %s.\nDo you want to enable %s as well?",
                #dependenciesToToggle,
                #dependenciesToToggle == 1 and "mod" or "mods",
                #dependenciesToToggle == 1 and "it" or "them"
            ),
            buttons = {
                {
                    "Yes",
                    function(container)
                        -- enable all the dependencies!
                        for k, depToToggle in ipairs(dependenciesToToggle) do
                            enableMod(depToToggle.row, depToToggle.info)
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
                        disableMod(row, info)
                        writeBlacklist()
                        container:close()
                    end
                }
            }
        })
    end
end

-- recursively lists all dependents of the given mod that should be disabled because they are going to miss it as a dependency
local function findDependenciesToDisableRecursively(info, dependenciesFoundSoFar)
    for i, mod in ipairs(scene.modlist) do
        if not mod.info.IsBlacklisted and mod.info.Dependencies then
            for j, dep in ipairs(mod.info.Dependencies) do
                if info.Name == dep and not contains(dependenciesFoundSoFar, mod) then
                    -- add this dependency to the list of mods to disable, and check if we should disable any of the mods depending on it as well
                    table.insert(dependenciesFoundSoFar, mod)
                    dependenciesFoundSoFar = findDependenciesToDisableRecursively(mod.info, dependenciesFoundSoFar)
                end
            end
        end
    end

    return dependenciesFoundSoFar
end

-- checks whether enabled mods depend on the mod that was just disabled, and prompts to disable them if so
local function checkEnabledModsDependingOnDisabledMod(info, row)
    local dependenciesToToggle = findDependenciesToDisableRecursively(info, {})

    if next(dependenciesToToggle) ~= nil then
        alert({
            body = string.format(
                "%s other %s on this mod.\nDo you want to disable %s as well?",
                #dependenciesToToggle,
                #dependenciesToToggle == 1 and "mod depends" or "mods depend",
                #dependenciesToToggle == 1 and "it" or "them"
            ),
            buttons = {
                {
                    "Yes",
                    function(container)
                        -- disable them all!
                        for k, depToToggle in ipairs(dependenciesToToggle) do
                            disableMod(depToToggle.row, depToToggle.info)
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
                        -- re-enable the mod
                        enableMod(row, info)
                        writeBlacklist()
                        container:close()
                    end
                }
            }
        })
    end
end

-- called whenever a mod is enabled or disabled
local function toggleMod(info, newState)
    -- find the UI row associated to this mod info
    local row
    for i, mod in ipairs(scene.modlist) do
        if info == mod.info then
            row = mod.row
            break
        end
    end

    if newState then
        enableMod(row, info)
        writeBlacklist()
        checkDisabledDependenciesOfEnabledMod(info, row)
    else
        disableMod(row, info)
        writeBlacklist()
        checkEnabledModsDependingOnDisabledMod(info, row)
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

-- loops thorugh modlist and calls disableMod() on every
local function disableAllMods()
    for i, mod in ipairs(scene.modlist) do
        disableMod(mod.row, mod.info)
    end
end

-- disables all mods then enables mods from preset
local function applyPreset(name)
    disableAllMods()
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
        local mod = findModByPath(path);
        if mod ~= nil then
            enableMod(mod.row, mod.info)
        else
            missingMods = missingMods .. filename .. ", "
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
        fs.write(fs.joinpath(root, "Mods", "modpresets.txt"), "# This is the mod presets.\n# File generated through the \"Manage Installed Mods\" screen in Olympus\n\n")
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

    --check if name is already taken
    local names = readPresetsList()
    if names ~= nil then
        for i, n in ipairs(names) do
            if n == name then
               displayErrorMessage("This preset already exists!")
               return false
            end
        end
    end

    local root = config.installs[config.install].path
    local contents = fs.read(fs.joinpath(root, "Mods", "modpresets.txt"))
    contents = contents .. "**" .. name .. "\n"
    
    for i, mod in ipairs(scene.modlist) do
        if mod.row:findChild("toggleCheckbox"):getValue() then
            contents = contents .. fs.filename(mod.info.Path) .. "\n"
        end
    end

    fs.write(fs.joinpath(root, "Mods", "modpresets.txt"), contents)
    return true
end

local presetField = uie.field("", function(self, value, prev)
    scene.preset = value
end):with({
    width = 200,
    height = 24,
    placeholder = "New preset name",
    enabled = false

})

scene.modPresets = nil

-- used to create Mod presets screen, use updatePresetsUI() before calling
local function displayPresetsUI() 
    alert({
        title = "Mod presets",
        body =  scene.modPresets,
        big = true,
        buttons = {
            {
                "Close"
            }
        }

    }):as("modPresets")
end

-- Prepares scene.modPresets as body for Mod presets screen 
local function updatePresetsUI()
    local presets = readPresetsList()
    local presetsRow = {}

    for i = 1, #presets do
        if presets ~= nil then
            local presetRow = uie.paneled.row({
                uie.label(presets[i]):with(verticalCenter),
                uie.row({                                  
                    uie.button("Load", function(self)
                        applyPreset(presets[i])
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
                                        updatePresetsUI()
                                        displayPresetsUI()
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
    
    scene.modPresets = uie.column({
        uie.paneled.row({
            uie.button("Edit modpresets.txt", function()
                local root = config.installs[config.install].path
                utils.openFile(fs.joinpath(root, "Mods", "modpresets.txt"))
            end),
            uie.row({
                presetField,
                uie.button("Add preset", function(self)
                    local success = addPreset(scene.preset)
                    if success then
                        self:getParent("modPresets"):close("OK")
                        updatePresetsUI()
                        displayPresetsUI()
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
    scene.onlyShowEnabledMods = false
    scene.search = ""
    scene.preset = ""



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
                    modupdater.updateAllMods(root, nil, "all", scene.reload)
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
                    updatePresetsUI()
                    displayPresetsUI()
                end), 
                uie.checkbox("Only show enabled mods", false, function(checkbox, newState)
                    scene.onlyShowEnabledMods = newState
                    refreshVisibleMods()
                end):with({ enabled = false }):with(verticalCenter):as("onlyShowEnabledModsCheckbox"),
                uie.row({
                    uie.label(""):with(verticalCenter):as("enabledModCountLabel"),
                    uie.button("Enable All", function()
                        for i, mod in ipairs(scene.modlist) do
                            enableMod(mod.row, mod.info)
                        end
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
            placeholder = "Search by file name or everest.yaml ID",
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
                    table.insert(scene.modlist, { info = info, row = row, visible = true })
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
        presetField:setEnabled(true)
        for i, mod in ipairs(scene.modlist) do
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
