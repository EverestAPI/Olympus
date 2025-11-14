local function logger(tag)
    local logger = {}
    local function log(level, ...)
        print('[' .. os.date('%Y-%m-%d %H:%M:%S') .. ']', '[' .. tag .. ']', '[' .. level .. ']', ...)
    end

    -- "..." lets us toss any number of arguments to the final call to "print"
    -- (unsure if this is Lua or morse code at this point)
    function logger.debug(...)
        log('dbg', ...)
    end
    function logger.info(...)
        log('inf', ...)
    end
    function logger.warning(...)
        log('wrn', ...)
    end
    function logger.error(...)
        log('err', ...)
    end
    return logger
end

return logger