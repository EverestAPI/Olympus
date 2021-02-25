return function(url)
    if url:match("https?://") then
        return require("modinstaller").install(url)
    end

    return false
end
