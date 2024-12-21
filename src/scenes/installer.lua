local ui, uiu, uie = require("ui").quick()
local fs = require("fs")
local utils = require("utils")
local threader = require("threader")
local scener = require("scener")
local config = require("config")
local sharp = require("sharp")
local native = require("native")
local shaper = require("shaper")
local alert = require("alert")

local scene = {
    name = "Installer"
}


local root = uie.group({

    uie.new({
        cacheable = false,

        update = function(self, dt)
            dt = math.min(0.1, dt)

            local tf = 0.5

            if scene.shapeNext ~= nil then
                -- Catch up to next shape.
                if scene.progress then
                    scene.time = scene.progress * 0.5
                    scene.progress = false
                end
                tf = 2
            end

            scene.timeReal = scene.timeReal + dt

            if scene.shapeNext == nil and scene.progressNext ~= nil then
                if scene.progress and scene.progressNext then
                    -- progress -> progress on same shape
                    scene.progress = scene.progressNext
                    scene.progressNext = nil
                    scene.time = scene.time + dt * tf

                elseif scene.progressNext then
                    -- ??? -> progress on possibly new shape
                    if scene.progress then
                        scene.time = scene.progress * 0.5
                    end
                    local canSwap = scene.time <= 0.5
                    scene.time = scene.time + dt * tf * 2
                    if canSwap and scene.time * 2 >= scene.progressNext then
                        scene.progress = scene.progressNext
                        scene.progressNext = nil
                    end

                else
                    -- ??? -> indeterminate progress
                    if scene.progress then
                        scene.time = scene.progress * 0.5
                    end
                    scene.progress = scene.progressNext
                    scene.progressNext = nil
                    scene.time = scene.time + dt * tf
                end

            else
                -- General indeterminate progress time update.
                scene.time = scene.time + dt * tf
            end

            if scene.time >= 1 then
                scene.time = scene.time - 1
                if scene.shapeNext ~= nil then
                    scene.shape = scene.shapeNext
                    scene.shapeNext = nil
                end
            end

            self:repaint()
        end,

        draw = function(self)
            uiu.setColor(1, 1, 1, 1)

            local sx = self.screenX
            local sy = self.screenY
            local w = self.width
            local h = self.height
            local fw = love.graphics.getWidth()
            local fh = love.graphics.getHeight()

            local cx = sx + w * 0.5
            local cy = sy + h * 0.5
            local cmx = cx - (ui.mouseX - fw * 0.5) * 0.015 * config.parallax
            local cmy = cy - (ui.mouseY - fh * 0.5) * 0.015 * config.parallax

            local shape = scene.shape
            if shape then
                local progA = 0
                local progB = scene.progress

                if progB then
                    progB = progB

                else
                    local t = scene.time
                    if t < 0.5 then
                        progA = 0
                        progB = t * 4
                    else
                        progA = t * 4 - 2
                        progB = 1
                    end
                end

                shape:draw(cmx - shape.width * 0.5, cmy - shape.height * 0.5, progA, progB)

            else
                local radius = 32

                local thickness = radius * 0.25
                love.graphics.setLineWidth(thickness)

                radius = radius - thickness

                local polygon = {}

                local edges = 128

                local progA = 0
                local progB = scene.progress

                if progB then
                    progB = progB * edges

                else
                    local t = scene.time
                    local offs = edges * t * 2
                    if t < 0.5 then
                        progA = offs + 0
                        progB = offs + edges * t * 2
                    else
                        progA = offs + edges * (t - 0.5) * 2
                        progB = offs + edges
                    end
                end

                local progAE = math.floor(progA)
                local progBE = math.ceil(progB - 1)

                if progBE - progAE >= 1 then
                    local i = 1
                    for edge = progAE, progBE do
                        local f = edge

                        if edge == progAE then
                            f = progA
                        elseif edge == progBE then
                            f = progB
                        end

                        f = (1 - f / (edges) + 0.5) * math.pi * 2
                        local x = cmx + math.sin(f) * radius
                        local y = cmy + math.cos(f) * radius

                        polygon[i + 0] = x
                        polygon[i + 1] = y
                        i = i + 2
                    end

                    love.graphics.line(polygon)
                end
            end


            uiu.resetColor()
        end,

        drawDebug = function(self)
            local sx = self.screenX
            local sy = self.screenY
            local w = self.width
            local h = self.height
            local fw = love.graphics.getWidth()
            local fh = love.graphics.getHeight()

            local cx = sx + w * 0.5
            local cy = sy + h * 0.5
            local cmx = cx - (ui.mouseX - fw * 0.5) * 0.015 * config.parallax
            local cmy = cy - (ui.mouseY - fh * 0.5) * 0.015 * config.parallax

            local shape = scene.shape
            if shape then
                shape:drawDebug(cmx - shape.width * 0.5, cmy - shape.height * 0.5)
            end
        end

    }):with(uiu.fillWidth):with(uiu.fillHeight(0.5 - 180)):as("canvas"),

    uie.group({
        uie.paneled.column({

            uie.scrollbox(
                uie.column({

                    uie.label("installer.lua machine broke, please fix."),

                }):with({
                    clip = false,
                    cacheable = false,
                    locked = true
                }):hook({
                    layoutLateLazy = function(orig, self)
                        self:layoutLate()
                    end,

                    layoutLate = function(orig, self)
                        orig(self)
                        if self.locked and self.height > self.parent.height then
                            self.y = self.parent.height - self.height
                            self.realY = self.parent.height - self.height
                        end
                    end
                }):with(uiu.fillWidth):as("loglist")
            ):hook({
                onScroll = function(orig, self, mx, my, dx, dy, raw, ...)
                    local child = self.children[1]
                    local y1 = child.y
                    orig(self, mx, my, dx, dy, raw, ...)
                    local y2 = child.y
                    if my and (not raw or dy > 0 or self.children[1].locked) then
                        self.children[1].locked = (raw and dy > 0 or dy < 0) and y1 == y2
                    end
                end
            }):with(uiu.fillWidth):with(uiu.fillHeight(true)),

            uie.group({}):with(uiu.fillWidth):with(uiu.bottombound):as("actionsholder")

        }):with(uiu.fill)
    }):with({
        style = {
            padding = 8
        }
    }):with(uiu.bottombound):with(uiu.fillWidth):with(uiu.fillHeight(0.5 + 120))

}):with({
    cacheable = false,
    _fullroot = true
})
scene.root = root

