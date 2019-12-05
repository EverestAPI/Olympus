local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local threader = require("threader")

local scene = {}


local root = uie.column({
    uie.scrollbox(
        uie.column({
        }):with({
            style = {
                bg = {},
                padding = 0,
            }
        }):with(uiu.fillWidth):as("mods")
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
    }):with(uiu.bottombound):with(uiu.rightbound):as("loadingMods")

})
scene.root = root


function scene.load()
    threader.routine(function()
        local utilsAsync = threader.wrap("utils")
        local entries = utilsAsync.downloadJSON("https://api.gamebanana.com/Core/List/New?gameid=6460&page=1"):result()

        local list = root:findChild("mods")

        --[[
        for ei = 1, #entries do
            local entry = entries[ei]

            local info = utilsAsync.downloadJSON(string.format("https://api.gamebanana.com/Core/Item/Data?itemtype=%s&itemid=%s&fields=name,Owner().name,description,views,likes,Withhold().bIsWithheld(),screenshots", entry[1], tostring(entry[2]))):result()

            local item = uie.listItem(entry[1] .. " - " .. entry[2] .. " - " .. uiu.join(info, " - "), entry)
            list:addChild(item)
        end
        ]]--

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
                mcitem(i, "fields", "Withhold().bIsWithheld(),name,Owner().name,description,views,likes,date,screenshots,Files().aFiles()")
        end

        local infos = utilsAsync.downloadJSON("https://api.gamebanana.com/Core/Item/Data?" .. multicall:sub(2)):result()
        for ii = 1, #infos do
            local info = infos[ii]

            if info[1] then
                goto next
            end

            local item = uie.column({
                uie.label({ { 1, 1, 1, 1 }, info[2], { 1, 1, 1, 0.5 }, " ∙ " .. info[3] .. " ∙ " .. entries[ii][1] .. " ∙ " .. os.date("%Y-%m-%d %H:%M:%S", info[7]) }):as("title"),

                uie.row({
                    uie.group({
                        uie.spinner():with({ time = ii * 0.09 }),
                    }):as("imgholder"),

                    uie.column({
                        uie.label(info[4]):with({ wrap = true }):as("description"),
                        uie.label({ { 1, 1, 1, 0.5 }, uiu.countformat(info[5], "%d view", "%d views") .. " ∙ " .. uiu.countformat(info[6], "%d like", "%d likes"), }):as("stats"),
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
                }):with(uiu.fillWidth)

            }):with({
                style = {
                    bg = { 0.1, 0.1, 0.1, 0.6 },
                }
            }):with(uiu.fillWidth)

            list:addChild(item)


            threader.routine(function()
                local imgholder = item:findChild("imgholder")

                local screenshots = utilsAsync.fromJSON(info[8]):result()

                imgholder.children[1]:removeSelf()

                if screenshots[1]._sFile530:match("%.webp$") then
                    item:reflowDown()
                    return
                end

                local img = utilsAsync.download("https://files.gamebanana.com/" .. screenshots[1]._sRelativeImageDir .. "/" .. screenshots[1]._sFile100):result()
                img = love.filesystem.newFileData(img, screenshots[1]._sFile530)
                img = love.graphics.newImage(img)

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
