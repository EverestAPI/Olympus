local luacom = require("luacom")
if not luacom then
    return false
end

local registry = {}

function registry.getKey(key)
    local sh = luacom.CreateObject("WScript.Shell")
    local status, rv = pcall(sh.RegRead, sh, key)
    if status then
      return rv
    else
      return nil
    end
end

function registry.setKey(key, value, type)
  if type ~= nil then
    value, type = type, value
  end
  local sh = luacom.CreateObject("WScript.Shell")
  if not value and not type then
    return pcall(sh.RegDelete, sh, key)
  end
  return pcall(sh.RegWrite, sh, key, value, type)
end

return registry