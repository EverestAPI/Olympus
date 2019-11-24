local lldb
local profile

local utils
local native

local ui
local uie
local moonshine

local main

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

    utils = require("ui.utils")

    love.version = table.pack(love.getVersion())
    love.versionStr = utils.join(love.version, ".")
    print(love.versionStr)

    native = require("native")

    ui = require("ui")
    uie = require("ui.elements")

    moonshine = require("moonshine")

    local root = uie.column({
        uie.new({
            id = "bg",
            width = 0,
            height = 0,
            cacheable = false,

            bg = utils.image("background"),

            cog = utils.image("cogwheel"),
            time = 8,

            effect = moonshine(moonshine.effects.gaussianblur),

            init = function(self)
                self.effect.gaussianblur.sigma = 5
            end,

            update = function(self)
                self.time = self.time + ui.delta

                local width, height = love.graphics.getWidth(), love.graphics.getHeight()
                if width ~= self.innerWidth or height ~= self.innerHeight then
                    self.effect.resize(width, height)
                    self.innerWidth = width
                    self.innerHeight = height
                end
                self:repaint()
            end,

            layoutLate = function(self)
                self.realX = 0
                self.realY = 0
            end,

            drawBG = function(self)
                local width, height = love.graphics.getWidth() + 4, love.graphics.getHeight() + 4
                local mouseX, mouseY = ui.mouseX - width / 2, ui.mouseY - height / 2
                local time = self.time

                local scale = math.max(width / 540, height / 700)
                scale = (scale - 1) * 0.25 + 1

                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(
                    self.bg,
                    width / 2 - mouseX * 0.02,
                    height / 2 - mouseY * 0.02,
                    0,
                    15 * scale, 15 * scale,
                    64, 36
                )

                love.graphics.setColor(0, 0, 0, 0.1)
                love.graphics.draw(
                    self.cog,
                    128 - mouseX * 0.04,
                    -32 - mouseY * 0.04,
                    time * 0.2,
                    2, 2,
                    128, 128
                )

                love.graphics.setColor(0.1, 0.1, 0.1, 0.15)
                love.graphics.draw(
                    self.cog,
                    width - 128 - mouseX * 0.06,
                    height + 32 - mouseY * 0.06,
                    time * 0.3,
                    3, 3,
                    128, 128
                )

                love.graphics.push()
                love.graphics.origin()
            end,

            draw = function(self)
                love.graphics.setColor(1, 1, 1, 1)
                self.effect(self.drawBG, self)
                love.graphics.pop()
            end
        }),

        uie.titlebar("Everest.Olympus", true):with({
            style = {
                focusedBG = { 0.4, 0.4, 0.4, 0.25 },
                unfocusedBG = { 0.2, 0.2, 0.2, 0.3 }
            },
            onDrag = utils.nop,
            root = true
        }):with(function(bar)
            bar._close:with({
                cb = love.event.quit,
                height = 7
            })
        end),

        uie.group({
            uie.column({
                uie.image("header"),

                uie.label("Step 1: Select Celeste.exe"),

                uie.row({
                    uie.field("<TODO: TEXT INPUT>"):with(utils.fillWidth(-1, true)),
                    uie.button("..."):with(utils.rightbound)
                }):with({
                    style = {
                        padding = 0,
                        bg = {}
                    }
                }):with(utils.fillWidth),

                uie.label("Celeste <version> + Everest <version>"),

                uie.label("Step 2: Select Everest Version"),
                uie.column({
                    uie.label(([[
Use the newest version for more features and bugfixes.
Use the latest "stable" version if you hate updating.]])),
                }):with({
                    style = {
                        bg = { 0.6, 0.5, 0.15, 0.6 },
                        radius = 3,
                    }
                }):with(utils.fillWidth),

                uie.scrollbox(
                    uie.list(
                        utils.map(utils.listRange(10, 1, -1), function(i)
                            return { text = string.format("%i%s", i, i % 7 == 0 and " (stable)" or ""), data = i }
                        end)
                    ):with(function(list)
                        list.selected = list.children[1]
                    end):as("versions")
                ):with(utils.fillWidth):with(utils.fillHeight(68, true)),

                uie.row({
                    uie.button("Step 3: Install"),
                    uie.button("Uninstall"),
                    uie.button("???", utils.magic(print, "pressed"))
                }):with({
                    style = {
                        padding = 0,
                        bg = {}
                    }
                }):with(utils.bottombound)

            }):with({
                style = {
                    padding = 16,
                    bg = {}
                },

                cacheable = false,
                clip = false,
            }):with(utils.fill):as("installer"),

            uie.label():with({
                style = {
                    color = { 0, 0, 0, 1 }
                }
            }):as("debug"),

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

        }):with({
            style = {
                bg = { bg = {} },
                padding = 0,
                spacing = 0,
                radius = 0
            },
            clip = false,
            cacheable = false
        }):with(utils.fillWidth):with(utils.fillHeight(true)):as("main")
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
    main = root._main

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
end

love.frame = 0
function love.update(dt)
    if not love.graphics then
        return
    end

    love.frame = love.frame + 1
    
    local root = ui.root._root
    local main = main

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
