local ui, uiu, uie = require("ui").quick()
local scener = require("scener")
local alert = require("alert")

local scene = {
    name = "Scene List"
}


local root = uie.group({
    uie.scrollbox(
        uie.column({
        }):with(uiu.fillWidth):as("scenes")
    ):with({
        clip = false,
        cacheable = false
    }):with(uiu.fill),
})
scene.root = root


function scene.load()
    local list = root:findChild("scenes")

    for i, file in ipairs(love.filesystem.getDirectoryItems("scenes")) do
        local path = file:match("^(.*)%.lua$")
        if path then
            local scene = scener.preload(path)
            list:addChild(uie.button(scene.name, function()
                if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
                    alert.scene(path)
                else
                    scener.push(path)
                end
            end):with(uiu.fillWidth))
        end
    end
end


function scene.enter()

end


return scene
