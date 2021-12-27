local ui, uiu, uie = require("ui").quick()
local moonshine = require("moonshine")
local config = require("config")

local blurrer = {}


function blurrer.drawBlurredCanvasContent(canvas, x, y, paddingL, paddingT, blurFade)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setColor(blurFade, blurFade, blurFade, blurFade)
    uiu.drawCanvas(canvas, x - paddingL, y - paddingT)
end

function blurrer.drawBlurredCanvas(orig, el, canvas, x, y, width, height, paddingL, paddingT, paddingR, paddingB)
    local blurFade = math.min(1, el.blurTime * 7)
    if not config.quality.bgBlur or blurFade < 0.01 then
        return orig(el, canvas, x, y, width, height, paddingL, paddingT, paddingR, paddingB)
    end

    love.graphics.push()
    love.graphics.origin()

    local blurFadeInv = math.sin(math.pi * (1 - blurFade) * 0.5)
    if blurFadeInv > 0.01 then
        love.graphics.setColor(blurFadeInv, blurFadeInv, blurFadeInv, blurFadeInv)
        uiu.drawCanvas(canvas, x - paddingL, y - paddingT)
    end

    love.graphics.setColor(1, 1, 1, 1)

    el.blurEffect(blurrer.drawBlurredCanvasContent, canvas, x, y, paddingL, paddingT, math.sin(math.pi * blurFade * 0.5))

    love.graphics.pop()

    uiu.resetColor()
end


function blurrer.blur(el, cb)
    el.cacheForce = true
    el.cachePadding = 0

    el.blurTime = 0
    el.blurWidth = 0
    el.blurHeight = 0
    el.blurEffect = moonshine(moonshine.effects.fastgaussianblur)
    el.blurEffect.fastgaussianblur.sigma = 120
    el.blurEffect.fastgaussianblur.taps = 51
    el.blurEffect.fastgaussianblur.offset = 0.5

    el:hook({
        update = function(orig, self, dt)
            orig(self, dt)

            local time = self.blurTime
            if cb(el) then
                time = math.min(1, time + dt * 2)

            else
                time = math.max(0, time - dt * 8)
            end

            self.blurTime = time
        end,

        layoutLateLazy = function(orig, self)
            -- Always reflow this child whenever its parent gets reflowed.
            self:layoutLate()
            self:repaint()
        end,

        layoutLate = function(orig, self)
            orig(self)
            local width = self.width + 32
            local height = self.height + 32
            if width > self.blurWidth or height > self.blurHeight then
                self.blurEffect.resize(width + 128, height + 128)
                self.blurWidth = width + 128
                self.blurHeight = height + 128
            end
        end,

        __drawCachedCanvas = blurrer.drawBlurredCanvas
    })

    return el
end


return setmetatable(blurrer, {
    __call = function(self, cb)
        return function(el)
            self.blur(el, cb)
        end
    end
})
