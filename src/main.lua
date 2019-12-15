require("love_filesystem_unsandboxing")

local debugging
local debuggingSharp
local lldb
local profile

local uiu
local utils
local threader
local native
local scener
local config
local sharp

local ui
local uie

local debugLabel

-- Needed to avoid running the same frame twice on resize
-- and to avoid Löve2D's default sleep throttle.
local _love_timer = love.timer
local _love_graphics = love.graphics
local _love_run = love.run
local _love_runStep
function love.run()
    local orig = _love_run()

    local function step()
        love.timer = _love_timer
        love.graphics = _love_graphics
        local rv = orig()
        love.timer = _love_timer
        love.graphics = _love_graphics
        return rv
    end

    _love_runStep = step
    return step
end

function love.load(args)
    for i = 1, #args do
        local arg = args[i]

        if arg == "--debug" then
            debugging = true
            if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" and not lldb then
                lldb = require("lldebugger")
                lldb.start()
            end

        elseif arg == "--debug-sharp" then
            debuggingSharp = true

        elseif arg == "--profile" then
            profile = profile or require("profile")
        end
    end

    love.graphics.setFont(love.graphics.newFont("data/fonts/Poppins-Regular.ttf", 14))

    utils = require("utils")
    threader = require("threader")

    love.version = {love.getVersion()}
    love.versionStr = table.concat(love.version, ".")
    print(love.versionStr)

    native = require("native")

    ui = require("ui")
    uie = require("ui.elements")
    uiu = require("ui.utils")

    scener = require("scener")

    config = require("config")

    sharp = require("sharp")
    sharp.init(debugging, debuggingSharp)

    local root = uie.column({
        require("background")(),

        os.getenv("OLYMPUS_TITLEBAR") == "1" and uie.titlebar(uie.image("titlebar"), true):with({
            style = {
                focusedBG = { 0.4, 0.4, 0.4, 0.05 },
                unfocusedBG = { 0.2, 0.2, 0.2, 0.1 }
            },
            onDrag = uiu.nop,
            root = true
        }):with(function(bar)
            bar._close:with({
                cb = love.event.quit,
                height = 7
            })
        end):as("titlebar"),

        uie.group({
            uie.group({

                -- Filled dynamically.

            }):with({
                style = {
                    padding = 0,
                    bg = {}
                },

                cacheable = false,
                clip = false,
            }):with(uiu.fill):as("wrapper"),

            uie.panel({
                uie.label():with({
                    style = {
                        color = { 0, 0, 0, 1 }
                    }
                }):as("debug"),
            }):with({
                interactive = -1,
                style = {
                    bg = { 1, 1, 1, 0.5 }
                },
                visible = true
            }):with(uiu.bottombound)

        }):with({
            style = {
                bg = { bg = {} },
                padding = 0,
                spacing = 0,
                radius = 0
            },
            clip = false,
            cacheable = false
        }):with(uiu.fillWidth):with(uiu.fillHeight(true)):as("main")
    }):with({
        style = {
            bg = { bg = {} },
            padding = 0,
            spacing = 0,
            radius = 0
        },
        clip = false,
        cacheable = false
    })

    debugLabel = root:findChild("debug")

    ui.init(root, false)
    ui.hookLove(false, true)

    if native then
        if love.system.getOS() == "Windows" then
            -- Shamelessly based off of how FNA force-repaints the window on resize.
            native.setEventFilter(function(userdata, event)
                if event[0].type == 0x200 then -- SDL_WINDOWEVENT
                    if event[0].window.event == 3 then -- SDL_WINDOWEVENT_EXPOSED
                        _love_runStep()
                        love.graphics = nil -- Don't redraw, we've already redrawn.
                        return 0
                    end
                end
                return 1
            end)
        end

        if root._titlebar then
            native.setWindowHitTest(function(win, area)
                local border = 8
                local corner = 12

                local x = area.x
                local y = area.y

                if root._titlebar._close:contains(x, y) then
                    return 0
                end

                local w, h, flags = love.window.getMode()

                if flags.resizable then
                    if y < border then
                        if x < border then
                            return 2
                        end
                        if w - corner <= x then
                            return 4
                        end
                        return 3
                    end

                    if h - border <= y then
                        if x < border then
                            return 8
                        end
                        if w - corner < x then
                            return 6
                        end
                        return 7
                    end

                    if x < border then
                        return 9
                    end

                    if w - border <= x then
                        return 5
                    end
                end

                if y < root._titlebar.height then
                    return 1
                end

                return 0
            end)

            native.prepareWindow()
        end
    end

    love.graphics.setBackgroundColor(0.06, 0.06, 0.06, 1)

    local wrapper = root:findChild("wrapper")
    function scener.onChange(prev, next)
        wrapper.children = {
            next.root:with({
                style = {
                    bg = {},
                    padding = 16
                },

                cacheable = false,
                clip = false,
            }):with(uiu.fill)
        }

        wrapper:reflow()
        ui.root:recollect()
    end

    scener.set(require("scenes/installmanager"))
end

love.frame = 0
function love.update(dt)
    if not love.graphics then
        return
    end

    threader.update()

    love.frame = love.frame + 1

    if profile then
        profile.frame = (profile.frame or 0) + 1
        if profile.frame % 400 == 0 then
            debugLabel.text =
                "FPS: " .. love.timer.getFPS() ..
                profile.report(20)
            profile.reset()
        end

        profile.start()
    else
        debugLabel.text =
            "FPS: " .. love.timer.getFPS() .. "\n" ..
            "hovering: " .. tostring(ui.hovering) .. "\n" ..
            "dragging: " .. tostring(ui.dragging) .. "\n" ..
            "focusing: " .. tostring(ui.focusing) .. "\n" ..
            ""--"mouseing: " .. mouseX .. ", " .. mouseY .. ": " .. tostring(mouseState)
    end

    ui.update()

    if profile then
        profile.stop()
    end
end

function love.draw()
    if love.frame == 0 then
        return
    end

    -- love.graphics.setScissor(0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    ui.draw()

    -- love.graphics.setScissor()

    if love.version[1] ~= 0 then
        love.timer = nil
    end
end

function love.keypressed(key, scancode, isrepeat)
    if key == "escape" then
        love.event.quit()
    end

    if key == "f12" then
        if love.keyboard.isDown("lshift") then
            debug.debug()

        elseif os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
            if not lldb then
                lldb = require("lldebugger")
                lldb.start()
            else
                lldb.stop()
                lldb = nil
            end
        end
    end

    if key == "f1" then
        debugLabel.parent.visible = not debugLabel.parent.visible
    end

    if key == "f2" then
        if not profile then
            debugLabel.parent.visible = true
            debugLabel.text = "Profiling..."
            profile = require("profile")
            profile.reset()
        else
            profile = nil
        end
    end
end
