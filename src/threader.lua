local threader = {
    _threads = {},
    _routines = {},
    _wrapCache = {},
}


local mtThreadResultWrap = {
    __name = "threader.thread.result"
}

function mtThreadResultWrap:__call()
    return table.unpack(self)
end


local threadWrap = {}

function threadWrap:start(...)
    if self.released then
        error("Thread " .. self.id .. " already released!")
    end

    if self.running then
        return
    end

    self.running = true
    self.thread:start(self.code, self.upvalues, self.channel, ...)
    threader._threads[#threader._threads + 1] = self

    return self
end

function threadWrap:update()
    if self.released then
        error("Thread " .. self.id .. " already released!")
    end

    local thread = self.thread

    local wasRunning = self.running
    local running = thread:isRunning()
    self.running = running

    local errorMsg = thread:getError()
    self.error = errorMsg
    local rethrow = errorMsg and self.critical

    if wasRunning and not running then
        local channel = self.channel
        local rv = channel:pop()
        self.result = setmetatable(rv, mtThreadResultWrap)

        if errorMsg then
            local cbs = self.fallbacks
            for i = 1, #cbs do
                local cb = cbs[i]
                if cb(self, errorMsg) then
                    rethrow = false
                end
            end

        else
            local cbs = self.callbacks
            for i = 1, #cbs do
                local cb = cbs[i]
                cb(self, table.unpack(rv))
            end
        end
    end

    if rethrow then
        error(errorMsg)
    end

    return self
end

function threadWrap:wait(...)
    if self.released then
        error("Thread " .. self.id .. " already released!")
    end

    self:start(...)

    local co = coroutine.running()
    if threader._routines[co] then
        self:calls(function(...)
            local pass, errorMsg = coroutine.resume(co, ...)
            if not pass then
                error(errorMsg)
            end
        end)
        coroutine.yield(self)
        return self
    end

    self.thread:wait()
    self:update()

    return self
end

function threadWrap:await()
    return self:result()
end

function threadWrap:calls(cb, cb2, ...)
    self.callbacks[#self.callbacks + 1] = cb
    if cb2 then
        return self:calls(cb2, ...)
    end
    return self
end

function threadWrap:falls(cb, cb2, ...)
    self.fallbacks[#self.fallbacks + 1] = cb
    if cb2 then
        return self:falls(cb2, ...)
    end
    return self
end

function threadWrap:release()
    if self.running then
        error("Thread " .. self.id .. " still running!")
    end

    if self.released then
        error("Thread " .. self.id .. " already released!")
    end

    self.released = true
    self.thread:release()
    self.channel:release()

    return self
end


local mtThreadWrap = {
    __name = "threader.thread"
}

function mtThreadWrap:__index(key)
    local value = rawget(self, key)
    if value ~= nil then
        return value
    end

    if key == "result" then
        self:wait()
    end

    value = rawget(self, key)
    if value ~= nil then
        return value
    end

    return threadWrap[key]
end


local threadID = 0
function threader.new(func)
    local thread = love.thread.newThread([[-- threader.new
        local args = {...}

        local code = args[1]
        table.remove(args, 1)

        local load = load or loadstring
        local func = assert(load(code))

        local upvalues = args[1]
        table.remove(args, 1)

        local channel = args[1]
        _G._channel = channel
        table.remove(args, 1)

        for i = 1, #upvalues do
            local slot = upvalues[i]
            debug.setupvalue(func, i, slot.value)
        end

        local unpack = unpack or table.unpack
        local rv = {func(unpack(args))}
        channel:push(rv)
    ]])
    local channelKey = "threader:" .. tostring(threadID)
    local channel = love.thread.getChannel(channelKey)

    local upvalues = {}
    if type(func) == "function" then
        local i = 1
        while true do
            local key, value = debug.getupvalue(func, i)
            if not key then
                break
            end
            upvalues[i] = { key = key, value = value }
            i = i + 1
        end
    end

    local wrap = setmetatable({
        id = threadID,
        thread = thread,
        channel = channel,
        code = type(func) == "string" and func or string.dump(func),
        upvalues = upvalues,
        callbacks = {},
        fallbacks = {},
        critical = true,
        released = false
    }, mtThreadWrap)

    threadID = threadID + 1
    return wrap
end

function threader.run(fun, ...)
    return threader.new(fun):start(...)
end

function threader.async(fun, ...)
    return threader.run([[
        local rv = ]] .. fun .. [[
        if type(rv) == 'function' then
            return rv(...)
        end
        return rv
    ]], ...)
end

function threader.await(thread, ...)
    if type(thread) == "string" or type(thread) == "nil" then
        thread = threader.run(thread or "return ...", ...)
    end
    if type(thread) == "function" then
        thread = threader.run(thread, ...)
    end
    return thread:result()
end

function threader.routine(fun, ...)
    local co = coroutine.create(fun)
    threader._routines[co] = true
    local pass, errorMsg = coroutine.resume(co, ...)
    if not pass then
        error(errorMsg)
    end
end

function threader.update()
    local all = threader._threads
    for i = #all, 1, -1 do
        local t = all[i]
        t:update()
        if not t.running then
            table.remove(all, i)
        end
    end
end


local mtThreadTableWrap = {
    __name = "threader.table"
}

function mtThreadTableWrap:__index(key)
    local value = rawget(self, key)
    if value ~= nil then
        return value
    end

    value = function(...)
        return threader.run(self[mtThreadTableWrap][key], ...)
    end

    rawset(self, key, value)
    return value
end

function mtThreadTableWrap:__newindex(key, value)
    error("Wrapped tables are readonly!")
end


local mtThreadRequireWrap = {
    __name = "threader.require"
}

function mtThreadRequireWrap:__index(key)
    local value = rawget(self, key)
    if value ~= nil then
        return value
    end

    value = function(...)
        return threader.run([[-- threader.wrap
            local args = {...}

            local dep = args[1]
            table.remove(args, 1)

            local key = args[1]
            table.remove(args, 1)

            local unpack = unpack or table.unpack
            return require(dep)[key](unpack(args))
        ]], self[mtThreadRequireWrap], key, ...)
    end

    rawset(self, key, value)
    return value
end

function mtThreadRequireWrap:__newindex(key, value)
    error("Wrapped tables are readonly!")
end

function threader.wrap(raw)
    local wrapCache = threader._wrapCache
    if type(raw) == "string" then
        local wrap = wrapCache[raw]
        if not wrap then
            wrap = setmetatable({[mtThreadRequireWrap] = raw}, mtThreadRequireWrap)
            wrapCache[raw] = wrap
        end
        return wrap
    end

    return setmetatable({[mtThreadTableWrap] = raw}, mtThreadTableWrap)
end

return threader
