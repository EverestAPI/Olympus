local threader = require("threader")

-- These must be named channels so that new threads requiring sharp can use them.
local channelQueue = love.thread.getChannel("sharpQueue")
local channelDebug = love.thread.getChannel("sharpDebug")
local channelStatus = love.thread.getChannel("sharpStatus")

-- Thread-local ID.
local tuid = 0

-- The command queue thread.
local function sharpthread()
    channelStatus:clear()
    channelStatus:push("start")

    local status, err = pcall(function()
        local debuggingFlags = channelDebug:peek()
        local debugging, debuggingSharp = debuggingFlags[1], debuggingFlags[2]

        print("[sharp init]", "starting thread")

        local threader = require("threader")
        local fs = require("fs")
        local subprocess = require("subprocess")
        local ffi = require("ffix")
        local utils = require("utils")
        local socket = require("socket")

        -- Olympus.Sharp is stored in the sharp subdir.
        -- Running love src/ sets the cwd to the src folder.
        local cwd = fs.getsrc()
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

        print("[sharp init]", "starting subprocess", exe, pid, debuggingSharp and "--debug" or nil)
        print("[sharp init]", "logging to", logpath)

        local pargs = {
            exe,
            pid,

            stdin = subprocess.PIPE,
            stdout = subprocess.PIPE,
            stderr = logpath,
            cwd = cwd
        }

        if debuggingSharp then
            pargs[#pargs + 1] = "--debug"
        end

        if os.getenv("OLYMPUS_SHARP_VERBOSE") == "1" then
            pargs[#pargs + 1] = "--verbose"
        end

        local process = assert(subprocess.popen(pargs))
        local stdout = process.stdout
        local stdin = process.stdin

        local read, write, flush

        read = function()
            return assert(stdout:read("*l"))
        end

        write = function(data)
            return assert(stdin:write(data))
        end

        flush = function()
            return assert(stdin:flush())
        end

        local function readBlob()
            return {
                uid = utils.fromJSON(read()),
                value = utils.fromJSON(read()),
                status = utils.fromJSON(read())
            }
        end

        local function checkTimeoutFilter(err)
            if type(err) == "string" and (err:match("timeout") or err:match("closed")) then
                return "timeout"
            end
            if type(err) == "userdata" or type(err) == "table" then
                return err
            end
            return debug.traceback(tostring(err), 1)
        end

        local function checkTimeout(fun, ...)
            local status, rv = xpcall(fun, checkTimeoutFilter, ...)
            if rv == "timeout" then
                return "timeout"
            end
            if not status then
                error(rv, 2)
            end
            return rv
        end

        local function run(uid, cid, argsLua)
            channelStatus:clear()
            channelStatus:push("txcmd " .. tostring(uid) .. " " .. cid)
            write(utils.toJSON(uid, { indent = false }) .. "\n\0")
            write(utils.toJSON(cid, { indent = false }) .. "\n\0")

            local argsSharp = {}
            -- Olympus.Sharp expects C# Tuples, which aren't lists.
            for i = 1, #argsLua do
                argsSharp["Item" .. i] = argsLua[i]
            end
            write(utils.toJSON(argsSharp, { indent = false }) .. "\n\0")

            flush()

            channelStatus:clear()
            channelStatus:push("rxcmd " .. tostring(uid) .. " " .. cid)
            local data = readBlob()
            assert(uid == data.uid)
            return data
        end

        local uid = "?"

        local function dprint(...)
            if debugging then
                print("[sharp #" .. uid .. " queue]", ...)
            end
        end

        local unpack = table.unpack or _G.unpack

        -- The child process immediately sends a status message.
        print("[sharp init]", "reading init")
        local initStatus = readBlob()
        print("[sharp init]", "read init", initStatus)

        -- The status message contains the TCP port we're actually supposed to listen to.
        -- Switch from STDIN / STDOUT to sockets.
        local port = initStatus.uid -- initStatus gets modified later
        local function connect()
            local try = 1
            ::retry::
            channelStatus:clear()
            channelStatus:push("connect attempt " .. tostring(try))
            local clientOrStatus, clientError = socket.connect("127.0.0.1", port)
            if not clientOrStatus then
                try = try + 1
                if try >= 3 then
                    channelStatus:clear()
                    channelStatus:push("connect error " .. tostring(clientError))
                    error(clientError, 2)
                end
                print("[sharp init]", "failed to connect, retrying in 2s", clientError)
                threader.sleep(2)
                goto retry
            end
            -- clientOrStatus:settimeout(1) -- Lua-side timeout seems to cause issues, C#-side only timeout works perfectly fine:tm:
            return clientOrStatus
        end

        local client = connect()

        read = function()
            return assert(client:receive("*l"))
        end

        write = function(data)
            return assert(client:send(data))
        end

        flush = function()
        end

        local timeoutping = {
            uid = "_timeoutping",
            cid = "echo",
            args = { "timeout ping" }
        }

        while true do
            if debugging then
                print("[sharp queue]", "awaiting next cmd")
            end
            local cmd = channelQueue:demand(0.4)
            if not cmd then
                if debugging then
                    print("[sharp queue]", "timeoutping")
                end
                cmd = timeoutping
            end
            uid = cmd.uid
            local cid = cmd.cid
            local args = cmd.args

            channelStatus:clear()
            channelStatus:push("gotcmd " .. tostring(uid) .. " " .. cid)
            local channelReturn = love.thread.getChannel("sharpReturn" .. tostring(uid))

            if cid == "_init" then
                dprint("returning init", initStatus)
                initStatus.uid = uid
                channelReturn:push(initStatus)

            elseif cid == "_die" then
                print("[sharp queue]", "time to _die")
                channelReturn:push({ value = "ok" })
                break

            else
                ::rerun::
                dprint("running", cid, unpack(args))
                local rv = checkTimeout(run, uid, cid, args)
                if rv == "timeout" then
                    print("[sharp queue]", "timeout reconnecting", channelStatus:peek(), rv.value, rv.status, rv.status and rv.status.error)
                    channelStatus:clear()
                    channelStatus:push("reruncmd " .. tostring(uid) .. " " .. cid)
                    client:close()
                    client = connect()
                    goto rerun
                end
                if uid == "_timeoutping" then
                    dprint("timeoutping returning", rv.value, rv.status, rv.status and rv.status.error)
                else
                    local value = tostring(rv.value)
                    if #value > 128 then
                        value = "<insert long string here - " .. tostring(#value) .. " bytes>"
                    end
                    dprint("returning", value, rv.status, rv.status and rv.status.error)
                    channelReturn:push(rv)
                end
            end

            channelStatus:clear()
            channelStatus:push("donecmd " .. tostring(uid) .. " " .. cid)
        end

        channelStatus:clear()
        channelStatus:push("rip")

        client:close()
    end)

    channelStatus:clear()
    channelStatus:push("rip")

    if not status then
        print("[sharpthread error]", err)
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

function sharp._run(cid, ...)
    local debugging = channelDebug:peek()[1]
    local uid = string.format("(%s)#%d", require("threader").id, tuid)
    tuid = tuid + 1

    local status = channelStatus:peek(100)
    if status == "rip" then
        if cid == "_init" then
            return false
        else
            error(string.format("Failed running %s %s: sharp thread died", uid, cid))
        end
    end

    local function dprint(...)
        if debugging then
            print("[sharp #" .. uid .. " run]", ...)
        end
    end

    dprint("enqueuing", cid, ...)
    channelQueue:push({ uid = uid, cid = cid, args = {...} })

    dprint("awaiting return value")
    local channelReturn = love.thread.getChannel("sharpReturn" .. uid)
    ::reget::
    local rv = channelReturn:demand(100)
    if not rv then
        status = channelStatus:peek(100)
        if status == "rip" then
            if cid == "_init" then
                channelReturn:release()
                return false
            else
                channelReturn:release()
                error(string.format("Failed running %s %s: sharp thread died", uid, cid))
            end
        end
        goto reget
    end
    channelReturn:release()
    if rv.uid ~= uid then
        error(string.format("Failed running %s %s: sharp thread returned value on wrong channel", uid, cid))
    end

    dprint("got", rv.value, rv.status, rv.status and rv.status.error)

    if type(rv.status) == "table" and rv.status.error then
        error(string.format("Failed running %s %s: %s", uid, cid, tostring(rv.status.error)))
    end

    assert(uid == rv.uid)
    return rv.value
end
function sharp.run(id, ...)
    return threader.run(sharp._run, id, ...)
end

sharp.initStatus = false
function sharp.init(debug, debugSharp)
    if sharp.initStatus then
        return sharp.initStatus
    end

    channelDebug:clear()
    channelDebug:push({ debug and true or os.getenv("OLYMPUS_SHARP_DEBUGLOG") == "1", debugSharp and true or false })
    channelStatus:clear()
    channelStatus:push("init")

    -- Run the command queue on a separate thread.
    local thread = threader.new(sharpthread)
    sharp.thread = thread
    thread:start()

    -- The child process immediately sends a status message.
    sharp.initStatus = sharp.run("_init"):result()

    return sharp.initStatus
end

function sharp.getStatus()
    return channelStatus:peek() or "unknown"
end

return sharp
