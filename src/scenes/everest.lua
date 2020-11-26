local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local threader = require("threader")
local scener = require("scener")
local config = require("config")
local sharp = require("sharp")
local mainmenu = scener.preload("mainmenu")

local scene = {
    name = "Everest Installer"
}


local root = uie.column({
    uie.row({

        mainmenu.createInstalls(),

        uie.column({
            uie.label("Versions", ui.fontBig),
            uie.column({
                uie.label(({{ 1, 1, 1, 1 },
[[Use the newest version for more features and bugfixes.
Use the latest ]], { 0.3, 0.8, 0.5, 1 }, "stable", { 1, 1, 1, 1 }, " or ", { 0.8, 0.8, 0.5, 1 }, "beta", { 1, 1, 1, 1 }, [[ version if you hate updating.]]})),
            }):with({
                style = {
                    radius = 3,
                }
            }):with(uiu.fillWidth),

            uie.column({

                uie.scrollbox(
                    uie.list({
                    }):with({
                        grow = false
                    }):with(uiu.fillWidth):with(function(list)
                        list.selected = list.children[1]
                    end):as("versions")
                ):with(uiu.fillWidth):with(uiu.fillHeight),

                uie.row({
                    uie.label("Loading"),
                    uie.spinner():with({
                        width = 16,
                        height = 16
                    })
                }):with({
                    clip = false,
                    cacheable = false
                }):with(uiu.bottombound):with(uiu.rightbound):as("loadingVersions")

            }):with({
                style = {
                    padding = 0,
                    bg = {}
                }
            }):with(uiu.fillWidth):with(uiu.fillHeight(true)):as("versionsParent")
        }):with(uiu.fillWidth(-1, true)):with(uiu.fillHeight),

    }):with({
        style = {
            padding = 0,
            bg = {}
        }
    }):with(uiu.fillWidth):with(uiu.fillHeight(true)),

    uie.row({
        uie.button("Step 3: Install", function()
            scene.install()
        end):hook({
            update = function(orig, self, ...)
                local root = scene.root
                local selected = root:findChild("installs").selected
                self.enabled = selected and root:findChild("versions").selected
                selected = selected and selected.data
                selected = selected and selected.version
                self.text = (selected and selected:match("%+")) and "Step 3: Update" or "Step 3: Install"
                orig(self, ...)
            end
        }):with(uiu.fillWidth(8, true)):as("install"),

        uie.button("Uninstall"):hook({
            update = function(orig, self, ...)
                local root = scene.root
                local selected = root:findChild("installs").selected
                selected = selected and selected.data
                selected = selected and selected.version
                selected = selected and selected:match("%+")
                self.enabled = selected
                orig(self, ...)
            end
        }):with(uiu.rightbound):as("uninstall")
    }):with({
        style = {
            padding = 0,
            bg = {}
        }
    }):with(uiu.fillWidth):with(uiu.bottombound)

})
scene.root = root


function scene.install()
    local install = root:findChild("installs").selected
    install = install and install.data

    local version = root:findChild("versions").selected
    version = version and version.data

    if not install or not version then
        return
    end

    local installer = scener.set("installer")
    installer.update(string.format("Preparing installation of Everest %s", version.version), false, "")

    threader.routine(function()
        local task = sharp.installEverest(install.entry.path, version.artifactBase):result()
        while sharp.status(task):result() == "running" do
            local result = { sharp.poll(task):result() }
            if type(result[1]) ~= "table" then
                print("task poll invalid value", result)
                error("task poll gave " .. type(result[1]) .. " not table, " .. tostring(result[1]))
            end
            installer.update(table.unpack(result[1]))
        end

        local last = sharp.poll(task):result()
        if sharp.status(task):result() == "error" then
            last[2] = 1
            last[3] = "error"
        end

        installer.update(table.unpack(last))
    end)

end

function scene.uninstall()
    local install = root:findChild("installs").selected
    install = install and install.data

    if not install then
        return
    end

end


function scene.load()

    threader.routine(function()
        local utilsAsync = threader.wrap("utils")
        local buildsTask = utilsAsync.downloadJSON("https://dev.azure.com/EverestAPI/Everest/_apis/build/builds")
        -- TODO: Limit commits range
        local commitsTask = utilsAsync.downloadJSON("https://api.github.com/repos/EverestAPI/Everest/commits")

        local builds, buildsError = buildsTask:result()
        if not builds then
            root:findChild("loadingVersions"):removeSelf()
            root:findChild("versionsParent"):addChild(uie.row({
                uie.label("Error downloading builds list: " .. tostring(buildsError)),
            }):with({
                clip = false,
                cacheable = false
            }):with(uiu.bottombound):with(uiu.rightbound):as("error"))
            return
        end
        builds = builds.value

        local commits, commitsError = commitsTask:result()
        if not commits then
            root:findChild("versionsParent"):addChild(uie.row({
                uie.label("Error downloading commits list: " .. tostring(commitsError)),
            }):with({
                clip = false,
                cacheable = false
            }):with(uiu.bottombound):with(uiu.rightbound):as("error"))
        end

        local offset = 700
        local list = root:findChild("versions")
        for bi = 1, #builds do
            local build = builds[bi]

            if (build.status == "completed" or build.status == "succeeded") and (build.reason == "manual" or build.reason == "individualCI") then
                local text = tostring(build.id + offset)

                local branch = build.sourceBranch:gsub("refs/heads/", "")
                if branch ~= "dev" then
                    text = text .. " (" .. branch .. ")"
                end

                local version = text

                local info = ""

                local time = build.finishTime
                if time then
                    info = info .. " ∙ " .. os.date("%Y-%m-%d %H:%M:%S", utils.dateToTimestamp(time))
                end

                local sha = build.sourceVersion
                if sha and commits then
                    for ci = 1, #commits do
                        local c = commits[ci]
                        if c.sha == sha then
                            if c.commit.author.email == c.commit.committer.email then
                                info = info .. " ∙ " .. c.author.login
                            end

                            local message = c.commit.message
                            local nl = message:find("\n")
                            if nl then
                                message = message:sub(1, nl - 1)
                            end

                            info = info .. "\n" .. message

                            break
                        end
                    end
                end

                if #info ~= 0 then
                    text = { { 1, 1, 1, 1 }, text, { 1, 1, 1, 0.5 }, info }
                end

                build.version = version
                build.artifactBase = "https://dev.azure.com/EverestAPI/Everest/_apis/build/builds/" .. build.id .. "/artifacts?$format=zip&artifactName="

                local item = uie.listItem(text, build):with(uiu.fillWidth)
                item.label.wrap = true
                if branch == "stable" then
                    item.style.normalBG = { 0.2, 0.4, 0.2, 0.7 }
                    item.style.hoveredBG = { 0.36, 0.46, 0.39, 0.8 }
                    item.style.pressedBG = { 0.1, 0.5, 0.2, 0.8 }
                    item.style.selectedBG = { 0.5, 0.8, 0.5, 0.8 }
                elseif branch == "beta" then
                    item.style.normalBG = { 0.6, 0.6, 0.1, 0.7 }
                    item.style.hoveredBG = { 0.7, 0.7, 0.3, 0.8 }
                    item.style.pressedBG = { 0.4, 0.4, 0.2, 0.8 }
                    item.style.selectedBG = { 0.8, 0.8, 0.3, 0.8 }
                end
                list:addChild(item)
            end
        end

        root:findChild("loadingVersions"):removeSelf()
    end)

end


function scene.enter()
    mainmenu.reloadInstalls()
end


return scene
