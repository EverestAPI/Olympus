local uie = require("ui.elements.main")
local uiu = require("ui.utils")

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
