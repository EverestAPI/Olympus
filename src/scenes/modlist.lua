local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local fs = require("fs")
local threader = require("threader")
local scener = require("scener")
local config = require("config")
local sharp = require("sharp")
local alert = require("alert")
local notify = require("notify")

local scene = {
    name = "Mod Manager"
}

scene.loadingID = 0


local root = uie.column({
    uie.scrollbox(
        uie.column({
        }):with({
            style = {
                bg = {},
                padding = 16
            }
        }):with({
            cacheable = false
        }):with(uiu.fillWidth):as("mods")
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


function scene.item(info)
    if not info then
        return nil
    end

    local item = uie.row({
        uie.label({ { 1, 1, 1, 1 }, fs.filename(info.Path) .. "\n" .. (info.Name or "?"), { 1, 1, 1, 0.5 }, " ∙ " .. (info.Version or "?.?.?.?") }):as("title"),

        uie.row({

            uie.button(
                "Delete",
                function()
                    alert({
                        body = [[
Are you sure that you want to delete ]] .. fs.filename(info.Path) .. [[?
You will need to redownload the mod to use it again.
Tip: Edit the blacklist.txt to block Everest from loading it.]],
                        buttons = {
                            {
                                "Delete",
                                function(container)
                                    fs.remove(info.Path)
                                    scene.reload()
                                    container:close("OK")
                                end
                            },
                            { "Keep" }
                        }
                    })
                end
            ):with({
                enabled = info.IsZIP
            })

        }):with({
            style = {
                padding = 0,
                bg = {}
            },
            clip = false,
            cacheable = false
        }):with(uiu.rightbound)

    }):with(uiu.fillWidth)

    return item
end


function scene.reload()
    local loadingID = scene.loadingID + 1
    scene.loadingID = loadingID

    return threader.routine(function()
        local loading = uie.row({
            uie.label("Loading"),
            uie.spinner():with({
                width = 16,
                height = 16
            })
        }):with({
            clip = false,
            cacheable = false
        }):with(uiu.bottombound(16)):with(uiu.rightbound(16)):as("loadingMods")
        scene.root:addChild(loading)

        local list = root:findChild("mods")
        list.children = {}
        list:reflow()

        local root = config.installs[config.install].path

        list:addChild(uie.column({
            uie.label("Note", ui.fontBig),
            uie.label([[
This menu isn't finished yet. It will be improved in future updates.
If you want to blacklist or update mods easily, you can do so in Everest.]])
        }):with(uiu.fillWidth))

        list:addChild(uie.button("Open mods folder", function()
            utils.openFile(fs.joinpath(root, "Mods"))
        end):with(uiu.fillWidth))

        list:addChild(uie.button("Edit blacklist.txt", function()
            utils.openFile(fs.joinpath(root, "Mods", "blacklist.txt"))
        end):with(uiu.fillWidth))

        local task = sharp.modlist(root):result()
        local batches = 0
        while loadingID == scene.loadingID do
            local status = sharp.status(task):result()
            if status[1] ~= "running" and status[2] == 0 then
                break
            end
            if status[2] ~= 0 then
                local batch = {}
                for i = 1, status[2] do
                    batch[i] = sharp.pollNext(task):result()
                end
                batches = batches + #batch
                if loadingID ~= scene.loadingID then
                    break
                end
                for i = 1, status[2] do
                    list:addChild(scene.item(batch[i]))
                end
            end
        end
        -- notify(tostring(batches) .. " mods found.")
        local status = sharp.free(task)
        if status == "error" then
            notify("An error occurred while loading the mod list.")
        end

        loading:removeSelf()
    end)
end


function scene.load()
    --[[
    threader.run(function()
        local utils = require("utils")
        local url = utils.trim(utils.download("https://everestapi.github.io/modupdater.txt"))
        return utils.downloadYAML(url)
    end):calls(function(thread, data)
        scene.remote = data
        if data then
            notify("Mod database updated.")
        else
            notify("Mod database failed to update.")
        end
    end)
    ]]
end


function scene.enter()
    scene.reload()
end


return scene
