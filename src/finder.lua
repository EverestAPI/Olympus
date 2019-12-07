local fs = require("fs")
local utils = require("utils")
local registry = require("registry")
require("love.system")

local finder = {}


function finder.findSteamRoot()
    local userOS = love.system.getOS()

    if userOS == "Windows" then
        local steam =
            registry.getKey([[HKLM\SOFTWARE\WOW6432Node\Valve\Steam\InstallPath]]) or
            registry.getKey([[HKLM\SOFTWARE\Valve\Steam\InstallPath]])

        return fs.isDirectory(steam)

    elseif userOS == "OS X" then
        return fs.isDirectory(fs.joinpath(os.getenv("HOME"), "Library", "Application Support", "Steam"))

    elseif userOS == "Linux" then
        local paths = {
            fs.joinpath(os.getenv("HOME"), ".local", "share", "Steam"),
            fs.joinpath(os.getenv("HOME"), ".steam", "steam"),
        }

        for i = 1, #paths do
            local path = paths[i]
            if fs.isDirectory(path) then
                return path
            end
        end

        return false
    end
end

function finder.findSteamCommon(root)
    local commons = {
        fs.joinpath(root, "SteamApps", "common"),
        fs.joinpath(root, "steamapps", "common"),
    }

    for i = 1, #commons do
        local path = commons[i]
        if fs.isDirectory(path) then
            return path
        end
    end
end

function finder.findSteamLibraries()
    local libraries = {}

    local steam = finder.findSteamRoot()
    if not steam then
        return libraries
    end

    local common = finder.findSteamCommon(steam)
    if common then
        libraries[#libraries + 1] = common
    end

    local config = fs.isFile(fs.joinpath(steam, "config", "config.vdf"))
    if not config then
        return libraries
    end

    local fh = io.open(config, "rb")
    if not fh then
        return libraries
    end

    config = fh:read("*a")
    fh:close()

    for path in config:gmatch([[BaseInstallFolder[^"]*"%s*("[^"]*")]]) do
        path = utils.fromJSON(path)
        path = finder.findSteamCommon(path)
        if path then
            libraries[#libraries + 1] = path
        end
    end

    return libraries
end

function finder.findSteamInstalls(id)
    local list = {}

    local libraries = finder.findSteamLibraries()
    for i = 1, #libraries do
        local path = libraries[i]
        path = fs.joinpath(path, "Celeste")

        if fs.isDirectory(path) then
            list[#list + 1] = {
                type = "steam",
                path = path
            }
        end
    end

    return list
end


function finder.findEpicRoot()
    local userOS = love.system.getOS()

    if userOS == "Windows" then
        local epic =
            registry.getKey([[HKLM\SOFTWARE\WOW6432Node\Epic Games\EpicGamesLauncher\AppDataPath]]) or
            registry.getKey([[HKLM\SOFTWARE\Epic Games\EpicGamesLauncher\AppDataPath]])

        return fs.isDirectory(epic)

    elseif userOS == "OS X" then
        return false

    elseif userOS == "Linux" then
        return false
    end
end


function finder.findEpicInstalls(id)
    local list = {}

    local epic = finder.findEpicRoot()
    if not epic then
        return list
    end

    local manifests = fs.joinpath(epic, "Manifests")
    for manifest in fs.dir(manifests) do
        if not manifest:match("%.item$") then
            goto next
        end

        manifest = fs.joinpath(manifests, manifest)
        local data = utils.fromJSON(fs.read(manifest))

        if data.DisplayName ~= id then
            goto next
        end

        local path = data.InstallLocation
        if fs.isDirectory(path) then
            list[#list + 1] = {
                type = "epic",
                path = path
            }
        end

        ::next::
    end

    return list
end


function finder.findAll()
    return {
        table.unpack(finder.findSteamInstalls("Celeste")),
        table.unpack(finder.findEpicInstalls("Celeste")),
    }
end

return finder
