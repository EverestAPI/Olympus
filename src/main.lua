local debugmode = "" -- "debug" "profile" ""
local lldb
local profile

local utils
local sdlx

local ui
local uie
local main

local mousePresses = 0

function love.load(args)
    for i = 1, #args do
        local arg = args[i]

        if arg == "--debug" then
            debugmode = debugmode .. " debug"

        elseif arg == "--profile" then
            debugmode = debugmode .. " profile"
        end
    end

    if debugmode:match("debug") and os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
        lldb = require("lldebugger")
        lldb.start()
    end

    utils = require("utils")
    sdlx = require("sdlx")

    love.graphics.setBackgroundColor(0.06, 0.06, 0.06)
    love.graphics.setFont(love.graphics.newFont(16))

    ui = require("ui.main")
    uie = require("ui.elements.all")

    local root = uie.column({
        uie.titlebar({ uie.label("Everest.Olympus"):as("title") }):with({
            onDrag = function(self, x, y, dx, dy)
            end
        }),

        uie.group({
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

                    uie.button("Useless")

                })
            ):with({ x = 200, y = 50 }):as("test"),

        }):with({ clip = true }):as("main")
    }):with({ style = { padding = 0, spacing = 0 } }):as("root")
    ui.root = root
    main = root._main

    if debugmode:match("profile") then
        profile = require("profile")
    end

    sdlx.setWindowHitTest(function(win, area)
        if area.y <= root._titlebar.height then
            return 1 -- Draggable
        end

        return 0
    end)
end

love.frame = 0
function love.update()
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
            "hovering: " .. (ui.hovering and tostring(ui.hovering) or "-") .. "\n" ..
            "dragging: " .. (ui.dragging and tostring(ui.dragging) or "-") .. "\n" ..
            "focused: " .. (ui.focused and tostring(ui.focused) or "-")
    end

    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    
    root.width = width
    root.height = height

    main.width = width
    main.height = height - root._titlebar.height

    main._test._inner._info.text =
        "FPS: " .. love.timer.getFPS() .. "\n" ..
        "Delta: " .. love.timer.getDelta()

    ui.update()

    if profile then
        profile.stop()
    end
end

function love.draw()
    ui.draw()
end

function love.mousemoved(x, y, dx, dy, istouch)
    ui.mousemoved(x, y, dx, dy)
end

function love.mousepressed(x, y, button, istouch, presses)
    if mousePresses == 0 then
        sdlx.captureMouse(true)
    end
    mousePresses = mousePresses + presses
    ui.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button, istouch, presses)
    mousePresses = mousePresses - presses
    ui.mousereleased(x, y, button)
    if mousePresses == 0 then
        sdlx.captureMouse(false)
    end
end

function love.wheelmoved(x, y)
    ui.wheelmoved(x, y)
end
