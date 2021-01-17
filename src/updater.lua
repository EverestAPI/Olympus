local utils = require("utils")
local config = require("config")
local threader = require("threader")
local notify = require("notify")
local alert = require("alert")
local scener = require("scener")
local sharp = require("sharp")
local ffi = require("ffix")

local updater = {}


function updater.check()
    if updater.checking then
        return updater.checking
    end

    updater.checking = threader.routine(function()
        updater.latest = nil

        local versionOld, extraOld = utils.load("version.txt"):match("(.*)-(.*-.*-[^\n]*)")
        local srcOld, idOld = (extraOld or "?"):match("(.*)-(.*)-.*")
        idOld = tonumber(idOld)
        if not idOld then
            notify("Cannot determine currently running version of Olympus!")
        end

        local options = scener.preload("options")
        local changelog, updatebtn = options.root:findChild("changelog", "updatebtn")

        changelog.text = "Checking for updates..."
        updatebtn.enabled = false
        updatebtn:reflow()

        local utilsAsync = threader.wrap("utils")
        local builds, buildsError = utilsAsync.downloadJSON("https://dev.azure.com/EverestAPI/Olympus/_apis/build/builds"):result()

        if not builds then
            notify("Error downloading builds list: " .. tostring(buildsError))
            return false
        end
        builds = builds.value

        for bi = 1, #builds do
            local build = builds[bi]

            if (build.status == "completed" or build.status == "succeeded") and (build.reason == "manual" or build.reason == "individualCI") then
                local id = build.id
                local branch = build.sourceBranch:gsub("refs/heads/", "")
                if id <= idOld then
                    break

                elseif config.updates:match(branch, 1, false) then
                    local latest = {
                        id = id,
                        branch = branch,
                        version = build.buildNumber
                    }
                    updater.latest = latest

                    notify(string.format([[
There's a newer version of Olympus available.
Go to the options menu to update to %s]], build.buildNumber))

                    local changelogTask = utilsAsync.download(string.format("https://raw.githubusercontent.com/EverestAPI/Olympus/%s/changelog.txt", build.sourceVersion))

                    local function setChangelog(changelogText)
                        changelog.text = {{ 1, 1, 1, 1 },
                            "Currently installed:\n" .. versionOld, { 1, 1, 1, 0.5 }, "-" .. extraOld .. "\n\n", { 1, 1, 1, 1 },
                            "Newest available:\n" .. build.buildNumber, { 1, 1, 1, 0.5 }, string.format("-azure-%s-%s", build.id, build.sourceVersion and build.sourceVersion:sub(1, 5) or "?????") .. "\n\n", { 1, 1, 1, 1 },
                            "Changelog:\n" .. changelogText
                        }
                    end

                    setChangelog("Downloading...")
                    changelogTask:calls(function(task, data, error)
                        data = data and data:match("#changelog#\n(.*)")
                        if not data then
                            setChangelog("Failed to download:\n" .. tostring(error))
                            return
                        end

                        latest.changelog = data
                        setChangelog(data)
                    end)

                    updatebtn.enabled = true
                    updatebtn.cb = function()
                        if srcOld ~= "dev" then
                            updater.update(tostring(build.id))
                            return
                        end

                        alert({
                            body = "One does not simply update a devbuild.",
                            buttons = {
                                { "OK", function(container)
                                    if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
                                        updater.update(tostring(build.id))
                                    end
                                    container:close("OK")
                                end }
                            },
                            init = function(container)
                                container:findChild("buttons").children[1]:hook({
                                    update = function(orig, self, dt)
                                        orig(self, dt)
                                        if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
                                            self.text = "I know what I'm doing."
                                        else
                                            self.text = "OK"
                                        end
                                    end
                                })
                            end
                        })
                    end
                    updatebtn:reflow()

                    updater.checking = nil
                    return
                end
            end
        end

        changelog.text = {{ 1, 1, 1, 1 },
            "Currently installed:\n" .. versionOld, { 1, 1, 1, 0.5 }, "-" .. extraOld .. "\n\n", { 1, 1, 1, 1 },
            "No updates found."
        }
        updatebtn.enabled = false
        updatebtn:reflow()

        updater.checking = nil
    end)
    return updater.checking
end


function updater.update(id)
    local installer = scener.push("installer")
    installer.update("Preparing update of Olympus", false, "")

    installer.sharpTask("installOlympus", id):calls(function(task, last)
        if not last then
            return
        end

        installer.update("Olympus successfully updated", 1, "done")
        installer.done({
            {
                "Restart",
                function()
                    sharp.restart(love.filesystem.getSource()):result()
                    love.event.quit()
                end
            }
        })
    end)
end


return updater
