-- LuaCOM dumps itself into _G

if not _G.luacom then
  local init, err1, err2 = package.loadlib("luacom.dll", "luacom_openlib")
  if not init then
    print((err1 or "") .. (err2 or ""))
    return false
  end

  init()
end

return _G.luacom
