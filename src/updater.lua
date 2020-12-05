local threader = require("threader")
local alert = require("alert")

local updater = {}

function updater.check()
    if updater.checking then
        return updater.checking
    end

    updater.checking = threader.routine(function()
        local utilsAsync = threader.wrap("utils")
        local builds, buildsError = utilsAsync.downloadJSON("https://dev.azure.com/EverestAPI/Olympus/_apis/build/builds"):result()

        if not builds then
            alert("Error downloading builds list: " .. tostring(buildsError))
            return false
        end
        builds = builds.value

        
    end)
    return updater.checking
end

return updater
