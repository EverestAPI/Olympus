local ffiStatus, ffi = pcall(require, "ffi")
if not ffiStatus then
    return false
end

local sdl
local sys = ffi.C
if ffi.os == "Windows" then
    sdl = ffi.load("SDL2")

else
    sdl = sys
end

ffi.cdef[[
    typedef struct SDL_Window SDL_Window;
    SDL_Window* SDL_GL_GetCurrentWindow();
    void SDL_GetWindowPosition(SDL_Window* window, int* x, int* y);
    int SDL_CaptureMouse(bool enabled);
    int SDL_GetGlobalMouseState(int* x, int* y);
]]

local uin = {}

uin.ffi = ffi
uin.sdl = sdl
uin.sys = sys
uin.os = ffi.os

function uin.getCurrentWindow()
    return sdl.SDL_GL_GetCurrentWindow()
end

function uin.getWindowPosition()
    local window = uin.getCurrentWindow()
    local x = ffi.new("int[1]")
    local y = ffi.new("int[1]")
    sdl.SDL_GetWindowPosition(window, x, y)
    return x[0], y[0]
end

function uin.captureMouse(value)
    return sdl.SDL_CaptureMouse(value)
end

function uin.getGlobalMouseState()
    local x = ffi.new("int[1]")
    local y = ffi.new("int[1]")
    local state = sdl.SDL_GetGlobalMouseState(x, y)
    return x[0], y[0], state
end

return uin
