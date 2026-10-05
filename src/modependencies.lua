local log = require('logger')('modependencies')

local fs = require("fs")
local sharp = require("sharp")

local modependencies = {}

local function collectMods(root)
    local task = sharp.modlist(root, true, false, false, false):result()

    local modsByName = {}
    local modDependencies = {}

    local batch
    repeat
        batch = sharp.pollWaitBatch(task):result()
        local all = batch[3]
        for i = 1, #all do
            local info = all[i]
            if info ~= nil and info.Name then
                if not modsByName[info.Name] then
                    modsByName[info.Name] = {}
                end
                table.insert(modsByName[info.Name], info)

                if not modDependencies[info.Name] then
                    modDependencies[info.Name] = {}
                end
                for _, depName in ipairs(info.Dependencies or {}) do
                    table.insert(modDependencies[info.Name], depName)
                end
            end
        end
    until batch[1] ~= "running" and batch[2] == 0

    local status = sharp.free(task):result()
    if status == "error" then
        log.warning("failed to scan mods to enable dependencies")
        return nil
    end

    return modsByName, modDependencies
end

local function findDisabledDependencies(modsByName, modDependencies, modName)
    local queue = {}
    local tried = {}
    local disabledDependencies = {}

    local function enqueue(deps)
        for _, depName in ipairs(deps or {}) do
            if not tried[depName] then
                tried[depName] = true
                table.insert(queue, depName)
            end
        end
    end

    enqueue(modDependencies[modName])

    while #queue > 0 do
        local depName = table.remove(queue, 1)
        local depOptions = modsByName[depName]
        if depOptions then
            local disabled = true
            for _, dep in ipairs(depOptions) do
                if not dep.IsBlacklisted then
                    disabled = false
                    break
                end
            end
            if disabled then
                disabledDependencies[depName] = true
            end
            enqueue(modDependencies[depName])
        end
    end

    return disabledDependencies
end

function modependencies.enableDependenciesOf(root, modName)
    local modsByName, modDependencies = collectMods(root)
    if not modsByName or not modsByName[modName] then
        return nil
    end

    local disabledDependencies = findDisabledDependencies(modsByName, modDependencies, modName)
    if not next(disabledDependencies) then
        return {}
    end

    local filenamesToEnable = {}
    for depName in pairs(disabledDependencies) do
        for _, dep in ipairs(modsByName[depName] or {}) do
            if dep.IsBlacklisted then
                filenamesToEnable[fs.filename(dep.Path)] = true
            end
        end
    end

    if not next(filenamesToEnable) then
        return {}
    end

    local blacklistPath = fs.joinpath(root, "Mods", "blacklist.txt")
    local contents = fs.read(blacklistPath)
    if not contents then
        return {}
    end

    local out = {}
    local changed = false
    for line in (contents .. "\n"):gmatch("(.-)\n") do
        line = line:gsub("\r$", "")
        local trimmed = line:match("^%s*(.-)%s*$")
        if trimmed ~= "" and not trimmed:match("^#") and filenamesToEnable[trimmed] then
            out[#out + 1] = "# " .. trimmed
            changed = true
        else
            out[#out + 1] = line
        end
    end

    if changed then
        fs.write(blacklistPath, table.concat(out, "\n"))
    end

    local enabledDependencies = {}
    for depName in pairs(disabledDependencies) do
        table.insert(enabledDependencies, depName)
    end
    table.sort(enabledDependencies)

    return enabledDependencies
end

return modependencies