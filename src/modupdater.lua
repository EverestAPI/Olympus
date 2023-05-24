local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local threader = require("threader")
local alert = require("alert")
local config = require("config")
local sharp = require("sharp")
local fs = require("fs")

local modupdater = {}

function modupdater.updateAllModsThenRunGame(path, notify)
    if config.updateModsOnStartup == "none" then
        utils.launch(nil, false, notify)
        return
    end

    local task = sharp.updateAllMods(path or config.installs[config.install].path, config.updateModsOnStartup == "enabled"):result()

    local alertMessage = alert({
        title = config.updateModsOnStartup == "enabled" and "Updating enabled mods" or "Updating all mods",
        body = uie.column({
            uie.row({
                uie.spinner():with({
                    width = 16,
                    height = 16
                }),
                uie.label("Please wait..."):as("loadingMessage")
            })
        }):with(uiu.fillWidth),
        buttons = {
            {
                "Skip",
                function(container)
                    sharp.free(task)
                    utils.launch(nil, false, notify)
                    container:close()
                end
            }
        },
        init = function(container)
            container:findChild("box"):with({
                width = 600, height = 120
            })
            container:findChild("buttons"):with(uiu.bottombound)
        end
    })

    alertMessage:findChild("bg"):hook({
        onClick = function() end
    })

    threader.routine(function()
        local status
        repeat
            status = sharp.pollWait(task, true):result() or { "interrupted", "", "" }
            local lastStatusLine = status[3]

            if lastStatusLine then
                alertMessage:findChild("loadingMessage"):setText(lastStatusLine)
            end
        until status[1] ~= "running"

        alertMessage:close()

        if status[1] == "done" then
            utils.launch(nil, false, notify)
        elseif status[1] ~= "interrupted" then
            alert({
                body = "An error occurred while updating your mods.\nMake sure you are connected to the Internet and that Lönn is not running!",
                buttons = {
                    {
                        "Retry",
                        function(container)
                            modupdater.updateAllModsThenRunGame()
                            container:close()
                        end
                    },
                    {
                        "Open logs folder",
                        function(container)
                            utils.openFile(fs.getStorageDir())
                        end
                    },
                    {
                        "Run anyway",
                        function(container)
                            utils.launch(nil, false, notify)
                            container:close()
                        end
                    },
                    {
                        "Cancel",
                        function(container)
                            container:close()
                        end
                    },
                }
            })
        end
    end)
end

return modupdater