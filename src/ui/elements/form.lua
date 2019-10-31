local ui = require("ui.main")
local uie = require("ui.elements.main")
require("ui.elements.basic")
require("ui.elements.layout")

-- Basic button, behaving like a row with a label.
uie.add("button", {
    base = "row",

    style = {
        padding = 8,
        spacing = 8,
        bg = { 0.3, 0.3, 0.3, 1 }
    },

    interactive = 1,

    init = function(self, text, cb)
        uie.__row.init(self, { uie.label(text):as("label") })
        self.cb = cb
        self.enabled = true
    end,

    getText = function(self)
        return self._label.text
    end,

    setText = function(self, value)
        self._label.text = value
    end,

    onClick = function(self, x, y, button)
        local cb = self.cb
        if cb and button == 1 then
            cb(self, x, y, button)
        end
    end
})


return uie
