local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local threader = require("threader")
local alert = require("alert")
local config = require("config")
local sharp = require("sharp")
local fs = require("fs")
local lang = require("lang")

local modupdater = {}

function modupdater.updateAllMods(path, notify, mode, callback, showRecap)
    local willRunGame = callback == nil

    local origMode = mode
    local origCallback = callback

    mode = mode or config.updateModsOnStartup
    callback = callback or function()
        utils.launch(nil, false, notify)
    end

    if mode == "none" then
        callback()
        return
    end

    local task = sharp.updateAllMods(path or config.installs[config.install].path, mode == "enabled", config.mirrorPreferences, config.apiMirror, config.language):result()

    local alertMessage = alert({
        title = mode == "enabled" and lang.get("updating_enabled_mods") or lang.get("updating_all_mods"),
        body = uie.column({
            uie.row({
                uie.spinner():with({
                    width = 16,
                    height = 16
                }),
                uie.label(lang.get("please_wait")):as("loadingMessage")
            })
        }):with(uiu.fillWidth),
        buttons = {
            {
                willRunGame and lang.get("skip") or lang.get("cancel"),
                function(container)
                    sharp.free(task)
                    callback()
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
        local lastStatusLine
        repeat
            status = sharp.pollWait(task, true):result() or { "interrupted", "", "" }
            lastStatusLine = status[3]

            if lastStatusLine then
                alertMessage:findChild("loadingMessage"):setText(lastStatusLine)
            end
        until status[1] ~= "running"

        alertMessage:close()

        if status[1] == "done" then
            callback()

            if showRecap then
                alert({
                    body = uie.scrollbox(uie.label(lastStatusLine))
                        :with(uiu.hook({
                            calcSize = function (orig, self, width, height)
                                uie.group.calcSize(self)
                            end
                        }))
                        :with({ maxHeight = 300 }),
                    buttons = {{ lang.get("ok") }}
                })
            end
        elseif status[1] ~= "interrupted" then
            local buttons = {
                {
                    lang.get("retry"),
                    function(container)
                        modupdater.updateAllMods(path, notify, origMode, origCallback)
                        container:close()
                    end
                },
                {
                    lang.get("open_logs_folder"),
                    function(container)
                        utils.openFile(fs.getStorageDir())
                    end
                },
                {
                    willRunGame and lang.get("run_anyway") or lang.get("cancel"),
                    function(container)
                        callback()
                        container:close()
                    end
                }
            }

            if willRunGame then
                table.insert(buttons,
                {
                    lang.get("cancel"),
                    function(container)
                        container:close()
                    end
                })
            end

            alert({
                body = lang.get("an_error_occurred_while_updating_your_mo"),
                buttons = buttons
            })
        end
    end)
end

return modupdater