scene.canvas = root:findChild("canvas")
scene.loglist = root:findChild("loglist")
scene.actionsholder = root:findChild("actionsholder")


scene.shapes = {}

for i, file in ipairs(love.filesystem.getDirectoryItems("data/installshapes")) do
    local name = file:match("^(.+)%.svg$")
    if name then
        scene.shapes[name] = shaper.load("data/installshapes/" .. name .. ".svg")
    end
end

scene.shape = nil
scene.shapeNext = nil
scene.timeReal = 0
scene.time = 0
scene.timeDraw = 0
scene.progress = 0
scene.progressNext = 0
scene.progressDraw = 0
scene.autocloseDuration = 3


function scene.update(status, progress, shape, replace)
    if status ~= nil then
        status = status or ""
        local loglist = scene.loglist
        local last = scene.loglast
        if not replace or not last then
            if loglist.children[300] then
                table.remove(loglist.children, 1)
            end
            last = uie.label(status):with({ wrap = true }):with(uiu.fillWidth)
            loglist:addChild(last)
            scene.loglast = last
        else
            last.text = status
        end
    end

    if progress ~= nil then
        scene.progressNext = progress
    end

    if shape ~= nil then
        if shape == "" then
            scene.shapeNext = false
        else
            scene.shapeNext = scene.shapes[shape] or scene.shape
        end
        if scene.shapeNext == scene.shape then
            scene.shapeNext = nil
        end
    end
