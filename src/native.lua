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
        SDL_FIRSTEVENT = 0,
        SDL_QUIT = 0x100,
        SDL_APP_TERMINATING,
        SDL_APP_LOWMEMORY,
        SDL_APP_WILLENTERBACKGROUND,
        SDL_APP_DIDENTERBACKGROUND,
        SDL_APP_WILLENTERFOREGROUND,
        SDL_APP_DIDENTERFOREGROUND,
        SDL_DISPLAYEVENT = 0x150,
        SDL_WINDOWEVENT = 0x200,
        SDL_SYSWMEVENT,
        SDL_KEYDOWN = 0x300,
        SDL_KEYUP,
        SDL_TEXTEDITING,
        SDL_TEXTINPUT,
        SDL_KEYMAPCHANGED,
        SDL_MOUSEMOTION = 0x400,
        SDL_MOUSEBUTTONDOWN,
        SDL_MOUSEBUTTONUP,
        SDL_MOUSEWHEEL,
        SDL_JOYAXISMOTION = 0x600,
        SDL_JOYBALLMOTION,
        SDL_JOYHATMOTION,
        SDL_JOYBUTTONDOWN,
        SDL_JOYBUTTONUP,
        SDL_JOYDEVICEADDED,
        SDL_JOYDEVICEREMOVED,
        SDL_CONTROLLERAXISMOTION = 0x650,
        SDL_CONTROLLERBUTTONDOWN,
        SDL_CONTROLLERBUTTONUP,
        SDL_CONTROLLERDEVICEADDED,
        SDL_CONTROLLERDEVICEREMOVED,
        SDL_CONTROLLERDEVICEREMAPPED,
        SDL_FINGERDOWN = 0x700,
        SDL_FINGERUP,
        SDL_FINGERMOTION,
        SDL_DOLLARGESTURE = 0x800,
        SDL_DOLLARRECORD,
        SDL_MULTIGESTURE,
        SDL_CLIPBOARDUPDATE = 0x900,
        SDL_DROPFILE = 0x1000,
        SDL_DROPTEXT,
        SDL_DROPBEGIN,
        SDL_DROPCOMPLETE,
        SDL_AUDIODEVICEADDED = 0x1100,
        SDL_AUDIODEVICEREMOVED,
        SDL_SENSORUPDATE = 0x1200,
        SDL_RENDER_TARGETS_RESET = 0x2000,
        SDL_RENDER_DEVICE_RESET,
        SDL_USEREVENT = 0x8000,
        SDL_LASTEVENT = 0xFFFF
    } SDL_EventType;
    typedef struct SDL_CommonEvent {
        unsigned int type;
        unsigned int timestamp;
    } SDL_CommonEvent;
    typedef struct SDL_WindowEvent {
        unsigned int type;
        unsigned int timestamp;
        unsigned int windowID;
        unsigned char event;
        unsigned char padding1;
        unsigned char padding2;
        unsigned char padding3;
        int data1;
        int data2;
    } SDL_WindowEvent;
    typedef union SDL_Event {
        unsigned int type;
        SDL_CommonEvent common;
        SDL_WindowEvent window;
        unsigned char padding[56];
    } SDL_Event;
    typedef int (*SDL_EventFilter)(void* userdata, SDL_Event* event);
    void SDL_SetEventFilter(SDL_EventFilter filter, void* userdata);

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

local _eventFilterCB = nil
function native.setEventFilter(callback)
    local cb = _eventFilterCB
    if cb ~= nil then
        cb:free()
    end
    cb = nil

    if callback ~= nil then
        cb = ffi.cast("SDL_EventFilter", function(data, event)
            return callback(data, event)
        end)
    end

    sdl.SDL_SetEventFilter(cb, nil)
    _eventFilterCB = cb
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
            local verS = verP:read("*a")
            verP:close()
            local verMajIndex = verS:find("%[Version ") + 8
            local verMinIndex = verS:find("%.", verMajIndex)
            local verMinEndIndex = verS:find("%.", verMinIndex + 1)
            local verMaj = tonumber(verS:sub(verMajIndex + 1, verMinIndex - 1))
            local verMin = tonumber(verS:sub(verMinIndex + 1, verMinEndIndex - 1))
            if verMaj == 2000 then
                verMaj = 5
            end

            if verMaj >= 10 and false then -- Dragging the window lags no matter the accentState on some machines.
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

            elseif verMaj >= 5 then
                -- Windows Vista+

                if verMaj >= 8 or (verMaj == 6 and verMin >= 2) then
                    -- Windows 8+ lacks Aero.
                    status.transparent = false
                else
                    status.transparent = true
                end

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
