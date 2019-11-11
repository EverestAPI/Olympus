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
        uie.group({
            uie.image("background"):as("bg"):run(function(bg)
                local transform = love.math.newTransform()
                transform:scale(10, 10)
                bg.transform = transform
            end)
        }):with({
            width = 0,
            height = 0,
            clip = false,
            cacheable = false
        }),

        uie.titlebar("Everest.Olympus", true):with({
            style = { focusedBG = { 0.4, 0.4, 0.4, 0.25 }, unfocusedBG = { 0.2, 0.2, 0.2, 0.3 } }, onDrag = utils.nop
        }),

        uie.group({
            uie.column({
                uie.image("header"),

                uie.label("Step 1: Select Celeste.exe"),
                uie.row({
                    uie.label("<TODO: TEXT INPUT>"),
                    uie.button("...")
                }):with({ style = { padding = 0, bg = {} }}),
                uie.label("Celeste <version> + Everest <version>"),

                uie.label("Step 2: Select Everest Version"),
                uie.scrollbox(
                    uie.list(
                        utils.map(utils.listRange(100, 1, -1), function(i)
                            return { text = string.format("%i%s", i, i % 7 == 0 and " (stable)" or ""), data = i }
                        end)
                    )
                ):with({
                    height = 300,
                    layoutLazy = function(self)
                        -- Required to allow the container to shrink again.
                        uie.__scrollbox.layoutLazy(self)
                        self.width = 0
                    end,
                
                    layoutLateLazy = function(self)
                        -- Always reflow this child whenever its parent gets reflowed.
                        self:layoutLate()
                    end,
                
                    layoutLate = function(self)
                        local width = self.parent.innerWidth
                        self.width = width
                        self.innerWidth = width - self.style.padding * 2
                        uie.__row.layoutLate(self)
                    end,
                }),

                uie.row({
                    uie.button("Step 3: Install"),
                    uie.button("Uninstall"),
                    uie.button("???", utils.magic(print, "pressed"))
                }):with({ style = { padding = 0, bg = {} }})

            }):with({
                style = {
                    padding = 32,
                    bg = {}
                },

                clip = false,

                layoutLazy = function(self)
                    -- Required to allow the container to shrink again.
                    uie.__scrollbox.layoutLazy(self)
                    self.width = 0
                end,
            
                layoutLateLazy = function(self)
                    -- Always reflow this child whenever its parent gets reflowed.
                    self:layoutLate()
                end,
            
                layoutLate = function(self)
                    local width = self.parent.innerWidth
                    self.width = width
                    self.innerWidth = width - self.style.padding * 2
                    uie.__row.layoutLate(self)
                end,
            }):as("installer"),

            uie.label():as("debug"),

            --[[
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
            --]]

        }):with({ clip = true }):as("main")
    }):with({ style = { bg = { 0, 0, 0, 0 }, padding = 0, spacing = 0, radius = 0 } }):as("root")
    ui.root = root
    main = root._main

    function root._titlebar._close:cb()
        love.event.quit()
    end

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
    ]]--
    love.graphics.setBackgroundColor(0.06, 0.06, 0.06, 1)
end

love.frame = 0
function love.update(dt)
    if not love.graphics then
        return
    end

    love.frame = love.frame + 1
    
    local root = ui.root
    local main = main

    local mouseX, mouseY = love.mouse.getPosition()

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
            "mouseing: " .. mouseX .. ", " .. mouseY .. ": " .. tostring(love.mouse.isDown(1))
    end

    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()

    root.focused = love.window.hasFocus()
    
    if main.width ~= width or main.height ~= height - root._titlebar.height then
        root.width = width
        root.height = height

        main.width = width
        main.height = height - root._titlebar.height

        root._titlebar:reflow()
        main:reflow()
        main._installer:reflow()
    end
    
    if main._test then
        main._test.text =
            "FPS: " .. love.timer.getFPS() .. "\n" ..
            "Mouse: " .. mouseX .. ", " .. mouseY .. ": " .. tostring(love.mouse.isDown(1))
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

    ui.draw()

    love.timer = nil
end

function love.keypressed(key, scancode, isrepeat)
    if key == "escape" then
        love.event.quit()
    end
end

function love.mousemoved(x, y, dx, dy, istouch)
    ui.mousemoving = false
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
