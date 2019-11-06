local utils = {}

function math.round(x)
    return x + 0.5 - (x + 0.5) % 1
end

return utils
