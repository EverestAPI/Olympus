local ui = require("ui.main")
local uie = require("ui.elements.main")
require("ui.elements.basic")
require("ui.elements.layout")

-- Basic view box.
uie.add("scrollbox", {
    base = "group",
    
    init = function(self, inner)
        if inner and (inner.id == nil or inner.id == "") then
            inner = inner:as("inner")
            inner.style.radius = 0
        end
        uie.__group.init(self, {
            inner,
            uie.scrollhandleX():as("handleX"),
            uie.scrollhandleY():as("handleY")
        })
    end,

})


-- Shared scroll bar handle code.
uie.add("scrollhandle", {
    interactive = 1,

    style = {
        color = { },
        border = { },

        thickness = 6,
        radius = 3,

        normalColor = { 0.26, 0.26, 0.26, 0.5 },
        normalBorder = { 0.26, 0.26, 0.26, 1 },

        hoveredColor = { 0.22, 0.22, 0.22, 1 },
        hoveredBorder = { 0.22, 0.22, 0.22, 0.5 },

        pressedColor = { 0.17, 0.17, 0.17, 1 },
        pressedBorder = { 0.17, 0.17, 0.17, 0.5 },

        fadeDuration = 0.2
    },

    init = function(self, inner)
        if inner and (inner.id == nil or inner.id == "") then
            inner = inner:as("inner")
            inner.style.radius = 0
        end
        uie.__group.init(self, {
            inner
        })

        self.enabled = nil
        self.__enabled = true
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

        if self.pressed then
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
            fadeTime = fadeTime + ui.delta
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

    getIsNeeded = function(self)
        local box = self.parent
        local inner = box._inner
        return box.width < inner.width
    end,

    layoutLate = function(self)
        local thickness = self.style.thickness
        local box = self.parent
        local inner = box._inner
        
        local size = box.width
        local innerSize = inner.width
        local pos = inner.x

        pos = size * pos / innerSize
        size = math.max(0, math.min(size, size * size / innerSize + pos) - pos)

        self.realX = pos
        self.realY = box.height - thickness
        self.width = size
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

    getIsNeeded = function(self)
        local box = self.parent
        local inner = box._inner
        return box.height < inner.height
    end,

    layoutLate = function(self)
        local thickness = self.style.thickness
        local box = self.parent
        local inner = box._inner
        
        local size = box.height
        local innerSize = inner.height
        local pos = inner.y

        pos = size * pos / innerSize
        size = math.max(0, math.min(size, size * size / innerSize + pos) - pos)

        self.realX = box.width - thickness
        self.realY = pos
        self.height = size
    end
})

return uie
