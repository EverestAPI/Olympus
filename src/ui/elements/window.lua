local ui = require("ui.main")
local uie = require("ui.elements.main")
local uiu = require("ui.utils")
require("ui.elements.basic")
require("ui.elements.layout")
require("ui.elements.input")

-- Basic window.
uie.add("window", {
    base = "column",
    cacheable = false,
    interactive = 2,

    style = {
        bg = { 0.12, 0.12, 0.12, 1 },
        border = { 0.15, 0.15, 0.15, 1 },
        padding = 1,
        spacing = 0
    },

    init = function(self, title, inner)
        inner = inner:as("inner")
        inner.style.radius = 0

        uie.__column.init(self, {
            uie.titlebar(title),
            inner
        })
    end,

    getTitle = function(self)
        return self._titlebar._title._text
    end,

    setTitle = function(self, value)
        self._titlebar._title.text = value
    end,

    update = function(self)
        local parent = self.parent
        if not parent then
            return
        end

        local x = self.x
        local y = self.y
        local width = self.width
        local height = self.height
        local parentWidth = parent.innerWidth
        local parentHeight = parent.innerHeight
        
        local max
        max = x + width
        if parentWidth < max then
            x = parentWidth - width
        end
        max = y + height
        if parentHeight < max then
            y = parentHeight - height
        end

        if x < 0 then
            x = 0
        end
        if y < 0 then
            y = 0
        end

        self.x = x
        self.y = y
    end,

    onPress = function(self, x, y, button, dragging)
        local parent = self.parent
        if not parent then
            return
        end
        
        local children = parent.children
        if not children then
            return
        end

        for i = 1, #children do
            local c = children[i]
            if c == self then
                table.remove(children, i)
                children[#children + 1] = self
                return
            end
        end
    end
})

uie.add("titlebar", {
    base = "row",
    cacheable = false,
    interactive = 1,

    id = "titlebar",

    style = {
        border = { 0, 0, 0, 0 },
        radius = 0,

        focusedBG = { 0.15, 0.15, 0.15, 1 },
        focusedFG = { 1, 1, 1, 1 },

        unfocusedBG = { 0.1, 0.1, 0.1, 1 },
        unfocusedFG = { 0.7, 0.7, 0.7, 1 },

        fadeDuration = 0.3
    },

    init = function(self, title, closeable)
        local children = {
            uie.label(title):as("label")
        }
        if closeable then
            children[#children + 1] = uie.buttonClose()
        end
        uie.__row.init(self, children)
        self.style.bg = {}
        self:with(uiu.fillWidth)
    end,

    update = function(self)
        local style = self.style
        local label = self._label
        local labelStyle = label.style
        local bgPrev = style.bg
        local fgPrev = labelStyle.color
        local bg = bgPrev
        local fg = fgPrev

        if self.parent.focused then
            bg = style.focusedBG
            fg = style.focusedFG
        else
            bg = style.unfocusedBG
            fg = style.unfocusedFG
        end

        local fadeTime

        if self.__bg ~= bg or self.__fg ~= fg then
            self.__bg = bg
            self.__fg = fg
            fadeTime = 0
        else
            fadeTime = self.__fadeTime
        end

        local fadeDuration = style.fadeDuration
        if #bgPrev ~= 0 and fadeTime < fadeDuration then
            fadeTime = math.min(fadeDuration, fadeTime + ui.delta)
            local f = fadeTime / fadeDuration
            bg = {
                bgPrev[1] + (bg[1] - bgPrev[1]) * f,
                bgPrev[2] + (bg[2] - bgPrev[2]) * f,
                bgPrev[3] + (bg[3] - bgPrev[3]) * f,
                bgPrev[4] + (bg[4] - bgPrev[4]) * f,
            }
            fg = {
                fgPrev[1] + (fg[1] - fgPrev[1]) * f,
                fgPrev[2] + (fg[2] - fgPrev[2]) * f,
                fgPrev[3] + (fg[3] - fgPrev[3]) * f,
                fgPrev[4] + (fg[4] - fgPrev[4]) * f,
            }
            self:repaint()
        end

        self.__fadeTime = fadeTime
        style.bg = bg
        labelStyle.color = fg
    end,

    onPress = function(self, x, y, button, dragging)
        if button == 1 then
            self.dragging = dragging
        end
    end,

    onRelease = function(self, x, y, button, dragging)
        if button == 1 or not dragging then
            self.dragging = dragging
        end
    end,

    onDrag = function(self, x, y, dx, dy)
        local parent = self.parent
        parent.x = parent.x + dx
        parent.y = parent.y + dy
        parent:reflow()
    end
})

uie.add("buttonClose", {
    base = "button",
    id = "close",

    interactive = 1,

    style = {
        padding = 16,
        normalBG = { 0.9, 0.1, 0.2, 1 },
        hoveredBG = { 0.85, 0.25, 0.25, 1 },
        pressedBG = { 0.6, 0.08, 0.14, 1 }
    },

    init = function(self)
       uie.__button.init(self, uie.image("ui/close"))
    end,

    layoutLazy = function(self)
        uie.__button.layoutLazy(self)
        self.realHeight = self.height
        self.height = 0
    end,

    layoutLateLazy = function(self)
        -- Always reflow this child whenever its parent gets reflowed.
        self:layoutLate()
    end,

    layoutLate = function(self)
        local parent = self.parent
        self.realX = parent.width - self.width + 1
        self.realY = -1
        self.height = self.realHeight
    end
})

return uie
