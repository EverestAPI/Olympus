local utils = require("utils")
local config = require("config")
local threader = require("threader")
local notify = require("notify")
local alert = require("alert")
local scener = require("scener")
local sharp = require("sharp")

local modinstaller = {}

function modinstaller.install(modurl, cb)
    local install = config.installs[config.install]
    install = install and install.path

    if not install or not modurl then
        return
    end

    if not cb then
        cb = function()
            scener.pop(1)
        end
    end

    local installer = scener.push("installer")
    installer.update(string.format("Preparing installation of %s", modurl), false, "")

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
