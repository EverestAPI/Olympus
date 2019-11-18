local ui = require("ui.main")
local uie = require("ui.elements")
ui.e = uie

function ui.init(root, skipHooks)
    ui.root = uie.root(root)
    if not skipHooks then
        ui.hookLove()
    end
end

return ui
