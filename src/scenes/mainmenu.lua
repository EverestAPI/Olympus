local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local threader = require("threader")
local scener = require("scener")
local alert = require("alert")
local notify = require("notify")
local config = require("config")
local sharp = require("sharp")
local updater = require("updater")

local scene = {
    name = "Main Menu"
}


local function checkInstall(forceInstall)
    if not forceInstall or config.installs[config.install] then
        return true
    end

    alert({
        body = [[
Your Celeste installation list is empty.
Do you want to go to the Celeste installation manager?]],
        buttons = {
            {
                "Yes",
                function(container)
                    scener.push("installmanager")
                    container:close("OK")
                end
            },
            { "No" }
        }
    })

    return false
end


local function buttonBig(icon, text, scene, forceInstall)
    return uie.button(
        uie.row({
            uie.icon(icon):with({ scale = 48 / 256 }),
            uie.label(text, ui.fontBig):with({ x = -4, y = 11 })
        }):with({ style = { bg = {}, padding = 0, spacing = 16 } }),
        type(scene) == "function" and scene or function()
            if checkInstall(forceInstall) then
                scener.push(scene)
            end
        end
    ):with({ style = { padding = 8 } })
end

local function button(icon, text, scene, forceInstall)
    return uie.button(
        uie.row({
            uie.icon(icon):with({ scale = 24 / 256 }),
            uie.label(text):with({ y = 2 })
        }):with({ style = { bg = {}, padding = 0 } }),
        type(scene) == "function" and scene or function()
            if checkInstall(forceInstall) then
                scener.push(scene)
            end
        end
    ):with({ style = { padding = 8 } })
end

local function newsEntry(data)
    if not data then
        return nil
    end

    local item = uie.column({

        data.title and uie.label(data.title, ui.fontMedium),

        data.image and uie.group({
            uie.spinner():with({ time = love.math.random() }),
        }):as("imgholder"),

        data.preview and uie.label(data.preview):with({ wrap = true }),

        uie.row({

            data.link and uie.button(
                uie.icon("browser"):with({ scale = 24 / 256 }),
                function()
                    utils.openURL(data.link)
                end
            ),

            data.text and uie.button(
                uie.icon("article"):with({ scale = 24 / 256 }),
                function()
                    alert({
                        title = data.title,
                        body = uie.label(data.text),
                        buttons = data.link and {
                            {
                                "Open in browser",
                                function()
                                    utils.openURL(data.link)
                                end
                            },
                            { "Close" }
                        } or { { "Close" }}
                    })
                end
            ),

        }):with({
            style = {
                padding = 0,
                bg = {}
            },
            clip = false
        }):with(uiu.rightbound)
    }):with(uiu.fillWidth)

    if data.image then
        threader.routine(function()
            local utilsAsync = threader.wrap("utils")
            local imgholder = item:findChild("imgholder")

            local url = data.image
            if url:sub(1, 1) == "." then
                url = "https://everestapi.github.io/olympusnews" .. url:sub(2)
            end

            local imgData = utilsAsync.download(url):result()
            if not imgData then
                imgholder:removeSelf()
                item:reflowDown()
                return
            end

            imgData = love.filesystem.newFileData(imgData, url)
            local status, img = pcall(love.graphics.newImage, imgData)
            if not status or not img then
                imgholder:removeSelf()
                item:reflowDown()
                return
            end

            imgholder.children[1]:removeSelf()
            if img then
                img = uie.image(img):with({
                    scaleRoundAuto = "auto"
                })
                if img.image:getWidth() > (256 - 8 * 2) then
                    img.scale = (256 - 8 * 2) / img.image:getWidth()
                end
                imgholder:addChild(img)
            end
            item:reflowDown()
        end)
    end

    return item
end


