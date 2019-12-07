if not luacom then
  local init, err1, err2 = package.loadlib("luacom.dll", "luacom_openlib")
  assert (init, (err1 or '')..(err2 or ''))
  init()
end

return luacom
