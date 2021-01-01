local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local fs = require("fs")
local threader = require("threader")
local scener = require("scener")
local alert = require("alert")
local config = require("config")
local sharp = require("sharp")
local themer = require("themer")
local background = require("background")
local updater = require("updater")

local scene = {
    name = "Ahorn Setup"
}


local nobg = {
    style = {
        bg = {},
        padding = 0,
        radius = 0
    },
    clip = false,
    cacheable = false
}


scene.loadingID = 0


local root = uie.column({
    uie.scrollbox(
        uie.column({

            uie.column({
                uie.label("Status", ui.fontBig),
                uie.label("Info machine broke, please fix."):as("status"),
            }):with(uiu.fillWidth),

        }):with({
            style = {
                bg = {},
                padding = 16
            }
        }):with({
            cacheable = false
        }):with(uiu.fillWidth)
    ):with({
        style = {
            barPadding = 16,
        },
        clip = false,
        cacheable = false
    }):with(uiu.fill),

}):with({
    cacheable = false,
    _fullroot = true
})
scene.root = root


function scene.reload()
    if scene.reloading then
        return scene.reloading
    end

    scene.reloading = threader.routine(function()
        local status = root:findChild("status")

        status.text = "Checking Ahorn installation status..."

        scene.reloading = nil
    end)
    return scene.reloading
end


function scene.load()
end


function scene.enter()
    scene.reload()
end


return scene
