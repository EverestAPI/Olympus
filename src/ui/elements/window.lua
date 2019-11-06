local ui = require("ui.main")
local uie = require("ui.elements.main")
require("ui.elements.basic")
require("ui.elements.layout")
require("ui.elements.form")

-- Basic window.
uie.add("window", {
    base = "column",

    interactive = 2,

    style = {
        border = { 0.15, 0.15, 0.15, 1 },
        padding = 1,
        spacing = 0
    },

    init = function(self, title, inner)
        if inner and (inner.id == nil or inner.id == "") then
            inner = inner:as("inner")
            inner.style.radius = 0
        end
        uie.__column.init(self, {
            uie.titlebar({ uie.label(title):as("title") }),
            inner
        })
    end,

    getTitle = function(self)
        return self._titlebar._title._text
    end,

    setTitle = function(self, value)
        self._titlebar._title.text = value
    end,

    recalc = function(self)
        uie.__column.recalc(self)

        local parent = self.parent
        if not parent then
            return
        end

        local x = self.x
        local y = self.y
        local width = self.width
        local height = self.height
        local parentWidth = parent.width
        local parentHeight = parent.height
        
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
                table.insert(children, self)
                return
            end
        end
    end
})

uie.add("titlebar", {
    base = "row",

    id = "titlebar",

    style = {
        bg = { 0.12, 0.12, 0.12, 1 },
        border = { 0, 0, 0, 0 },
        radius = 0
    },

    init = function(self, ...)
        uie.__row.init(self, ...)

        self.interactive = true
    end,

    layout = function(self)
        uie.__row.layout(self)
        self.width = 0
    end,

    layoutLate = function(self)
        local parent = self.parent
        self.width = parent.width - parent.style.padding * 2
        uie.__row.layoutLate(self)
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

return uie
