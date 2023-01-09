local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local fs = require("fs")
local threader = require("threader")
local scener = require("scener")
local config = require("config")
local sharp = require("sharp")
local alert = require("alert")
local notify = require("notify")

local scene = {
    name = "Mod Manager",
    modlist = {}
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

        if self.isNeeded and self.height < 20 then
            -- back up the values used for rendering
            self.renderY = self.realY
            self.renderHeight = self.height
            self.resizeRender = true

            -- make the handle bigger so that it's easier to hit with the mouse!
            local expandBy = 20 - self.height
            self.height = 20
            self.realY = uiu.round(self.realY - (expandBy / 2))
        else
            self.resizeRender = false
        end
    end,

    draw = function(orig, self)
        if self.resizeRender then
            local origY = self.realY
            local origHeight = self.height

            -- change the dimensions to their rendering values
            self.realY = self.renderY
            self.height = self.renderHeight

            -- render
            orig(self)

            -- change the dimensions back
            self.realY = origY
            self.height = origHeight
        else
            orig(self)
        end
    end
})

scene.root = root

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
    end
end

-- disable a mod on the UI (writeBlacklist needs to be called afterwards to write the change to disk)
local function disableMod(row, info)
    if not info.IsBlacklisted then
        row:findChild("toggleCheckbox"):setValue(false)
        info.IsBlacklisted = true
        row:findChild("title"):setText(getLabelTextFor(info))
        updateEnabledModCountLabel()
    end
end

-- called whenever a mod is enabled or disabled
local function toggleMod(info, checkbox)
    -- find the UI row associated to this mod info
    local row
    for i, mod in ipairs(scene.modlist) do
        if info == mod.info then
            row = mod.row
            break
        end
    end

    if checkbox:getValue() then
        -- enable the mod that was just checked
        enableMod(row, info)
        writeBlacklist()

        -- check if the mod has disabled dependencies
        local dependenciesToToggle = {}
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

            if foundDependency ~= nil and foundDependency.info.IsBlacklisted then
                table.insert(dependenciesToToggle, foundDependency)
            end
        end

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
    else
        -- disable the mod that was just unchecked
        disableMod(row, info)
        writeBlacklist()

        -- check if there are enabled mods that depend on the one we are disabling
        local dependenciesToToggle = {}
        for i, mod in ipairs(scene.modlist) do
            if not mod.info.IsBlacklisted then
                for j, dep in ipairs(mod.info.Dependencies) do
                    if info.Name == dep then
                        table.insert(dependenciesToToggle, mod)
                    end
                end
            end
        end

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

function scene.item(info)
    if not info then
        return nil
    end

    local item = uie.paneled.row({
        uie.label(getLabelTextFor(info)):as("title"),

        uie.row({
            uie.checkbox("Enabled", not info.IsBlacklisted, function(checkbox)
                toggleMod(info, checkbox)
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
                enabled = info.IsZIP
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
            uie.label("Manage Installed Mods", ui.fontBig),
            uie.label("This menu allows you to enable, disable or delete the mods you currently have installed."),
            uie.row({
                uie.button("Open mods folder", function()
                    utils.openFile(fs.joinpath(root, "Mods"))
                end),
                uie.button("Edit blacklist.txt", function()
                    utils.openFile(fs.joinpath(root, "Mods", "blacklist.txt"))
                end),
                uie.row({
                    uie.label(""):with(verticalCenter):as("enabledModCountLabel"),
                    uie.button("Enable All", function()
                        for i, mod in ipairs(scene.modlist) do
                            enableMod(mod.row, mod.info)
                        end
                        writeBlacklist()
                    end):with({ enabled = false }):as("enableAllButton"),
                    uie.button("Disable All", function()
                        for i, mod in ipairs(scene.modlist) do
                            disableMod(mod.row, mod.info)
                        end
                        writeBlacklist()
                    end):with({ enabled = false }):as("disableAllButton"),
                }):with(uiu.rightbound)
            }):with(uiu.fillWidth)
        }):with(uiu.fillWidth))

        local searchField = uie.field("", function(self, value, prev)
            value = string.lower(value)

            local modIndex = 3 -- the 2 first elements are the header, and the search field

            for i, mod in ipairs(scene.modlist) do
                -- a mod is visible if the search is part of the filename or mod ID (case-insensitive) or if there is no search at all
                local newVisible = value == ""
                    or string.find(string.lower(fs.filename(mod.info.Path)), value, 1, true)
                    or (mod.info.Name and string.find(string.lower(mod.info.Name), value, 1, true))

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
        end):with({
            placeholder = "Search by file name",
            enabled = false
        }):with(uiu.fillWidth)
        list:addChild(searchField)

        local task = sharp.modlist(root):result()

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
        searchField:setEnabled(true)

        for i, mod in ipairs(scene.modlist) do
            mod.row:findChild("toggleCheckbox"):setEnabled(true)
        end

        updateEnabledModCountLabel()
    end)
end

function scene.enter()
    scene.reload()
end


return scene
