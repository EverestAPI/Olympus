local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local threader = require("threader")

local scene = {}


local root = uie.column({
    uie.image("header"),

    uie.row({

        uie.column({
            uie.label("Step 1: Select your installation"),

            uie.column({

                uie.scrollbox(
                    uie.list(
                        {
                            "Steam",
                            "Epic",
                            "Bingo",
                            "Casual",
                            "Custom",
                        }
                    ):with({
                        grow = false
                    }):with(uiu.fillWidth):with(function(list)
                        list.selected = list.children[1]
                    end):as("installs")
                ):with(uiu.fillWidth):with(uiu.fillHeight),

                uie.button("Manage"):with({
                    clip = false,
                    cacheable = false
                }):with(uiu.bottombound):with(uiu.rightbound):as("loadingInstalls")

            }):with({
                style = {
                    padding = 0,
                    bg = {}
                }
            }):with(uiu.fillWidth):with(uiu.fillHeight(true))
        }):with(uiu.fillHeight),

        uie.column({
            uie.label("Step 2: Select version"),
            uie.column({
                uie.label(({{ 1, 1, 1, 1 },
[[Use the newest version for more features and bugfixes.
Use the latest ]], { 0.3, 0.8, 0.5, 1 }, "stable", { 1, 1, 1, 1 }, [[ version if you hate updating.]]})),
            }):with({
                style = {
                    bg = {},
                    border = { 0.1, 0.6, 0.3, 0.7 },
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
            }):with(uiu.fillWidth):with(uiu.fillHeight(true))
        }):with(uiu.fillWidth(-1, true)):with(uiu.fillHeight),

    }):with({
        style = {
            padding = 0,
            bg = {}
        }
    }):with(uiu.fillWidth):with(uiu.fillHeight(true)),

    uie.row({
        uie.button("Step 3: Install"),
        uie.button("Uninstall"),
        uie.button("???", uiu.magic(print, "pressed")),
    }):with({
        style = {
            padding = 0,
            bg = {}
        }
    }):with(uiu.bottombound)

})
scene.root = root


function scene.load()

    threader.routine(function()
        local utilsAsync = threader.wrap("utils")
        local builds = utilsAsync.downloadJSON("https://dev.azure.com/EverestAPI/Everest/_apis/build/builds"):result().value
        -- TODO: Limit commits range
        local commits = utilsAsync.downloadJSON("https://api.github.com/repos/EverestAPI/Everest/commits"):result()

        local offset = 700
        local list = root:findChild("versions")
        for bi = 1, #builds do
            local build = builds[bi]

            if (build.status == "completed" or build.status == "succeeded") and (build.reason == "manual" or build.reason == "individualCI") then
                local text = tostring(build.id + offset)

                local branch = build.sourceBranch:gsub("refs/heads/", "")
                if branch ~= "master" then
                    text = text .. " (" .. branch .. ")"
                end

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

                local item = uie.listItem(text, build)
                if branch == "stable" then
                    item.style.normalBG = { 0.08, 0.2, 0.12, 0.6 }
                    item.style.hoveredBG = { 0.36, 0.46, 0.39, 0.7 }
                    item.style.pressedBG = { 0.1, 0.5, 0.2, 0.7 }
                    item.style.selectedBG = { 0.1, 0.6, 0.3, 0.7 }
                end
                list:addChild(item)
            end
        end

        root:findChild("loadingVersions"):removeSelf()
    end)

end


function scene.enter()

end


return scene
