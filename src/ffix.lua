local ffi = require("ffi")
local ffix = {}
ffix.ffi = ffi

function ffix.cdef(def)
    local max = #def
    local current = 1

    local all = {}

    repeat
        local nextA = def:find("/%*!%*/", current) or max
        local nextB = def:find("//!\n", current) or max
        local next = math.min(nextA, nextB)

        local part = def:sub(current, next - 1)
        local status, rv = pcall(ffi.cdef, part)
        if not status then
            print("Error in ffi.cdef[[\n" .. part .. "\n]]\nerror:\n" .. tostring(rv) .. "\ncontext:\n" .. debug.traceback())
        end
        all[#all + 1] = { part, status, rv }

        current = next + (next == nextA and 5 or 4)
    until current >= max

    return all
end


return setmetatable(ffix, {
    __index = ffi
})
