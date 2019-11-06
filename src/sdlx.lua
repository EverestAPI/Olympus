local ffi = require("ffi")
local sdl = ffi.os == "Windows" and ffi.load("SDL2") or ffi.C

ffi.cdef[[
	typedef struct SDL_Window SDL_Window;

	SDL_Window* SDL_GL_GetCurrentWindow();

	typedef struct {
		int x;
		int y;
	} SDL_Point;

	int SDL_CaptureMouse(bool enabled);

	int SDL_GetGlobalMouseState(int* x, int* y);

	typedef enum {
		SDL_HITTEST_NORMAL,
		SDL_HITTEST_DRAGGABLE,
		SDL_HITTEST_RESIZE_TOPLEFT,
		SDL_HITTEST_RESIZE_TOP,
		SDL_HITTEST_RESIZE_TOPRIGHT,
		SDL_HITTEST_RESIZE_RIGHT,
		SDL_HITTEST_RESIZE_BOTTOMRIGHT,
		SDL_HITTEST_RESIZE_BOTTOM,
		SDL_HITTEST_RESIZE_BOTTOMLEFT,
		SDL_HITTEST_RESIZE_LEFT
	} SDL_HitTestResult;
	typedef SDL_HitTestResult (*SDL_HitTest)(SDL_Window* win, const SDL_Point* area, void* data);
	int SDL_SetWindowHitTest(SDL_Window* window, SDL_HitTest callback, void* callback_data);
]]

local sdlx = {}

sdlx.sdl = sdl

function sdlx.getCurrentWindow()
	return sdl.SDL_GL_GetCurrentWindow()
end

function sdlx.captureMouse(value)
	return sdl.SDL_CaptureMouse(value)
end

function sdlx.getGlobalMouseState()
	local x = ffi.new("int[1]", 0)
	local y = ffi.new("int[1]", 0)
	local state = sdl.SDL_GetGlobalMouseState(x, y)
	return x[0], y[0], state
end

local _windowHitTestCB = nil
function sdlx.setWindowHitTest(callback)
	local window = sdlx.getCurrentWindow()

	local cb = _windowHitTestCB
	if cb ~= nil then
		cb:free()
	end
	cb = nil

	if callback ~= nil then
		cb = ffi.cast("SDL_HitTest", function(win, area, data)
			return callback(win, area)
		end)
	end

	sdl.SDL_SetWindowHitTest(window, cb, nil)

	_windowHitTestCB = cb
end

return sdlx
