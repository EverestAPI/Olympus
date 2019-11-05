local ffi = require("ffi")
local sdl = ffi.os == "Windows" and ffi.load("SDL2") or ffi.C

ffi.cdef[[
	int SDL_GetGlobalMouseState(int *x, int *y);
]]

local sdlext = {}

function sdlext.getGlobalMouseState()
	local x = ffi.new("int[1]", 0)
	local y = ffi.new("int[1]", 0)
	local state = sdl.SDL_GetGlobalMouseState(x, y)
	return x[0], y[0], state
end

return sdlext
