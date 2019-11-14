local ui = require("ui.main")
local uie = require("ui.elements.main")
local uiu = require("ui.utils")
require("ui.elements.basic")
require("ui.elements.layout")

-- Basic view box.
uie.add("scrollbox", {
    base = "group",
    cacheable = false,
    interactive = 2,

    init = function(self, inner)
        inner:as("inner")
        inner.style.radius = 0

        uie.__group.init(self, {
            inner,
            uie.scrollhandleX():as("handleX"),
            uie.scrollhandleY():as("handleY")
        })

        self.clip = true

        self.__dx = 0
        self.__dy = 0
    end,

    calcSize = function(self, width, height)

    end,

    update = function(self)
        local dx = self.__dx
        local dy = self.__dy
        if dx ~= 0 or dy ~= 0 then
            dx = dx * 0.475
            dy = dy * 0.475

            self:onScroll(nil, nil, dx, dy, true)

            if math.abs(dx) < 0.001 then
                dx = 0
            end
            if math.abs(dy) < 0.001 then
                dy = 0
            end

            self.__dx = dx
            self.__dy = dy
        end
    end,

    onScroll = function(self, x, y, dx, dy, raw)
        local inner = self._inner

        if not raw then
            dx = dx * -32
            dy = dy * -32
            self.__dx = self.__dx + dx
            self.__dy = self.__dy + dy
        end

        local x = -inner.x
        local boxWidth = self.width
        local innerWidth = inner.width
        x = x + dx
        if x < 0 then
            x = 0
        elseif innerWidth < x + boxWidth then
            x = innerWidth - boxWidth
        end
        inner.x = uiu.round(-x)

        local y = -inner.y
        local boxHeight = self.height
        local innerHeight = inner.height
        y = y + dy
        if y < 0 then
            y = 0
        elseif innerHeight < y + boxHeight then
            y = innerHeight - boxHeight
        end
        inner.y = uiu.round(-y)

        self:repositionChildren()
        ui.root:reflow()
        self._handleX:repaint()
        self._handleX:layoutLate()
        self._handleY:repaint()
        self._handleY:layoutLate()
        self:repaint()
    end
})


-- Shared scroll bar handle code.
uie.add("scrollhandle", {
    cacheable = false,
    interactive = 1,

    style = {
        color = { },
        border = { },

        thickness = 6,
        radius = 3,

        normalColor = { 0.5, 0.5, 0.5, 0.6 },
        normalBorder = { 0.5, 0.5, 0.5, 1 },

        hoveredColor = { 0.6, 0.6, 0.6, 1 },
        hoveredBorder = { 0.6, 0.6, 0.6, 0.7 },

        pressedColor = { 0.55, 0.55, 0.55, 1 },
        pressedBorder = { 0.55, 0.55, 0.55, 0.7 },

        fadeDuration = 0.2
    },

    init = function(self)
        self.enabled = nil
        self.__enabled = true
    end,

    layoutLateLazy = function(self)
        -- Always reflow this child whenever its parent gets reflowed.
        self:layoutLate()
    end,

    update = function(self)
        local enabled = self.enabled
        if enabled == nil then
            enabled = self.isNeeded
        end
        self.__enabled = enabled

        if not enabled then
            return
        end

        local style = self.style
        local colorPrev = style.color
        local borderPrev = style.border
        local color = colorPrev
        local border = borderPrev

        if self.dragged then
            color = style.pressedColor
            border = style.pressedBorder
        elseif self.hovered then
            color = style.hoveredColor
            border = style.hoveredBorder
        else
            color = style.normalColor
            border = style.normalBorder
        end

        local fadeTime

        if self.__color ~= color or self.__border ~= border then
            self.__color = color
            self.__border = border
            fadeTime = 0
        else
            fadeTime = self.__fadeTime
        end

        local fadeDuration = style.fadeDuration
        if #colorPrev ~= 0 and fadeTime < fadeDuration then
            fadeTime = math.min(fadeDuration, fadeTime + ui.delta)
            local f = fadeTime / fadeDuration
            color = {
                colorPrev[1] + (color[1] - colorPrev[1]) * f,
                colorPrev[2] + (color[2] - colorPrev[2]) * f,
                colorPrev[3] + (color[3] - colorPrev[3]) * f,
                colorPrev[4] + (color[4] - colorPrev[4]) * f,
            }
            border = {
                borderPrev[1] + (border[1] - borderPrev[1]) * f,
                borderPrev[2] + (border[2] - borderPrev[2]) * f,
                borderPrev[3] + (border[3] - borderPrev[3]) * f,
                borderPrev[4] + (border[4] - borderPrev[4]) * f,
            }
            self:repaint()
        end

        self.__fadeTime = fadeTime
        style.color = color
        style.border = border
    end,

    draw = function(self)
        if not self.__enabled then
            return
        end

        local radius = self.style.radius
        love.graphics.setColor(self.style.color)
        love.graphics.rectangle("fill", self.screenX, self.screenY, self.width, self.height, radius, radius)
        love.graphics.setColor(self.style.border)
        love.graphics.rectangle("line", self.screenX, self.screenY, self.width, self.height, radius, radius)
    end

})


