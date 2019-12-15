local fs = require("fs")
local utils = require("utils")
local registry = require("registry")
local sqlite3status, sqlite3 = pcall(require, "lsqlite3")
if not sqlite3status then
    sqlite3status, sqlite3 = pcall(require, "lsqlite3complete")
end
require("love.system")

local finder = {}

local channelCache = love.thread.getChannel("finderCache")

finder.defaultName = "Celeste"


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

    config = fs.read(config)
    if not config then
        return libraries
    end

    for path in config:gmatch([[BaseInstallFolder[^"]*"%s*("[^"]*")]]) do
        path = utils.fromJSON(path)
        path = finder.findSteamCommon(path)
        if path then
            libraries[#libraries + 1] = path
        end
    end

    return libraries
end

function finder.findSteamShortcuts()
    local steam = finder.findSteamRoot()
    if not steam then
        return {}
    end

    local byte = string.byte

    local allLists = {}

    local userdata = fs.isDirectory(fs.joinpath(steam, "userdata"))
    for userid in fs.dir(userdata) do
        local path = userid:match("%d+") and fs.isFile(fs.joinpath(userdata, userid, "config", "shortcuts.vdf"))
        local data = path and fs.read(path)
        if data then
            local pos = 1

            local function get(pattern)
                pattern = "^(" .. pattern .. ")"
                local rv = {data:match(pattern, pos)}
                if rv[1] then
                    pos = pos + #rv[1]
                    if rv[2] then
                        table.remove(rv, 1)
                    end
                end
                return table.unpack(rv)
            end

            local root = {}
            local current = root
            local pathStack = {}
            local stack = {}

            while true do
                while get("\8") do
                    current = stack[#stack]
                    pathStack[#pathStack] = nil
                    stack[#stack] = nil
                    if not current then
                        break
                    end
                end

                local typ, key = get("(.)([^%z]+)%z")
                if not typ then
                    break
                end
                typ = byte(typ)
                -- Field names can have different casings across different objs in the same file!
                key = key:lower()

                if typ == 0 then
                    pathStack[#pathStack + 1] = key
                    stack[#stack + 1] = current
                    local child = {}
                    current[key] = child
                    current = child

                else
                    current[key] = get("([^%z]*)%z")
                end

            end

            allLists[#allLists + 1] = root.shortcuts
        end
    end

    local all = {}
    for i = 1, #allLists do
        for k, shortcut in pairs(allLists[i]) do
            all[#all + 1] = shortcut
        end
    end

    return all
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

    -- Note: This will add *all* shortcutted games and their startup dirs!
    local shortcuts = finder.findSteamShortcuts()
    for i = 1, #shortcuts do
        local shortcut = shortcuts[i]

        local path = shortcut.exe
        path = path and fs.isDirectory(fs.dirname(path:match("^\"?([^\" ]*)")))
        if fs.isDirectory(path) then
            list[#list + 1] = {
                type = "steam_shortcut",
                path = path
            }
        end

        path = shortcut.startdir
        if fs.isDirectory(path) then
            list[#list + 1] = {
                type = "steam_shortcut",
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
        return fs.isDirectory(fs.joinpath(os.getenv("HOME"), "Library", "Application Support", "Epic", "EpicGamesLauncher", "Data"))

    elseif userOS == "Linux" then
        return false
    end
end

function finder.findEpicInstalls(name)
    local list = {}

    local epic = finder.findEpicRoot()
    if not epic then
        return list
    end

    local manifests = fs.joinpath(epic, "Manifests")
    for manifest in fs.dir(manifests) do
        manifest = manifest:match("%.item$") and fs.joinpath(manifests, manifest)
        local data = manifest and utils.fromJSON(fs.read(manifest))
        if data and data.DisplayName == name then
            local path = data.InstallLocation
            if fs.isDirectory(path) then
                list[#list + 1] = {
                    type = "epic",
                    path = path
                }
            end
        end
    end

    return list
end


function finder.findItchDatabase()
    local userOS = love.system.getOS()

    if userOS == "Windows" then
        return fs.isFile(fs.joinpath(os.getenv("APPDATA"), "itch", "db", "butler.db"))

    elseif userOS == "OS X" then
        return fs.isFile(fs.joinpath(os.getenv("HOME"), "Library", "Application Support", "itch", "db", "butler.db"))

    elseif userOS == "Linux" then
        return fs.isFile(fs.joinpath(os.getenv("XDG_CONFIG_HOME") or fs.joinpath(os.getenv("HOME"), ".config"), "itch", "db", "butler.db"))
    end
end

function finder.findItchInstalls(name)
    local list = {}

    local dbPath = finder.findItchDatabase()
    if not dbPath then
        return list
    end

    local db = sqlite3.open(dbPath)

    local query = db:prepare([[
        SELECT verdict FROM caves
        WHERE game_id == (
            SELECT ID FROM games
            WHERE title == ?
        )
    ]])
    query:bind_values(name)

    for body in query:urows() do
        local data = utils.fromJSON(body)
        local path = data.basePath
        if fs.isDirectory(path) then
            list[#list + 1] = {
                type = "itch",
                path = path
            }
        end
    end

    query:finalize()
    db:close()
    return list
end


function finder.fixRoot(path, appname)
    path = fs.normalize(path)
    appname = appname or finder.defaultName

    local appdir = fs.isDirectory(fs.joinpath(path, appname .. ".app"))
    if appdir then
        path = fs.isDirectory(fs.joinpath(appdir, "Contents", "MacOS"))
    end

    if not fs.isFile(fs.joinpath(path, "Celeste.exe")) then
        return nil
    end

    return path
end


function finder.findAll(uncached)
    local all = uncached and channelCache:peek()
    if all then
        return all
    end

    all = utils.concat(
        finder.findSteamInstalls(finder.defaultName),
        finder.findEpicInstalls(finder.defaultName),
        finder.findItchInstalls(finder.defaultName)
    )

    for i = #all, 1, -1 do
        local entry = all[i]
        local path = entry and finder.fixRoot(entry.path, finder.defaultName)
        if not path then
            table.remove(all, i)
        else
            entry.path = path
        end
    end

    for i = 1, #all do
        local entryA = all[i]
        local pathA = entryA.path
        if pathA then
            for j = #all, i + 1, -1 do
                local entryB = all[j]
                local pathB = entryB.path
                if pathB and pathB == pathA then
                    table.remove(all, j)
                end
            end
        end
    end

    channelCache:push(all)
    return all
end

return finder
