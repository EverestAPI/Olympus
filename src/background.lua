local ui, uiu, uie = require("ui").quick()
local moonshine = require("moonshine")

local bgs = {}
local snows = {}
local cog = uiu.image("cogwheel")

for i, file in ipairs(love.filesystem.getDirectoryItems("data")) do
    local bg = file:match("^(bg%d+)%.png$")
    if bg then
        bgs[#bgs + 1] = uiu.image(bg)
    end

    local snow = file:match("^(snow%d+)%.png$")
    if snow then
        snows[#snows + 1] = uiu.image(snow)
    end
end

return function()
    return uie.new({
        id = "bg",
        width = 0,
        height = 0,
        cacheable = false,

        bg = bgs[love.math.random(#bgs)],

        time = 8,

        effect = moonshine(moonshine.effects.gaussianblur),

        dots = {},

        init = function(self)
            self.effect.gaussianblur.sigma = 5

            local dots = self.dots
            for i = 1, 128 do
                dots[i] = {
                    time = 1
                }
            end
        end,

        update = function(self, dt)
            self.time = self.time + dt

            local random = love.math.random

            local width, height = love.graphics.getWidth(), love.graphics.getHeight()
            local mouseX, mouseY = ui.mouseX - width / 2, ui.mouseY - height / 2

            local dots = self.dots
            for i = 1, #dots do
                local dot = dots[i]
                dot.time = dot.time + dt * (dot.speed or 1)

                if dot.time >= 1 or (dot.cx * (width - dot.rad) + dot.rad * 0.5 + dot.rad - mouseX * 0.12) < -128 then
                    dot.time = random() * 0.5 + 0.3
                    dot.tex = snows[love.math.random(#snows)]
                    dot.cx = (dot.cx and 1 or -1) + (768 + math.max(mouseX, -mouseX) * 0.12) / width + random() * (dot.cx and 1 or 3)
                    dot.cy = random()
                    dot.z = 0.5 + random()
                    dot.r = random() * 0.1 + 0.9
                    dot.g = random() * 0.1 + 0.9
                    dot.b = random() * 0.1 + 0.9
                    dot.a = (random() * random() * random() * 1.5) + (random() * 0.5) + 0.5
                    dot.offs = random() * math.pi * 2
                    dot.dir = math.sign(random() - 0.5)
                    dot.rad = (random() + 0.3) * 256
                    dot.speed = (random() + 0.5) * 0.04 + (random() * random()) * 0.04
                    dot.scale = (random() + 0.5) * 0.8
                end

                dot.cx = dot.cx - dt / width * ((width * 0.25) + 32 + (64 + dot.speed * dot.speed) * dot.speed)
            end

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
                cog,
                128 - mouseX * 0.04,
                -32 - mouseY * 0.04,
                time * 0.2,
                2, 2,
                128, 128
            )

            love.graphics.setColor(0.1, 0.1, 0.1, 0.15)
            love.graphics.draw(
                cog,
                width - 128 - mouseX * 0.06,
                height + 32 - mouseY * 0.06,
                time * 0.3,
                3, 3,
                128, 128
            )

            local dots = self.dots
            for i = 1, #dots do
                local dot = dots[i]

                local dtime = dot.time
                local dtex = dot.tex
                local dcx = dot.cx
                local dcy = dot.cy
                local dz = dot.z
                local dr = dot.r
                local dg = dot.g
                local db = dot.b
                local da = dot.a
                local doffs = dot.offs
                local ddir = dot.dir
                local drad = dot.rad
                local dscale = dot.scale

                local ang = dtime * ddir * math.pi + doffs
                local t = math.sin(dtime * math.pi)

                local dx = dcx * (width - drad) + drad * 0.5 + math.cos(ang) * drad
                local dy = dcy * (height - drad) + drad * 0.5 + math.sin(ang) * drad

                dscale = dscale * (t * 0.8 + 0.2)

                love.graphics.setColor(dr, dg, db, 0.05 * t * da)
                love.graphics.draw(
                    dtex,
                    dx - mouseX * 0.08 * dz,
                    dy - mouseY * 0.08 * dz,
                    time * 0.2 + dtime * 0.5,
                    dscale, dscale,
                    16, 16
                )
            end

            love.graphics.push()
            love.graphics.origin()
        end,

        draw = function(self)
            love.graphics.setColor(1, 1, 1, 1)
            self.effect(self.drawBG, self)
            love.graphics.pop()
        end
    })
end