-- Separate X and Y scrollers.
uie.add("scrollhandleX", {
    base = "scrollhandle",

    recalc = function(self)
        -- Needed to not grow the parent by accident.
        self.realX = 0
        self.realY = 0
        self.width = 0
        self.height = self.style.thickness
    end,

    layoutLate = function(self)
        local thickness = self.style.thickness
        local box = self.parent
        local inner = box._inner

        local boxSize = box.width
        local innerSize = inner.width
        local pos = -inner.x

        pos = boxSize * pos / innerSize
        local size = boxSize * boxSize / innerSize
        local tail = pos + size

        if pos < 1 then
            pos = 1
        elseif tail > boxSize - 1 then
            tail = boxSize - 1
            if pos > tail then
                pos = tail - 1
            end
        end

        size = math.max(1, tail - pos)

        if size + 1 < innerSize then
            self.isNeeded = true
            self.realX = math.round(pos)
            self.realY = box.height - thickness - 1
            self.width = math.round(size)
        else
            self.isNeeded = false
            self.realX = 0
            self.realY = 0
            self.width = 0
        end
    end,

    onDrag = function(self, x, y, dx, dy)
        local box = self.parent
        local inner = box._inner
        self.parent:onScroll(x, y, dx * inner.width / box.width, 0, true)
    end
})

uie.add("scrollhandleY", {
    base = "scrollhandle",

    recalc = function(self)
        -- Needed to not grow the parent by accident.
        self.realX = 0
        self.realY = 0
        self.width = self.style.thickness
        self.height = 0
    end,

    layoutLate = function(self)
        local thickness = self.style.thickness
        local box = self.parent
        local inner = box._inner

        local boxSize = box.height
        local innerSize = inner.height
        local pos = -inner.y

        pos = boxSize * pos / innerSize
        local size = boxSize * boxSize / innerSize
        local tail = pos + size

        if pos < 1 then
            pos = 1
        elseif tail > boxSize - 1 then
            tail = boxSize - 1
            if pos > tail then
                pos = tail - 1
            end
        end

        size = math.max(1, tail - pos)
        
        if size + 1 < innerSize then
            self.isNeeded = true
            self.realX = box.width - thickness - 1
            self.realY = math.round(pos)
            self.height = math.round(size)
        else
            self.isNeeded = false
            self.realX = 0
            self.realY = 0
            self.height = 0
        end
    end,

    onDrag = function(self, x, y, dx, dy)
        local box = self.parent
        local inner = box._inner
        self.parent:onScroll(x, y, 0, dy * inner.height / box.height, true)
    end
})

return uie
