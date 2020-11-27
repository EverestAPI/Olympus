local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local threader = require("threader")
local scener = require("scener")
local config = require("config")
local sharp = require("sharp")
local native = require("native")
local shaper = require("shaper")

local scene = {
    name = "Installer"
}


local root = uie.group({

})
scene.root = root

scene.textFont = ui.fontMono or uie.__label.__default.style.font or love.graphics.getFont()
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
    if not status then
        status = ""
    end

    local text = scene.text
    text:set(status or "")
    scene.textWidth = math.ceil(text:getWidth())
    scene.textHeight = math.ceil(text:getHeight())
    if scene.textHeight == 0 then
        scene.textHeight = math.ceil(scene.textFont:getHeight(" "))
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


function root.update(self, dt)
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
end

function root.draw(self)
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


    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle(
        "fill",
        sx, sy + h - 128 - 16,
        w, 128 + 16
    )

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(
        scene.text,
        math.floor(cx - scene.textWidth * 0.5),
        math.floor(sy + h - 128)
    )

    uiu.resetColor()
end

function root.drawDebug(self)
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
end


function scene.enter()
    scene.timeReal = 0
    scene.time = 0
    scene.timeDraw = 0
    scene.progress = 0
    scene.update("", false, "")
    scener.lock()
end


function scene.leave()
    scener.unlock()
    native.setProgress("none", 0)
end


return scene
