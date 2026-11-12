local log = require('logger')('modinstaller')

local utils = require("utils")
local fs = require("fs")
local config = require("config")
local alert = require("alert")
local sharp = require("sharp")
local registry = require("registry")
local modupdater = require("modupdater")
local modependencies = require("modependencies")
local lang = require("lang")
local threader = require("threader")
local downloadqueue = require("downloadqueue")

local modinstaller = {}


function modinstaller.register()
    local userOS = love.system.getOS()

    if userOS == "Windows" then
        local exepath = love.filesystem.getSource()
        if (exepath:match(".exe$") and
            registry.setKey([[HKCU\Software\Classes\Everest\]], "URL:Everest") and
            registry.setKey([[HKCU\Software\Classes\Everest\URL Protocol]], "") and
            registry.setKey([[HKCU\Software\Classes\Everest\shell\open\command\]], string.format([["%s" "%%1"]], exepath)))
            then

            -- While we're here, might as well register the application properly.
            log.debug("updating installed application listing")
            sharp.win32AppAdd(exepath, utils.trim(utils.load("version.txt") or "?"))

            -- While we're here, might as well create some helpful .lnks
            -- INTRODUCED AFTER BUILD 1531
            if config.lastrun < 0 or config.lastrun <= 1531 then
                log.info("creating shortcuts", exepath)
                sharp.win32CreateShortcuts(exepath)
            end

            return true
        end

    elseif userOS == "OS X" then
        return false

    elseif userOS == "Linux" then
        if fs.isFile("/.flatpak-info") or os.getenv("OLYMPUS_SKIP_SCHEME_HANDLER_CHECK") == "1" then
            return false
        end

        -- While we're here, might as well check if the everest scheme handler is registered.
        local p = io.popen([["xdg-mime" "query" "default" "x-scheme-handler/everest"]])
        local data = utils.trim(p:read("*a")) or ""
        if p:close() and data == "" then
            alert(lang.get("olympus_isn_t_fully_installed_please_run"))
        end

        return false
    end
end


-- === Dependency download / enable handling ===
--
-- When "Enable Dependencies on Download" is turned on, installing a mod also
-- un-blacklists its installed dependencies, and missing ones are fetched from
-- the mod update database and downloaded. The "Only download" setting skips the
-- enabling step. Dependency downloads resolve recursively: once a dependency is
-- installed, its own missing dependencies are fetched too.

-- Cache of the mod update database (name -> { URL, MirrorName, ... }).
local dependencyDatabase

-- Names of dependencies that were queued for download, so a dependency required
-- by several mods only gets downloaded once.
local dependencyDownloads = {}

-- Mods whose dependencies still have to be resolved. They are processed serially
-- by the single routine spawned by scheduleDependencyResolution below, so the
-- blacklist and the dependency queue are never touched from two places at once.
local resolveQueue = {}
local resolving = false


local function getDependencyDatabase()
    if dependencyDatabase ~= nil then
        return dependencyDatabase
    end

    local utilsAsync = threader.wrap("utils")

    local url
    if config.apiMirror then
        url = "https://everestapi.github.io/updatermirror/everest_update.yaml"
    else
        local listUrl = utilsAsync.download("https://everestapi.github.io/modupdater.txt"):result()
        url = listUrl and utils.trim(listUrl) or nil
    end

    if not url or #url == 0 then
        log.warning("couldn't retrieve the mod update database URL for dependencies")
        return nil
    end

    local data, err = utilsAsync.downloadYAML(url):result()
    if not data then
        log.warning("failed to download the mod update database for dependencies:", tostring(err))
        return nil
    end

    dependencyDatabase = data
    return data
end


local function isDependencyQueued(depName)
    local tasks = downloadqueue.getTasks()
    for i = 1, #tasks do
        local task = tasks[i]
        local state = task.state
        if task.name == depName and (state == "queued" or state == "downloading" or state == "paused") then
            return true
        end
    end
    return false
end


local scheduleDependencyResolution

local function resolveDependencies(root, modName)
    if not root or not modName then
        return
    end

    local mode = config.autoEnableDependencies
    if mode ~= "enabled" and mode ~= "download" then
        return
    end

    -- Download the missing dependencies first.
    local missing = modependencies.findMissingDependenciesOf(root, modName)
    if missing and next(missing) then
        local database = getDependencyDatabase()
        if database then
            for depName in pairs(missing) do
                if not dependencyDownloads[depName] and not isDependencyQueued(depName) then
                    local update = database[depName]
                    if type(update) == "table" and update.URL then
                        dependencyDownloads[depName] = true
                        log.info("downloading dependency", depName, "of", modName)
                        downloadqueue.enqueue(update.URL, update.MirrorName or "", {
                            name = depName,
                            onSuccess = function()
                                scheduleDependencyResolution(root, depName)
                            end,
                            onFailure = function()
                                dependencyDownloads[depName] = nil
                            end,
                        })
                    end
                end
            end
        end
    end

    -- Then enable the dependencies that are already installed and blacklisted.
    if mode == "enabled" then
        local ok, enabled = pcall(modependencies.enableDependenciesOf, root, modName)
        if ok then
            if enabled and #enabled > 0 then
                log.info("enabled dependencies of", modName, ":", table.concat(enabled, ", "))
            end
        else
            log.warning("failed to enable dependencies of", modName, ":", tostring(enabled))
        end
    end
end


scheduleDependencyResolution = function(root, modName)
    resolveQueue[#resolveQueue + 1] = { root = root, modName = modName }
    if resolving then
        return
    end

    resolving = true
    threader.routine(function()
        while #resolveQueue > 0 do
            local job = table.remove(resolveQueue, 1)
            local ok, err = pcall(resolveDependencies, job.root, job.modName)
            if not ok then
                log.warning("failed to resolve dependencies of", job.modName, ":", tostring(err))
            end
        end
        resolving = false
    end)
end


-- Queues a mod download in the background, so the UI can stay responsive.
-- The cb and autoclose parameters are kept for backwards compatibility with
-- existing callers; the background queue replaces the old installer scene.
-- modname is an optional display name (e.g. the mod title); when omitted we
-- fall back to the file name for file:// links and the URL otherwise.
function modinstaller.install(modurl, mirrorName, cb, autoclose, modname)
    local name = modname
    if name == nil then
        name = modurl
        if modurl:match("^file://") then
            name = fs.filename(modurl)
        end
    end

    downloadqueue.enqueue(modurl, mirrorName or "", {
        name = name,
        autoclose = autoclose,
        onSuccess = function(last)
            if config.autoEnableDependencies == "disabled" then
                return
            end
            local status = type(last) == "table" and last[1] or last
            local modName = tostring(status):match("^Successfully installed (.+)$")
            if modName then
                local install = config.installs[config.install]
                install = install and install.path
                local ok, err = pcall(scheduleDependencyResolution, install, modName)
                if not ok then
                    log.warning("failed to schedule dependency resolution of", modName, ":", tostring(err))
                end
            else
                log.warning("couldn't determine the name of the installed mod, skipping dependency handling:", tostring(status))
            end
        end
    })
end


return modinstaller