local uiu = {}

function uiu.nop()
end


uiu.imageCache = {}
function uiu.image(path)
    local cache = uiu.imageCache
    local img = cache[path]
    if img then
        return img
    end

    img = love.graphics.newImage("data/" .. path .. ".png")
    cache[path] = img
    return img
end


function uiu.round(x)
    return x + 0.5 - (x + 0.5) % 1
end
math.round = math.round or uiu.round


function uiu.listRange(from, to, step)
    local output = {}
    for i = from, to, (step or 1) do
        output[#output + 1] = i
    end
    return output
end


function uiu.map(input, fn)
    local output = {}
    for k, v in pairs(input) do
        output[k] = fn(v)
    end
    return output
end


function uiu.join(list, splitter)
    local output = ""
    if #list == 0 then
        return output
    end
    for i = 1, #list - 1 do
        output = output .. tostring(list[i]) .. splitter
    end
    for i = #list, #list do
        output = output .. tostring(list[i])
    end
    return output
end


function uiu.concat(...)
    return uiu.join({ ... }, "")
end


function uiu.magic(fn, ...)
    local magic = uiu.magic
    local mask = { ... }

    return function(...)
        local input = { ... }
        local args = {}

        local ii = 1

        for i = 1, #mask do
            local arg = mask[i]
            if arg == magic then
                arg = input[ii]
                ii = ii + 1
            end
            args[#args + 1] = arg
        end

        for i = ii, #input do
            args[#args + 1] = input[i]
        end

        return fn(table.unpack(args))
    end
end


function uiu.hook(target, nameOrMap, cb)
    if type(nameOrMap) ~= "string" then
        for name, cb in pairs(nameOrMap) do
            uiu.hook(target, name, cb)
        end
        return
    end

    local name = nameOrMap
    local orig = target[name] or uiu.nop
    target[name] = function(self, ...)
        cb(self, orig, ...)
    end
end


function uiu.fillWidth(el)
    uiu.hook(el, {
        layoutLazy = function(self, orig)
            -- Required to allow the container to shrink again.
            orig(self)
            self.width = 0
        end,
    
        layoutLateLazy = function(self, orig)
            -- Always reflow this child whenever its parent gets reflowed.
            self:layoutLate()
        end,
    
        layoutLate = function(self, orig)
            local width = self.parent.innerWidth
            self.width = width
            self.innerWidth = width - self.style.padding * 2
            orig(self)
        end
    })
end

function uiu.fillWidthExcept(leftover)
    return function(el)
        uiu.hook(el, {
            layoutLazy = function(self, orig)
                -- Required to allow the container to shrink again.
                orig(self)
                self.width = 0
            end,
        
            layoutLateLazy = function(self, orig)
                -- Always reflow this child whenever its parent gets reflowed.
                self:layoutLate()
            end,
        
            layoutLate = function(self, orig)
                local width = self.parent.innerWidth - leftover
                self.width = width
                self.innerWidth = width - self.style.padding * 2
                orig(self)
            end
        })
    end
end


function uiu.fillHeight(el)
    uiu.hook(el, {
        layoutLazy = function(self, orig)
            -- Required to allow the container to shrink again.
            orig(self)
            self.height = 0
        end,
    
        layoutLateLazy = function(self, orig)
            -- Always reflow this child whenever its parent gets reflowed.
            self:layoutLate()
        end,
    
        layoutLate = function(self, orig)
            local Height = self.parent.innerHeight
            self.height = Height
            self.innerHeight = Height - self.style.padding * 2
            orig(self)
        end
    })
end

function uiu.fillHeightExcept(leftover)
    return function(el)
        uiu.hook(el, {
            layoutLazy = function(self, orig)
                -- Required to allow the container to shrink again.
                orig(self)
                self.height = 0
            end,
        
            layoutLateLazy = function(self, orig)
                -- Always reflow this child whenever its parent gets reflowed.
                self:layoutLate()
            end,
        
            layoutLate = function(self, orig)
                local Height = self.parent.innerHeight - leftover
                self.height = Height
                self.innerHeight = Height - self.style.padding * 2
                orig(self)
            end
        })
    end
end


function uiu.rightbound(el)
    uiu.hook(el, {
        layoutLateLazy = function(self, orig)
            -- Always reflow this child whenever its parent gets reflowed.
            self:layoutLate()
        end,
    
        layoutLate = function(self, orig)
            local parent = self.parent
            self.realX = parent.innerWidth - self.width
            orig(self)
        end
    })
end


table.pack = table.pack or function(...)
    return { ... }
end
table.unpack = table.unpack or _G.unpack


return uiu
