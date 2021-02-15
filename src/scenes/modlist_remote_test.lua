local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local threader = require("threader")

local scene = {
    name = "Mod Manager (Remote Test)"
}


local root = uie.column({
    uie.scrollbox(
        uie.column({
        }):with({
            style = {
                padding = 16,
            }
        }):with(uiu.fillWidth):as("mods")
    ):with({
        style = {
            barPadding = 16,
        },
        clip = false,
        cacheable = false
    }):with(uiu.fill),

    uie.paneled.row({
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

        local remoteurl = utils.trim(utilsAsync.download("https://everestapi.github.io/modupdater.txt"):result())
        local remotelist = utilsAsync.downloadYAML(remoteurl):result()

        for name, data in pairs(remotelist) do
            local ki = 0
            local vi = 0
            list:addChild(
                uie.column({
                    uie.label(name),
                    uie.row({
                        uie.column(
                            uiu.map(data, function(v, k)
                                ki = ki + 1
                                return uie.label(k), ki
                            end)
                        ),
                        uie.column(
                            uiu.map(data, function(v, k)
                                vi = vi + 1
                                return uie.label(tostring(v)), vi
                            end)
                        )
                    })
                }):with(uiu.fillWidth)
            )
        end

        root:findChild("loadingMods"):removeSelf()
    end)

end


function scene.enter()

end


return scene
