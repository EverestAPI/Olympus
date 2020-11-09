local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local threader = require("threader")
local scener = require("scener")
local config = require("config")
local sharp = require("sharp")

local scene = {
    name = "Main Menu"
}


local function buttonBig(icon, text, scene)
    return uie.button(
        uie.row({
            uie.image(icon):with({ scale = 48 / 256 }),
            uie.label(text, ui.fontBig):with({ y = 4 })
        }):with({ style = { bg = {}, padding = 0, spacing = 16 } }),
        function()
            scener.push(scene)
        end
    ):with({ style = { padding = 16 } }):with(uiu.fillWidth(4))
end

local function button(icon, text, scene)
    return uie.button(
        uie.row({
            uie.image(icon):with({ scale = 24 / 256 }),
            uie.label(text):with({ y = 2 })
        }):with({ style = { bg = {}, padding = 0 } }),
        function()
            scener.push(scene)
        end
    ):with({ style = { padding = 8 } }):with(uiu.fillWidth(4))
end


function scene.createInstalls()
    return uie.column({
        uie.label("Your Installations", ui.fontBig),

        uie.column({

            uie.scrollbox(
                uie.list({}, function(self, data)
                    config.install = data.index
                    config.save()
                end):with({
                    grow = false
                }):with(uiu.fillWidth):as("installs")
            ):with(uiu.fillWidth):with(uiu.fillHeight),

            uie.button("Manage", function()
                scener.push("installmanager")
            end):with({
                clip = false,
                cacheable = false
            }):with(uiu.bottombound):with(uiu.rightbound):as("manageInstalls")

        }):with({
            style = {
                padding = 0,
                bg = {}
            }
        }):with(uiu.fillWidth):with(uiu.fillHeight(true))
    }):with(uiu.fillHeight)
end


function scene.reloadInstalls()
    local list = scener.current.root:findChild("installs")
    list.children = {}

    local installs = config.installs or {}
    for i = 1, #installs do
        local entry = installs[i]
        local item = uie.listItem({{1, 1, 1, 1}, entry.name, {1, 1, 1, 0.5}, "\nScanning..."}, { index = i, entry = entry, version = "???" })

        sharp.getVersionString(entry.path):calls(function(t, version)
            version = version or "???"

            local celeste = version:match("Celeste ([^ ]+)")
            local everest = version:match("Everest ([^ ]+)")
            if everest then
                version = celeste .. " + " .. everest

            else
                version = celeste or version
            end

            item.text = {{1, 1, 1, 1}, entry.name, {1, 1, 1, 0.5}, "\n" .. version}
            item.data.version = version
        end)

        list:addChild(item)
    end

    list.selected = list.children[config.install or 1] or list.children[1]
    list:reflow()
end


local root = uie.column({
    uie.image("header_olympus"),

    uie.row({

        scene.createInstalls(),

        uie.column({
            buttonBig("mainmenu/everest", "Install Everest (Mod Loader)", "everest"),
            button("mainmenu/gamebanana", "Download Mods From GameBanana", "gamebanana"),
            button("cogwheel", "Manage Installed Mods", "modlist"),
            button("mainmenu/ahorn", "Install Ahorn (Map Editor)", "dummy"),
            button("cogwheel", "[DEBUG] Scene List", "scenelist"),
        }):with(uiu.fillWidth(true)):with(uiu.fillHeight)

    }):with({
        style = {
            padding = 0,
            bg = {}
        }
    }):with(uiu.fillWidth):with(uiu.fillHeight(true)),

})
scene.root = root


function scene.load()
end


function scene.enter()
    scene.reloadInstalls()

end


return scene
