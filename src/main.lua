local debugmode = "" -- "debug" "profile" ""

local lldb
local profile

local ui
local uie
local root

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

    love.graphics.setBackgroundColor(0.05, 0.05, 0.05)

    love.graphics.setFont(love.graphics.newFont(16))

    ui = require("ui.main")
    uie = require("ui.elements.all")

    root = uie.group({
        uie.window("Debug", uie.column({
            uie.label():as("info")
        })):with({ x = 16, y = 16 }):as("debug"),

        uie.window("Hello, World!", uie.column({
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

        })):with({ x = 32, y = 64 }):as("main"),

    }):as("root")
    ui.root = root

    if debugmode:match("profile") then
        profile = require("profile")
        root._debug.y = 290
    end
end

love.frame = 0
function love.update()
    love.frame = love.frame + 1

    if profile then
        if love.frame % 100 == 0 then
            root._debug._inner._info.text = profile.report(10)
            profile.reset()
        end

        profile.start()
    else
        root._debug._inner._info.text =
            "FPS: " .. love.timer.getFPS() .. "\n" ..
            "hovering: " .. (ui.hovering and tostring(ui.hovering) or "-") .. "\n" ..
            "dragging: " .. (ui.dragging and tostring(ui.dragging) or "-") .. "\n" ..
            "focused: " .. (ui.focused and tostring(ui.focused) or "-")
    end

    root._main._inner._info.text =
        "FPS: " .. love.timer.getFPS() .. "\n" ..
        "Delta: " .. love.timer.getDelta().. "\n" ..
        "test: " .. tostring((0 and true) or false)

    root.fixWidth = love.graphics.getWidth()
    root.fixHeight = love.graphics.getHeight()

    ui.update()

    if profile then
        profile.stop()
    end
end

function love.draw()
    ui.draw()
end

function love.mousemoved(x, y, dx, dy, istouch)
    ui.mousemoved(x, y, dx, dy, istouch)
end

function love.mousepressed(x, y, button, istouch, presses)
    ui.mousepressed(x, y, button, istouch)
end

function love.mousereleased(x, y, button, istouch, presses)
    ui.mousereleased(x, y, button, istouch)
end
