local fs = require("fs")
local utils = require("utils")
local registry = require("registry")
local sqlite3status, sqlite3 = pcall(require, "lsqlite3")
if not sqlite3status then
    sqlite3status, sqlite3 = pcall(require, "lsqlite3complete")
end
if not sqlite3status then
    sqlite3status, sqlite3 = pcall(require, "lsqlite3")
    print("Failed loading lsqlite3")
    print(sqlite3)
    sqlite3status, sqlite3 = pcall(require, "lsqlite3complete")
    print("Failed loading lsqlite3complete")
    print(sqlite3)
end
local sharpStatus, sharp = pcall(require, "sharp")
require("love.system")

local finder = {}

local channelCache = love.thread.getChannel("finderCache")

finder.defaultName = "Celeste"
-- https://www.microsoft.com/en-us/p/celeste/bwmql2rpwbhb
-- https://bspmts.mp.microsoft.com/v1/public/catalog/Retail/Products/bwmql2rpwbhb/applockerdata
finder.defaultUWPName = "MattMakesGamesInc.Celeste_79daxvg0dq3v6"

-- enhance linux compatibility
local function getLinuxConfigDir()
    local xdg_cfg = os.getenv("XDG_CONFIG_HOME")
    if fs.isFile("/.flatpak-info") or xdg_cfg == "" or xdg_cfg == nil then
       return fs.joinpath(os.getenv("HOME"), ".config")
    end
    return xdg_cfg
end

