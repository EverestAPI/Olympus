local luacomStatus, luacom = false, nil -- pcall(require, "luacom")
if luacomStatus and luacom then
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

  function registry.setKey(key, value)
    local sh = luacom.CreateObject("WScript.Shell")
    if value == nil then
      return pcall(sh.RegDelete, sh, key)
    end
    return pcall(sh.RegWrite, sh, key, value)
  end

  return registry
end

local sharp = require("sharp")

local registry = {}

function registry.getKey(key)
  return sharp._run("regWin32Get", key)
end

function registry.setKey(key, value)
  return sharp._run("regWin32Set", key, value)
end

return registry
