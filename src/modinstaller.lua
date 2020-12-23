local utils = require("utils")
local fs = require("fs")
local config = require("config")
local threader = require("threader")
local notify = require("notify")
local alert = require("alert")
local scener = require("scener")
local sharp = require("sharp")
local registry = require("registry")

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
            -- While we're here, might as well create some helpful .lnks

            -- INTRODUCED AFTER BUILD 1531
            if 0 < config.lastrun or config.lastrun <= 1531 then
                print("creating shortcuts", exepath)
                sharp.createShortcutsWin32(exepath)
            end

            return true
        end

    elseif userOS == "OS X" then
        return false

    elseif userOS == "Linux" then
        return false
    end
end


function modinstaller.install(modurl, cb)
    local install = config.installs[config.install]
    install = install and install.path

    modurl = modurl and modurl:match("^(https://gamebanana.com/mmdl/.*),.*,.*$") or modurl

    if not install or not modurl then
        return
    end

    if not cb then
        cb = function()
            scener.pop()
        end
    end

    local modname = modurl
    if modurl:match("^file://") then
        modname = fs.filename(modurl)
    end

    local installer = scener.push("installer")
    installer.update(string.format("Preparing installation of %s", modname), false, "")

    installer.sharpTask("installMod", install, modurl):calls(function(task, last)
        if not last then
            return
        end

        installer.update(last[1], 1, "done")
        installer.done({
            {
                "Launch",
                function()
                    sharp.launch(install)
                    alert([[
Everest is now starting in the background.
You can close this window.]])
                    cb()
                end
            },
            {
                "OK",
                function()
                    cb()
                end
            }
        })
    end)

end


return modinstaller
