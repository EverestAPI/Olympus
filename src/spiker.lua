require("love.timer")

local pool = {}
local index = 1

local spike = {}

function spike:start(tag, threshold, thresholdStep)
    if not tag then
        local caller = debug.getinfo(2, "fSl")
        if caller.func == next then
            caller = debug.getinfo(3, "Sl")
        end
        tag = caller.short_src .. ":" .. caller.currentline
    end

    pool[self.index] = nil
    self.tag = tag
    self.threshold = threshold or 0.001
    self.thresholdStep = thresholdStep or threshold or 0.001
    local time = love.timer.getTime()
    self.timeStart = time
    self.timeStep = time
    self.timeStepped = 0
    self.steps = 0
    return self, self.timeStart
end

function spike:step(steptag, threshold)
    local time = love.timer.getTime()
    local stopping = pool[self.index]
    local delta = time - (stopping and self.timeStart or self.timeStep) - self.timeStepped

    threshold = threshold or (type(steptag) == "number" and steptag) or (stopping and self.threshold or self.thresholdStep)
    steptag = type(steptag) == "string" and steptag

    local steps = self.steps
    if not stopping then
        steps = steps + 1
        self.steps = steps
    end

    if delta >= threshold then
        if steps ~= 0 or steptag then
            print("[SPIKE " .. (stopping and "> " or "| ") .. self.tag .. "]", steptag or steps, delta)
        else
            print("[SPIKE " .. (stopping and "> " or "| ") .. self.tag .. "]", delta)
        end
        self.threshold = 0
    end

    local timeEnd = love.timer.getTime()
    self.timeStepped = self.timeStepped + (timeEnd - time)
    self.timeStep = timeEnd
    return self, time
end

function spike:stop(...)
    pool[self.index] = self
    local _, time = self:step(...)
    self.timeEnd = time
    return self, time
end

local mtSpike = {
    __name = "spiker.spike",
    __index = spike,
    __call = spike.step
}

local function next(arg1, ...)
    if type(arg1) == "table" and getmetatable(arg1) == mtSpike then
        return arg1:stop()
    end

    local s = pool[index]

    if not s then
        for i = 1, #pool do
            s = pool[i]
            if s then
                index = i
                break
            end
        end

        if not s then
            s = setmetatable({}, mtSpike)
            pool[#pool + 1] = s
            index = #pool
            s.index = #pool
        end
    end

    index = (index % #pool) + 1

    return s:start(arg1, ...)
end

return next
