local utils = require("utils")
local fs = require("fs")
local subprocess = require("subprocess")
local ffi = require("ffi")


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

function sharp.run(id, ...)
    local stdin = sharp.process.stdin

    assert(stdin:write(utils.toJSON(id)))

    local argsLua = {...}
    local argsSharp = {}
    -- Olympus.Sharp expects C# Tuples, which aren't lists.
    for i = 1, #argsLua do
        argsSharp["Item" .. i] = argsLua[i]
    end
    assert(stdin:write(utils.toJSON(argsSharp)))

    assert(stdin:flush())
    return sharp.read()
end

function sharp.read()
    local stdout = sharp.process.stdout

    local value = utils.fromJSON(assert(stdout:read("*l")))
    local status = utils.fromJSON(assert(stdout:read("*l")))

    if status and status.error then
        error(string.format("Failed running: %s", status.error));
    end

    return value
end

sharp.initStatus = false
function sharp.init(debug)
    if sharp.initStatus then
        return sharp.initStatus
    end

    sharp.process = assert(subprocess.popen({
        fs.joinpath(cwd, "Olympus.Sharp.exe"),
        pid,

        debug and "--debug" or nil,

        stdin = subprocess.PIPE,
        stdout = subprocess.PIPE,
        cwd = cwd
    }))

    -- The child process immediately sends a status message.
    sharp.initStatus = sharp.read()
    return sharp.initStatus
end

return sharp