end


function scene.done(success, buttons, autoclose)
    if not buttons then
        buttons = success
        success = true
    end

    native.flashWindow()

    local row = uie.row({}):with({
        clip = false
    }):with(uiu.fillWidth)

    if not autoclose then
        local listcount = #buttons
        for i = 1, #buttons do
            local btn = buttons[i]
            btn = uie.button(table.unpack(btn))
            if listcount == 1 then
                btn = btn:with(uiu.fillWidth)
            else
                btn = btn:with(uiu.fillWidth(1 / listcount + 4)):with(uiu.at((i == 1 and 0 or 4) + (i - 1) / listcount, 0))
            end
            row:addChild(btn)
        end

        scene.actionsholder:addChild(row:with(success and utils.importantCheck(24) or utils.important(24)))

    else
        -- place+start self destruct countdown
        local countdown = uie.label(
            string.format("Autoclosing in %d...", scene.autocloseDuration)
        )


        countdown = countdown:with(uiu.fillWidth):with(uiu.at(0))
        row:addChild(countdown)

        threader.routine(
            function()
                local totalDuration = scene.autocloseDuration
                for i = 1, totalDuration do
                    threader.sleep(1)
                    countdown:setText(string.format("Autoclosing in %d...", totalDuration - i) )
                end
                love.event.quit()
            end
        )

        scene.actionsholder:addChild(row)
    end

    scene.actionsrow = row

end


function scene.sharpTask(id, ...)
    local args = {...}
    return threader.routine(function()
        local task = sharp[id](table.unpack(args)):result()
        local batch
        local last
        repeat
            batch = sharp.pollWaitBatch(task):result()
            local all = batch[3]
            for i = 1, #all do
                local update = all[i]
                if update ~= nil then
                    if not last or last[1] ~= update[1] or last[2] ~= update[2] or last[3] ~= update[3] or last[4] ~= update[4] then
                        last = update
                        scene.update(update[1], update[2], update[3], update[4])
                    end
                else
                    print("installer.sharpTask encountered nil on poll", task)
                end
            end
        until batch[1] ~= "running" and batch[2] == 0

        local status = sharp.free(task):result()
        if status == "error" then
            scene.update(last and last[1], 1, "error", true)
            scene.done(false, {
                {
                    "Open log",
                    function()
                        alert({
                            body = [[
You can ask for help in the Celeste Discord server.
An invite can be found on the Everest website.

Please drag and drop your log files into the #modding_help channel.
Before uploading, check your logs for sensitive info (f.e. your username).]],
                            buttons = {
                                { "Open log folder", function(container)
                                    utils.openFile(fs.getStorageDir())
                                end },

                                { "Open Everest Website", function(container)
                                    utils.openURL("https://everestapi.github.io/")
                                    container:close("website")
                                end },

                                { "Close" },
                            }
                        })
                    end
                },
                {
                    "OK",
                    function()
                        scener.pop(1)
                    end
                }
            })
            return false
        end

        return last[1]
    end)
end


function scene.enter()
    scene.shape = nil
    scene.shapeNext = nil
    scene.timeReal = 0
    scene.time = 0
    scene.timeDraw = 0
    scene.progress = 0
    scene.progressNext = 0
    scene.progressDraw = 0
    scene.loglist.children = {}
    scene.loglist.y = 0
    scene.loglist.realY = 0
    scene.loglist.locked = true
    scene.loglist:reflow()
    scene.loglast = nil
    if scene.actionsrow then
        scene.actionsrow:removeSelf()
        scene.actionsrow = nil
    end
    scene.update(nil, false, "")
    scener.lock()
end


function scene.leave()
    scener.unlock()
    if scene.onLeave then
        scene.onLeave()
    end
    scene.onLeave = nil
end


return scene
