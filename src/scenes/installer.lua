local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local threader = require("threader")
local scener = require("scener")
local config = require("config")
local sharp = require("sharp")
local shaper = require("shaper")

local scene = {
    name = "Installer"
}


local root = uie.group({

})
scene.root = root

scene.textFont = ui.fontBig or uie.__label.__default.style.font or love.graphics.getFont()
scene.text = love.graphics.newText(scene.textFont, "")

scene.shape = shaper.load("data/installshapes/monomod.svg")


function scene.update(status, progress)
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
        scene.progress = progress
    end
end


function root.update(self, dt)
    self.time = (self.time + dt * 0.3) % 1
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
        shape:draw(cmx - shape.width * 0.5, cmy - shape.height * 0.5)

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
            local t = self.time
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
    scene.update("", false)
    root.time = 0
    scener.lock()
end


function scene.leave()
    scener.unlock()
end


return scene
