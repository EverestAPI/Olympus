local utils = require("utils")
local config = require("config")
local threader = require("threader")
local notify = require("notify")

local updater = {}

function updater.check()
    if updater.checking then
        return updater.checking
    end

    updater.checking = threader.routine(function()
        local idOld = tonumber((utils.load("version.txt") or "?"):match(".*-.*-(.*)-.*"))
        if not idOld then
            notify("Cannot determine currently running version of Olympus!")
        elseif idOld == 0 then
            return
        end

        local utilsAsync = threader.wrap("utils")
        local builds, buildsError = utilsAsync.downloadJSON("https://dev.azure.com/EverestAPI/Olympus/_apis/build/builds"):result()

        if not builds then
            notify("Error downloading builds list: " .. tostring(buildsError))
            return false
        end
        builds = builds.value

        for bi = 1, #builds do
            local build = builds[bi]

            if (build.status == "completed" or build.status == "succeeded") and (build.reason == "manual" or build.reason == "individualCI") then
                local id = build.id
                local branch = build.sourceBranch:gsub("refs/heads/", "")
                if id <= idOld then
                    break
                elseif config.updates:match(branch, 1, false) then
                    notify(string.format([[
There's a newer version of Olympus available.
Go to the options menu to update to %s]], build.buildNumber)) --, build.id, build.sourceVersion and build.sourceVersion:sub(1, 5) or "?????"))
                    break
                end
            end
        end

        updater.checking = nil
    end)
    return updater.checking
end

return updater
