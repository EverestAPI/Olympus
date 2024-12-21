local utils = require("utils")
local fs = require("fs")
local config = require("config")
local threader = require("threader")
local notify = require("notify")
local alert = require("alert")
local scener = require("scener")
local sharp = require("sharp")
local registry = require("registry")
local modupdater = require("modupdater")

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
            print("updating installed application listing")
            sharp.win32AppAdd(exepath, utils.trim(utils.load("version.txt") or "?"))

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
            alert([[
Olympus isn't fully installed.
Please run install.sh to install the one-click installer handler.
install.sh can be found in your Olympus installation folder.]])
        end

        return false
    end
end


function modinstaller.install(modurl, cb, autoclose)
    local install = config.installs[config.install]
    install = install and install.path

    modurl = modurl and modurl:match("^(https://gamebanana.com/mmdl/.*),.*,.*$") or modurl

    if not install or not modurl then
        return
    end

    if not cb then
        cb = function(launch)
            scener.pop()
        end
    end

    local modname = modurl
    if modurl:match("^file://") then
        modname = fs.filename(modurl)
    end

    local installer = scener.push("installer")
    installer.update(string.format("Preparing installation of %s", modname), false, "")

    installer.sharpTask("installMod", install, modurl, config.mirrorPreferences):calls(function(task, last)
        if not last then
            return
        end

        installer.update(last[1], 1, "done", true)
        installer.done({
            {
                "Launch",
                function()
                    cb(modupdater.updateAllMods(install))
                end
            },
            {
                "OK",
                function()
                    cb(false)
                end
            }
        }, nil, autoclose)
    end)

end


return modinstaller
