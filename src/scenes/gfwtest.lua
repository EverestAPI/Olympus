local log = require('logger')('gfwtest')

local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local threader = require("threader")
local fs = require("fs")
local sharp = require("sharp")
local lang = require("lang")

local scene = {
    -- name = "Great Firewall Test"
    name = lang.get("connectivity_test")
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
        lualabel.text = data and lang.get("ok") or lang.get("ko")
        lualabel.style.color = data and uie.greentext().style.color or { 0.8, 0.5, 0.5, 1 }
        if msg then
            log.warning('Error for ' .. label .. ' / Lua: ' .. msg)
        end
    end)

    sharp.webGet(url):calls(function(_, result)
        sharplabel.text = lang.get("ok")
        sharplabel.style.color = uie.greentext().style.color
    end):falls(function(msg)
        log.warning('Error for ' .. label .. ' / Sharp, check log-sharp for more details', msg)
        sharplabel.text = lang.get("ko")
        sharplabel.style.color = { 0.8, 0.5, 0.5, 1 }
        return true
    end)
    return row
end

local function loadRows()
    scene.root:findChild("rows").children = {
        buildRow(lang.get("maddie_s_random_stuff"), 'https://maddie480.ovh/celeste/everest-versions'),
        buildRow(lang.get("github"), 'https://github.com/EverestAPI/Everest/releases'),
        buildRow(lang.get("azure_pipelines"), 'https://dev.azure.com/EverestAPI/Olympus/_apis/build/builds'),
        buildRow(lang.get("everest_website"), 'https://everestapi.github.io/olympusnews/index.txt'),
        buildRow(lang.get("gamebanana_files"), 'https://files.gamebanana.com/bitpit/check.txt'),
    }
    scene.root:findChild("rows"):layoutChildren()
end

function scene.enter()
    local root = uie.column({
        uie.column({
            uie.panel({
                uie.column({
                    uie.label(lang.get("connectivity_test"), ui.fontBig),
                    uie.label(lang.get("you_can_use_this_page_to_check_your_conn") ..
                        (love.system.getOS() == "Windows" and (lang.get("nif_lua_is_ko_but_sharp_is_ok_deleting") .. fs.getsrc() .. lang.get("libcurl_dll_might_help")) or ""))
                })
            }):with(uiu.fillWidth),
            uie.row({
                uie.panel({
                    uie.column({
                        uie.row({
                            uie.row({ uie.label(lang.get("service")) }):with({ width = 200 }),
                            uie.row({ uie.label(lang.get("lua")) }):with({ width = 50 }),
                            uie.row({ uie.label(lang.get("sharp")) }):with({ width = 50 }),
                        }),
                        uie.column({}):as("rows"),
                        uie.button(lang.get("reload"), loadRows)
                    })
                }),
                uie.panel({
                    uie.column({
                        uie.label({ uie.greentext().style.color, lang.get("maddie_s_random_stuff"), { 1, 1, 1, 1 }, lang.get("maddie480_ovh_nprovides_the_everest_vers") }),
                        uie.label({ uie.greentext().style.color, lang.get("github"), { 1, 1, 1, 1 }, lang.get("github_com_nhosts_stable_versions_of_eve") }),
                        uie.label({ uie.greentext().style.color, lang.get("azure_pipelines"), { 1, 1, 1, 1 }, lang.get("dev_azure_com_nhosts_olympus_updates_and") }),
                        uie.label({ uie.greentext().style.color, lang.get("everest_website"), { 1, 1, 1, 1 }, lang.get("everestapi_github_io_nprovides_olympus_n") }),
                        uie.label({ uie.greentext().style.color, lang.get("gamebanana_files"), { 1, 1, 1, 1 }, lang.get("files_gamebanana_com_nhosts_all_celeste_") })
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