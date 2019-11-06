local ffi = require("ffi")
local bit = require("bit")

local sdl
local dwm
local sys = ffi.C
if ffi.os == "Windows" then
	sdl = ffi.load("SDL2")
	dwm = ffi.load("dwmapi")

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

		int DwmIsCompositionEnabled(bool* enabled);

		typedef enum {
			DWMWA_NCRENDERING_ENABLED = 1,
			DWMWA_NCRENDERING_POLICY,
			DWMWA_TRANSITIONS_FORCEDISABLED,
			DWMWA_ALLOW_NCPAINT,
			DWMWA_CAPTION_BUTTON_BOUNDS,
			DWMWA_NONCLIENT_RTL_LAYOUT,
			DWMWA_FORCE_ICONIC_REPRESENTATION,
			DWMWA_FLIP3D_POLICY,
			DWMWA_EXTENDED_FRAME_BOUNDS,
			DWMWA_HAS_ICONIC_BITMAP,
			DWMWA_DISALLOW_PEEK,
			DWMWA_EXCLUDED_FROM_PEEK,
			DWMWA_CLOAK,
			DWMWA_CLOAKED,
			DWMWA_FREEZE_REPRESENTATION,
			DWMWA_LAST
        } DWMWINDOWATTRIBUTE;
		int DwmSetWindowAttribute(void* hwnd, DWMWINDOWATTRIBUTE attr, void* attrData, int attrSize);

		typedef struct {
			int left;
			int right;
			int top;
			int bottom;
		} MARGINS;
		int DwmExtendFrameIntoClientArea(void* hwnd, MARGINS* margins);

		typedef struct {
			unsigned long flags;
			bool enable;
			void* rgnBlur;
			bool transitionOnMaximized;
		} DWM_BLURBEHIND;
		int DwmEnableBlurBehindWindow(void* hwnd, DWM_BLURBEHIND* margins);
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
	local status = {
		transparent = false
	}

	local sdlWindow = native.getCurrentWindow()
	local sdlWMinfo = ffi.new("SDL_SysWMinfo[1]")
	sdl.SDL_GetWindowWMInfo(sdlWindow, sdlWMinfo)

	if ffi.os == "Windows" then
		local hwnd = sdlWMinfo[0].info.win.window

		local dwmEnabled = ffi.new("bool[1]")
		dwm.DwmIsCompositionEnabled(dwmEnabled)
		if dwmEnabled[0] then
			local verP = io.popen("ver")
			local ver = verP:read("*a")
			verP:close()
			ver = tonumber(ver:sub(ver:find("%[Version ") + 9, ver:find("%.") - 1))

			if ver ~= 2000 and ver >= 10 then
				-- Windows 10+
				status.transparent = true

				local attrData = ffi.new("WINCOMPATTRDATA[1]")
				local accentPolicy = ffi.new("ACCENTPOLICY[1]")
		
				attrData[0].attribute = 19 -- WCA_ACCENT_POLICY
				attrData[0].data = accentPolicy
				attrData[0].dataSize = ffi.sizeof("ACCENTPOLICY")
		
				accentPolicy[0].accentState = 3 -- ACCENT_ENABLE_BLURBEHIND = 3, ACCENT_ENABLE_ACRYLICBLURBEHIND = 4
				accentPolicy[0].flags = bit.bor(0x20, 0x40, 0x80, 0x100) -- Window border behavior
				accentPolicy[0].color = 0xFFFFFFFF
		
				sys.SetWindowCompositionAttribute(hwnd, attrData)

			else
				-- Windows Vista+
				status.transparent = ver ~= 8

				local ncRenderingPolicy = ffi.new("int[1]", 2)
				dwm.DwmSetWindowAttribute(hwnd, 2, ncRenderingPolicy, ffi.sizeof("int"))

				local margins = ffi.new("MARGINS[1]")
				margins[0].left = -1
				margins[0].right = -1
				margins[0].top = -1
				margins[0].bottom = -1
				dwm.DwmExtendFrameIntoClientArea(hwnd, margins)

				local blurbehind = ffi.new("DWM_BLURBEHIND[1]")
				blurbehind[0].flags = 0x01
				blurbehind[0].enable = true
				dwm.DwmEnableBlurBehindWindow(hwnd, blurbehind)

			end
		end
	end

	return status
end

return native
