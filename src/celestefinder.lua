local fs = require("fs")
local utils = require("utils")
local registry = require("registry")
require("love.system")

local celestefinder = {}


function celestefinder.getSteamRoot()
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

function celestefinder.getSteamCommon(root)
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

function celestefinder.getSteamLibraries()
    local libraries = {}

    local steam = celestefinder.getSteamRoot()
    if not steam then
        return libraries
    end

    local common = celestefinder.getSteamCommon(steam)
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
        path = celestefinder.getSteamCommon(path)
        if path then
            libraries[#libraries + 1] = path
        end
    end

    return libraries
end


function celestefinder.findAll()
    local list = {}

    list[#list + 1] = {
        name = "NO NAME",
        type = "dummy",
        path = "/oh/no"
    }

    local libraries = celestefinder.getSteamLibraries()
    for i = 1, #libraries do
        local path = libraries[i]
        path = fs.joinpath(path, "Celeste")
        if fs.isDirectory(path) then
            list[#list + 1] = {
                name = "uhh",
                type = "steam",
                path = path
            }
        end
    end

    return list
end

return celestefinder
