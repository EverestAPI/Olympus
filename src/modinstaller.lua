local log = require('logger')('modinstaller')

local utils = require("utils")
local fs = require("fs")
local config = require("config")
local alert = require("alert")
local sharp = require("sharp")
local registry = require("registry")
local lang = require("lang")
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
    })
end


return modinstaller