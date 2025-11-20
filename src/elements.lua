local ui, uiu, uie = require("ui").quick()


uie.add("buttonGreen", {
    base = "button",
    style = {
        normalBG = { 0.2, 0.4, 0.2, 0.8 },
        hoveredBG = { 0.3, 0.6, 0.3, 0.9 },
        pressedBG = { 0.2, 0.6, 0.2, 0.9 }
    }
})

uie.add("listItemGreen", {
    base = "listItem",
    style = {
        normalBG = { 0.2, 0.4, 0.2, 0.8 },
        hoveredBG = { 0.36, 0.46, 0.39, 0.9 },
        pressedBG = { 0.1, 0.5, 0.2, 0.9 },
        selectedBG = { 0.5, 0.8, 0.5, 0.9 }
    }
})

uie.add("listItemYellow", {
    base = "listItem",
    style = {
        normalBG = { 0.5, 0.4, 0.1, 0.8 },
        hoveredBG = { 0.8, 0.7, 0.3, 0.9 },
        pressedBG = { 0.5, 0.4, 0.2, 0.9 },
        selectedBG = { 0.8, 0.7, 0.3, 0.9 }
    }
})

uie.add("modNameLabelColors", {
    -- this dummy UI element makes the mod name label colors in Manage Installed Mods themable.
    -- colors calculated from https://learn.microsoft.com/en-us/dotnet/api/system.windows.media.colors
    style = {
        normalColor = { 1, 1, 1, 1 }, -- white
        disabledColor = { 1, 1, 1, 0.5 }, -- white but half-transparent
        favoriteColor = { 1, 0.0784313725, 0.5764705882, 1 }, -- deep pink
        dependencyColor = { 0.8549019608, 0.6470588235, 0.1254901961, 1 }, -- goldenrod
        dependencyOfFavoriteColor = { 1, 0.7137254902, 0.7568627451, 1 }, -- light pink
    }
})

uie.add("greentext", {
    style = { color = { 0.5, 0.8, 0.5, 1 } }
})

-- A simple clickable icon that can be toggled on and off. Child classes should override getColor()
-- The fading mechanic is the same as in uie.button
uie.add("clickableIcon", {
    base = "group",
    interactive = 1,

    style = {
        padding = 0,
        spacing = 0,
        size = 20,
        icon = "heart",

        color = {1, 1, 1, 1},
        toggleValueOnClick = false,

        fadeDuration = 0.2
    },

    init = function(self, value, cb)
        uie.group.init(self)

        self.cb = cb
        self._enabled = true
        self._value = value or false

        self.icon = uie.icon(self.style.icon)
        self.icon.style.color = self:getColor()
        local width, height = self.icon.image:getDimensions()
        self.icon = self.icon:with(uiu.at(-0.5 - width / 2, -0.5 - height / 2))
        self:addChild(self.icon)

        self.width = self.style.size
        self.height = self.style.size

        self:hook({
            layout = function(orig, self)
                local parent = self.parent
                local size = self.style.size
                if parent and parent.label then
                    size = math.ceil(parent.label.height / 2) * 2
                end
                self.icon.width = size
                self.icon.height = size
                self.width = size
                self.height = size
                orig(self)
            end
        })
    end,

    revive = function(self)
        self._fadeFGStyle, self._fadeFGPrev, self._fadeFG = {}, false, false
    end,

    setValue = function(self, value)
        self._value = value
    end,

    getValue = function(self) return self._value end,

    setEnabled = function(self, value)
        self._enabled = value
        self.interactive = value and 1 or -1
    end,

    getColor = function(self)
        return self.icon.style.color
    end,

    update = function(self, dt)
        local style = self.style
        local fg, fgPrev, fgNext = self._fadeFGStyle, self._fadeFG, self:getColor()

        local faded = false
        faded, self.icon.style.color, fgPrev, self._fadeFGPrev, self._fadeFG = uiu.fadeSwap(faded, fg, self._fadeFGPrev, fgPrev, fgNext)

        local fadeTime = faded and 0 or self._fadeTime
        local fadeDuration = style.fadeDuration
        if fadeTime < fadeDuration then
            fadeTime = fadeTime + dt
            local f = 1 - fadeTime / fadeDuration
            f = f * f * f * f * f
            f = 1 - f

            faded = uiu.fade(faded, f, fg, fgPrev, fgNext)

            if faded then
                self:repaint()
            end

            self._fadeTime = fadeTime
        end
    end,

    onClick = function(self, x, y, button)
        if self._enabled and button == 1 then
            if self.style.toggleValueOnClick then
                self:setValue(not self._value)
            end
            if self.cb then
                self:cb(self._value)
            end
        end
    end
})

-- Heart icon that can be toggled on and off, typically used to mark favorites
uie.add("heart", {
    base = "clickableIcon",

    style = {
        icon = "heart",
        activeColor = {1, 0, 0, 1},
        activeHoverColor = {1, 0.3, 0.3, 1},
        inactiveColor = {0.5, 0.5, 0.5, 1},
        inactiveHoverColor = {0.7, 0.4, 0.4, 1},
        toggleValueOnClick = true
    },

    getColor = function(self)
        if self._value then
            return self.hovered and self.style.activeHoverColor or self.style.activeColor
        else
            return self.hovered and self.style.inactiveHoverColor or self.style.inactiveColor
        end
    end
})

-- Warning icon that can be toggled on and off, typically used to mark warnings
uie.add("warning", {
    base = "clickableIcon",

    style = {
        icon = "warning",
        color = { 1, 0.9, 0, 1 },
        hoverColor = { 1, 1, 0.6, 1 },
        toggleValueOnClick = false
    },

    getColor = function(self)
        local color = { table.unpack(self.hovered and self.style.hoverColor or self.style.color) }
        if not self._value then
            color[4] = 0
        end
        return color
    end
})

-- Dropdown with sub-options optionally coming out of the options
uie.add("dropdownWithSubmenu", {
    base = "dropdown",

    getItemCached = function(self, entry, i)
        local cache = self._itemsCache
        local item = cache[i]
        if not item then
            local dropdown = self

            if entry.submenu then
                local itemContainer = {}

                local submenuEntries = uiu.map(entry.submenu, function(subentry)
                    return {subentry.text, function(self)
                        -- call the event listener
                        dropdown:cb(subentry.data)

                        -- change the selected values
                        dropdown.selected = itemContainer.item
                        self.parent.selected = self
                        dropdown.selectedSubIndex = uie.list.getSelectedIndex(self.parent)
                        dropdown.text = subentry.dropdownText or self.text

                        -- close everything
                        dropdown.submenu:removeSelf()
                    end}
                end)

                item = uie.menuItem(entry.text, submenuEntries):with({
                    owner = dropdown
                }):hook({
                    onClick = function(orig, self, x, y, button)
                        orig(self, x, y, button)
                        self.parent.submenu.isList = true
                        self.parent.submenu.enabled = true
                        if dropdown.selected == itemContainer.item then
                            self.parent.submenu.selected = self.parent.submenu.children[dropdown.selectedSubIndex]
                        end
                    end
                })

                itemContainer["item"] = item
            else
                item = uie.menuItem(entry.text, function(self)
                    -- call the event listener
                    dropdown:cb(entry.data)

                    -- change the selected values
                    dropdown.text = self.text
                    dropdown.selected = self

                    -- close everything
                    dropdown.submenu:removeSelf()
                end):with({
                    owner = dropdown
                })
            end

            cache[i] = item
        end

        item:reflow()
        return item
    end
})


return uie
