local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local threader = require("threader")
local scener = require("scener")
local fs = require("fs")
local config = require("config")
local ui, uiu, uie = require("ui").quick()
local sharp = require("sharp")

local scene = {
    name = "Great Firewall Test"
}

local function buildRow(label, url)
    local lualabel = uie.label('...')
    local sharplabel = uie.label('...')
    local row = uie.row({
        uie.row({ uie.label(label) }):with({ width = 200 }),
        uie.row({ lualabel }):with({ width = 50 }),
        uie.row({ sharplabel }):with({ width = 50 })
    })

    threader.routine(function()
        local data, msg = threader.wrap("utils").download(url):result()
        lualabel.text = data and 'OK' or 'KO'
        lualabel.style.color = data and { 0.5, 0.8, 0.5, 1 } or { 0.8, 0.5, 0.5, 1 }
        if msg then
            print('[gfwtest] Error for ' .. label .. ' / Lua: ' .. msg)
        end
    end)

    sharp.webGet(url):calls(function(_, result)
        sharplabel.text = 'OK'
        sharplabel.style.color = { 0.5, 0.8, 0.5, 1 }
    end):falls(function(msg)
        print('[gfwtest] Error for ' .. label .. ' / Sharp, check log-sharp for more details', msg)
        sharplabel.text = 'KO'
        sharplabel.style.color = { 0.8, 0.5, 0.5, 1 }
        return true
    end)
    return row
end

local function loadRows()
    scene.root:findChild("rows").children = {
        buildRow('Everest website', 'https://everestapi.github.io/everestupdater.txt'),
        buildRow('GitHub', 'https://github.com/EverestAPI/Everest/releases'),
        buildRow('Azure Pipelines', 'https://dev.azure.com/EverestAPI/Olympus/_apis/build/builds'),
        buildRow("Maddie's Random Stuff", 'https://maddie480.ovh/celeste/everest-versions'),
        buildRow("GameBanana", 'https://gamebanana.com/bitpit/check.txt'),
    }
    scene.root:findChild("rows"):layoutChildren()
end

function scene.enter()
    local root = uie.column({
        uie.column({
            uie.panel({
                uie.label("Great Firewall Test", ui.fontBig)
            }):with(uiu.fillWidth),
            uie.row({
                uie.panel({
                    uie.column({
                        uie.row({
                            uie.row({ uie.label('Service') }):with({ width = 200 }),
                            uie.row({ uie.label('Lua') }):with({ width = 50 }),
                            uie.row({ uie.label('Sharp') }):with({ width = 50 }),
                        }),
                        uie.column({}):as("rows"),
                        uie.button("Reload", loadRows)
                    })
                }),
                uie.panel({
                    uie.column({
                        uie.label({ { 0.5, 0.8, 0.5, 1 }, 'Everest website:', { 1, 1, 1, 1 }, ' Used for listing Everest versions, and displaying news' }),
                        uie.label({ { 0.5, 0.8, 0.5, 1 }, 'GitHub:', { 1, 1, 1, 1 }, ' Used for downloading stable versions of Everest' }),
                        uie.label({ { 0.5, 0.8, 0.5, 1 }, 'Azure Pipelines:', { 1, 1, 1, 1 }, ' Used for updating Olympus, and downloading non-stable versions of Everest' }),
                        uie.label({ { 0.5, 0.8, 0.5, 1 }, "Maddie's Random Stuff:", { 1, 1, 1, 1 }, ' Used for listing Everest versions, checking for mod updates, and listing mods\nin the \"Download Mods\" section' }),
                        uie.label({ { 0.5, 0.8, 0.5, 1 }, 'GameBanana:', { 1, 1, 1, 1 }, ' Used by default to download mods' })
                    })
                }):with(uiu.fillWidth(true)),
            }):with(uiu.fillWidth)
        }):with({ style = { padding = 16 }}):with(uiu.fillWidth)
    }):with({
        cacheable = false,
        _fullroot = true
    })
    scene.root = root
    loadRows()
end


return scene
