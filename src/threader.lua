local unpack = _G.unpack or table.unpack


local threader = {
    _threads = {},
    _routines = {},
    _wrapCache = {},
}


local mtThreadResultWrap = {
    __name = "threader.thread.result"
}

function mtThreadResultWrap:__call()
    return unpack(self)
end


local sharedWrap = {}

function sharedWrap:update(...)
    if self.released then
        error(self.id .. " already released!")
    end

    local wasRunning = self.running
    if not wasRunning then
        error(self.id .. " not running!")
    end

    local rv = self:__update(...)

    local running = self.running
    local errorMsg = self.error
    local rethrow = errorMsg and self.critical

    if wasRunning and not running then
        self.result = setmetatable(rv, mtThreadResultWrap)

        local all = threader._threads
        for i = #all, 1, -1 do
            if all[i] == self then
                table.remove(all, i)
                break
            end
        end

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
                cb(self, unpack(rv))
            end
        end
    end

    if rethrow then
        error(errorMsg)
    end

    return unpack(rv)
end

function sharedWrap:wait(...)
    if self.released then
        error(self.id .. " already released!")
    end

    if not self.running then
        error(self.id .. " not running!")
    end

    local co = coroutine.running()
    local routine = threader._routines[co]
    if routine then
        routine.waiting = true
        self:calls(function(...)
            routine.waiting = false
        end)
        return coroutine.yield(self)
    end

    self:__wait()
    return self:update(...)
end

function sharedWrap:await()
    return self:result()
end

function sharedWrap:calls(cb, cb2, ...)
    self.callbacks[#self.callbacks + 1] = cb
    if cb2 then
        return self:calls(cb2, ...)
    end
    return self
end

function sharedWrap:falls(cb, cb2, ...)
    self.fallbacks[#self.fallbacks + 1] = cb
    if cb2 then
        return self:falls(cb2, ...)
    end
    return self
end


local threadWrap = {}

function threadWrap:start(...)
    if self.released then
        error(self.id .. " already released!")
    end

    if self.running then
        error(self.id .. " already running!")
        return
    end

    self.running = true
    self.thread:start(self.code, self.upvalues, self.channel, ...)
    threader._threads[#threader._threads + 1] = self

    return self
end

function threadWrap:__update()
    local thread = self.thread

    local wasRunning = self.running
    local running = thread:isRunning()
    self.running = running

    self.error = thread:getError()

    if wasRunning and not running then
        return self.channel:pop()
    end

    return {}
end

function threadWrap:__wait(...)
    self.thread:wait()
end

function threadWrap:release()
    if self.running then
        error(self.id .. " still running!")
    end

    if self.released then
        error(self.id .. " already released!")
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

    return threadWrap[key] or sharedWrap[key]
end


local routineWrap = {}

function routineWrap:start()
    error("Coroutines cannot be restarted!")
end

function routineWrap:__update(...)
    local co = self.routine

    local rv = {coroutine.resume(co, ...)}
    local passed = rv[1]
    table.remove(rv, 1)

    local running = coroutine.status(co) ~= "dead"
    self.running = running

    local errorMsg = not passed and (rv[1] or "???")
    self.error = errorMsg

    return rv
end

function routineWrap:__wait(...)
    while self.running do
        coroutine.yield()
    end
end

function routineWrap:release()
    error("Coroutines cannot be released!")
end

local mtRoutineWrap = {
    __name = "threader.routine"
}

function mtRoutineWrap:__index(key)
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

    return routineWrap[key] or sharedWrap[key]
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
        id = "thread#" .. threadID,
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
    if type(thread) == "table" and not thread.result then
        local results = {}
        for i = 1, #thread do
            results[i] = {threader.await(thread[i], ...)}
        end
        return unpack(results)
    end

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

    local wrap = setmetatable({
        id = "routine#" .. threadID,
        routine = co,
        callbacks = {},
        fallbacks = {},
        critical = true,
        released = false,
        running = true
    }, mtRoutineWrap)
    threader._threads[#threader._threads + 1] = wrap
    threader._routines[co] = wrap

    threadID = threadID + 1
    return wrap
end

function threader.update()
    local all = threader._threads
    for i = #all, 1, -1 do
        local t = all[i]
        if not t.waiting then
            t:update()
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
