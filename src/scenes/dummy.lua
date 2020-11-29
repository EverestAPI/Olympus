local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local threader = require("threader")
local scener = require("scener")
local alert = require("alert")
local config = require("config")
local sharp = require("sharp")

local scene = {
    name = "Dummy Scene"
}


local root = uie.column({
    uie.image("header"),

})
scene.root = root


function scene.load()

end


function scene.enter()

end


return scene
