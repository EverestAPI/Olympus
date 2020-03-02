local threader = require("threader")

-- These must be named channels so that new threads requiring sharp can use them.
local channelQueue = love.thread.getChannel("sharpQueue")
local channelReturn = love.thread.getChannel("sharpReturn")
local channelDebug = love.thread.getChannel("sharpDebug")

-- The command queue thread.
local function sharpthread()
    local debuggingFlags = channelDebug:peek()
    local debugging, debuggingSharp = debuggingFlags[1], debuggingFlags[2]

    if debugging then
        print("[sharp init]", "starting thread")
    end

    local fs = require("fs")
    local subprocess = require("subprocess")
    local ffi = require("ffi")
    local utils = require("utils")

    -- Olympus.Sharp is stored in the sharp subdir.
    -- Running love src/ sets the cwd to the src folder.
    local cwd = fs.getcwd()
    if fs.filename(cwd) == "src" then
        cwd = fs.joinpath(fs.dirname(cwd), "love")
    end
    cwd = fs.joinpath(cwd, "sharp")

    -- The current process ID is used by Olympus.Sharp so that
    -- it dies when this process dies, without becoming a zombie.
    local pid = nil
    if ffi.os == "Windows" then
        ffi.cdef[[
            int GetCurrentProcessId();
        ]]
        pid = tostring(ffi.C.GetCurrentProcessId())

    else
        ffi.cdef[[
            int getpid();
        ]]
        pid = tostring(ffi.C.getpid())
    end

    local exename = nil
    if ffi.os == "Windows" then
        exename = "Olympus.Sharp.exe"

    elseif ffi.os == "Linux" then
        if ffi.arch == "x86" then
            -- Note: MonoKickstart no longer ships with x86 prebuilts.
            exename = "Olympus.Sharp.bin.x86"
        elseif ffi.arch == "x64" then
            exename = "Olympus.Sharp.bin.x86_64"
        end

    elseif ffi.os == "OSX" then
        exename = "Olympus.Sharp.bin.osx"
    end

    local exe = fs.joinpath(cwd, exename)

    local logpath = os.getenv("OLYMPUS_SHARP_LOGPATH") or nil
    if logpath and #logpath == 0 then
        logpath = nil
    end

    if not logpath and not debugging then
        logpath = fs.joinpath(fs.getStorageDir(), "log-sharp.txt")
        fs.mkdir(fs.dirname(logpath))
    end

    if debugging then
        print("[sharp init]", "starting subprocess", exe, pid, debuggingSharp and "--debug" or nil)
        print("[sharp init]", "logging to", logpath)
    end

    local process = assert(subprocess.popen({
        exe,
        pid,

        debuggingSharp and "--debug" or nil,

        stdin = subprocess.PIPE,
        stdout = subprocess.PIPE,
        stderr = logpath,
        cwd = cwd
    }))
    local stdout = process.stdout
    local stdin = process.stdin

    local function read()
        return {
            value = utils.fromJSON(assert(stdout:read("*l"))),
            status = utils.fromJSON(assert(stdout:read("*l")))
        }
    end

    local function run(id, argsLua)
        assert(stdin:write(utils.toJSON(id) .. "\n"))

        local argsSharp = {}
        -- Olympus.Sharp expects C# Tuples, which aren't lists.
        for i = 1, #argsLua do
            argsSharp["Item" .. i] = argsLua[i]
        end
        assert(stdin:write(utils.toJSON(argsSharp) .. "\n"))

        assert(stdin:flush())
        return read()
    end

    local function dprint(...)
        if debugging then
            print("[sharp queue]", ...)
        end
    end

    local unpack = table.unpack or _G.unpack

    -- The child process immediately sends a status message.
    if debugging then
        print("[sharp init]", "reading init")
    end
    local initStatus = read()
    if debugging then
        print("[sharp init]", "read init", initStatus)
    end

    while true do
        dprint("awaiting next cmd")
        local cmd = channelQueue:demand()
        local id = cmd.id
        local args = cmd.args

        if id == "_init" then
            dprint("returning init", initStatus)
            channelReturn:push(initStatus)

        elseif id == "_die" then
            dprint("dying")
            channelReturn:push({ value = "ok" })
            break

        else
            dprint("running", id, unpack(args))
            local rv = run(id, args)
            dprint("returning", rv.value, rv.status, rv.status and rv.status.error)
            channelReturn:push(rv)
        end
    end
end


local mtSharp = {}

-- Automatically generate helpers for all function calls.
function mtSharp:__index(key)
    local rv = rawget(self, key)
    if rv ~= nil then
        return rv
    end

    rv = function(...)
        return self.run(key, ...)
    end
    self[key] = rv
    return rv
end


local sharp = setmetatable({}, mtSharp)

local function _run(id, ...)
    local debugging = channelDebug:peek()[1]

    local function dprint(...)
        if debugging then
            print("[sharp run]", ...)
        end
    end

    dprint("enqueuing", id, ...)
    channelQueue:push({ id = id, args = {...} })

    dprint("awaiting return value")
    local rv = channelReturn:demand()
    dprint("got", rv.value, rv.status, rv.status and rv.status.error)

    if type(rv.status) == "table" and rv.status.error then
        error(string.format("Failed running %s: %s", id, rv.status.error))
    end

    return rv.value
end
function sharp.run(id, ...)
    return threader.run(_run, id, ...)
end

sharp.initStatus = false
function sharp.init(debug, debugSharp)
    if sharp.initStatus then
        return sharp.initStatus
    end

    channelDebug:pop()
    channelDebug:push({ debug and true or false, debugSharp and true or false })

    -- Run the command queue on a separate thread.
    local thread = threader.new(sharpthread)
    sharp.thread = thread
    thread:start()

    -- The child process immediately sends a status message.
    sharp.initStatus = sharp.run("_init"):result()

    return sharp.initStatus
end

return sharp