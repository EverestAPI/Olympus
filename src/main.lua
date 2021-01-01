local debugging
local debuggingSharp
local lldb
local profile

local uiu
local utils
local threader
local native
local scener
local alert
local notify
local config
local themer
local sharp
local fs

local logChannel
local logFile

local ui
local uie

local debugLabel
local logWindow
local logList


local function logDump()
    while true do
        local logLine = logChannel:pop()
        if not logLine then
            break
        end
        if logFile then
            logFile:write(logLine, "\n")
        end
        if logList and not lldb then
            if logList.children[100] then
                table.remove(logList.children, 1)
            end
            logList:addChild(uie.label(logLine))
        end
    end
end


local function askExit()
    alert({
        body = [[
Do you want to close Olympus?]],
        buttons = {
            {
                "Yes",
                function()
                    love.event.quit()
                end
            },
            { "No" }
        }
    })
end

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

local _love_errhand = love.errhand
function love.errhand(...)
    _love_runStep = nil
    logList = nil
    print("ERROR")
    print(...)
    logDump()
    return _love_errhand(...)
end

function love.load(args)
    local userOS = love.system.getOS()

    local protocol

    for i = 1, #args do
        local arg = args[i]

        if arg == "--debug" then
            debugging = true
            if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" and not lldb then
                lldb = require("lldebugger")
                if os.getenv("OLYMPUS_DEBUG") ~= "1" then
                    lldb.start()
                    local ffi = require("ffix")
                end
            end

        elseif arg == "--debug-sharp" then
            debuggingSharp = true

        elseif arg == "--profile" then
            profile = profile or require("profile")

        elseif arg == "--repl" then
            debug.debug()
            love.event.quit()

        else
            arg = arg:match("^[Ee]verest:(.*)")
            if arg then
                -- love.window.showMessageBox("Olympus Debug", "huh, neat.\n" .. require("fs").getcwd() .. "\n" .. protocol)
                protocol = arg
            end
        end
    end

    utils = require("utils")
    threader = require("threader")

    fs = require("fs")

    logChannel = love.thread.getChannel("olympusLog")
    logFile = io.open(fs.joinpath(fs.getStorageDir(), "log.txt"), "w+")

    love.version = {love.getVersion()}
    love.versionStr = table.concat(love.version, ".")
    print("love2d version", love.versionStr)

    require("spiker")(os.getenv("OLYMPUS_SPIKER") == "1")

    native = require("native")

    if native then
        love.versionSDL = native.getSDLVersion()
        love.versionSDLStr = table.concat(love.versionSDL, ".")
        print("SDL2 version", love.versionSDLStr)
    end

    print("Olympus version", utils.trim(utils.load("version.txt") or "?"))

    ui = require("ui")
    uie = require("ui.elements")
    uiu = require("ui.utils")

    love.graphics.setFont(love.graphics.newFont("data/fonts/Poppins-Regular.ttf", 14))
    ui.fontDebug = love.graphics.newFont("data/fonts/Perfect DOS VGA 437.ttf", 8)
    ui.fontMono = love.graphics.newFont("data/fonts/Perfect DOS VGA 437.ttf", 16)
    ui.fontBig = love.graphics.newFont("data/fonts/Renogare-Regular.otf", 28)

    scener = require("scener")
    alert = require("alert")
    notify = require("notify")
    themer = require("themer")

    config = require("config")
    config.load()

    themer.apply((config.theme == "default" or not config.theme) and themer.default or utils.loadJSON("data/themes/" .. config.theme .. ".json"))

    sharp = require("sharp")
    local sharpStatus, sharpError = pcall(sharp.init, debugging or debuggingSharp, debuggingSharp)
    if not sharpStatus then
        love.window.showMessageBox("Olympus.Sharp Startup Error", "Failed loading Olympus.Sharp: " .. tostring(sharpError), "error")
    else
        threader.routine(function()
            for i = 1, 4 do
                for j = 1, 10 do
                    sharp.echo("warmup " .. tostring(i) .. " " .. tostring(j)):result()
                end
                threader.sleep(0.2)
            end
        end)
    end

    local root = uie.column({
        require("background")(),

        config.csd and uie.titlebar(uie.image("titlebar"), true):with({
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
            uie.label(utils.load("version.txt") or "?"):with({
                style = {
                    color = { 1, 1, 1, 0.1 }
                }
            }):with(uiu.bottombound(4)):with(uiu.rightbound(4)),

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

            uie.group({
            }):with({
                clip = false,
                cacheable = false
            }):with(uiu.fill):as("alertroot"),

            uie.group({
            }):with({
                clip = false,
                cacheable = false
            }):with(uiu.fill):as("notifyroot"),



            uie.window("debug",
                uie.label("", ui.fontMono):with({
                    style = {
                        color = { 0.9, 0.9, 0.9, 1 }
                    },

                    interactive = 1,

                    onPress = function(self, ...)
                        self.parent.titlebar:onPress(...)
                    end,

                    onRelease = function(self, ...)
                        self.parent.titlebar:onRelease(...)
                    end,

                    onDrag = function(self, ...)
                        self.parent.titlebar:onDrag(...)
                    end
                }):as("debug")
            ):with({
                style = {
                    bg = { 0.02, 0.02, 0.02, 0.96 },
                    padding = 8
                },
                visible = profile ~= nil,
                interactive = profile ~= nil and 1 or -1
            }):with(function(el)
                table.remove(el.children, 1).parent = el
            end),

            uie.window("log",
                uie.column({

                    uie.scrollbox(
                        uie.column({}):with({
                            style = {
                                bg = {},
                                padding = 0
                            },
                            clip = false,
                            cacheable = false,

                            locked = true,

                            interactive = 2,

                            onPress = function(self, ...)
                                logWindow.titlebar:onPress(...)
                            end,

                            onRelease = function(self, ...)
                                logWindow.titlebar:onRelease(...)
                            end,

                            onDrag = function(self, ...)
                                logWindow.titlebar:onDrag(...)
                            end
                        }):hook({
                            layoutLateLazy = function(orig, self)
                                self:layoutLate()
                            end,

                            layoutLate = function(orig, self)
                                orig(self)
                                if self.locked then
                                    self.y = -self.height
                                end
                            end
                        }):as("log")
                    ):with(uiu.fillWidth):with(uiu.fillHeight(true)),

                    uie.row({
                        uie.button("Unlock scroll", function(self)
                            logList.locked = not logList.locked
                            self.label.text = logList.locked and "Unlock scroll" or "Lock scroll"
                            self.parent:reflowDown()
                        end),

                        uie.button("Open folder", function()
                            utils.openFile(fs.getStorageDir())
                        end),

                        uie.button("Clear", function()
                            logList.children = {}
                            logList:reflow()
                        end):with(uiu.fillWidth(true))
                    }):with({
                        style = {
                            bg = {},
                            padding = 0
                        },
                        clip = false
                    }):with(uiu.fillWidth):with(uiu.bottombound)

                }):with({
                    style = {
                        bg = {}
                    }
                }):with(uiu.fill)
            ):with({
                style = {
                    bg = { 0.02, 0.02, 0.02, 0.96 },
                    padding = 8
                },
                width = 800,
                height = 500,
                visible = false,
                interactive = -1
            }):with(function(el)
                table.remove(el.children, 1).parent = el
            end):as("logWindow")

        }):with({
            style = {
                bg = {},
                padding = 0,
                spacing = 0,
                radius = 0
            },
            clip = false,
            cacheable = false
        }):with(uiu.fillWidth):with(uiu.fillHeight(true)):with(uiu.at(0, 29)):as("main"),

        uie.topbar({}):as("pathbar"),
    }):with({
        style = {
            bg = {},
            padding = 0,
            spacing = 0,
            radius = 0
        },
        clip = false,
        cacheable = false
    })

    debugLabel = root:findChild("debug")
    logWindow = root:findChild("logWindow")
    logList = logWindow:findChild("log")

    ui.init(root, false)
    ui.hookLove(false, true)

    if native then
        native.setEventFilter(function(userdata, event)
            -- print(string.format("sdl event 0x%x", event[0].type))

            --[==[
            local caller = debug.getinfo(2, "Sn")
            local co = coroutine.running()
            if co ~= nil or caller.source ~= "=[C]" or caller.name ~= "pump" then
                print("SDL_EventFilter ran outside of event pump!")
                print("userdata:", tostring(userdata))
                print("event:", tostring(event))
                print("coroutine:", co)
                print(debug.traceback())
                return 1
            end
            ]==]

            -- Shamelessly based off of how FNA force-repaints the window on resize.
            if userOS == "Windows" and threader.unsafe == 0 and _love_runStep and event[0].type == 0x200 and event[0].window.event == 3 then -- SDL_WINDOWEVENT and SDL_WINDOWEVENT_EXPOSED
                pcall(_love_runStep)
                love.graphics = nil -- Don't redraw, we've already redrawn.
                return 0
            end

            return 1
        end)

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

    local pathbar = root:findChild("pathbar")
    local wrapper = root:findChild("wrapper")

    function scener.onChangeLock(locked)
        pathbar:reflow()
        for i = 1, #pathbar.children do
            pathbar.children[i].enabled = not locked
        end
    end

    function scener.onChange(prev, next)
        wrapper.children = {
            next.root:with({
                style = {
                    bg = {},
                    padding = next.root._fullroot and 0 or 16
                },

                cacheable = false,
                clip = false,
            }):with(uiu.fill)
        }

        wrapper:reflow()

        local items = {

            { "<<<",
                function()
                    if #scener.stack > 0 then
                        scener.pop()
                    else
                        askExit()
                    end
                end
            }

        }

        for i = 1, #scener.stack do
            items[i + 1] = { scener.stack[i].name, function()
                scener.pop(#scener.stack - i + 1)
            end }
        end

        items[#scener.stack + 2] = { next.name }

        pathbar.children = uiu.map(items, uie.menuItem.map)

        for i = 1, #pathbar.children do
            pathbar.children[i].enabled = not scener.locked
        end

        pathbar:reflow()

        ui.root:recollect()
    end

    alert.init(root:findChild("alertroot"))
    notify.init(root:findChild("notifyroot"))

    scener.set("mainmenu")
    require("updater").check()
    require("modinstaller").register()

    require("dragndrop")

    if protocol then
        require("modinstaller").install(protocol, function(task)
            if task then
                scener.set("installer")
                task:calls(function()
                    threader.routine(function()
                        threader.sleep(1)
                        love.event.quit()
                    end)
                end)
            else
                love.event.quit()
            end
        end)
    end

    if userOS == "OS X" and love.versionSDL and love.versionSDL.major == 2 and love.versionSDL.minor == 0 and love.versionSDL.patch < 12 then
        alert({
            body = [[
The Olympus app is out of date.
Sometimes, new features and huge fixes require updates
under the hood of Olympus, which it can't apply itself.

Most notably, the one-click installer buttons found on GameBanana
were broken on macOS. To fix this, you will need to reinstall Olympus.

Please go to the Everest website for further instructions.
Keeping Olympus outdated can cause crashes in the future.]],
            buttons = {
                { "Open Everest Website", function(container)
                    container:close("ok")
                    scener.set("installer")
                    utils.openURL("https://everestapi.github.io/"):calls(function()
                        threader.routine(function()
                            threader.sleep(1)
                            love.event.quit()
                        end)
                    end)
                end }
            }
        })
    end

    config.save()
end

love.frame = 0
function love.update(dt)
    if not love.graphics then
        return
    end

    logDump()

    love.frame = love.frame + 1

    if love.frame > 1 then
        if profile then
            profile.frame = (profile.frame or 0) + 1
            if profile.frame % 100 == 0 then
                debugLabel.text =
                    "FPS: " .. love.timer.getFPS() ..
                    profile.report(20)
                debugLabel.parent:reflow()
                profile.reset()
            end

            profile.start()

        else
            debugLabel.text =
                "FPS: " .. love.timer.getFPS() .. "\n" ..
                "hovering: " .. tostring(ui.hovering) .. "\n" ..
                "dragging: " .. tostring(ui.dragging) .. "\n" ..
                "focusing: " .. tostring(ui.focusing) .. "\n" ..
                "debug: " .. tostring(lldb ~= nil) .. "\n" ..
                "debugDraw: " .. tostring(ui.debug.draw) .. "\n" ..
                -- "mouseing: " .. mouseX .. ", " .. mouseY .. ": " .. tostring(mouseState) ..
                "\n" ..
                "storageDir: " .. fs.getStorageDir() .. "\n" ..
                "sharp: " .. sharp.getStatus() .. "\n" ..
                "threader: " .. tostring(threader.unsafe) .. "\n" ..
                ""
            debugLabel.parent:reflow()
        end
    end

    threader.update()

    ui.update()

    if profile then
        profile.stop()
    end

    local bg = uie.panel.__default.style.bg
    love.graphics.setBackgroundColor(bg[1] * 0.5, bg[2] * 0.5, bg[3] * 0.5, 1)

    if dt < (1 / 300) then
        if not love.window.isVisible() then
            love.timer.sleep(1 / 10)
        elseif not love.window.hasFocus() and not love.window.hasMouseFocus() then
            love.timer.sleep(1 / 50)
        end
    end
end

function love.draw()
    if love.frame == 0 then
        return
    end

    if profile then
        profile.start()
    end

    -- love.graphics.setScissor(0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    pcall(ui.draw)

    -- love.graphics.setScissor()

    if profile then
        profile.stop()
    end

    if love.version[1] ~= 0 then
        love.timer = nil
    end
end

function love.keypressed(key, scancode, isrepeat)
    if key == "escape" then
        if #alert.root.children > 0 then
            alert.root.children[#alert.root.children]:close(false)

        elseif not scener.locked then
            if #scener.stack > 0 then
                scener.pop()
            else
                askExit()
                -- love.event.quit()
            end
        end
    end

    if key == "f12" then
        if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
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
        debugLabel.parent.interactive = debugLabel.parent.visible and 1 or -1
        ui.root:recollect(false, true)
    end

    if key == "f2" then
        logWindow.visible = not logWindow.visible
        logWindow.interactive = logWindow.visible and 1 or -1
        ui.root:recollect(false, true)
    end

    if key == "f3" then
        if not profile then
            debugLabel.parent.visible = true
            debugLabel.parent.interactive = 1
            ui.root:recollect(false, true)
            debugLabel.text = "Profiling..."
            debugLabel.parent:reflow()
            profile = require("profile")
            profile.reset()
            profile.frame = 0
        else
            profile = nil
        end
    end

    if key == "f5" then
        themer.apply((config.theme == "default" or not config.theme) and themer.default or utils.loadJSON("data/themes/" .. config.theme .. ".json"))
    end

    if key == "f6" then
        scener.push("scenelist")
    end

    if key == "f10" then
        if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
            ui.globalReflowID = ui.globalReflowID + 1
        else

            ui.root:recollect()
        end
    end

    if key == "f11" then
        ui.globalReflowID = ui.globalReflowID + 1
        if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
            ui.debug.draw = (ui.debug.draw ~= -1) and -1 or true

        elseif love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") then
            ui.debug.draw = -2

        else
            ui.debug.draw = not ui.debug.draw
        end
    end
end
