-- DON'T EVER UPDATE THESE FILES.
local physfs = require("physfs_core")
local lfs = require("lfs_ffi")

if os.getenv("OLYMPUS_DEBUG") == "1" then
    if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
        require("lldebugger").start()
    end
end

local src = love.filesystem.getSource()
if not src:match("[/\\]src[/\\]?$") then
    lfs.chdir(src:match("(.*[/\\])"):gsub("([^/\\])[/\\]$", "%1"))
end

if lfs.attributes("./sharp", "mode") == "directory" and lfs.attributes("./sharp.new", "mode") == "directory" then
    local restarterPID = tonumber(os.getenv("OLYMPUS_RESTARTER_PID"))
    if restarterPID then
        local ffi = require("ffi")
        local C = ffi.C

        if ffi.os == "Windows" then
            ffi.cdef[[
                void* OpenProcess(int dwDesiredAccess, int bInheritHandle, int dwProcessId);
                int WaitForSingleObject(void* hHandle, int dwMilliseconds);
                int CloseHandle(void* hObject);
            ]]
            local handle = C.OpenProcess(--[[SYNCHRONIZE]] 0x00100000, false, restarterPID)
            C.WaitForSingleObject(handle, 5000)
            C.CloseHandle(handle)

        else
            ffi.cdef[[
                int kill(int pid, int sig);
                int usleep(int usec);
            ]]
            for _ = 1, 50 do
                if C.kill(restarterPID, 0) then
                    break
                end
                C.usleep(100 * 1000)
            end
        end
    end

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

require("prethread")({
    meta = {
        id = "main"
    }
})

local fs = require("fs")

local storageDir = fs.getStorageDir()

print("pre-initializing")
local cwd = fs.getcwd()
print("cwd:", cwd)
local src = fs.getsrc()
print("src:", src)
print("storageDir:", storageDir)

if love.system.getOS() == "Windows" and cwd ~= src then
    local ffi = require("ffi")
    local C = ffi.C

    ffi.cdef[[
        int SetCurrentDirectoryW(wchar_t* lpPathName);
        int MultiByteToWideChar(
            unsigned int CodePage,
            int dwFlags,
            char* lpMultiByteStr,
            int cbMultiByte,
            wchar_t* lpWideCharStr,
            int cchWideChar
        );
    ]]

    -- CP_UTF8 = 65001

    local length = #src + 1
    local srcC = ffi.new("char[?]", length)
    ffi.copy(srcC, src)
    srcC[#src] = 0
    local size = C.MultiByteToWideChar(65001, 0, srcC, length, nil, 0)
    assert(size ~= 0)
    local srcW = ffi.new("wchar_t[?]", size)
    length = C.MultiByteToWideChar(65001, 0, srcC, length, srcW, size)
    assert(size == length)

    assert(C.SetCurrentDirectoryW(srcW) ~= 0)

    cwd = fs.getcwd()
    print("cwd (new):", cwd)
end

local storageDirAttrs = lfs.attributes(storageDir)

if not storageDirAttrs then
    print("storageDir is missing - creating")
    print(fs.mkdir(storageDir))

elseif storageDirAttrs.mode == "file" then
    print("storageDir is actually file - trying to delete")
    print(os.remove(storageDir))

elseif not storageDirAttrs.permissions:match("rwx......") and (love.system.getOS() == "Linux" or love.system.getOS() == "OS X") then
    print("storageDir permissions are broken - trying to fix")
    print(os.execute([["chmod" "u+rwx" "]] .. storageDir .. [["]]))
end

love.filesystem.mountUnsandboxed(storageDir, "/", 0)

for i, file in ipairs(love.filesystem.getDirectoryItems("preload")) do
    local name = file:match("^(.*).lua$")
    if name then
        love.filesystem.load(string.format("preload/%s.lua", name))()
    end
end

function love.conf(t)
    local config = require("config")
    config.load()

    t.window.title = "Olympus"
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

    -- Disable unused love2d modules
    t.modules.audio = false
    t.modules.joystick = false
    t.modules.physics = false
    t.modules.sound = false
    t.modules.touch = false
    t.modules.video = false

    print("pre-initialized")
end