function scene.createInstalls()
    return uie.column({
        uie.label("Installations", ui.fontBig),

        uie.column({

            uie.scrollbox(
                uie.list({}, function(self, data)
                    config.install = data.index
                    config.save()
                end):with({
                    grow = false
                }):with(uiu.fillWidth):as("installs")
            ):with(uiu.fillWidth):with(uiu.fillHeight(true)),

            uie.row({

                uie.group({
                    uie.label({ { 1, 1, 1, 0.5 }, "mainmenu.lua broke, please fix." }):with({
                        y = 8
                    }):with(uiu.rightbound):as("installcount")
                }):with(uiu.fillWidth(true)),

                uie.button("Manage", function()
                    scener.push("installmanager")
                end):with({
                    clip = false,
                    cacheable = false
                }):with(utils.important(24, function() return #config.installs == 0 end)):with(uiu.rightbound)

            }):with({
                style = {
                    padding = 0,
                    bg = {}
                },
                clip = false
            }):with(uiu.bottombound):with(uiu.fillWidth)

        }):with({
            style = {
                padding = 0,
                bg = {}
            },
            clip = false
        }):with(uiu.fillWidth):with(uiu.fillHeight(true))
    }):with{
        width = 256
    }:with(uiu.fillHeight)
end


function scene.reloadInstalls(scene, cb)
    local list, counter = scene.root:findChild("installs", "installcount")
    list.children = {}
    counter.text = { { 1, 1, 1, 0.5 }, "Scanning..." }

    local installs = config.installs

    local function handleFound(task, all)
        local new = #all
        for i = 1, #all do
            local found = all[i]
            for j = 1, #installs do
                local existing = installs[j]
                if found.path == existing.path then
                    new = new - 1
                    break
                end
            end
        end

        if new == 0 then
            counter.text = ""
        else
            counter.text = { { 1, 1, 1, 0.5 }, uiu.countformat(new, "%d new install found.", "%d new installs found.")}
        end
    end

    local foundCached = require("finder").getCached()
    if foundCached then
        handleFound(nil, foundCached)
    else
        threader.wrap("finder").findAll():calls(handleFound)
    end

    for i = 1, #installs do
        local entry = installs[i]
        local item = uie.listItem({{1, 1, 1, 1}, entry.name, {1, 1, 1, 0.5}, "\nScanning..."}, { index = i, entry = entry, version = "???" })

        sharp.getVersionString(entry.path):calls(function(t, version)
            version = version or "???"

            local celeste = version:match("Celeste ([^ ]+)")
            local everest = version:match("Everest ([^ ]+)")
            if everest then
                version = celeste .. " + " .. everest

            else
                version = celeste or version
            end

            item.text = {{1, 1, 1, 1}, entry.name, {1, 1, 1, 0.5}, "\n" .. version}
            item.data.version = version
            item.data.versionCeleste = celeste
            item.data.versionEverest = everest
            if cb and item.data.index == config.install then
                cb(item.data)
            end
        end)

        list:addChild(item)
    end

    if #installs == 0 then
        list:addChild(uie.group({
            uie.label([[
Your Celeste installs list is empty.
Press the manage button below.]])
        }):with({
            style = {
                padding = 8
            }
        }))
    end

    list.selected = list.children[config.install or 1] or list.children[1] or false
    list:reflow()

    if cb then
        cb()
    end
end


local root = uie.row({
    uie.column({
        uie.icon("header_olympus"),

        uie.row({

            scene.createInstalls(),

            uie.column({
                buttonBig("mainmenu/gamebanana", "Download Mods", "gamebanana", true):with(uiu.fillWidth),
                buttonBig("mainmenu/berry", "Manage Installed Mods", "modlist", true):with(uiu.fillWidth),
                buttonBig("mainmenu/ahorn", "Ahorn (Map Editor)", "ahornsetup"):with(uiu.fillWidth),
                buttonBig("cogwheel", updater.available and "Options & Updates" or "Options", "options"):with(uiu.fillWidth):with(utils.important(32, function() return updater.latest end)),
                -- button("cogwheel", "[DEBUG] Scene List", "scenelist"):with(uiu.fillWidth),
            }):with({
                style = {
                    padding = 0,
                    bg = {}
                },
                clip = false
            }):with(uiu.fillWidth(true)):with(uiu.fillHeight):as("mainlist"),

        }):with({
            style = {
                padding = 0,
                bg = {}
            },
            clip = false
        }):with(uiu.fillWidth):with(uiu.fillHeight(true)),

    }):hook({
        layoutLateLazy = function(orig, self)
            -- Always reflow this child whenever its parent gets reflowed.
            self:layoutLate()
        end,

        layoutLate = function(orig, self)
            orig(self)
            local style = self.style
            style.bg = nil
            local boxBG = style.bg
            style.bg = { boxBG[1], boxBG[2], boxBG[3], 0.6 }
        end
    }):with(uiu.fillWidth(true)):with(uiu.fillHeight),

    uie.column({
        uie.label("News", ui.fontBig),
        uie.scrollbox(
            uie.column({

                newsEntry({
                    preview = "News machine broke, please fix."
                })

            }):with({
                style = {
                    padding = 0,
                    bg = {}
                },
                clip = false
            }):with(uiu.fillWidth):as("newsfeed")
        ):with({
            style = {
                padding = 0,
                bg = {}
            },
            clip = true,
            clipPadding = { 8, 4, 8, 8 },
            cachePadding = { 8, 4, 8, 8 }
        }):with(uiu.fillWidth):with(uiu.fillHeight(true)),
    }):with({
        width = 256,
    }):with(uiu.fillHeight):with(uiu.rightbound),

})
scene.root = root


scene.installs = root:findChild("installs")
scene.mainlist = root:findChild("mainlist")
scene.launchrow = uie.row({
    buttonBig("mainmenu/everest", "Everest", function()
        utils.launch(nil)
    end):with(uiu.fillWidth(2.5 + 32 + 2 + 4)):with(uiu.at(0, 0)),
    buttonBig("mainmenu/celeste", "Celeste", function()
        utils.launch(nil, true)
    end):with(uiu.fillWidth(2.5 + 32 + 2 + 4)):with(uiu.at(2.5 - 32 - 2, 0)),
    buttonBig("cogwheel", "", "everest"):with({
        width = 48
    }):with(uiu.rightbound)
}):with({
    activated = false,
    style = {
        bg = {},
        padding = 0,
        radius = 0
    },
    clip = false,
    cacheable = false
}):with(uiu.fillWidth):as("launchrow")

scene.installbtn = buttonBig("mainmenu/everest", "Install Everest", "everest"):with(utils.important(32)):with(uiu.fillWidth):as("installbtn")


scene.installs:hook({
    cb = function(orig, self, data)
        orig(self, data)
        scene.updateMainList(data)
    end
})


function scene.updateMainList(install)
    ui.runOnce(function(config, scene, install)
        if not install and #config.installs ~= 0 then
            return
        end

        scene.launchrow:removeSelf()
        scene.installbtn:removeSelf()

        if install and install.versionEverest then
            scene.mainlist:addChild(scene.launchrow, 1)
        else
            scene.mainlist:addChild(scene.installbtn, 1)
        end
    end, config, scene, install)
end


function scene.load()
    threader.routine(function()
        local newsfeed = scene.root:findChild("newsfeed")

        newsfeed.children = {}
        newsfeed:addChild(uie.row({
            uie.label("Loading"),
            uie.spinner():with({
                width = 16,
                height = 16
            }):with(uiu.rightbound)
        }):with({
            clip = false,
            cacheable = false
        }):with(uiu.fillWidth))

        local all = threader.run(function()
            local utils = require("utils")
            local list, err = utils.download("https://everestapi.github.io/olympusnews/index.txt")
            if not list then
                print("failed fetching news index")
                print(err)
                return {
                    {
                        error = true,
                        preview = "Olympus failed fetching the news feed."
                    }
                }
            end

            local all = {
            }

            for entryName in list:gmatch("[^\r\n]+") do
                if entryName:match("%.md$") then
                    all[#all + 1] = entryName
                end
            end

            table.sort(all, function(a, b)
                return b < a
            end)

            for i = 1, #all do
                local entryName = all[i]
                local data, err = utils.download("https://everestapi.github.io/olympusnews/" .. entryName)
                if not data then
                    print("failed fetching news entry", entryName)
                    print(err)
                    all[i] = {
                        error = true,
                        preview = "Olympus failed fetching a news entry."
                    }
                    goto next
                end

                local text
                data, text = data:match("^%-%-%-\n(.-)\n%-%-%-\n(.*)$")
                if not data or not text then
                    print("news entry not in expected format", entryName)
                    all[i] = {
                        error = true,
                        preview = "A news entry was in an unexpected format."
                    }
                    goto next
                end

                local status
                status, data = pcall(utils.fromYAML, data)
                if not status or not data then
                    print("news entry contains malformed yaml", entryName)
                    print(data)
                    all[i] = {
                        error = true,
                        preview = "A news entry contained invalid metadata."
                    }
                    goto next
                end

                if data.ignore then
                    all[i] = false
                    goto next
                end

                local preview, body = text:match("^(.-)\n%-%-%-\n(.*)$")
                if not data.preview and preview and body then
                    data.preview = utils.trim(preview)
                    data.text = utils.trim(body)
                else
                    data.preview = utils.trim(text)
                end

                all[i] = data

                ::next::
            end

            return all
        end):result()

        scene.news = all

        newsfeed.children = {}

        for i = 1, #all do
            newsfeed:addChild(newsEntry(all[i]))
        end
    end)
end


function scene.enter()
    scene.reloadInstalls(scene, scene.updateMainList)

end


return scene
