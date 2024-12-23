local threader = require("threader")

-- These must be named channels so that new threads requiring sharp can use them.
local channelQueue = love.thread.getChannel("sharpQueue")
local channelDebug = love.thread.getChannel("sharpDebug")
local channelStatus = love.thread.getChannel("sharpStatus")
local channelStatusTx = love.thread.getChannel("sharpStatusTx")
local channelStatusRx = love.thread.getChannel("sharpStatusRx")
local channelStatusWaiting = love.thread.getChannel("sharpStatusWaiting")
local channelSleep = love.thread.getChannel("sharpSleep")

-- Thread-local ID.
local tuid = 0

-- The command queue thread.
local function sharpthread()
    local function channelSetCb(channel, value)
        channel:clear()
        channel:push(value)
    end

    local function channelSet(channel, value)
        channel:performAtomic(channelSetCb, value)
    end

    channelSet(channelStatus, "start")

    local status, err = xpcall(function()
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

        local exename = "Olympus.Sharp"
        if ffi.os == "Windows" then
            exename = "Olympus.Sharp.exe"
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

        if ffi.os ~= "Windows" then
            subprocess.call({"chmod", "-v", "u+x", exe})
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

        local stopping = false
        local running = true

        local uid = "?"

        local function dprint(...)
            if debugging then
                print("[sharp #" .. uid .. " queue]", ...)
            end
        end

        local unpack = table.unpack or _G.unpack

        -- The child process immediately sends a status message.
        print("[sharp init]", "reading init")
        local initStatus = {
            UID = utils.fromJSON(assert(stdout:read("*l"))),
            Value = utils.fromJSON(assert(stdout:read("*l"))),
            Error = utils.fromJSON(assert(stdout:read("*l")))
        }
        print("[sharp init]", "read init", initStatus)

        local buffer = ""

        -- The status message contains the TCP port we're actually supposed to listen to.
        -- Switch from STDIN / STDOUT to sockets.
        local port = initStatus.UID -- initStatus gets modified later
        local function connect()
            buffer = ""
            local try = 1
            ::retry::
            channelSet(channelStatus, "connect attempt " .. tostring(try))
            local clientOrStatus, clientError = socket.connect("127.0.0.1", port)
            if not clientOrStatus then
                try = try + 1
                if try >= 3 then
                    channelSet(channelStatus, "connect error " .. tostring(clientError))
                    error(clientError, 2)
                end
                print("[sharp init]", "failed to connect, retrying in 2s", clientError)
                threader.sleep(2)
                goto retry
            end
            return clientOrStatus
        end

        local client = connect()

        local timeoutping = {
            uid = "_timeoutping",
            cid = "echo",
            args = { "timeout ping" }
        }

        local lastSend = socket.gettime()
        print("[sharp init]", "startime", lastSend)

        local partLast
        local function read(pattern)
            local rv, err, part = client:receive(pattern or "*l")
            if rv and rv ~= partLast then
                return rv, false
            end

            if part ~= "" then
                partLast = part
                return part, true
            end

            if err ~= "timeout" and not stopping then
                print("[sharp read]", "hard error reconnecting", err, channelStatus:peek())
                channelSet(channelStatus, "reread")
                client:close()
                client = connect()
            end

            return nil
        end

        local function getReturn(uid)
            return love.thread.getChannel("sharpReturn" .. uid)
        end

        local function sendReturn(uid, data)
            getReturn(uid):push(data)
        end

        local nops = 0
        local sleepPoll = 0
        local sleeps = channelSleep:peek()
        local sleepShort = sleeps[1]
        local sleepLong = sleeps[2]

        local waiting = {}
        channelSet(channelStatusWaiting, waiting)

        while running do
            channelSet(channelStatus, "idle")

            local nop = true

            client:settimeout(0)
            while true do
                local raw, rawPart = read()
                if not raw or raw == "" then
                    break
                end

                raw = buffer .. raw
                local index = 0
                local prev = 1
                while true do
                    index = raw:find("\0", prev, true)
                    if not index then
                        buffer = raw:sub(prev)
                        break
                    end

                    nop = false

                    local part = raw:sub(prev, index - 1)
                    prev = index + 1
                    local data = utils.fromJSON(part)
                    if not data then
                        print("[sharp rx]", "erroreous part", part)
                        goto next
                    end

                    if data.UID ~= "_timeoutping" then
                        channelSet(channelStatusRx, data.UID)

                        local dbgvalue

                        if data.RawSize then
                            client:settimeout(nil)
                            if rawPart then
                                read(1) -- Skip the newline byte that luasocket (in)conveniently ignores...
                            end
                            data.Value = read(data.RawSize)
                            client:settimeout(0)

                            if debugging then
                                dbgvalue = "<insert raw data here - " .. tostring(data.RawSize) .. " bytes expected, " .. tostring(#data.Value) .. " bytes gotten>"
                            end

                        elseif debugging then
                            dbgvalue = tostring(data.Value)
                            if #dbgvalue > 512 then
                                dbgvalue = "<insert long string here - " .. tostring(#dbgvalue) .. " bytes>"
                            end
                        end

                        if debugging then
                            data.DebugValue = dbgvalue
                            print("[sharp rx]", data.UID, dbgvalue, data.Error)
                        end
                        sendReturn(data.UID, data)

                        client:send(
                            utils.toJSON(data.UID, { indent = false }) .. "\0\n" ..
                            utils.toJSON("_ack", { indent = false }) .. "\0\n" ..
                            utils.toJSON(nil, { indent = false }) .. "\0\n")

                        for i = 1, #waiting do
                            if waiting[i] == data.UID then
                                table.remove(waiting, i)
                                channelSet(channelStatusWaiting, waiting)
                                break
                            end
                        end

                        if data.UID == "_stop" then
                            running = false
                            break
                        end
                    end

                    ::next::
                end
                break
            end
            client:settimeout(nil)

            local cmd = not stopping and channelQueue:pop()
            if not cmd and (socket.gettime() - lastSend) >= 0.4 then
                cmd = timeoutping
            end

            if cmd then
                nop = false

                lastSend = socket.gettime()
                uid = cmd.uid
                local cid = cmd.cid
                local args = cmd.args

                if uid ~= "_timeoutping" then
                    channelSet(channelStatus, "runcmd " .. uid .. " " .. cid)
                end

                if cid == "_init" then
                    dprint("returning init", initStatus)
                    initStatus.UID = uid
                    sendReturn(uid, initStatus)

                elseif cid == "_die" then
                    print("[sharp queue]", "time to _die")
                    sendReturn(uid, { UID = uid, Value = "ok" })
                    break

                elseif cid then
                    ::rerun::
                    if uid ~= "_timeoutping" then
                        dprint("running", cid, unpack(args))

                        channelSet(channelStatusTx, uid .. " " .. cid)
                    end

                    if cid == "_stop" then
                        stopping = true
                    end

                    local argsSharp = {}
                    -- Olympus.Sharp expects C# Tuples, which aren't lists.
                    for i = 1, #args do
                        argsSharp["Item" .. i] = args[i]
                    end
                    local rv, err = client:send(
                        utils.toJSON(uid, { indent = false }) .. "\0\n" ..
                        utils.toJSON(cid, { indent = false }) .. "\0\n" ..
                        utils.toJSON(argsSharp, { indent = false }) .. "\0\n")

                    if stopping then
                        break
                    end

                    if not rv then
                        print("[sharp queue]", "hard error reconnecting", err, channelStatus:peek())
                        channelSet(channelStatus, "reruncmd " .. uid .. " " .. cid)
                        client:close()
                        client = connect()
                        goto rerun
                    end

                    if uid ~= "_timeoutping" then
                        waiting[#waiting + 1] = uid
                        channelSet(channelStatusWaiting, waiting)
                    end
                end

                if uid ~= "_timeoutping" then
                    channelSet(channelStatus, "donecmd " .. uid .. " " .. cid)
                end
            end

            sleepPoll = sleepPoll + 1
            if sleepPoll >= 100 then
                sleepPoll = 0
                sleeps = channelSleep:peek()
                sleepShort = sleeps[1]
                sleepLong = sleeps[2]
            end

            if nop then
                nops = nops + 1
                if nops > 40 then
                    nops = 40
                    threader.sleep(sleepLong)
                else
                    threader.sleep(sleepShort)
                end
            else
                nops = 0
            end
        end

        channelSet(channelStatus, "rip")

        client:close()
    end,
    function(err)
        if type(err) == "userdata" or type(err) == "table" then
            return err
        end
        return debug.traceback(tostring(err), 1)
    end)

    channelSet(channelStatus, "rip")

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
    local uid = string.format("(%s)(%s)#%d", cid, require("threader").id, tuid)
    tuid = tuid + 1

    local function handleDeath()
        channelStatus:push("rip") -- let the next ones picking know of the death as well
        if cid == "_init" or cid == "_stop" then
            return false
        else
            error(string.format("Failed running %s %s: sharp thread died", uid, cid))
        end
    end

    local status = channelStatus:peek()
    if status == "rip" then
        return handleDeath()
    end

    local function dprint(...)
        if debugging then
            print("[sharp #" .. uid .. " run]", ...)
        end
    end

    dprint("enqueuing", cid, ...)
    channelQueue:push({ uid = uid, cid = cid, args = {...} })

    dprint("awaiting return value")
    ::reget::
    local channelReturn = love.thread.getChannel("sharpReturn" .. uid)
    local rv = channelReturn:demand(0.1)
    if not rv or rv == uid then
        status = channelStatus:demand(0.1)
        if status == "rip" then
            channelReturn:release()
            return handleDeath()
        end
        goto reget
    end
    channelReturn:release()
    if rv.UID ~= uid then
        error(string.format("Failed running %s %s: sharp thread returned value on wrong channel", uid, cid))
    end

    dprint("got", rv.DebugValue, rv.Error)

    if rv.Error then
        error(string.format("Failed running %s %s: %s", uid, cid, tostring(rv.Error)))
    end

    return rv.Value
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
    channelSleep:push({ 0.07, 0.07 })

    -- Run the command queue on a separate thread.
    local thread = threader.new(sharpthread)
    sharp.thread = thread
    thread:start()

    -- The child process immediately sends a status message.
    sharp.initStatus = sharp._run("_init")

    return sharp.initStatus
end

function sharp.stop()
    sharp._run("_stop")
end

local function channelSetCb(channel, value)
    channel:clear()
    channel:push(value)
end

local function channelSet(channel, value)
    channel:performAtomic(channelSetCb, value)
end

function sharp.getStatus()
    return channelStatus:peek() or "unknown"
end

function sharp.getStatusTx()
    return channelStatusTx:peek() or "unknown"
end

function sharp.getStatusRx()
    return channelStatusRx:peek() or "unknown"
end

function sharp.getStatusWaiting()
    return channelStatusWaiting:peek() or {}
end

function sharp.setSleep(short, long)
    channelSet(channelSleep, { short, long })
end

return sharp
