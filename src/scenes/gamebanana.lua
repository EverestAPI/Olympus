local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local threader = require("threader")
local config = require("config")
local alert = require("alert")

local scene = {
    name = "GameBanana"
}


local root = uie.column({

    uie.scrollbox(
        uie.column({
        }):with({
            style = {
                bg = {},
                padding = 0,
                spacing = 2
            },
            cacheable = false
        }):with(uiu.fillWidth):as("mods")
    ):with({
        style = {
            barPadding = 16,
        },
        clip = false,
        cacheable = false
    }):with(uiu.fillWidth):with(uiu.fillHeight(59)):with(uiu.at(0, 59)),

    uie.column({
        uie.group():with({
            height = 32
        }),

        uie.row({

            uie.button(
                uie.row({
                    uie.icon("browser"):with({ scale = 24 / 256 }),
                    uie.label("Go to gamebanana.com"):with({ y = 2 })
                }):with({ style = { bg = {}, padding = 0 } }),
                function()
                    utils.openURL("https://gamebanana.com/games/6460")
                end
            ),

            uie.row({

                uie.button("<<<", function()
                    scene.loadPage(scene.page - 1)
                end):as("pagePrev"),
                uie.label("Page #?", ui.fontBig):with({
                    y = 4
                }):as("pageLabel"),
                uie.button(">>>", function()
                    scene.loadPage(scene.page + 1)
                end):as("pageNext"),

            }):with({
                style = {
                    bg = {},
                    padding = 0,
                    spacing = 24
                },
                cacheable = false,
                clip = false
            }):hook({
                layoutLateLazy = function(orig, self)
                    -- Always reflow this child whenever its parent gets reflowed.
                    self:layoutLate()
                end,

                layoutLate = function(orig, self)
                    orig(self)
                    self.x = math.floor(self.parent.innerWidth * 0.5 - self.width * 0.5)
                    self.realX = math.floor(self.parent.width * 0.5 - self.width * 0.5)
                end
            })

        }):with({
            style = {
                bg = {},
                padding = 0
            },
            cacheable = false,
            clip = false
        }):with(uiu.fillWidth)
    }):with({
        style = {
            patch = "ui:patches/topbar",
            spacing = 0
        }
    }):with(uiu.at(0, -32)):with(uiu.fillWidth),

}):with({
    style = {
        spacing = 2
    },
    cacheable = false,
    _fullroot = true
})
scene.root = root


scene.cache = {}


function scene.loadPage(page)
    if scene.loadingPage then
        return scene.loadingPage
    end

    scene.loadingPage = threader.routine(function()
        local list, pagePrev, pageLabel, pageNext = root:findChild("mods", "pagePrev", "pageLabel", "pageNext")

        if page < 1 then
            page = 1
        end

        list.children = {}
        list:reflow()
        pagePrev.enabled = false
        pageNext.enabled = false
        pagePrev:reflow()
        pageNext:reflow()
        pageLabel.text = "Page #" .. tostring(page)

        scene.page = page

        local loading = uie.row({
            uie.label("Loading"),
            uie.spinner():with({
                width = 16,
                height = 16
            })
        }):with({
            clip = false,
            cacheable = false
        }):with(uiu.bottombound(16)):with(uiu.rightbound(16)):as("loadingMods")
        scene.root:addChild(loading)

        local entries, entriesError = scene.downloadEntries(page)
        if not entries then
            loading:removeSelf()
            root:addChild(uie.row({
                uie.label("Error downloading mod list: " .. tostring(entriesError)),
            }):with({
                clip = false,
                cacheable = false
            }):with(uiu.bottombound):with(uiu.rightbound):as("error"))
            scene.loadingPage = nil
            pagePrev.enabled = page > 1
            pageNext.enabled = true
            pagePrev:reflow()
            pageNext:reflow()
            return
        end

        local infos, infosError = scene.downloadInfo(entries)
        if not infos then
            loading:removeSelf()
            root:addChild(uie.row({
                uie.label("Error downloading mod info: " .. tostring(infosError)),
            }):with({
                clip = false,
                cacheable = false
            }):with(uiu.bottombound):with(uiu.rightbound):as("error"))
            scene.loadingPage = nil
            pagePrev.enabled = page > 1
            pageNext.enabled = true
            pagePrev:reflow()
            pageNext:reflow()
            return
        end

        for ii = 1, #infos do
            list:addChild(scene.item(infos[ii]))
        end

        loading:removeSelf()
        scene.loadingPage = nil
        pagePrev.enabled = page > 1
        pageNext.enabled = true
        pagePrev:reflow()
        pageNext:reflow()
    end)
    return scene.loadingPage
