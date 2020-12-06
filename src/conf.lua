-- require("lldebugger").start(); require("lldebugger").start()

if tonumber((love.filesystem.read("version.txt") or "?"):match(".*-.*-(.*)-.*")) ~= 0 then
    local physfs = love.filesystem.load("physfs.lua")()

    local isSeparated = false
    local paths = physfs.getSearchPath()
    for i = 1, #paths do
        if paths[i]:match("^.*[\\/]olympus%.love$") then
            isSeparated = true
            break
        end
    end

    if not isSeparated and physfs.mount("olympus.love", "/", 0) ~= 0 then
        love.filesystem.load("conf.lua")()
        return
    end
end

love.filesystem.setRequirePath(love.filesystem.getRequirePath() .. ";xml2lua/?.lua")

require("prethread")("main")

function love.conf(t)
    local configStatus, config = pcall(require, "config")
    if configStatus then
        config.load()
    else
        config = {
            csd = false,
            vsync = true
        }
    end

    t.window.title = "Everest.Olympus"
    t.window.icon = "data/icon.png"
    t.window.width = 1100
    t.window.minwidth = 1100
    t.window.height = 600
    t.window.minheight = 600
    t.window.borderless = config.csd
    t.window.resizable = true -- when borderless, true causes a flickering border on Windows
    t.window.vsync = config.vsync and 1 or 0
    t.window.highdpi = true
    t.console = false
end
