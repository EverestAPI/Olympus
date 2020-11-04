local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local threader = require("threader")

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
    }):with(uiu.bottombound):with(uiu.rightbound):as("loadingMods")

}):with({
    cacheable = false,
    _fullroot = true
})
scene.root = root


function scene.load()
    threader.routine(function()
        local utilsAsync = threader.wrap("utils")

        local list = root:findChild("mods")

        local entries, entriesError = utilsAsync.downloadJSON("https://api.gamebanana.com/Core/List/New?gameid=6460&page=1"):result()
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

        local function mcitem(index, key, value)
            return string.format("&%s[%d]=%s", key, index, value)
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

        local infos, infosError = utilsAsync.downloadJSON("https://api.gamebanana.com/Core/Item/Data?" .. multicall:sub(2)):result()
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
            local info = infos[ii]

            local withheld, name, owner, date, description, text, views, likes, downloads, screenshotsRaw, files = table.unpack(info)

            if withheld then
                goto next
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
                        bg = { 0, 0, 0, 0.8 }
                    }
                }):with(uiu.fill):as("bgdarken"),

                uie.column({

                    uie.label({ { 1, 1, 1, 1 }, name, { 1, 1, 1, 0.5 }, " ∙ " .. owner .. " ∙ " .. entries[ii][1] .. " ∙ " .. os.date("%Y-%m-%d %H:%M:%S", date) }):as("title"),

                    uie.row({
                        uie.group({
                            uie.spinner():with({ time = ii * 0.09 }),
                        }):as("imgholder"),

                        uie.column({
                            uie.label(description):with({ wrap = true }):as("description"),
                            uie.label({ { 1, 1, 1, 0.5 }, uiu.countformat(views, "%d view", "%d views") .. " ∙ " .. uiu.countformat(likes, "%d like", "%d likes") .. " ∙ " .. uiu.countformat(downloads, "%d download", "%d downloads"), }):as("stats"),
                        }):with({
                            style = {
                                padding = 0,
                                bg = {}
                            }
                        })

                    }):with({
                        style = {
                            padding = 0,
                            spacing = 16,
                            bg = {}
                        }
                    }),

                    --[([
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

            list:addChild(item)


            threader.routine(function()
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

                            orig(self)
                        end,

                        drawBG = function(orig, self)
                            love.graphics.draw(self._image, self.ix - self.screenX * 0.8, self.iy - self.screenY * 0.8, 0, self.scale, self.scale)
                        end,

                        draw = function(orig, self)
                            love.graphics.push()
                            love.graphics.origin()
                            if ui.debugDraw then
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

            ::next::
        end

        root:findChild("loadingMods"):removeSelf()
    end)

end


function scene.enter()

end


return scene