end


function scene.load()
    scene.loadPage(1)

end


function scene.enter()

end


function scene.downloadEntries(page)
    local url = "https://api.gamebanana.com/Core/List/New?gameid=6460&page=" .. tostring(page)
    local data = scene.cache[url]
    if data ~= nil then
        return data
    end

    local msg
    data, msg = threader.wrap("utils").downloadJSON(url):result()
    if data then
        scene.cache[url] = data
    end
    return data, msg
end


function scene.downloadInfo(entries, id)
    if not entries then
        return threader.wrap("utils").nop()
    end

    local function mcitem(index, key, value)
        return string.format("&%s[%d]=%s", key, index, value)
    end

    if id then
        entries = {{ entries, id }}
        mcitem = function(index, key, value)
            return string.format("&%s=%s", key, value)
        end
    end

    local multicall = ""
    for ei = 1, #entries do
        local entry = entries[ei]

        local i = ei - 1
        multicall = multicall ..
            mcitem(i, "itemtype", entry[1]) ..
            mcitem(i, "itemid", tostring(entry[2])) ..
            mcitem(i, "fields", "Withhold().bIsWithheld(),name,Owner().name,date,description,text,views,likes,downloads,screenshots,Files().aFiles(),Url().sGetDownloadUrl()")
    end

    local url = "https://api.gamebanana.com/Core/Item/Data?" .. multicall:sub(2)
    local data = scene.cache[url]
    if data ~= nil then
        return data
    end

    local msg
    data, msg = threader.wrap("utils").downloadJSON(url):result()
    if data then
        scene.cache[url] = data
    end
    return data, msg
end


