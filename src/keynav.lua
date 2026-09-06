-- Focus navigation for the keyboard (Tab / Shift+Tab) and gamepad (d-pad/stick).
--
-- OlympUI (the src/ui submodule) provides the core focus mechanism:
--   - ui.keyFocusMove(step)   cycles the focus cursor in document order
--   - keyFocus on elements    marks what is focusable
--   - native Enter/Space      activation on buttons, checkboxes, fields, list items
--
-- The submodule however does not maintain the `focused` field that buttons /
-- fields / checkboxes use to render their highlighted state, and movement is
-- document-order only. This file adds, entirely from the Olympus side:
--   - a `focused` visual-field sync (keynav.syncFocus)
--   - gamepad-appropriate directional movement (keynav.moveDir)
--   - keeping focus inside open (modal) alerts
--   - forwarding Tab / Shift+Tab into ui.keyFocusMove
--
-- The submodule is never touched.

local ui = require("ui.main")
local alert = require("alert")

local keynav = {}

local prevFocusedEl = false


-- Keep the elements' `focused` field (which drives their highlight styling) in
-- sync with the actual focus cursor ui.focusing.
function keynav.syncFocus()
    local focusing = ui.focusing
    if focusing and not focusing.isRooted then
        ui.focusing = false
        focusing = nil
    end

    if prevFocusedEl and prevFocusedEl ~= focusing then
        prevFocusedEl.focused = false
    end
    if focusing and prevFocusedEl ~= focusing then
        focusing.focused = true
        -- Input fields drive their cursor blink off a numeric `blinkTime`
        -- (initialized to 0 by a mouse click in onPress). Seed it the same way
        -- when focus arrives via keyboard/gamepad, so draw's `blinkTime < 0.5`
        -- never compares a boolean.
        if focusing.blinkTime ~= nil and type(focusing.blinkTime) ~= "number" then
            focusing.blinkTime = 0
        end
    end
    prevFocusedEl = focusing
end


