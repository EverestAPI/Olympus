local sharp = require("sharp")

local registry = {}

function registry.getKeySharp(key)
  return sharp._run("Win32RegGet", key)
end
registry.getKey = registry.getKeySharp

function registry.setKeySharp(key, value)
  return sharp._run("Win32RegSet", key, value)
end
registry.setKey = registry.setKeySharp


-- Fuck LuaCOM. Besides the fact that it likes to not work at random, it also keeps love.exe alive.
--[[
local luacomStatus, luacom = pcall(require, "luacom")
if luacomStatus and luacom then
  function registry.getKey(key)
    local sh = luacom.CreateObject("WScript.Shell")
    if not sh then
      return registry.getKeySharp(key)
    end
    local status, rv = pcall(sh.RegRead, sh, key)
    if status then
      return rv
    else
      return nil
    end
  end

  function registry.setKey(key, value)
    local sh = luacom.CreateObject("WScript.Shell")
    if not sh then
      return registry.setKeySharp(key, value)
    end
    if value == nil then
      return pcall(sh.RegDelete, sh, key)
    end
    return pcall(sh.RegWrite, sh, key, value)
  end

end

]]

return registry
