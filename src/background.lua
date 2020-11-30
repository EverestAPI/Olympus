local ui, uiu, uie = require("ui").quick()
local config = require("config")
local moonshine = require("moonshine")

local background = {}

background.bgs = {}
background.snows = {}
background.cog = uiu.image("cogwheel")

for i, file in ipairs(love.filesystem.getDirectoryItems("data")) do
    local bg = file:match("^(bg%d+)%.png$")
    if bg then
        background.bgs[#background.bgs + 1] = uiu.image(bg)
    end

    local snow = file:match("^(snow%d+)%.png$")
    if snow then
        background.snows[#background.snows + 1] = "data/" .. snow .. ".png"
    end
end

background.snow = love.graphics.newArrayImage(background.snows)
background.snows = #background.snows

function background.refresh()
    background.bg = config.bg and config.bg > 0 and background.bgs[config.bg] or background.bgs[love.math.random(#background.bgs)]
end

function background.new()
    if not background.bg then
        background.refresh()
    end
    return uie.new({
        id = "bg",
        width = 0,
        height = 0,
        cacheable = false,

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

            local snows = background.snows
            local random = love.math.random

            local width, height = love.graphics.getWidth(), love.graphics.getHeight()
            local mouseX, mouseY = ui.mouseX - width / 2, ui.mouseY - height / 2

            local dots = self.dots
            for i = 1, #dots do
                local dot = dots[i]
                dot.time = dot.time + dt * (dot.speed or 1)

                if dot.time >= 1 or (dot.cx * (width - dot.rad) + dot.rad * 0.5 + dot.rad - mouseX * 0.12) < -128 then
                    dot.time = random() * 0.5 + 0.3
                    dot.tex = love.math.random(snows)
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

            if width > self.innerWidth or height > self.innerHeight then
                self.effect.resize(width, height)
                self.innerWidth = width
                self.innerHeight = height
            end

            --self:repaint()
        end,

        layoutLate = function(self)
            self.realX = 0
            self.realY = 0
        end,

        drawBG = function(self)
            local width, height = love.graphics.getWidth() + 4, love.graphics.getHeight() + 4
            local mouseX, mouseY = ui.mouseX - width / 2, ui.mouseY - height / 2
            local time = self.time
            local cog = background.cog

            local scale = math.max(width / 540, height / 700)
            scale = (scale - 1) * 0.25 + 1

            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(
                background.bg,
                width / 2 - mouseX * 0.01,
                height / 2 - mouseY * 0.01,
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
            local snow = background.snow
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
                love.graphics.drawLayer(
                    snow,
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
            if not config.quality.bg then
                return
            end

            love.graphics.setColor(1, 1, 1, 1)

            if config.quality.bgBlur then
                self.effect(self.drawBG, self)
            else
                self:drawBG()
            end

            love.graphics.pop()

            uiu.resetColor()
        end
    })
end


return setmetatable(background, {
    __call = function(self, ...)
        return self.new(...)
    end
})
