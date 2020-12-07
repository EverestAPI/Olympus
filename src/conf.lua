if os.getenv("OLYMPUS_DEBUG") == "1" then
    if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
        local lldb = require("lldebugger")
        lldb.start()
    end
end


-- DON'T EVER UPDATE THESE TWO FILES.
local physfs = require("physfs_core")
local lfs = require("lfs_ffi")

if lfs.attributes("./sharp", "mode") == "directory" and lfs.attributes("./sharp.new", "mode") == "directory" then
    for name in lfs.dir("./sharp.new") do
        if name ~= "." and name ~= ".." then
            local new = "./sharp.new/" .. name
            local old = "./sharp/" .. name
            if lfs.attributes(old, "mode") == "file" then
                os.remove(old)
            end
            os.rename(new, old)
        end
    end
    lfs.rmdir("./sharp.new")
end

local isSeparated = false
local paths = physfs.getSearchPath()
for i = 1, #paths do
    if paths[i]:match("^.*[\\/]olympus%.love$") then
        isSeparated = true
        break
    end
end

if not isSeparated then
    if lfs.attributes("./olympus.new.love", "mode") == "file" then
        if lfs.attributes("./olympus.love", "mode") == "file" then
            os.remove("./olympus.love")
        end
        os.rename("./olympus.new.love", "./olympus.love")
    end

    if physfs.mount("./olympus.love", "/", 0) ~= 0 and #paths ~= #physfs.getSearchPath() then
        love.filesystem.load("conf.lua")()
        return
    end

else
    if lfs.attributes("./olympus.old.love", "mode") == "file" then
        os.remove("./olympus.old.love")
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
