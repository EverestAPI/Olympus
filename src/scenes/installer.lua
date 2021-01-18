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

})
scene.root = root

scene.textFont = ui.font or uie.label.__default.style.font or love.graphics.getFont()
scene.text = love.graphics.newText(scene.textFont, "")


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


function scene.update(status, progress, shape)
    if status ~= nil then
        local text = scene.text
        text:set(status or "")
        scene.textWidth = math.ceil(text:getWidth())
        scene.textHeight = math.ceil(text:getHeight())
        if scene.textHeight == 0 then
            scene.textHeight = math.ceil(scene.textFont:getHeight(" "))
        end
    end

    if progress ~= nil then
        native.setProgress(shape == "error" and "error" or not progress and "indeterminate" or "normal", progress or 0)
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


function scene.done(buttons)
    local row = uie.row({}):with({
        style = {
            bg = {},
            padding = 0,
            radius = 0
        },
        clip = false
    }):hook({
        layoutLateLazy = function(orig, self)
            -- Always reflow this child whenever its parent gets reflowed.
            self:layoutLate()
        end,

        layoutLate = function(orig, self)
            orig(self)
            self.x = math.floor(self.parent.innerWidth * 0.5 - self.width * 0.5)
            self.realX = math.floor(self.parent.width * 0.5 - self.width * 0.5)
            self.y = self.parent.innerHeight - 84
            self.realY = self.parent.height - 84 - self.parent.style:getIndex("padding", 4)
        end
    })
    for i = 1, #buttons do
        local btn = buttons[i]
        btn = uie.button(table.unpack(btn))
        row:addChild(btn)
    end
    root:addChild(row)
end


uiu.hook(root, {
    update = function(orig, self, dt)
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

        orig(self, dt)
    end,

    draw = function(orig, self)
        uiu.setColor(1, 1, 1, 1)

        local sx = self.screenX
        local sy = self.screenY
        local w = self.width
        local h = self.height
        local fw = love.graphics.getWidth()
        local fh = love.graphics.getHeight()

        local cx = sx + w * 0.5
        local cy = sy + h * 0.5
        local cmx = cx - (ui.mouseX - fw * 0.5) * 0.015
        local cmy = cy - (ui.mouseY - fh * 0.5) * 0.015

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

        if uiu.setColor(uie.panel.__default.style.bg) then
            love.graphics.rectangle(
                "fill",
                sx, sy + h - 128 - 16,
                w, 128 + 16
            )
        end

        if uiu.setColor(uie.label.__default.style.color) then
            love.graphics.draw(
                scene.text,
                math.floor(cx - scene.textWidth * 0.5),
                math.floor(sy + h - 128)
            )
        end

        uiu.resetColor()

        orig(self)
    end,

    drawDebug = function(orig, self)
        local sx = self.screenX
        local sy = self.screenY
        local w = self.width
        local h = self.height
        local fw = love.graphics.getWidth()
        local fh = love.graphics.getHeight()

        local cx = sx + w * 0.5
        local cy = sy + h * 0.5
        local cmx = cx - (ui.mouseX - fw * 0.5) * 0.015
        local cmy = cy - (ui.mouseY - fh * 0.5) * 0.015

        local shape = scene.shape
        if shape then
            shape:drawDebug(cmx - shape.width * 0.5, cmy - shape.height * 0.5)
        end

        orig(self)
    end
})


function scene.sharpTask(id, ...)
    local args = {...}
    return threader.routine(function()
        local task = sharp[id](table.unpack(args)):result()
        local result
        repeat
            result = sharp.pollWait(task, true):result()
            local update = result[3]
            if update ~= nil then
                scene.update(update[1], update[2], update[3])
            else
                print("installer.sharpTask encountered nil on poll", task)
            end
        until result[1] ~= "running" and result[2] == 0

        local last = sharp.poll(task):result()
        last = tostring(last)
        local status = sharp.free(task):result()
        if status == "error" then
            scene.update(last[1], 1, "error")
            scene.done({
                {
                    "Open log",
                    function()
                        alert({
                            body = [[
You can ask for help in the Celeste Discord server.
An invite can be found on the Everest website.

Please drag and drop your files into the #modding_help channel.
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

        return last
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
    scene.update("", false, "")
    root.children = {}
    scener.lock()
end


function scene.leave()
    scener.unlock()
    native.setProgress("none", 0)
    if scene.onLeave then
        scene.onLeave()
    end
    scene.onLeave = nil
end


return scene