function scene.item(info)
    if not info then
        return nil
    end

    local withheld, name, owner, date, description, text, views, likes, downloads, screenshotsRaw, files, website = table.unpack(info)

    if withheld then
        return nil
    end

    website = website:gsub("/download/", "/")

    local file
    for k, v in pairs(files) do
        file = v
        file._id = k
        break
    end

    local containsEverestYaml = false
    if file and file._aMetadata and file._aMetadata._aArchiveFileTree then
        for k, v in pairs(file._aMetadata._aArchiveFileTree) do
            if v == "everest.yaml" then
                containsEverestYaml = k
                break
            end
        end
    end

    local item = uie.group({
        uie.group({
        }):with({
            clip = false,
            cacheable = false
        }):with(uiu.fill):as("bgholder"),

        uie.panel({
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
                style.bg = { boxBG[1], boxBG[2], boxBG[3], 0.5 }
            end
        }):with({
            style = {
                padding = 0,
                radius = 0,
                patch = false
            }
        }):with(uiu.fill):as("bgdarken"),

        uie.group({

            uie.column({

                uie.row({

                    uie.column({

                        uie.label({ { 1, 1, 1, 1 }, name, { 1, 1, 1, 0.5 }, " ∙ " .. owner .. " ∙ " .. os.date("%Y-%m-%d %H:%M:%S", date) }):as("title"),

                        uie.row({
                            uie.group({
                                uie.spinner():with({ time = love.math.random() }),
                            }):as("imgholder"),

                            uie.column({
                                uie.label({ { 1, 1, 1, 0.5 }, uiu.countformat(views, "%d view", "%d views") .. " ∙ " .. uiu.countformat(likes, "%d like", "%d likes") .. " ∙ " .. uiu.countformat(downloads, "%d download", "%d downloads"), }):as("stats"),
                                description and #description ~= 0 and uie.label(description):with({ wrap = true }):as("description"),
                            }):with({
                                style = {
                                    padding = 0,
                                    bg = {}
                                }
                            }):with(uiu.fillWidth(16, true))

                        }):with({
                            style = {
                                padding = 0,
                                spacing = 16,
                                bg = {}
                            }
                        }):with(uiu.fillWidth),

                    }):with({
                        style = {
                            padding = 0,
                            bg = {}
                        },
                        clip = false,
                        cacheable = false
                    }):with(uiu.fillWidth(true)),

                    uie.row({

                        uie.button(
                            uie.icon("browser"):with({ scale = 24 / 256 }),
                            function()
                                utils.openURL(website)
                            end
                        ),

                        uie.button(
                            uie.icon("article"):with({ scale = 24 / 256 }),
                            function()
                                alert({
                                    title = name,
                                    body = uie.scrollbox(
                                        uie.label(utils.cleanHTML(text)):with({
                                            wrap = true
                                        })
                                    ):with(uiu.fillWidth):with(uiu.fillHeight(true)),
                                    buttons = {
                                        {
                                            "Open in browser",
                                            function()
                                                utils.openURL(website)
                                            end
                                        },
                                        { "Close" }
                                    },
                                    init = function(container)
                                        container:findChild("box"):with({
                                            width = 800
                                        }):with(uiu.fillHeight(64))
                                        container:findChild("buttons"):with(uiu.bottombound)
                                    end
                                })
                            end
                        ),

                        containsEverestYaml and uie.button(
                            uie.icon("download"):with({ scale = 24 / 256 }),
                            function()
                                local btns = {}

                                for _, file in pairs(files) do
                                    local containsEverestYaml = false
                                    if file and file._aMetadata and file._aMetadata._aArchiveFileTree then
                                        for k, v in pairs(file._aMetadata._aArchiveFileTree) do
                                            if v == "everest.yaml" then
                                                containsEverestYaml = k
                                                break
                                            end
                                        end
                                    end

                                    if containsEverestYaml then
                                        btns[#btns + 1] = uie.button(
                                            { { 1, 1, 1, 1 }, file._sFile, { 1, 1, 1, 0.5 }, " ∙ " .. uiu.countformat(file._nDownloadCount, "%d download", "%d downloads") .. "\n" .. file._sDescription},
                                            function()
                                            end
                                        ):with({
                                            date = file._tsDateAdded
                                        })
                                    end
                                end

                                table.sort(btns, function(a, b)
                                    return a.date > b.date
                                end)

                                alert({
                                    title = name,
                                    body = uie.scrollbox(
                                        uie.column(btns):with({
                                            style = {
                                                bg = {},
                                                padding = 0
                                            }
                                        })
                                    ),
                                    init = function(container)
                                        btns[#btns + 1] = uie.button("Close", function()
                                            container:close("Close")
                                        end)
                                        container:findChild("buttons"):removeSelf()

                                        local body = container:findChild("body")

                                        if #btns < 6 then
                                            body:with({
                                                calcSize = uie.group.calcSize
                                            })
                                            container:hook({
                                                awake = function(orig, self)
                                                    orig(self)
                                                    self:layoutLazy()
                                                    self:layoutLateLazy()
                                                    if self:findChild("title").width > body.width then
                                                        body:with(uiu.fillWidth)
                                                        local el = body.children[1]
                                                        el:with(uiu.fillWidth)
                                                        local children = el.children
                                                        for i = 1, #children do
                                                            children[i]:with(uiu.fillWidth)
                                                        end
                                                    else
                                                        local el = body.children[1]
                                                        local children = el.children
                                                        local widest = 0
                                                        for i = 1, #children do
                                                            local width = children[i].width
                                                            if width > widest then
                                                                widest = width
                                                            end
                                                        end
                                                        for i = 1, #children do
                                                            if children[i].width < widest then
                                                                children[i]:with(uiu.fillWidth):reflow()
                                                            end
                                                        end
                                                    end
                                                    self:reflowDown()
                                                    self:reflow()
                                                end
                                            })

                                        else
                                            body:with(uiu.fillWidth):with(uiu.fillHeight(true))
                                            local el = body.children[1]
                                            el:with(uiu.fillWidth)
                                            local children = el.children
                                            for i = 1, #children do
                                                children[i]:with(uiu.fillWidth)
                                            end
                                            container:findChild("box"):with(uiu.fillHeight(64))
                                        end
                                    end
                                })
                            end
                        )

                    }):with({
                        style = {
                            padding = 0,
                            bg = {}
                        },
                        clip = false,
                        cacheable = false
                    }):with(uiu.rightbound)

                }):with({
                    style = {
                        bg = {}
                    },
                    clip = false,
                    cacheable = false
                }):with(uiu.fillWidth),

                --[[
                uie.group({
                    uie.label(utils.cleanHTML(text)):with({ wrap = true }):as("text")
                }):with(uiu.fillWidth),
                --]]

            }):with({
                clip = false,
                cacheable = false
            }):with(uiu.fillWidth):as("content"),

        }):with({
            style = {
                padding = 16
            },
            clip = false,
            cacheable = false
        }):with(uiu.fillWidth)

    }):with({
        clip = false,
        cacheable = false
    }):with(uiu.fillWidth)

    threader.routine(function()
        local utilsAsync = threader.wrap("utils")

        local bgholder = item:findChild("bgholder")
        local imgholder = item:findChild("imgholder")

        local screenshots = utilsAsync.fromJSON(screenshotsRaw):result()

        local bg, img

        local function downloadImage(name, url)
            local img = scene.cache[url]
            if img ~= nil then
                return img
            end

            img = utilsAsync.download(url):result()
            if not img then
                return false
            end

            img = love.filesystem.newFileData(img, name)
            img = love.graphics.newImage(img)
            scene.cache[url] = img
            return img
        end

        if not screenshots[1]._sFile:match("%.webp$") then
            -- TODO: WEBP SUPPORT
            img = downloadImage(screenshots[1]._sFile, "https://files.gamebanana.com/" .. screenshots[1]._sRelativeImageDir .. "/" .. screenshots[1]._sFile100)
        end

        if screenshots[2] and not screenshots[2]._sFile:match("%.webp$") then
            -- TODO: WEBP SUPPORT
            bg = downloadImage(screenshots[2]._sFile, "https://files.gamebanana.com/" .. screenshots[2]._sRelativeImageDir .. "/" .. screenshots[2]._sFile)
        end

        bg = bg or img

        imgholder.children[1]:removeSelf()
        if bg then
            local effect = ui.root:findChild("bg").effect
            bg = uie.image(bg):with({
                cacheForce = true,
                cachePadding = 0
            }):hook({
                update = function(orig, self)
                    local image = self._image
                    local width, height = image:getWidth(), image:getHeight()
                    local fwidth, fheight = love.graphics.getWidth(), love.graphics.getHeight()

                    if width >= height then
                        self.scale = (fwidth + 512) / width

                    else
                        self.scale = (fheight + 512) / height
                    end

                    self.ix = fwidth * 0.5 - width * self.scale * 0.5 - (ui.mouseX - fwidth * 0.5) * 0.013
                    self.iy = fheight * 0.5 - height * self.scale * 0.5 - (ui.mouseY - fheight * 0.5) * 0.013

                    if orig then
                        orig(self)
                    end
                end,

                drawBG = function(orig, self)
                    if not self.ix then
                        self:update()
                    end
                    love.graphics.draw(self._image, self.ix - self.screenX * 0.8, self.iy - self.screenY * 0.8, 0, self.scale, self.scale)
                end,

                draw = function(orig, self)
                    if not config.quality.bg then
                        return
                    end

                    love.graphics.push()
                    love.graphics.origin()

                    love.graphics.setColor(1, 1, 1, 1)

                    if not ui.debug.draw and config.quality.bgBlur then
                        effect(self.drawBG, self)
                    else
                        self:drawBG()
                    end

                    love.graphics.pop()

                    uiu.resetColor()
                end
            }):with(uiu.fill)
            bgholder:addChild(bg)
        end
        if img then
            imgholder:addChild(uie.image(img))
        end
        item:reflowDown()
    end)

    return item
end


return scene
