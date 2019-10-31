local ui = require("ui.main")
local uie = require("ui.elements.main")
require("ui.elements.basic")


-- Basic vertical list.
uie.add("column", {
    base = "panel",

    style = {
        spacing = 8
    },

    calcSize = function(self)
        local height = 0
        local addSpacing = false
        local spacing = self.style.spacing
        local children = self.children
        for i = 1, #children do
            local c = children[i]
            if addSpacing then
                height = height + spacing
            end
            height = height + c.height
            addSpacing = true
        end
        return uie.__panel.calcSize(self, nil, height)
    end,

    layoutChildren = function(self)
        local padding = self.style.padding
        local y = padding
        local spacing = self.style.spacing
        local children = self.children
        for i = 1, #children do
            local c = children[i]
            c.parent = self
            c:layout()
            y = y + c.y
            c.realX = c.x + padding
            c.realY = y
            y = y + c.height + spacing
        end
    end
})


-- Basic horizontal list.
uie.add("row", {
    base = "panel",

    style = {
        spacing = 8
    },

    calcSize = function(self)
        local width = 0
        local addSpacing = false
        local spacing = self.style.spacing
        local children = self.children
        for i = 1, #children do
            local c = children[i]
            if addSpacing then
                width = width + spacing
            end
            width = width + c.width
            addSpacing = true
        end
        return uie.__panel.calcSize(self, width, nil)
    end,

    layoutChildren = function(self)
        local padding = self.style.padding
        local x = padding
        local spacing = self.style.spacing
        local children = self.children
        for i = 1, #children do
            local c = children[i]
            c.parent = self
            c:layout()
            x = x + c.x
            c.realX = x
            c.realY = c.y + padding
            x = x + c.width + spacing
        end
    end
})


return uie
