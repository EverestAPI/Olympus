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
        table.insert(output, i)
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
            table.insert(args, arg)
        end

        for i = ii, #input do
            table.insert(args, input[ii])
        end

        return fn(table.unpack(args))
    end
end


table.pack = table.pack or function(...)
    return { ... }
end
table.unpack = table.unpack or _G.unpack


return uiu
