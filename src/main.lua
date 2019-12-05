local lldb
local profile

local uiu
local utils
local threader
local native
local scener

local ui
local uie

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

        if arg == "--debug" and os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
            lldb = lldb or require("lldebugger")
            lldb.start()

        elseif arg == "--profile" then
            profile = profile or require("profile")
        end
    end

    love.graphics.setFont(love.graphics.newFont("data/fonts/Poppins-Regular.ttf", 14))

    uiu = require("ui.utils")
    utils = require("utils")
    threader = require("threader")

    love.version = table.pack(love.getVersion())
    love.versionStr = uiu.join(love.version, ".")
    print(love.versionStr)

    native = require("native")

    ui = require("ui")
    uie = require("ui.elements")

    scener = require("scener")

    local root = uie.column({
        require("background")(),

        uie.titlebar(uie.image("titlebar"), true):with({
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

            uie.label():with({
                style = {
                    color = { 0, 0, 0, 0 }
                }
            }):as("debug"),

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

    ui.init(root, false)
    ui.hookLove(false, true)

    if native then
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

        local windowStatus = native.prepareWindow()
        --[[
        if windowStatus.transparent then
            love.graphics.setBackgroundColor(0.06, 0.06, 0.06, 0.87)
        else
            love.graphics.setBackgroundColor(0.06, 0.06, 0.06, 1)
        end
        --]]
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

    scener.set(require("scenes/modlist"))
end

love.frame = 0
function love.update(dt)
    if not love.graphics then
        return
    end

    threader.update()

    love.frame = love.frame + 1

    --[[
    if profile then
        if love.frame % 100 == 0 then
            main._debug.text = profile.report(10)
            profile.reset()
        end

        profile.start()
    else
        main._debug.text =
            "FPS: " .. love.timer.getFPS() .. "\n" ..
            "hovering: " .. tostring(ui.hovering) .. "\n" ..
            "dragging: " .. tostring(ui.dragging) .. "\n" ..
            "focusing: " .. tostring(ui.focusing) .. "\n" ..
            ""--"mouseing: " .. mouseX .. ", " .. mouseY .. ": " .. tostring(mouseState)
    end
    --]]

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
end
