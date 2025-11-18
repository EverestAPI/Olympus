local log = require('logger')('dragndrop')

local ui, uiu, uie = require("ui").quick()
local fs = require("fs")
local threader = require("threader")
local scener = require("scener")
local config = require("config")
local sharp = require("sharp")
local native = require("native")
local alert = require("alert")
local notify = require("notify")
local modinstaller = require("modinstaller")
local modupdater = require("modupdater")
local lang = require("lang")

function love.filedropped(file)
    threader.routine(function()
        file = file:getFilename()
        log.info("file drag n dropped", file)

        if #alert.root.children > 0 or scener.locked then
            notify(lang.get("olympus_is_currently_busy_with_something"))
            return
        end

        local install = config.installs[config.install]
        if not install then
            alert({
                body = lang.get("your_celeste_installation_list_is_still_"),
                buttons = {
                    {
                        lang.get("yes"),
                        function(container)
                            scener.push("installmanager")
                            container:close(lang.get("ok"))
                        end
                    },
                    { lang.get("no") }
                }
            })
            return
        end

        -- On macOS, launching an app via the browser requires special event handling.
        -- SDL2 exposes that as a file drop event.
        -- See https://bugzilla.libsdl.org/show_bug.cgi?id=5073
        local protocolArg = file:match("^[Ee]verest:(.*)")
        if protocolArg then
            require("protocol")(protocolArg)
            return
        end

        if not fs.isFile(file) then
            log.warning("user drag-n-dropped pathless file?")
            notify(lang.get("olympus_can_t_handle_that_file_does_it_e"))
            return
        end

        local filetype = sharp.scanDragAndDrop(file):result()

        if filetype == "mod" then
            modinstaller.install("file://" .. file)

        elseif filetype == "everest" then
            local installer = scener.push("installer")
            installer.sharpTask("installEverest", install.path, "file://" .. file):calls(function(task, last)
                if not last then
                    return
                end

                installer.update(lang.get("everest_successfully_installed"), 1, "done")
                installer.done({
                    {
                        lang.get("launch"),
                        function()
                            modupdater.updateAllMods(install.entry.path, true)
                            scener.pop()
                        end
                    },
                    {
                        lang.get("ok"),
                        function()
                            scener.pop()
                        end
                    }
                })
            end)

        else
            log.warning("user drag-n-dropped file of unknown type", file)
            notify(lang.get("olympus_can_t_handle_that_file"))
        end
    end)
end