local lldb
local profile

local utils
local native

local ui
local uie
local main

local mousePresses = 0

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

    utils = require("ui.utils")
    native = require("native")

    love.graphics.setFont(love.graphics.newFont(16))

    ui = require("ui.main")
    uie = require("ui.elements.all")

    local root = uie.column({
        uie.titlebar("Everest.Olympus"):with({
            style = { focusedBG = { 0.4, 0.4, 0.4, 0.25 }, unfocusedBG = { 0.2, 0.2, 0.2, 0.3 } }, onDrag = utils.nop
        }),

        uie.group({
            uie.image("header"),

            uie.window("Debug",
                uie.column({
                    uie.label():as("info")
                })
            ):with({ x = 10, y = 10 }):as("debug"),

            uie.window("Windowception",
                uie.scrollbox(
                    uie.group({
                        uie.window("Child 1", uie.column({ uie.label("Oh no") })):with({ x = 10, y = 10}),
                        uie.window("Child 2", uie.column({ uie.label("Oh no two") })):with({ x = 30, y = 30})
                    }):with({ width = 200, height = 400 })
                ):with({ width = 200, height = 200 })
            ):with({ x = 50, y = 100 }),

            uie.window("Hello, World!",
                uie.column({
                    uie.label("This is a one-line label."),
                    
                    -- Labels use Löve2D Text objects under the hood.
                    uie.label({ { 1, 1, 1 }, "This is a ", { 1, 0, 0 }, "colored", { 0, 1, 1 }, " label."}),

                    -- Multi-line labels aren't subjected to the parent element's spacing property.
                    uie.label("This is a two-line label.\nThe following label is updated dynamically."),

                    -- Dynamically updated label.
                    uie.label():as("info"),

                    uie.button("This is a button.", function(btn)
                        if btn.counter == nil then
                            btn.counter = 0
                        end
                        btn.counter = btn.counter + 1
                        btn.text = "Pressed " .. tostring(btn.counter) .. " time" .. (btn.counter == 1 and "" or "s")
                    end),

                    uie.button("Disabled"):with({ enabled = false }),

                    uie.button("Useless"),

                    uie.label("Select an item from the list below."):as("selected"),
                    uie.list(utils.map(utils.listRange(1, 3), function(i)
                        return { text = string.format("Item %i!", i), data = i }
                    end), function(list, item)
                        list.parent._selected.text = "Selected " .. tostring(item)
                    end)

                })
            ):with({ x = 200, y = 50 }):as("test"),

        }):with({ clip = true }):as("main")
    }):with({ style = { bg = { 0, 0, 0, 0 }, padding = 0, spacing = 0, radius = 0 } }):as("root")
    ui.root = root
    main = root._main

    native.setWindowHitTest(function(win, area)
        local border = 8
        local corner = 12

        local x = area.x
        local y = area.y

        local w, h = love.window.getMode()

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
    if windowStatus.transparent then
        love.graphics.setBackgroundColor(0.06, 0.06, 0.06, 0.87)
    else
        love.graphics.setBackgroundColor(0.06, 0.06, 0.06, 1)
    end
end

love.frame = 0
function love.update(dt)
    if not love.graphics then
        return
    end

    love.frame = love.frame + 1
    
    local root = ui.root
    local main = main

    if profile then
        if love.frame % 100 == 0 then
            main._debug._inner._info.text = profile.report(10)
            profile.reset()
        end

        profile.start()
    else
        main._debug._inner._info.text =
            "FPS: " .. love.timer.getFPS() .. "\n" ..
            "hovering: " .. tostring(ui.hovering) .. "\n" ..
            "dragging: " .. tostring(ui.dragging) .. "\n" ..
            "focusing: " .. tostring(ui.focusing)
    end

    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()

    root.focused = love.window.hasFocus()
    
    if root.width ~= width or root.height ~= height then
        root.width = width
        root.height = height

        main.width = width
        main.height = height - root._titlebar.height

        main:reflow()
    end
    
    local mouseX, mouseY = love.mouse.getPosition()
    main._test._inner._info.text =
        "FPS: " .. love.timer.getFPS() .. "\n" ..
        "Mouse: " .. mouseX .. ", " .. mouseY .. ": " .. tostring(love.mouse.isDown(1))

    ui.update()

    if profile then
        profile.stop()
    end
end

function love.draw()
    if love.frame == 0 then
        return
    end

    ui.draw()

    love.timer = nil
end

function love.keypressed(key, scancode, isrepeat)
    if key == "escape" then
        love.event.quit()
    end
end

function love.mousemoved(x, y, dx, dy, istouch)
    ui.mousemoved(x, y, dx, dy)
end

function love.mousepressed(x, y, button, istouch, presses)
    if mousePresses == 0 then
        native.captureMouse(true)
    end
    mousePresses = mousePresses + presses
    ui.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button, istouch, presses)
    mousePresses = mousePresses - presses
    ui.mousereleased(x, y, button)
    if mousePresses == 0 then
        native.captureMouse(false)
    end
end

function love.wheelmoved(x, y)
    ui.wheelmoved(x, y)
end
