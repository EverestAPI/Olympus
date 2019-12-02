local lldb
local profile

local uiu
local utils
local threader
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

    uiu = require("ui.utils")
    utils = require("utils")
    threader = require("threader")

    love.version = table.pack(love.getVersion())
    love.versionStr = uiu.join(love.version, ".")
    print(love.versionStr)

    native = require("native")

    ui = require("ui")
    uie = require("ui.elements")

    moonshine = require("moonshine")

    local bgs = {}
    for i, file in ipairs(love.filesystem.getDirectoryItems("data")) do
        local bg = file:match("^(bg%d+)%.png$")
        if bg then
            bgs[#bgs + 1] = bg
        end
    end

    local root = uie.column({
        uie.new({
            id = "bg",
            width = 0,
            height = 0,
            cacheable = false,

            bg = uiu.image(bgs[love.math.random(#bgs)]),

            cog = uiu.image("cogwheel"),
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
            uie.column({
                uie.image("header"),

                uie.row({

                    uie.column({
                        uie.label("Step 1: Select your installation"),

                        uie.column({

                            uie.scrollbox(
                                uie.list(
                                    {
                                        "Steam",
                                        "Epic",
                                        "Bingo",
                                        "Casual",
                                        "Custom",
                                    }
                                ):with({
                                    grow = false
                                }):with(uiu.fillWidth):with(function(list)
                                    list.selected = list.children[1]
                                end):as("installs")
                            ):with(uiu.fillWidth):with(uiu.fillHeight),

                            uie.button("Manage"):with({
                                clip = false,
                                cacheable = false
                            }):with(uiu.bottombound):with(uiu.rightbound):as("loadingInstalls")

                        }):with({
                            style = {
                                padding = 0,
                                bg = {}
                            }
                        }):with(uiu.fillWidth):with(uiu.fillHeight(true))
                    }):with(uiu.fillHeight),

                    uie.column({
                        uie.label("Step 2: Select version"),
                        uie.column({
                            uie.label(({{ 1, 1, 1, 1 }, [[
Use the newest version for more features and bugfixes.
Use the latest ]], { 0.3, 0.8, 0.5, 1 }, "stable", { 1, 1, 1, 1 }, [[ version if you hate updating.]]})),
                        }):with({
                            style = {
                                bg = {},
                                border = { 0.1, 0.6, 0.3, 0.7 },
                                radius = 3,
                            }
                        }):with(uiu.fillWidth),

                        uie.column({

                            uie.scrollbox(
                                uie.list({
                                }):with({
                                    grow = false
                                }):with(uiu.fillWidth):with(function(list)
                                    list.selected = list.children[1]
                                end):as("versions")
                            ):with(uiu.fillWidth):with(uiu.fillHeight),

                            uie.row({
                                uie.label("Loading"),
                                uie.spinner():with({
                                    width = 16,
                                    height = 16
                                })
                            }):with({
                                clip = false,
                                cacheable = false
                            }):with(uiu.bottombound):with(uiu.rightbound):as("loadingVersions")

                        }):with({
                            style = {
                                padding = 0,
                                bg = {}
                            }
                        }):with(uiu.fillWidth):with(uiu.fillHeight(true))
                    }):with(uiu.fillWidth(-1, true)):with(uiu.fillHeight),

                }):with({
                    style = {
                        padding = 0,
                        bg = {}
                    }
                }):with(uiu.fillWidth):with(uiu.fillHeight(16, true)),

                uie.row({
                    uie.button("Step 3: Install"),
                    uie.button("Uninstall"),
                    uie.button("???", uiu.magic(print, "pressed")),
                }):with({
                    style = {
                        padding = 0,
                        bg = {}
                    }
                }):with(uiu.bottombound)

            }):with({
                style = {
                    padding = 16,
                    bg = {}
                },

                cacheable = false,
                clip = false,
            }):with(uiu.fill):as("installer"),

            uie.label():with({
                style = {
                    color = { 0, 0, 0, 0 }
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
                    uie.label():with({
                        update = function(el)
                            el.text = "FPS: " .. love.timer.getFPS()
                        end
                    }),

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

    threader.routine(function()
        local utilsAsync = threader.wrap("utils")
        local builds = utilsAsync.downloadJSON("https://dev.azure.com/EverestAPI/Everest/_apis/build/builds"):result().value
        -- TODO: Limit commits range
        local commits = utilsAsync.downloadJSON("https://api.github.com/repos/EverestAPI/Everest/commits"):result()

        local offset = 700
        local list = main:findChild("versions")
        for bi = 1, #builds do
            local build = builds[bi]

            if (build.status == "completed" or build.status == "succeeded") and (build.reason == "manual" or build.reason == "individualCI") then
                local text = tostring(build.id + offset)

                local branch = build.sourceBranch:gsub("refs/heads/", "")
                if branch ~= "master" then
                    text = text .. " (" .. branch .. ")"
                end

                local info = ""

                local time = build.finishTime
                if time then
                    info = info .. " built at " .. os.date("%Y-%m-%d %H:%M:%S", utils.dateToTimestamp(time))
                end

                local sha = build.sourceVersion
                if sha and commits then
                    for ci = 1, #commits do
                        local c = commits[ci]
                        if c.sha == sha then
                            if c.commit.author.email == c.commit.committer.email then
                                info = info .. " by " .. c.author.login
                            end

                            local message = c.commit.message
                            local nl = message:find("\n")
                            if nl then
                                message = message:sub(1, nl - 1)
                            end

                            info = info .. "\n" .. message

                            break
                        end
                    end
                end

                if #info ~= 0 then
                    text = { { 1, 1, 1, 1 }, text, { 1, 1, 1, 0.5 }, info }
                end

                local item = uie.listItem(text, build)
                if branch == "stable" then
                    item.style.normalBG = { 0.08, 0.2, 0.12, 0.6 }
                    item.style.hoveredBG = { 0.36, 0.46, 0.39, 0.7 }
                    item.style.pressedBG = { 0.1, 0.5, 0.2, 0.7 }
                    item.style.selectedBG = { 0.1, 0.6, 0.3, 0.7 }
                end
                list:addChild(item)
            end
        end

        main:findChild("loadingVersions"):removeSelf()
    end)

end

love.frame = 0
function love.update(dt)
    if not love.graphics then
        return
    end

    threader.update()

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
