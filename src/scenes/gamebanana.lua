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
            }
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

})
scene.root = root


function scene.load()
    threader.routine(function()
        local utilsAsync = threader.wrap("utils")

        local list = root:findChild("mods")

        local entries = utilsAsync.downloadJSON("https://api.gamebanana.com/Core/List/New?gameid=6460&page=1"):result()

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

        local infos = utilsAsync.downloadJSON("https://api.gamebanana.com/Core/Item/Data?" .. multicall:sub(2)):result()
        for ii = 1, #infos do
            local info = infos[ii]

            local withheld, name, owner, date, description, text, views, likes, downloads, screenshotsRaw, files = table.unpack(info)

            if withheld then
                goto next
            end

            local item = uie.column({
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
                    }):with(uiu.fillWidth(-1, true))

                }):with({
                    style = {
                        padding = 0,
                        spacing = 16,
                        bg = {}
                    }
                }):with(uiu.fillWidth),

                -- uie.label(utils.cleanHTML(text)):with({ wrap = true }):as("text"),

            }):with(uiu.fillWidth)

            list:addChild(item)


            threader.routine(function()
                local imgholder = item:findChild("imgholder")

                local screenshots = utilsAsync.fromJSON(screenshotsRaw):result()

                if screenshots[1]._sFile:match("%.webp$") then
                    -- TODO: WEBP SUPPORT
                    imgholder.children[1]:removeSelf()
                    return item:reflowDown()
                end

                local img = utilsAsync.download("https://files.gamebanana.com/" .. screenshots[1]._sRelativeImageDir .. "/" .. screenshots[1]._sFile100):result()
                img = love.filesystem.newFileData(img, screenshots[1]._sFile)
                img = love.graphics.newImage(img)

                imgholder.children[1]:removeSelf()
                imgholder:addChild(uie.image(img))
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
