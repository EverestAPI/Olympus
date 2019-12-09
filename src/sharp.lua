local threader = require("threader")

-- The command queue thread.
local function sharpthread(channelQueue, channelReturn, debug)
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

    local process = assert(subprocess.popen({
        fs.joinpath(cwd, "Olympus.Sharp.exe"),
        pid,

        debug and "--debug" or nil,

        stdin = subprocess.PIPE,
        stdout = subprocess.PIPE,
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
        assert(stdin:write(utils.toJSON(id)))

        local argsSharp = {}
        -- Olympus.Sharp expects C# Tuples, which aren't lists.
        for i = 1, #argsLua do
            argsSharp["Item" .. i] = argsLua[i]
        end
        assert(stdin:write(utils.toJSON(argsSharp)))

        assert(stdin:flush())
        return read()
    end

    -- The child process immediately sends a status message.
    local initStatus = read()

    while true do
        local cmd = channelQueue:demand()
        local id = cmd.id
        local args = cmd.args

        if id == "_init" then
            channelReturn:push(initStatus)
            break
        end

        if id == "_die" then
            channelReturn:push({ value = "ok" })
            break
        end

        channelReturn:push(run(id, args))
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

local function _run(channelQueue, channelReturn, id, ...)
    channelQueue:push({ id = id, args = {...} })

    local rv = channelReturn:demand()

    if type(rv.status) == "error" and rv.status.error then
        error("Failed running %s: %s", id, rv.status.error)
    end

    return rv.value
end
function sharp.run(id, ...)
    return threader.run(_run, sharp.channelQueue, sharp.channelReturn, id, ...)
end

sharp.initStatus = false
function sharp.init(debug)
    if sharp.initStatus then
        return sharp.initStatus
    end

    -- Run the command queue on a separate thread.
    local thread = threader.new(sharpthread)
    sharp.thread = thread
    sharp.channelQueue = love.thread.newChannel()
    sharp.channelReturn = love.thread.newChannel()
    thread:start(sharp.channelQueue, sharp.channelReturn, debug and true or false)

    -- The child process immediately sends a status message.
    sharp.initStatus = sharp.run("_init"):result()

    return sharp.initStatus
end

return sharp