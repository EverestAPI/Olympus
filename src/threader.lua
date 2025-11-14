local log = require('logger')('threader')

local spikerStatus, spiker = pcall(require, "spiker")
if not spikerStatus then
    spiker = nil
end
local unpack = _G.unpack or table.unpack

local threader = {
    _threads = {},
    _routines = {},
    _wrapCache = {},

    id = "main",

    -- Native callbacks (such as SDL_EventFilter) can run during coroutine yields. This counter is to be used in native callbacks where threader updates can happen.
    unsafe = 0
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
        error(self.id .. " already released!", 2)
    end

    local wasRunning = self.running
    if not wasRunning then
        error(self.id .. " not running!", 2)
    end

    local rv = self:__update(...)
    if rv == nil then
        return
    end

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
        error(self.id .. " died:\n" .. tostring(errorMsg))
    end

    return unpack(rv)
end

function sharedWrap:wait(...)
    if self.released then
        error(self.id .. " already released!", 2)
    end

    if not self.running then
        error(self.id .. " not running!", 2)
    end

    if self:__waitNeeded() then
        local routine = threader._routines[coroutine.running()]
        if routine then
            routine.waiting = true
            self:calls(function(...)
                routine.waiting = false
            end)
            threader.unsafe = threader.unsafe + 1
            coroutine.yield(self)
            threader.unsafe = threader.unsafe - 1
            return
        end

        self:__wait()
    end

    return self:update(...)
end

function sharedWrap:await()
    return self:result()
end

function sharedWrap:calls(cb, cb2, ...)
    self.callbacks[#self.callbacks + 1] = cb
    if not self.running then
        cb(self, unpack(self.result))
    end
    if cb2 then
        return self:calls(cb2, ...)
    end
    return self
end

function sharedWrap:falls(cb, cb2, ...)
    self.fallbacks[#self.fallbacks + 1] = cb
    if not self.running then
        cb(self, self.error)
    end
    if cb2 then
        return self:falls(cb2, ...)
    end
    return self
end


local threadWrap = {}

function threadWrap:start(...)
    if self.released then
        error(self.id .. " already released!", 2)
    end

    if self.running then
        error(self.id .. " already running!", 2)
    end

    self.running = true
    self.thread:start({
        meta = {
            id = self.id,
            code = self.code,
            upvalues = self.upvalues,
            channel = self.channel
        },
        args = { ... }
    })
    threader._threads[#threader._threads + 1] = self

    return self
end

function threadWrap:__update()
    local thread = self.thread

    local wasRunning = self.running
    local running = thread:isRunning()
    self.running = running

    local error = thread:getError()
    self.error = error

    if wasRunning and not running then
        local rv = self.channel:pop()
        if rv then
            if rv[1] then
                return rv[2]
            end

            self.error = error or rv[2]
            return rv
        end
    end

    return nil
end

function threadWrap:__waitNeeded()
    return self.thread:isRunning()
end

function threadWrap:__wait(...)
    self.thread:wait()
end

function threadWrap:release()
    if self.running then
        error(self.id .. " still running!", 2)
    end

    if self.released then
        error(self.id .. " already released!", 2)
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
    error("Coroutines cannot be restarted!", 2)
end

function routineWrap:__update(...)
    local log = require("logger")("threader.routine")
    local co = self.routine

    -- Sanity-check the status before resuming the coroutine in question.
    local status = coroutine.status(co)

    -- cannot resume running coroutine
    if status == "running" then
        -- There is a special place in hell for whenever this happens.
        -- The only reasonable way this should even happen is a threader.update from inside a threader coroutine, but CTRL+F SDL_EventFilters.
        log.warning("coroutine " .. self.id .. " is the currently running coroutine, can't resume!")
        log.warning(debug.traceback())
        return nil -- and hope that the caller knows how to handle this.
    end

    -- cannot resume dead coroutine
    if status == "dead" then
        -- Coroutines should never die outside of our control.
        -- Sadly we don't fully control the environment - CTRL+F SDL_EventFilters.
        log.warning("coroutine " .. self.id .. " died outside of our control - assuming graceful death!")
        log.warning(debug.traceback())
        self.running = false
        self.error = nil
        return nil -- and hope that the caller knows how to handle this.
    end

    local rv = {coroutine.resume(co, ...)}
    local passed = rv[1]
    table.remove(rv, 1)

    local running = coroutine.status(co) ~= "dead"
    self.running = running

    if not passed and rv[2] == nil and rv[1] == "cannot resume dead coroutine" then
        log.warning("coroutine " .. self.id .. " cannot be resumed because it's supposedly dead but the status was " .. status .. " and is " .. coroutine.status(co))
    end

    local errorMsg = not passed and (rv[1] or "???")
    self.error = errorMsg

    return rv
end

function routineWrap:__waitNeeded()
    return coroutine.status(self.routine) ~= "dead"
end

function routineWrap:__wait(...)
    while self.running do
        coroutine.yield()
    end
end

function routineWrap:release()
    error("Coroutines cannot be released!", 2)
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
function threader.new(fun)
    local thread = love.thread.newThread([[-- threader.new
        local __threadType = "new"

]] .. (threader.debug and ("-- DEBUG START\n" .. threader.debug .. "\n--DEBUG END") or "") .. [[
]] .. (threader.debugStart and threader.debugStart or "") .. [[

        local prethreadStatus, prethread = pcall(require, "prethread")
        if prethreadStatus and type(prethread) == "function" then
            prethread(...)
        end

        local log = require("logger")("threader.thread")

        local raw = ...
        local meta = raw.meta
        local args = raw.args

        local id = meta.id
        require("threader").id = id

        local load = load or loadstring
        local fun = assert(load(meta.code))

        local upvalues = meta.upvalues
        for i = 1, #upvalues do
            local slot = upvalues[i]
            debug.setupvalue(fun, i, slot.value)
        end

        local channel = meta.channel
        _G._channel = channel

        local unpack = unpack or table.unpack

        local status, rv = xpcall(
            function()
                return {fun(unpack(args))}
            end,
            function(err)
                log.error(id, err)
                if type(err) == "userdata" or type(err) == "table" then
                    return err
                end
                return debug.traceback(tostring(err), 1)
            end
        )

        if not status then
            -- error(rv) -- interferes with love.threaderror and skips debugEnd
            channel:push({ false, rv })
        else
            channel:push({ true, rv })
        end

    ]] .. (threader.debugEnd and threader.debugEnd or ""))

    local suffix = ""

    local upvalues = {}
    if type(fun) == "function" then
        local infoFun = debug.getinfo(fun, "S")
        suffix = suffix .. ">" .. infoFun.short_src .. ":" .. infoFun.linedefined

        local i = 1
        while true do
            local key, value = debug.getupvalue(fun, i)
            if not key then
                break
            end
            upvalues[i] = { key = key, value = value }
            i = i + 1
        end

    end

    local infoCall = debug.getinfo(2, "fSl")
    if infoCall.func == threader.run then
        infoCall = debug.getinfo(3, "Sl")
    end

    suffix = suffix .. "<" .. infoCall.short_src .. ":" .. infoCall.currentline

    local wrap = setmetatable({
        id = "thread#" .. threadID .. suffix,
        thread = thread,
        channel = love.thread.newChannel(),
        code = type(fun) == "string" and fun or string.dump(fun),
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
        local __threadType = "async"

]] .. (threader.debug and ("-- DEBUG START\n" .. threader.debug .. "\n--DEBUG END") or "") .. [[
]] .. (threader.debugStart and threader.debugStart or "") .. [[

        local rv = ]] .. fun .. [[
        if type(rv) == 'function' then
            return rv(...)
        end
        return rv
    ]] .. (threader.debugEnd and threader.debugEnd or ""), ...)
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
    local suffix = ""

    local infoFun = debug.getinfo(fun, "S")
    suffix = suffix .. ">" .. infoFun.short_src .. ":" .. infoFun.linedefined

    local infoCall = debug.getinfo(2, "Sl")
    suffix = suffix .. "<" .. infoCall.short_src .. ":" .. infoCall.currentline

    local wrap = setmetatable({
        id = "routine#" .. threadID .. suffix,
        callbacks = {},
        fallbacks = {},
        critical = true,
        released = false,
        running = true
    }, mtRoutineWrap)

    local co = coroutine.create(function(...)
        local id = wrap.id
        local args = {...}

        local status, rv = xpcall(
            function()
                return {fun(unpack(args))}
            end,
            function(err)
                logger.error(id, err)
                if type(err) == "userdata" or type(err) == "table" then
                    return err
                end
                return debug.traceback(tostring(err), 1)
            end
        )

        if not status then
            error(rv, 2)
        end

        return unpack(rv)
    end)

    wrap.routine = co
    threader._threads[#threader._threads + 1] = wrap
    threader._routines[co] = wrap

    threadID = threadID + 1
    return wrap
end

function threader.sleep(duration)
    local timeStart = love.timer.getTime()

    local routine = threader._routines[coroutine.running()]
    if routine then
        coroutine.yield()
        while love.timer.getTime() - timeStart < duration do
            coroutine.yield()
        end
        return
    end

    love.timer.sleep(duration)
end

function threader.update()
    local running = threader._routines[coroutine.running()]
    if running then
        local status = coroutine.status(running.routine)
        if status ~= "running" then
            logger.warning("threader.update called from within a " .. (running.waiting and "waiting " or "") .. " ZOMBIE threader coroutine (" .. running.id .. ", " .. status .. "), possibly via a native callback during coroutine.yield")
        else
            logger.warning("threader.update called from within a " .. (running.waiting and "waiting " or "") .. "threader coroutine (" .. running.id .. "), possibly via a native callback during coroutine.yield")
        end
    end

    local spiker = spiker
    local spike = spiker and spiker("threader.update", 0.005)

    local all = threader._threads
    for i = #all, 1, -1 do
        local t = all[i]
        if running ~= t and not t.waiting then
            t:update()
        end
        spike = spike and spike(t.id)
    end

    spike = spike and spiker(spike)
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
    error("Wrapped tables are readonly!", 2)
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
        local __threadType = "wrap"

]] .. (threader.debug and ("-- DEBUG START\n" .. threader.debug .. "\n--DEBUG END") or "") .. [[
]] .. (threader.debugStart and threader.debugStart or "") .. [[

            local args = {...}

            local dep = args[1]
            local key = args[2]
            local unpack = unpack or table.unpack
            return require(dep)[key](unpack(args, 3))
        ]] .. (threader.debugEnd and threader.debugEnd or ""), self[mtThreadRequireWrap], key, ...)
    end

    rawset(self, key, value)
    return value
end

function mtThreadRequireWrap:__newindex(key, value)
    error("Wrapped tables are readonly!", 2)
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
