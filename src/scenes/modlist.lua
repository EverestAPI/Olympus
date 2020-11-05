local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local threader = require("threader")
local scener = require("scener")
local gamebanana = scener.preload("gamebanana")

local scene = {
    name = "Mod Manager"
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
        local utilsAsync = threader.wrap("utils")

        local list = root:findChild("mods")

        local remoteurl = utils.trim(utilsAsync.download("https://everestapi.github.io/modupdater.txt"):result())
        local remotelist = utilsAsync.downloadYAML(remoteurl):result()

        for name, data in pairs(remotelist) do
            -- FIXME: Check against known installed mods, add to list.
            -- list:addChild(gamebanana.item(gamebanana.downloadInfo(data.GameBananaType, data.GameBananaId):result()))
        end

        -- FIXME: List unknown mods.

        root:findChild("loadingMods"):removeSelf()
    end)

end


function scene.enter()

end


return scene
