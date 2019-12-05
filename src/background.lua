local ui, uiu, uie = require("ui").quick()
local moonshine = require("moonshine")

local bgs = {}
for i, file in ipairs(love.filesystem.getDirectoryItems("data")) do
    local bg = file:match("^(bg%d+)%.png$")
    if bg then
        bgs[#bgs + 1] = bg
    end
end

return function()
    return uie.new({
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

        update = function(self, dt)
            self.time = self.time + dt

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
    })
end