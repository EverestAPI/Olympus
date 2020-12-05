-- This file runs before every threader thread and in main.lua.
return function(id, code, upvalues, channel, ...)
    require("love_filesystem_unsandboxing")

    -- Needed to make luajit-request work properly on Linux.
    local ffiStatus, ffi = pcall(require, "ffi")
    if ffiStatus then
        local _ffi_load = ffi.load
        function ffi.load(name, ...)
            local names = { name }

            -- libcurl is a versioned library, at least on Ubuntu.
            if ffi.os == "Linux" and name == "libcurl" then
                names = { name, name .. ".so.4", name .. ".so.3" }
            end

            for i = 1, #names - 1 do
                local rv = {pcall(_ffi_load, names[i], ...)}

                if rv[1] then
                    table.remove(rv, 1)
                    return _ffi_load("libcurl.so.4")
                end

                print(debug.traceback("Skipping " .. name .. " variant " .. names[i] .. ":\n" .. rv[2], 2))
            end

            -- Try the last variant without pcall. This can cause a misleading error message.
            return _ffi_load(names[#names], ...)
        end
    end

end