function finder.findSteamRoot()
    local userOS = love.system.getOS()
    local root

    if userOS == "Windows" then
        local steam =
            registry.getKey([[HKLM\SOFTWARE\WOW6432Node\Valve\Steam\InstallPath]]) or
            registry.getKey([[HKLM\SOFTWARE\Valve\Steam\InstallPath]])

        root = steam

    elseif userOS == "OS X" then
        root = fs.joinpath(os.getenv("HOME"), "Library", "Application Support", "Steam")

    elseif userOS == "Linux" then
        local paths = {
            fs.joinpath(os.getenv("HOME"), ".local", "share", "Steam"),
            fs.joinpath(os.getenv("HOME"), ".steam", "steam"),
            fs.joinpath(os.getenv("HOME"), ".var", "app", "com.valvesoftware.Steam", ".local", "share", "Steam"),
            fs.joinpath(os.getenv("HOME"), ".var", "app", "com.valvesoftware.Steam", ".steam", "steam"),
            fs.joinpath("/run", "media", "mmcblk0p1"), -- Add Steam Deck micro SD folder
        }

        for i = 1, #paths do
            local path = paths[i]
            if fs.isDirectory(path) then
                root = path
                break
            end
        end
    end

    if root then
        local rootReal = fs.isDirectory(root)
        print("[finder]", "steam root", root, root == rootReal and "<same>" or rootReal)
        return rootReal
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
            print("[finder]", "steam common", path)
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
    finder.addSteamLibrariesFromVdf(libraries, config, [[BaseInstallFolder[^"]*"%s*("[^"]*")]])

    local libraryFolders = fs.isFile(fs.joinpath(steam, "config", "libraryfolders.vdf"))
    finder.addSteamLibrariesFromVdf(libraries, libraryFolders, [[path[^"]*"%s*("[^"]*")]])

    return libraries
end

function finder.addSteamLibrariesFromVdf(libraries, vdfFile, pattern)
    if not vdfFile then
        return
    end

    vdfFile = fs.read(vdfFile)
    if not vdfFile then
        return
    end

    for path in vdfFile:gmatch(pattern) do
        path = utils.fromJSON(path)
        path = finder.findSteamCommon(path)
        if path then
            print("[finder]", "steam additional library", path)
            libraries[#libraries + 1] = path
        end
    end
end

function finder.findSteamShortcuts()
    local steam = finder.findSteamRoot()
    if not steam then
        return {}
    end

    local userdata = fs.isDirectory(fs.joinpath(steam, "userdata"))
    if not userdata then
        -- FIXME: At least one Windows user reported not having a Steam userdata folder!
        return {}
    end

    local byte = string.byte

    local allLists = {}

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
        path = fs.joinpath(path, id)
        if fs.isDirectory(path) then
            print("[finder]", "steam install", path)
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
        path = path and fs.isDirectory(fs.dirname(path:match("^\"?([^\" ]*)") or path))
        if fs.isDirectory(path) then
            -- print("[finder]", "steam shortcut", path)
            list[#list + 1] = {
                type = "steam_shortcut",
                path = path
            }
        end

        path = shortcut.startdir
        if fs.isDirectory(path) then
            -- print("[finder]", "steam shortcut", path)
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
    local root

    if userOS == "Windows" then
        local epic =
            registry.getKey([[HKLM\SOFTWARE\WOW6432Node\Epic Games\EpicGamesLauncher\AppDataPath]]) or
            registry.getKey([[HKLM\SOFTWARE\Epic Games\EpicGamesLauncher\AppDataPath]])

        root = epic

    elseif userOS == "OS X" then
        root = fs.joinpath(os.getenv("HOME"), "Library", "Application Support", "Epic", "EpicGamesLauncher", "Data")
    end

    if root then
        local rootReal = fs.isDirectory(root)
        print("[finder]", "epic root", root, root == rootReal and "<same>" or rootReal)
        return rootReal
    end
end

function finder.findEpicInstalls(name)
    local list = {}

    local epic = finder.findEpicRoot()
    if not epic then
        return list
    end

    local manifests = fs.joinpath(epic, "Manifests")
    if not fs.isDirectory(manifests) then
        return list
    end

    for manifest in fs.dir(manifests) do
        manifest = manifest:match("%.item$") and fs.joinpath(manifests, manifest)
        local data = manifest and utils.fromJSON(fs.read(manifest))
        if data and data.DisplayName == name then
            local path = data.InstallLocation
            if fs.isDirectory(path) then
                print("[finder]", "epic install", path)
                list[#list + 1] = {
                    type = "epic",
                    path = path
                }
            end
        end
    end

    return list
end


function finder.findLegendaryRoot()
    local userOS = love.system.getOS()

    -- As of the time of writing this, Legendary is only supported for Windows and Linux.
    -- It follows XDG_CONFIG_HOME and ~/.config/legendary on all platforms.
    local root = fs.joinpath(
        userOS == "Windows"
            and fs.joinpath(sharp.getEnv("USERPROFILE"):result(), ".config")
            or getLinuxConfigDir(),
        "legendary"
    )

    if root then
        local rootReal = fs.isDirectory(root)
        print("[finder]", "legendary root", root, root == rootReal and "<same>" or rootReal)
        return rootReal
    end
end

function finder.findLegendaryInstalls(name)
    local list = {}

    local legendary = finder.findLegendaryRoot()
    if not legendary then
        return list
    end

    local installed = fs.isFile(fs.joinpath(legendary, "installed.json"))
    if not installed then
        return list
    end

    installed = utils.fromJSON(fs.read(installed))
    if not installed then
        return list
    end

    for _, install in pairs(installed) do
        if install and install.title == name then
            local path = install.install_path
            if fs.isDirectory(path) then
                print("[finder]", "legendary install", path)
                list[#list + 1] = {
                    type = "legendary",
                    path = path
                }
            end
        end
    end

    return list
end


function finder.findItchDatabase()
    local userOS = love.system.getOS()
    local db

    if userOS == "Windows" then
        db = fs.joinpath(sharp.getEnv("APPDATA"):result(), "itch", "db", "butler.db")

    elseif userOS == "OS X" then
        db = fs.joinpath(os.getenv("HOME"), "Library", "Application Support", "itch", "db", "butler.db")

    elseif userOS == "Linux" then
        db = fs.joinpath(getLinuxConfigDir(), "itch", "db", "butler.db")
    end

    if db then
        local dbReal = fs.isFile(db)
        print("[finder]", "itch db", db, db == dbReal and "<same>" or dbReal)
        return dbReal
    end
end

function finder.findItchInstalls(name)
    local list = {}
    if not sqlite3status then
        return list
    end

    local dbPath = finder.findItchDatabase()
    if not dbPath then
        return list
    end

    -- sqlite3 can deal with UTF-8 or UTF-16. lsqlite3 can only deal with UTF-8.
    local db = sqlite3.open(dbPath)
    if not db then
        return list
    end

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
            print("[finder]", "itch install", path)
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


function finder.findLutrisDatabase()
    local userOS = love.system.getOS()
    local db

    if userOS == "Linux" then
        db = fs.joinpath(os.getenv("HOME"), ".local", "share", "lutris", "pga.db")
    end

    if db then
        local dbReal = fs.isFile(db)
        print("[finder]", "lutris db", db, db == dbReal and "<same>" or dbReal)
        return dbReal
    end
end

function finder.findLutrisDatabaseInstalls(name)
    local list = {}
    if not sqlite3status then
        return list
    end

    local dbPath = finder.findLutrisDatabase()
    if not dbPath then
        return list
    end

    local db = sqlite3.open(dbPath)

    local query = db:prepare([[
        SELECT directory FROM games
        WHERE name == ?
    ]])
    query:bind_values(name)

    for path in query:urows() do
        if fs.isDirectory(path) then
            print("[finder]", "lutris db install", path)
            list[#list + 1] = {
                type = "lutris",
                path = path
            }
        end
    end

    query:finalize()
    db:close()
    return list
end

function finder.findLutrisRoot()
    local userOS = love.system.getOS()
    local root

    if userOS == "Linux" then
        root = fs.joinpath(getLinuxConfigDir(), "lutris")
    end

    if root then
        local rootReal = fs.isDirectory(root)
        print("[finder]", "lutris root", root, root == rootReal and "<same>" or rootReal)
        return rootReal
    end
end

function finder.findLutrisYamlInstalls(name)
    local list = {}

    local epic = finder.findLutrisRoot()
    if not epic then
        return list
    end

    local games = fs.joinpath(epic, "games")
    if not fs.isDirectory(games) then
        return list
    end

    for game in fs.dir(games) do
        game = game:match("^" .. name:lower() .. "-.+%.yml$") and fs.joinpath(games, game)
        local data = game and utils.fromYAML(fs.read(game))
        if data and data.game and data.game then
            local path = data.game.exe
            if path and path:match(name .. ".exe$") and fs.isFile(path) then
                path = fs.dirname(path)
                print("[finder]", "lutris yml install", path)
                list[#list + 1] = {
                    type = "lutris",
                    path = path
                }
            end
        end
    end

    return list
end

function finder.findLutrisInstalls(name)
    local list = {}

    local fromDB = finder.findLutrisDatabaseInstalls(name)
    for i = 1, #fromDB do
        list[#list + 1] = fromDB[i]
    end

    local fromYAML = finder.findLutrisYamlInstalls(name)
    for i = 1, #fromYAML do
        list[#list + 1] = fromYAML[i]
    end

    return list
end


function finder.findUWPInstalls(package)
    if not sharpStatus or love.system.getOS() ~= "Windows" then
        return {}
    end

    local path = sharp.getUWPPackagePath(package):result()
    if not path or #path == 0 then
        return {}
    end

    return {
        {
            type = "uwp",
            path = path
        }
    }
end


function finder.findRunningInstall(name)
    if not sharpStatus then
        return {}
    end

    local path = sharp.getRunningPath("", name):result()
    if not path or #path == 0 then
        return {}
    end

    return {
        {
            type = "manual",
            path = path
        }
    }
end


function finder.fixRoot(root, appname)
    if not root or #root == 0 then
        return nil
    end

    appname = appname or finder.defaultName

    root = fs.normalize(root)
    -- If dealing with a macOS root, get the root's root to get the new real root.
    root = (
        root:match([=[^(.*)[\/]]=] .. appname .. [=[%.app[\/]Contents[\/]Resources[\/]?$]=]) or
        root:match([=[^(.*)[\/]]=] .. appname .. [=[%.app[\/]Contents[\/]MacOS[\/]?$]=]) or
        root
    )

    local dirs = {
        root,
        fs.joinpath(root, appname .. ".app", "Contents", "Resources"), -- 1.3.3.0 and newer
        fs.joinpath(root, appname .. ".app", "Contents", "MacOS"), -- pre 1.3.3.0
    }

    for i = 1, #dirs do
        local path = dirs[i]
        if fs.isFile(fs.joinpath(path, appname .. ".exe")) then
            print("[finder]", "found " .. appname .. ".exe root", path)
            return path
        elseif fs.isFile(fs.joinpath(path, appname .. ".dll")) then
            print("[finder]", "found " .. appname .. ".dll root", path)
            return path
        end
    end

    if root:match("[Cc]eleste") then
        print("[finder]", "found install root without Celeste.exe or Celeste.dll", root)
    end
    return nil
end


local function channelSetCb(channel, value)
    channel:clear()
    channel:push(value)
end

local function channelSet(channel, value)
    channel:performAtomic(channelSetCb, value)
end

function finder.fixRoots(all, keepStale, keepDupe, appname)
    for i = #all, 1, -1 do
        local entryA = all[i]
        local pathA = finder.fixRoot(entryA and entryA.path, appname)
        if not pathA then
            if not keepStale then
                table.remove(all, i)
            end
        else
            all[i].path = pathA
            if not keepDupe then
                local j = i + 1
                while j <= #all do
                    local entryB = all[j]
                    local pathB = entryB.path
                    if pathB and pathB == pathA then
                        table.remove(all, j)
                    else
                        j = j + 1
                    end
                end
            end
        end
    end
end

function finder.findAll(uncached)
    local all = uncached and channelCache:peek()
    if all then
        return all
    end

    all = utils.concat(
        finder.findSteamInstalls(finder.defaultName),
        finder.findEpicInstalls(finder.defaultName),
        finder.findItchInstalls(finder.defaultName),
        finder.findLutrisInstalls(finder.defaultName),
        finder.findLegendaryInstalls(finder.defaultName),
        finder.findRunningInstall(finder.defaultName),
        finder.findUWPInstalls(finder.defaultUWPName)
    )

    finder.fixRoots(all)

    channelSet(channelCache, all)
    return all
end

function finder.getCached()
    return channelCache:peek()
end

return finder
