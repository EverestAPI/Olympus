-- luacom.dll loads luacom5.lua in the cwd.
-- When running love src/, src is the cwd.
return assert(loadfile("../lib-windows/luacom5.lua"))(...)
