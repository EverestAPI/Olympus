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

return registry