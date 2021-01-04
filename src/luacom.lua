local love = _G.love
if love then
    if love.system.getOS() ~= "Windows" then
        return false
    end
else
    local jit = _G.jit
    if jit then
        if jit.os ~= "Windows" then
            return false
        end
    end
end

-- LuaCOM dumps itself into _G

if not _G.luacom then
    local init, err1, err2 = package.loadlib("luacom.dll", "luacom_openlib")
    if not init then
        print(err1, err2)
        return false
    end

    init()
end

return _G.luacom
