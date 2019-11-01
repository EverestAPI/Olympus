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
        normalBG = { 0.3, 0.3, 0.3, 1 },
        disabledBG = { 0.225, 0.225, 0.225, 1 },
        hoveredBG = { 0.325, 0.325, 0.325, 1 },
        pressedBG = { 0.275, 0.275, 0.275, 1 },
        bgFadeDuration = 0.2
    },

    init = function(self, text, cb)
        uie.__row.init(self, { uie.label(text):as("label") })
        self.cb = cb
        self.enabled = true
        self.style.bg = {}
    end,

    getEnabled = function(self)
        return self.__enabled
    end,

    setEnabled = function(self, value)
        self.__enabled = value
        if value then
            self.interactive = 1
        else
            self.interactive = 0
        end
    end,

    getText = function(self)
        return self._label.text
    end,

    setText = function(self, value)
        self._label.text = value
    end,

    update = function(self)
        local style = self.style
        local bgPrev = style.bg
        local bg = bgPrev

        if not self.enabled then
            bg = style.disabledBG
        elseif self.pressed then
            bg = style.pressedBG
        elseif self.hovered then
            bg = style.hoveredBG
        else
            bg = style.normalBG
        end

        local bgTime

        if self.__bg ~= bg then
            self.__bgPrev = bgPrev or bg
            self.__bg = bg
            bgTime = 0
        else
            bgTime = self.__bgTime
        end

        local bgFadeDuration = style.bgFadeDuration
        if #bgPrev ~= 0 and bgTime < bgFadeDuration then
            local f = bgTime / bgFadeDuration
            bg = {
                bgPrev[1] + (bg[1] - bgPrev[1]) * f,
                bgPrev[2] + (bg[2] - bgPrev[2]) * f,
                bgPrev[3] + (bg[3] - bgPrev[3]) * f,
                bgPrev[4] + (bg[4] - bgPrev[4]) * f,
            }
            bgTime = bgTime + ui.delta
        end

        self.__bgTime = bgTime
        style.bg = bg
    end,

    onClick = function(self, x, y, button)
        local cb = self.cb
        if cb and button == 1 then
            cb(self, x, y, button)
        end
    end
})


return uie
