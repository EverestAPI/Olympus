local ui = require("ui.main")
local uie = require("ui.elements.main")
require("ui.elements.basic")
require("ui.elements.layout")
require("ui.elements.form")

-- Basic window.
uie.add("window", {
    base = "column",

    style = {
        bg = { 0.15, 0.15, 0.15, 1 },
        border = { 0, 0, 0, 0 },
        padding = 0,
        radius = 3,
        spacing = 0
    },

    init = function(self, title, inner)
        if inner and (inner.id == nil or inner.id == "") then
            inner = inner:as("inner")
            inner.style.radius = 0
        end
        uie.__column.init(self, {
            uie.row({ uie.label(title):as("title") }):with({ style = { bg = { 0, 0, 0, 0 }, radius = 0 }}):as("titlebar"),
            inner
        })
    end,

    getTitle = function(self)
        return self._titlebar._title._text
    end,

    setTitle = function(self, value)
        self._titlebar._title.text = value
    end
})

return uie
