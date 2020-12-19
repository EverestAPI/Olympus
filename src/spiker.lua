require("love.timer")

local pool = {}
local index = 1

local spike = {}

function spike:start(tag, threshold, thresholdTotal, thresholdPrint)
    if not tag then
        local caller = debug.getinfo(2, "fSl")
        if caller.func == next then
            caller = debug.getinfo(3, "Sl")
        end
        tag = caller.short_src .. ":" .. caller.currentline
    end

    pool[self.index] = nil

    self.tag = tag
    self.threshold = threshold or 0.003
    self.thresholdTotal = thresholdTotal or threshold or 0.003
    self.thresholdPrint = thresholdPrint or 0.0003
    self.spiked = false
    self.steps = {}
    self.timeTotal = 0
    local time = love.timer.getTime()
    self.timeStart = time
    self.timeStep = time

    return self, 0
end

function spike:step(tag, threshold)
    local time = love.timer.getTime()

    local delta = time - self.timeStep
    self.steps[#self.steps + 1] = {
        delta = delta,
        tag = tag,
        threshold = threshold or (type(tag) == "number" and tag) or self.threshold
    }

    local timeTotal = self.timeTotal + delta
    self.timeTotal = timeTotal
    if delta > self.threshold or timeTotal >= self.thresholdTotal then
        self.spiked = true
    end

    self.timeStep = love.timer.getTime()
    return self, delta
end

function spike:stop(...)
    pool[self.index] = self
    local _, deltaEnd = self:step(...)

    if not self.spiked then
        return self, deltaEnd
    end

    local steps = self.steps
    print("[SPIKE T ", self.tag)
    for i = 1, #steps do
        local step = steps[i]
        if step.delta >= self.thresholdPrint then
            print("[SPIKE |" .. (step.delta > step.threshold and "*" or " "), step.delta, step.tag)
        end
    end
    print("[SPIKE >" .. (self.timeTotal > self.thresholdTotal and "*" or " "), self.timeTotal)

    return self, deltaEnd
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
