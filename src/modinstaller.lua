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
        -- While we're here, might as well create a helpful .desktop
        if config.currentrun == 0 then
            return false
        end

        local srcdir = love.filesystem.getSource()
        if srcdir then
            srcdir = fs.dirname(fs.normalize(srcdir))
        else
            srcdir = fs.getcwd()
        end

        local shpath = fs.joinpath(srcdir, "olympus.sh")
        if not fs.isFile(shpath) then
            return false
        end

        local iconpath = fs.joinpath(srcdir, "icon.png")
        if not fs.isFile(iconpath) then
            local fh = io.open(iconpath, "wb")
            if fh then
                fh:write(love.filesystem.read("data/icon.png"))
                fh:close()
            end
        end

        local desktoppath = fs.joinpath(os.getenv("HOME"), ".local", "share", "applications")
        if fs.isDirectory(desktoppath) then
            desktoppath = fs.joinpath(desktoppath, "Olympus.desktop")
            if not fs.isFile(desktoppath) then
                print("creating Olympus.desktop at", desktoppath)
                local fh = io.open(desktoppath, "w+")
                if fh then
                    fh:write(string.format([[
[Desktop Entry]
Encoding=UTF-8
Version=1.0
Type=Application
Terminal=false
Name=Olympus
Exec=%s %%u
Icon=%s
StartupNotify=false
MimeType=x-scheme-handler/everest;
]], shpath, iconpath))
                    fh:close()
                    print("registering everest url handler", pcall(os.execute, [["xdg-mime" "default" "]] .. desktoppath .. [[" "x-scheme-handler/everest"]]))
                end
            end
        end

        return true
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
