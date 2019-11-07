local utils = {}

function utils.nop()
end

utils.imageCache = {}
function utils.image(path)
    local cache = utils.imageCache
    local img = cache[path]
    if img then
        return img
    end

    img = love.graphics.newImage("data/" .. path .. ".png")
    cache[path] = img
    return img
end

function math.round(x)
    return x + 0.5 - (x + 0.5) % 1
end

return utils
