-- This file runs before every threader thread and in main.lua.

require("love_filesystem_unsandboxing")

-- Needed to make luajit-request work properly on Linux.
local ffi = require("ffi")
local _ffi_load = ffi.load
function ffi.load(name, ...)
    -- libcurl is a versioned library, at least on Ubuntu.
    if ffi.os == "Linux" and name == "libcurl" then
        local names = { name, name .. ".so.4", name .. ".so.3" }
        for i = 1, #names - 1 do
            local rv = {pcall(_ffi_load, names[i], ...)}
            if rv[1] then
                table.remove(rv, 1)
                return _ffi_load("libcurl.so.4")
            end
            print(debug.traceback("Skipping " .. name .. " variant " .. names[i] .. ":\n" .. rv[2], 2))
        end

        -- Try the last variant without pcall. This causes a slightly misleading error message.
        return _ffi_load(names[#names], ...)
    end

    return _ffi_load(name, ...)
end

return true