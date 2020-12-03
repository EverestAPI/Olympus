local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local threader = require("threader")

local scene = {
    name = "GameBanana"
}


local white = {
    style = {
        color = { 1, 1, 1, 1 }
    }
}


local root = uie.column({
    uie.scrollbox(
        uie.column({
        }):with({
            style = {
                bg = {},
                padding = 0,
                spacing = 2
            }
        }):with({
            cacheable = false
        }):with(uiu.fillWidth):as("mods")
    ):with({
        clip = false,
        cacheable = false
    }):with(uiu.fillWidth):with(uiu.fillHeight),

    uie.row({
        uie.label("Loading"),
        uie.spinner():with({
            width = 16,
            height = 16
        })
    }):with({
        clip = false,
        cacheable = false
    }):with(uiu.bottombound(16)):with(uiu.rightbound(16)):as("loadingMods")

}):with({
    cacheable = false,
    _fullroot = true
})
scene.root = root


function scene.load()
    threader.routine(function()
        local list = root:findChild("mods")

        local entries, entriesError = scene.downloadEntries(1):result()
        if not entries then
            root:findChild("loadingMods"):removeSelf()
            root:addChild(uie.row({
                uie.label("Error downloading mod list: " .. tostring(entriesError)),
            }):with({
                clip = false,
                cacheable = false
            }):with(uiu.bottombound):with(uiu.rightbound):as("error"))
            return
        end

        local infos, infosError = scene.downloadInfo(entries):result()
        if not infos then
            root:findChild("loadingMods"):removeSelf()
            root:addChild(uie.row({
                uie.label("Error downloading mod info: " .. tostring(infosError)),
            }):with({
                clip = false,
                cacheable = false
            }):with(uiu.bottombound):with(uiu.rightbound):as("error"))
            return
        end

        for ii = 1, #infos do
            list:addChild(scene.item(infos[ii]))
        end

        root:findChild("loadingMods"):removeSelf()
    end)

end


function scene.enter()

end


function scene.downloadEntries(page)
    return threader.wrap("utils").downloadJSON("https://api.gamebanana.com/Core/List/New?gameid=6460&page=" .. tostring(page))
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
            mcitem(i, "fields", "Withhold().bIsWithheld(),name,Owner().name,date,description,text,views,likes,downloads,screenshots,Files().aFiles()")
    end

    return threader.wrap("utils").downloadJSON("https://api.gamebanana.com/Core/Item/Data?" .. multicall:sub(2))
end


function scene.item(info)
    if not info then
        return nil
    end

    local withheld, name, owner, date, description, text, views, likes, downloads, screenshotsRaw, files = table.unpack(info)

    if withheld then
        return nil
    end

    local item = uie.group({
        uie.group({
        }):with({
            clip = false,
            cacheable = false
        }):with(uiu.fill):as("bgholder"),

        uie.panel({
        }):with({
            style = {
                padding = 0,
                radius = 0,
                bg = { 0, 0, 0, 0.8 },
                patch = false
            }
        }):with(uiu.fill):as("bgdarken"),

        uie.column({

            uie.label({ { 1, 1, 1, 1 }, name, { 1, 1, 1, 0.5 }, " ∙ " .. owner .. " ∙ " .. os.date("%Y-%m-%d %H:%M:%S", date) }):with(white):as("title"),

            uie.row({
                uie.group({
                    uie.spinner():with({ time = love.math.random() }):with(white),
                }):as("imgholder"),

                uie.column({
                    uie.label({ { 1, 1, 1, 0.5 }, uiu.countformat(views, "%d view", "%d views") .. " ∙ " .. uiu.countformat(likes, "%d like", "%d likes") .. " ∙ " .. uiu.countformat(downloads, "%d download", "%d downloads"), }):with(white):as("stats"),
                    description and #description ~= 0 and uie.label(description):with({ wrap = true }):with(white):as("description"),
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

            --[[
            uie.group({
                uie.label(utils.cleanHTML(text)):with({ wrap = true }):as("text")
            }):with(uiu.fillWidth),
            --]]

        }):with({
            clip = false,
            cacheable = false,
            style = {
                bg = {},
                padding = 24
            }
        }):with(uiu.fillWidth):as("content"),

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

        if not screenshots[1]._sFile:match("%.webp$") then
            -- TODO: WEBP SUPPORT
            img = utilsAsync.download("https://files.gamebanana.com/" .. screenshots[1]._sRelativeImageDir .. "/" .. screenshots[1]._sFile100):result()
            img = love.filesystem.newFileData(img, screenshots[1]._sFile)
            img = love.graphics.newImage(img)
        end

        if screenshots[2] and not screenshots[2]._sFile:match("%.webp$") then
            -- TODO: WEBP SUPPORT
            bg = utilsAsync.download("https://files.gamebanana.com/" .. screenshots[2]._sRelativeImageDir .. "/" .. screenshots[2]._sFile):result()
            bg = love.filesystem.newFileData(bg, screenshots[2]._sFile)
            bg = love.graphics.newImage(bg)
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
                    love.graphics.push()
                    love.graphics.origin()
                    if ui.debug.draw then
                        self:drawBG()
                        love.graphics.pop()
                        return
                    end

                    love.graphics.setColor(1, 1, 1, 1)
                    effect(self.drawBG, self)
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
