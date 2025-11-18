local utils = require("utils")
local config = require("config")
local threader = require("threader")
local notify = require("notify")
local alert = require("alert")
local scener = require("scener")
local sharp = require("sharp")
local ffi = require("ffix")
local fs = require("fs")
local lang = require("lang")

local updater = {}

local userOS = love.system.getOS()

if userOS == "Linux" then
    -- Let's assume that the owner of olympus.love is the only one who can self-update it.
    local sourceAttrs = fs.attributes(love.filesystem.getSource())

    if sourceAttrs and sourceAttrs.permissions:match("rw.......") then
        ffi.cdef[[
            int getuid();
            int geteuid();
        ]]
        local owner = tonumber(sourceAttrs.uid)
        updater.available = owner == tonumber(ffi.C.getuid()) or owner == tonumber(ffi.C.geteuid())

    else
        updater.available = false
    end

    -- If the app is flatpak'd then we disable by force the updater
    if fs.isFile("/.flatpak-info") then
        updater.available = false
    end

else
    updater.available = true
end


function updater.check(auto)
    if not updater.available then
        return
    end

    if updater.checking then
        return updater.checking
    end

    updater.checking = threader.routine(function()
        updater.latest = nil

        local versionOld, extraOld = utils.load("version.txt"):match("(.*)-(.*-.*-[^\n]*)")
        local srcOld, idOld = (extraOld or "?"):match("(.*)-(.*)-.*")
        idOld = tonumber(idOld)
        if not idOld then
            notify(lang.get("cannot_determine_currently_running_versi"))
        end

        if auto and srcOld == "dev" then
            updater.checking = nil
            return
        end

        local options = scener.preload("options")
        local changelog, updatebtn = options.root:findChild("changelog", "updatebtn")

        changelog.text = lang.get("checking_for_updates")
        updatebtn.enabled = false
        updatebtn:reflow()

        local utilsAsync = threader.wrap("utils")
        local builds, buildsError = utilsAsync.downloadJSON("https://dev.azure.com/EverestAPI/Olympus/_apis/build/builds"):result()

        if not builds then
            notify(lang.get("error_downloading_builds_list") .. tostring(buildsError))
            return false
        end
        builds = builds.value
        if not builds then
            notify(lang.get("error_downloading_builds_list_invalid_ol"))
            return false
        end

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

                    local cb = function()
                        if srcOld ~= "dev" then
                            updater.update(tostring(build.id))
                            return
                        end

                        alert({
                            body = "One does not simply update a devbuild.",
                            buttons = {
                                { lang.get("ok"), function(container)
                                    if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
                                        updater.update(tostring(build.id))
                                    end
                                    container:close(lang.get("ok"))
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

                    if auto then
                        alert({
                            body = string.format(lang.get("there_is_a_new_version_available_update"), build.buildNumber),
                            buttons = {
                                { lang.get("yes"), function(container)
                                    cb()
                                    container:close(lang.get("ok"))
                                end},
                                { lang.get("no") }
                            }
                        })
                    else
                        notify(string.format(lang.get("there_is_a_new_version_available"), build.buildNumber))
                    end

                    local changelogTask = utilsAsync.download(string.format("https://raw.githubusercontent.com/EverestAPI/Olympus/%s/changelog.txt", build.sourceVersion))

                    local function setChangelog(changelogText)
                        changelog.text = {{ 1, 1, 1, 1 },
                            lang.get("currently_installed_n") .. versionOld, { 1, 1, 1, 0.5 }, "-" .. extraOld .. "\n\n", { 1, 1, 1, 1 },
                            lang.get("newest_available_n") .. build.buildNumber, { 1, 1, 1, 0.5 }, string.format("-azure-%s-%s", build.id, build.sourceVersion and build.sourceVersion:sub(1, 5) or "?????") .. "\n\n", { 1, 1, 1, 1 },
                            lang.get("changelog_n") .. changelogText
                        }
                    end

                    setChangelog(lang.get("downloading"))
                    changelogTask:calls(function(task, data, error)
                        data = data and data:match("#changelog#\n(.*)")
                        if not data then
                            setChangelog(lang.get("failed_to_download_n") .. tostring(error))
                            return
                        end

                        latest.changelog = data
                        setChangelog(data)
                    end)

                    updatebtn.enabled = true
                    updatebtn.cb = cb
                    updatebtn:reflow()

                    updater.checking = nil
                    return
                end
            end
        end

        changelog.text = {{ 1, 1, 1, 1 },
            lang.get("currently_installed_n") .. versionOld, { 1, 1, 1, 0.5 }, "-" .. extraOld .. "\n\n", { 1, 1, 1, 1 },
            lang.get("no_updates_found")
        }
        updatebtn.enabled = false
        updatebtn:reflow()

        updater.checking = nil
    end)
    return updater.checking
end


function updater.update(id)
    if not updater.available then
        return
    end

    local installer = scener.push("installer")
    installer.update(lang.get("preparing_update_of_olympus"), false, "")

    installer.sharpTask("installOlympus", id):calls(function(task, last)
        if not last then
            return
        end

        installer.update(lang.get("olympus_successfully_updated"), 1, "done")
        installer.done({
            {
                lang.get("restart_olympus"),
                function()
                    sharp.restart(love.filesystem.getSource()):result()
                    love.event.quit()
                end
            }
        })
    end)
end


return updater