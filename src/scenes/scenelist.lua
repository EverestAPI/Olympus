local ui, uiu, uie = require("ui").quick()
local scener = require("scener")

local scene = {
    name = "Main Menu"
}


local root = uie.column({
    uie.image("header"),

    uie.scrollbox(
        uie.list({
        }):with({
            grow = false
        }):with(uiu.fillWidth):with(function(list)
            list.selected = list.children[1]
        end):as("scenes")
    ):with(uiu.fillWidth):with(uiu.fillHeight(true)),

})
scene.root = root


function scene.load()
    local list = root:findChild("scenes")

    for i, file in ipairs(love.filesystem.getDirectoryItems("scenes")) do
        local path = file:match("^(.*)%.lua$")
        if path then
            local scene = scener.preload(path)
            list:addChild(uie.button(scene.name, function()
                scener.push(path)
            end))
        end
    end
end


function scene.enter()

end


return scene
