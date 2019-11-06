local ffi = require("ffi")
local bit = require("bit")

local sdl
local sys = ffi.C
if ffi.os == "Windows" then
	sdl = ffi.load("SDL2")

else
	sdl = sys
end

ffi.cdef[[
	typedef struct {
		char major;
		char minor;
		char patch;
	} SDL_version;

	typedef struct {
		int x;
		int y;
	} SDL_Point;

	typedef struct SDL_Window SDL_Window;

	SDL_Window* SDL_GL_GetCurrentWindow();

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

	typedef enum {
		SDL_SYSWM_UNKNOWN,
		SDL_SYSWM_WINDOWS,
		SDL_SYSWM_X11,
		SDL_SYSWM_DIRECTFB,
		SDL_SYSWM_COCOA,
		SDL_SYSWM_UIKIT,
		SDL_SYSWM_WAYLAND,
		SDL_SYSWM_MIR,
		SDL_SYSWM_WINRT,
		SDL_SYSWM_ANDROID
	} SDL_SYSWM_TYPE;
	typedef struct {
		SDL_version version;
		SDL_SYSWM_TYPE subsystem;
		union {
			struct {
				void* window;
				void* hdc;
				void* hinstance;
			} win;
			char dummy[64];
		} info;
	} SDL_SysWMinfo;
	bool SDL_GetWindowWMInfo(SDL_Window* window, SDL_SysWMinfo* info);
]]

if ffi.os == "Windows" then
	ffi.cdef[[
		typedef struct {
			int accentState;
			int flags;
			int color;
			int animationId;
		} ACCENTPOLICY;
		typedef struct {
			int attribute;
			void* data;
			unsigned long dataSize;
		} WINCOMPATTRDATA;

		bool GetWindowCompositionAttribute(void* hwnd, WINCOMPATTRDATA* attrData);
		bool SetWindowCompositionAttribute(void* hwnd, WINCOMPATTRDATA* attrData);
	]]
end

local native = {}

native.ffi = ffi
native.sdl = sdl
native.sys = sys
native.os = ffi.os

function native.getCurrentWindow()
	return sdl.SDL_GL_GetCurrentWindow()
end

function native.captureMouse(value)
	return sdl.SDL_CaptureMouse(value)
end

function native.getGlobalMouseState()
	local x = ffi.new("int[1]")
	local y = ffi.new("int[1]")
	local state = sdl.SDL_GetGlobalMouseState(x, y)
	return x[0], y[0], state
end

local _windowHitTestCB = nil
function native.setWindowHitTest(callback)
	local window = native.getCurrentWindow()

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

function native.prepareWindow()
	local sdlWindow = native.getCurrentWindow()
	local sdlWMinfo = ffi.new("SDL_SysWMinfo[1]")
	sdl.SDL_GetWindowWMInfo(sdlWindow, sdlWMinfo)

	if ffi.os == "Windows" then
		local hwnd = sdlWMinfo[0].info.win.window

		local attrData = ffi.new("WINCOMPATTRDATA[1]")
		local accentPolicy = ffi.new("ACCENTPOLICY[1]")

		attrData[0].attribute = 19 -- WCA_ACCENT_POLICY
		attrData[0].data = accentPolicy
		attrData[0].dataSize = ffi.sizeof("ACCENTPOLICY")

		accentPolicy[0].accentState = 3 -- ACCENT_ENABLE_BLURBEHIND = 3, ACCENT_ENABLE_ACRYLICBLURBEHIND = 4
		accentPolicy[0].flags = bit.bor(0x20, 0x40, 0x80, 0x100) -- Window border behavior
		accentPolicy[0].color = 0xFFFFFFFF

		sys.SetWindowCompositionAttribute(hwnd, attrData)
	end
end

return native
