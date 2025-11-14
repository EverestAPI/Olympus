local log = require('logger')('gfwtest')

local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local threader = require("threader")
local fs = require("fs")
local sharp = require("sharp")

local scene = {
    -- name = "Great Firewall Test"
    name = "Connectivity Test"
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
        lualabel.style.color = data and uie.greentext().style.color or { 0.8, 0.5, 0.5, 1 }
        if msg then
            log.warning('Error for ' .. label .. ' / Lua: ' .. msg)
        end
    end)

    sharp.webGet(url):calls(function(_, result)
        sharplabel.text = 'OK'
        sharplabel.style.color = uie.greentext().style.color
    end):falls(function(msg)
        log.warning('Error for ' .. label .. ' / Sharp, check log-sharp for more details', msg)
        sharplabel.text = 'KO'
        sharplabel.style.color = { 0.8, 0.5, 0.5, 1 }
        return true
    end)
    return row
end

local function loadRows()
    scene.root:findChild("rows").children = {
        buildRow("Maddie's Random Stuff", 'https://maddie480.ovh/celeste/everest-versions'),
        buildRow('GitHub', 'https://github.com/EverestAPI/Everest/releases'),
        buildRow('Azure Pipelines', 'https://dev.azure.com/EverestAPI/Olympus/_apis/build/builds'),
        buildRow('Everest Website', 'https://everestapi.github.io/olympusnews/index.txt'),
        buildRow("GameBanana Files", 'https://files.gamebanana.com/bitpit/check.txt'),
    }
    scene.root:findChild("rows"):layoutChildren()
end

function scene.enter()
    local root = uie.column({
        uie.column({
            uie.panel({
                uie.column({
                    uie.label("Connectivity Test", ui.fontBig),
                    uie.label([[You can use this page to check your connectivity to the various web services Olympus uses.
If one of the tests fail, the corresponding features in Olympus will probably be unavailable.
Some of the possible reasons why this might be happening:
- Your antivirus / firewall is blocking Olympus from accessing the Internet.
- The service is down or there is a networking issue, try again later.
- Network filtering is blocking the website, try again on another connection or toggle your VPN.]] ..
                        (love.system.getOS() == "Windows" and ("\nIf Lua is KO but Sharp is OK, deleting " .. fs.getsrc() .. "\\libcurl.dll might help.") or ""))
                })
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
                        uie.label({ uie.greentext().style.color, "Maddie's Random Stuff", { 1, 1, 1, 1 }, ' (maddie480.ovh)\nProvides the Everest versions list, the mod updater, and the "Download Mods" section' }),
                        uie.label({ uie.greentext().style.color, 'GitHub', { 1, 1, 1, 1 }, ' (github.com)\nHosts stable versions of Everest' }),
                        uie.label({ uie.greentext().style.color, 'Azure Pipelines', { 1, 1, 1, 1 }, ' (dev.azure.com)\nHosts Olympus updates, and non-stable versions of Everest' }),
                        uie.label({ uie.greentext().style.color, 'Everest Website', { 1, 1, 1, 1 }, ' (everestapi.github.io)\nProvides Olympus News, displayed on the right side of the main menu' }),
                        uie.label({ uie.greentext().style.color, 'GameBanana Files', { 1, 1, 1, 1 }, ' (files.gamebanana.com)\nHosts all Celeste mods, select a mirror in Options & Updates in case of trouble' })
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