local function collectIn(element, all)
    local children = element.children
    if children then
        for i = 1, #children do
            local c = children[i]
            all[#all + 1] = c
            collectIn(c, all)
        end
    end
end

local function isFocusable(c)
    if c.keyFocus ~= true then
        return false
    end
    if c.visible == false or not c.onscreen then
        return false
    end
    local getEnabled = c.getEnabled
    if getEnabled then
        return getEnabled(c) ~= false
    end
    return c._enabled ~= false and c.enabled ~= false
end


-- Whether an element can be a directional navigation target. On-screen
-- elements always qualify; elements scrolled past a scrollbox's fold qualify
-- only when they lie beyond that fold in the requested direction (so the
-- scrollbox can be scrolled to reveal them, and focus never jumps into
-- unrelated hidden panels).
local function scrollBoxOf(el)
    local p = el.parent
    while p do
        if p.is and p:is("scrollbox") then
            return p
        end
        p = p.parent
    end
    return nil
end

local function isScrolledOut(c, dx, dy)
    local box = scrollBoxOf(c)
    if not box or not box.inner then
        return false
    end
    if box.inner.height <= box.height and box.inner.width <= box.width then
        return false
    end
    if dy ~= 0 then
        if dy > 0 then
            return c.screenY + c.height > box.screenY + box.height + 2
        end
        return c.screenY < box.screenY - 2
    end
    if dx > 0 then
        return c.screenX + c.width > box.screenX + box.width + 2
    end
    return c.screenX < box.screenX - 2
end

local function navFocusable(c, dx, dy)
    if c.keyFocus ~= true or c.visible == false then
        return false
    end
    local getEnabled = c.getEnabled
    local enabled
    if getEnabled then
        enabled = getEnabled(c) ~= false
    else
        enabled = c._enabled ~= false and c.enabled ~= false
    end
    if not enabled then
        return false
    end
    if c.onscreen then
        return true
    end
    return isScrolledOut(c, dx, dy)
end

-- Scroll the scrollbox containing `c` so the element is visible again.
local function revealInScrollbox(c)
    local box = scrollBoxOf(c)
    if not box or not box.inner then
        return
    end
    local top = box.screenY
    local bottom = top + box.height
    if c.screenY + c.height > bottom then
        box:onScroll(nil, nil, 0, c.screenY + c.height - bottom + 2, true)
    elseif c.screenY < top then
        box:onScroll(nil, nil, 0, c.screenY - top - 2, true)
    end
end


-- The open dropdown / topbar submenu the focus cursor is currently inside.
-- While inside one, navigation is confined to its own items.
local function submenuOf(el)
    local p = el and el.parent
    while p do
        if p.is and p:is("menuItemSubmenu") then
            return p
        end
        p = p.parent
    end
    return nil
end


-- Navigation targets, honoring alert confinement. The whole tree is walked
-- rather than ui.root.allInteractive, because that collection only contains
-- elements intersecting the viewport -- items scrolled past a scrollbox's fold
-- would never be reachable otherwise.
local function collectNav(dx, dy)
    local nav = {}

    if alert.count and alert.count > 0 then
        local children = alert.root.children
        local container = children[#children]
        if container then
            local all = {}
            collectIn(container, all)
            for i = 1, #all do
                local c = all[i]
                if navFocusable(c, dx, dy) then
                    nav[#nav + 1] = c
                end
            end
        end

    else
        local all = {}
        collectIn(ui.root, all)
        for i = 1, #all do
            local c = all[i]
            if navFocusable(c, dx, dy) then
                nav[#nav + 1] = c
            end
        end
    end

    return nav
end


local function applyFocus(next)
    local prev = ui.focusing
    if prev and prev ~= next then
        ui.interactiveIterate(prev, "onUnfocus")
    end
    ui.focusing = next

    -- Inside a list, focus doubles as the list's selected cursor so the move is
    -- visible and the underlying list keeps track of it.
    if next.is and next:is("listItem") then
        local owner = next.owner or next.parent
        if owner and owner.isList then
            next.selected = true
        end
    end

    keynav.syncFocus()
    return true
end


-- Move into the element spatially in front of the current one, using screen
-- geometry. dx/dy are -1, 0 or 1 (right/down positive, screen coordinates).
-- Falls back to a wrap-around (nearest element to the "column") when nothing is
-- located ahead in the requested direction. Elements hidden below/above a
-- scrollbox's fold are navigable too: they get revealed by scrolling first.
function keynav.moveDir(dx, dy)
    local current = ui.focusing

    -- Inside an open dropdown / topbar submenu, travel stays within it.
    local submenu = submenuOf(current)

    local nav
    if submenu then
        nav = {}
        local all = {}
        collectIn(submenu, all)
        for i = 1, #all do
            local c = all[i]
            if isFocusable(c) then
                nav[#nav + 1] = c
            end
        end
    else
        nav = collectNav(dx, dy)
    end
    if #nav == 0 then
        return false
    end

    if not current then
        for i = 1, #nav do
            if nav[i].onscreen then
                return applyFocus(nav[i])
            end
        end
        return applyFocus(nav[1])
    end

    local cx = current.screenX + current.width / 2
    local cy = current.screenY + current.height / 2

    local aheadWeight = 100000
    local wrapWeight = 100000
    local threshold = 4
    local best, bestScore = nil, math.huge
    local scrolled, scrolledScore = nil, math.huge
    local wrap, wrapScore = nil, math.huge

    for i = 1, #nav do
        local c = nav[i]
        if c ~= current then
            local vx = c.screenX + c.width / 2 - cx
            local vy = c.screenY + c.height / 2 - cy
            local primary = vx * dx + vy * dy
            local perp = math.abs(vx * dy - vy * dx)

            if primary > threshold then
                local score = perp * aheadWeight + primary
                if c.onscreen then
                    if score < bestScore then
                        best, bestScore = c, score
                    end
                elseif score < scrolledScore then
                    scrolled, scrolledScore = c, score
                end
            elseif c.onscreen then
                local score = perp * wrapWeight + math.abs(primary)
                if score < wrapScore then
                    wrap, wrapScore = c, score
                end
            end
        end
    end

    if best then
        return applyFocus(best)
    end
    if scrolled then
        revealInScrollbox(scrolled)
        return applyFocus(scrolled)
    end
    if wrap then
        return applyFocus(wrap)
    end
    return true
end


-- Document-order cycling within a single subtree (used to keep focus inside a
-- modal alert when navigating with Tab).
local function moveWithin(step, container, startEl)
    local all = {}
    collectIn(container, all)

    local focusables = {}
    local focusIndex = nil
    startEl = startEl or ui.focusing
    for i = 1, #all do
        local c = all[i]
        if isFocusable(c) then
            focusables[#focusables + 1] = c
            if c == startEl then
                focusIndex = #focusables
            end
        end
    end

    local count = #focusables
    if count == 0 then
        return false
    end

    local index = focusIndex
        or (step > 0 and 0 or count + 1)
    index = (index - 1 + step) % count + 1
    return applyFocus(focusables[index])
end


-- Document-order focus movement (Tab / Shift+Tab). While an alert is open, it
-- only travels within that alert's subtree.
local origKeyFocusMove = ui.keyFocusMove
function ui.keyFocusMove(step, startEl)
    local handled
    if alert.count and alert.count > 0 then
        local children = alert.root.children
        local container = children[#children]
        handled = container and moveWithin(step, container, startEl)
    else
        handled = origKeyFocusMove(step, startEl)
    end
    keynav.syncFocus()
    return handled
end

-- Ties Tab/Shift+Tab and the arrow keys into the input pipeline.
local origKeyPressed = ui.keypressed
function ui.keypressed(key, scancode, isrepeat)
    local handled = origKeyPressed(key, scancode, isrepeat)

    if key == "tab" then
        local shift = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
        if ui.keyFocusMove(shift and -1 or 1) then
            return true
        end

    elseif key == "up" or key == "down" or key == "left" or key == "right" then
        -- Let text fields keep the arrow keys for cursor movement.
        local focus = ui.focusing
        if not (focus and focus.is and focus:is("field")) then
            local dx = key == "left" and -1 or key == "right" and 1 or 0
            local dy = key == "up" and -1 or key == "down" and 1 or 0
            if keynav.moveDir(dx, dy) then
                return true
            end
        end
    end

    return handled
end

-- Keep the focused visual in sync when the mouse grabs focus as well.
local origMousePressed = ui.mousepressed
function ui.mousepressed(x, y, button, istouch, presses)
    local rv = origMousePressed(x, y, button, istouch, presses)
    keynav.syncFocus()
    return rv
end


local function isDropdown(el)
    return el and el.is and el:is("dropdown")
end


-- Pin focus to a dropdown's submenu. The submenu's update closes it as soon as
-- ui.focusing points outside of it, so we have to move the focus cursor in right
-- after opening it. `preferred` is the dropdown's current selection: when it is
-- one of the available options it is pre-highlighted, otherwise the first item.
local function focusSubmenu(submenu, preferred)
    if not submenu or not submenu.isRooted then
        return false
    end
    local all = {}
    collectIn(submenu, all)
    local first = nil
    for i = 1, #all do
        local c = all[i]
        if isFocusable(c) then
            if not first then
                first = c
            end
            if c == preferred then
                return applyFocus(c)
            end
        end
    end
    if first then
        return applyFocus(first)
    end
    return false
end


-- Dropdowns inherit olympui's button base, whose onKeyRelease passes click
-- coordinates to the dropdown's `cb` instead of the item's data, corrupting
-- whatever the callback stores. So a keyboard/gamepad press on a dropdown is
-- turned into its mouse click instead (spawning the submenu / opening pickers).
local function confirmDropdown(focus)
    focus:onClick(focus.screenX + focus.width / 2, focus.screenY + focus.height / 2, 1)
    focusSubmenu(focus.submenu, focus.selected)
    return true
end


-- Activate the currently focused element, reusing the exact same code path the
-- keyboard's Return key takes (press + release through the interactive chain),
-- which is equivalent to a mouse click. Returns true if anything consumed it.
function keynav.confirm()
    local focus = ui.focusing
    if not focus then
        return false
    end
    if isDropdown(focus) then
        return confirmDropdown(focus)
    end

    local el, handled = ui.interactiveIterate(focus, "onKeyPress", "return", false, false)
    local released = ui.interactiveIterate(focus, "onKeyRelease", "return")
    return handled or released
end


-- Dismiss an open dropdown / topbar submenu (the "back" button acts as an
-- "unselect" while one is up, instead of navigating away). Returns false when
-- there is nothing to dismiss, so the caller can fall back to a real back
-- navigation.
function keynav.cancel()
    local focus = ui.focusing

    local p = focus
    while p do
        if p.is and p:is("menuItemSubmenu") then
            local owner = p.owner
            if owner and owner.submenu == p then
                owner.submenu = false
            end
            p:removeSelf()
            if owner then
                applyFocus(owner)
            end
            return true
        end
        p = p.parent
    end

    if isDropdown(focus) and focus.submenu and focus.submenu.isRooted then
        focus.submenu:removeSelf()
        focus.submenu = false
        return true
    end

    return false
end


-- The native keyboard path has the same dropdown wart: button.onKeyRelease
-- calls the dropdown cb with click coordinates. Route release through the
-- click instead, like a mouse press.
local origKeyReleased = ui.keyreleased
function ui.keyreleased(key, scancode)
    if isDropdown(ui.focusing) and (key == "return" or key == "space") then
        return confirmDropdown(ui.focusing)
    end
    return origKeyReleased(key, scancode)
end


return keynav