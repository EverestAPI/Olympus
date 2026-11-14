local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local threader = require("threader")
local alert = require("alert")
local config = require("config")
local sharp = require("sharp")
local scener = require("scener")
local fs = require("fs")
local lang = require("lang")

local modupdater = {}

local function recapAlert(message)
    alert({
        body = uie.scrollbox(uie.label(message))
            :with(uiu.hook({
                calcSize = function (orig, self, width, height)
                    uie.group.calcSize(self)
                end
            }))
            :with({ maxHeight = 300 }),
        buttons = {{ lang.get("ok") }}
    })
end

local function updateEverest(path, willRunGame, callback, showRecap, recapMessage)
    threader.routine(function()
        local dir = path or config.installs[config.install].path

        local finish = function()
            callback()

            if showRecap and recapMessage then
                recapAlert(recapMessage)
            end
        end

        local versionString = sharp.getVersionString(dir):result()

        local installedBranch
        local installedNumber
        if versionString then
            local everest = versionString:match("Everest ([^ ]+)")
            if everest then
                installedNumber = tonumber(everest:match("^1%.([0-9]+)%.0-"))
                installedBranch = everest:match("%-([a-z]+)$")
            end
        end

        -- Only update Everest if it's already installed, don't install it on the user's behalf.
        if not installedNumber or not installedBranch then
            finish()
            return
        end

        if installedBranch ~= "dev" and installedBranch ~= "beta" and installedBranch ~= "stable" then
            installedBranch = "stable"
        end

        local builds, buildsError = threader.wrap("utils").downloadJSON(
            config.apiMirror
            and "https://everestapi.github.io/updatermirror/everest_versions.json"
            or "https://maddie480.ovh/celeste/everest-versions"
        ):result()

        if not builds then
            alert({
                body = lang.get("an_error_occurred_while_updating_everest") .. tostring(buildsError),
                buttons = {
                    {
                        lang.get("retry"),
                        function(container)
                            container:close()
                            updateEverest(path, willRunGame, callback, showRecap, recapMessage)
                        end
                    },
                    {
                        willRunGame and lang.get("run_anyway") or lang.get("cancel"),
                        function(container)
                            finish()
                            container:close()
                        end
                    }
                }
            })
            return
        end

        local latestBuild
        for bi = 1, #builds do
            if builds[bi].branch == config.everestUpdateBranch then
                latestBuild = builds[bi]
                break
            end
        end

        if not latestBuild then
            alert({
                body = string.format(lang.get("could_not_find_everest_build_for_branch"), config.everestUpdateBranch),
                buttons = {
                    {
                        willRunGame and lang.get("run_anyway") or lang.get("cancel"),
                        function(container)
                            finish()
                            container:close()
                        end
                    }
                }
            })
            return
        end

        local targetNumber = tonumber(latestBuild.version) or 0
        local updateNeeded = installedBranch ~= config.everestUpdateBranch or installedNumber < targetNumber

        if not updateNeeded then
            finish()
            return
        end

        local installer = scener.push("installer")
        installer.update(string.format(lang.get("preparing_installation_of_everest_s"), latestBuild.version), false, "")

        installer.sharpTask("installEverest", dir, latestBuild.mainDownload, latestBuild.olympusMetaDownload, latestBuild.olympusBuildDownload):calls(function(task, last)
            if not last then
                return
            end

            installer.update(string.format(lang.get("everest_s_successfully_installed"), latestBuild.version), 1, "done")

            if willRunGame then
                installer.done({
                    {
                        lang.get("launch"),
                        function()
                            finish()
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
            else
                installer.done({
                    {
                        lang.get("ok"),
                        function()
                            finish()
                            scener.pop()
                        end
                    }
                })
            end
        end)
    end)
end

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
            if config.updateEverestOnModUpdate == "enabled" then
                updateEverest(path, willRunGame, callback, showRecap, lastStatusLine)
            else
                callback()

                if showRecap then
                    recapAlert(lastStatusLine)
                end
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