-- Focus navigation for the keyboard (Tab / Shift+Tab) and gamepad (d-pad/stick).
--
-- Everything here is Olympus-side; the OlympUI submodule is used as-is (stock
-- has no keyboard-focus concept):
--   - focus targets are discovered purely by element type (buttons, fields,
--     list items and menu items), not by any olympui flag
--   - Tab / Shift+Tab cycle the cursor in document order through ui.keyFocusMove
--     (defined here, since stock olympui ships no equivalent)
--   - activation is synthesized through the element's own click/onClick path,
--     which is the same code path a mouse click takes
--   - a `focused` visual-field sync (keynav.syncFocus) mirrors the focus cursor
--   - gamepad-appropriate directional movement (keynav.moveDir)
--   - keeping focus inside open (modal) alerts

local ui = require("ui.main")
local alert = require("alert")

local keynav = {}

local prevFocusedEl = false

-- While the cursor sits inside an overlay that keynav moved it into (an alert
-- picker opened from a dropdown, or an open submenu), these remember the
-- overlay and the element that opened it, so the cursor can return there once
-- the overlay closes.
local popupFocusContainer = false
local popupFocusOwner = false


-- Element types a navigation cursor can land on. Ancestor types are inherited,
-- so drop-downs, buttonGreen and the like are covered automatically; containers
-- (rows, columns, groups, scrollboxes, ...) are not.
local FOCUSABLE = {
    button = true,
    field = true,
    listItem = true,
    menuItem = true,
}

local function isActionType(c)
    local types = c and c.__types
    if not types then
        return false
    end
    for i = 1, #types do
        if FOCUSABLE[types[i]] then
            return true
        end
    end
    return false
end


-- Keep the elements' `focused` field (which drives their highlight styling) in
-- sync with the actual focus cursor ui.focusing.
function keynav.syncFocus()
    local focusing = ui.focusing

    if (not focusing) or not focusing.isRooted then
        -- The cursor points at nothing (olympui already dropped it once the
        -- focused element left the tree) or at a removed element. If keynav had
        -- pinned it into an overlay that has now closed, walk it back to the
        -- element that opened the overlay. If the overlay is still alive (a
        -- freshly spawned overlay is only root-walkable after the next collect
        -- pass), the cursor is simply left where keynav put it.
        if popupFocusOwner
            and popupFocusContainer
            and not popupFocusContainer.alive
            and popupFocusOwner.isRooted then
            ui.focusing = popupFocusOwner
            focusing = popupFocusOwner
            popupFocusContainer = false
            popupFocusOwner = false
        elseif popupFocusContainer and popupFocusContainer.alive then
            return
        else
            ui.focusing = false
            focusing = nil
            popupFocusContainer = false
            popupFocusOwner = false
        end
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
    if not isActionType(c) then
        return false
    end
    if c.visible == false or not c.onscreen then
        return false
    end
    if not (c.interactive and c.interactive >= 1) then
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
    if not isActionType(c) or c.visible == false then
        return false
    end
    if not (c.interactive and c.interactive >= 1) then
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


local function applyFocusRaw(next)
    local prev = ui.focusing
    if prev and prev ~= next then
        ui.interactiveIterate(prev, "onUnfocus")
    end
    ui.focusing = next

    -- Input fields enable OS key repeat while focused, but stock olympui only
    -- does that from a mouse press (input's onPress), so a field focused via
    -- Tab / gamepad would unfocus into a nil setKeyRepeat argument (its
    -- onUnfocus restores the key-repeat state it recorded on focus). Mirror
    -- the mouse path: remember the current state, then switch repeat on.
    if next.is and next:is("field") and prev ~= next then
        next.__wasKeyRepeat = love.keyboard.hasKeyRepeat()
        love.keyboard.setKeyRepeat(true)
    end

    -- Inside a list, focus doubles as the list's selected cursor so the move is
    -- visible and the underlying list keeps track of it.
    if next.is and next:is("listItem") then
        local owner = next.owner or next.parent
        if owner and owner.isList then
            next.selected = true
        end
    end

    return true
end


local function applyFocus(next)
    applyFocusRaw(next)
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


-- Document-order cycling within a single subtree (the whole UI for Tab, or just
-- a modal alert so focus can't escape it).
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
-- only travels within that alert's subtree. Stock olympui ships no equivalent,
-- so this is defined from the Olympus side.
if not ui.keyFocusMove then
    function ui.keyFocusMove(step, startEl)
        local container = ui.root
        if alert.count and alert.count > 0 then
            local children = alert.root.children
            if children[#children] then
                container = children[#children]
            end
        end
        local handled = moveWithin(step, container, startEl)
        keynav.syncFocus()
        return handled
    end
end

-- Ties Tab/Shift+Tab and the arrow keys into the input pipeline.
local origKeyPressed = ui.keypressed
function ui.keypressed(key, scancode, isrepeat)
    local handled = origKeyPressed(key, scancode, isrepeat)

    -- Sync first: returns the cursor to an overlay's owner the moment the
    -- overlay is gone, before any navigation runs off the stale position.
    keynav.syncFocus()

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


-- Move the focus cursor into a freshly opened dropdown / topbar submenu. The
-- submenu is reachable either on the invoker itself (dropdown) or on its parent
-- (menuItem stores it on the topbar). `preferred` is the current selection and
-- gets pre-highlighted when it is one of the options.
local function focusSubmenu(submenu, preferred)
    -- A freshly spawned overlay is not root-walkable (parent pointers are only
    -- refreshed on the next collect), but is still alive; a closed one is dead.
    if not submenu or not (submenu.isRooted or submenu.alive) then
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
                -- Remember the overlay so picking an option (which removes it)
                -- can return the cursor to its owner.
                popupFocusContainer = submenu
                popupFocusOwner = submenu.owner
                return applyFocusRaw(c)
            end
        end
    end
    if first then
        popupFocusContainer = submenu
        popupFocusOwner = submenu.owner
        -- applyFocusRaw: a freshly spawned overlay's content only gets its
        -- parent/root pointers refreshed during the next ui update, so the
        -- sync pass of applyFocus would (incorrectly) drop the cursor here.
        return applyFocusRaw(first)
    end
    return false
end

local function focusOpenSubmenu(focus, preferred)
    local submenu = focus.submenu or (focus.parent and focus.parent.submenu)
    if not submenu then
        return false
    end
    return focusSubmenu(submenu, preferred)
end


-- A newly spawned modal alert (an "alert picker" such as the theme/background
-- dropdowns in Olympus) that the cursor can be pinned into. The overlay itself
-- is still rooted but its content may not have a computed `onscreen` flag yet,
-- so on-screen-ness is not required when targeting it.
local function popupFocusable(c)
    if not isActionType(c) or c.visible == false then
        return false
    end
    if not (c.interactive and c.interactive >= 1) then
        return false
    end
    local getEnabled = c.getEnabled
    if getEnabled then
        return getEnabled(c) ~= false
    end
    return c._enabled ~= false and c.enabled ~= false
end


-- Focus the first interactive element inside a just-opened alert. Returns false
-- when nothing new opened (or the topmost overlay is not of the alert kind).
local function focusNewestAlert(owner)
    local children = alert.root.children
    local container = children and children[#children]
    if not (container and container.popup and container.closing ~= true) then
        return false
    end
    local all = {}
    collectIn(container, all)
    for i = 1, #all do
        local c = all[i]
        if popupFocusable(c) then
            popupFocusContainer = container
            popupFocusOwner = owner or false
            return applyFocusRaw(c)
        end
    end
    return false
end


-- Dropdowns inherit olympui's button base, whose onKeyRelease passes click
-- coordinates to the dropdown's `cb` instead of the item's data, corrupting
-- whatever the callback stores. So a keyboard/gamepad press on a dropdown is
-- turned into its mouse click instead (spawning the submenu / opening pickers).
local function confirmDropdown(focus)
    focus:onClick(focus.screenX + focus.width / 2, focus.screenY + focus.height / 2, 1)
    if focusSubmenu(focus.submenu, focus.selected) then
        return true
    end
    -- Several Olympus dropdowns turn into alert pickers instead of a submenu
    -- (theme, background, ...); move the cursor into the opened picker.
    return focusNewestAlert(focus)
end


-- Activate the currently focused element, reusing the exact same code path the
-- keyboard's Return key takes (press + release through the interactive chain),
-- which is equivalent to a mouse click. List/menu items get their click
-- synthesized directly, because stock olympui only wires up key activation for
-- buttons, fields and checkboxes. Returns true if anything consumed it.
function keynav.confirm()
    local focus = ui.focusing
    if not focus then
        return false
    end
    if isDropdown(focus) then
        return confirmDropdown(focus)
    end

    local cx = focus.screenX + focus.width / 2
    local cy = focus.screenY + focus.height / 2

    if focus.is and focus:is("menuItem") then
        if focus.onClick then
            focus:onClick(cx, cy, 1)
        end
        -- Open the spawned submenu (topbar menus, nested options dropdowns)
        -- and pin the focus cursor inside it, like confirmDropdown does. When
        -- instead something like an alert picker pops up, hop into that.
        if focusOpenSubmenu(focus, focus.selected) then
            return true
        end
        return focusNewestAlert(focus) or true
    end

    if focus.is and focus:is("listItem") then
        if focus.onClick then
            focus:onClick(cx, cy, 1)
        end
        -- Selecting an option commonly closes its overlay (submenu/picker);
        -- syncFocus() then returns the cursor to the overlay's owner.
        return true
    end

    local el, handled = ui.interactiveIterate(focus, "onKeyPress", "return", false, false)
    local released = ui.interactiveIterate(focus, "onKeyRelease", "return")
    if handled or released then
        -- A button was activated; if this opened an alert picker, move the
        -- cursor into it so the keyboard user can reach its options directly.
        focusNewestAlert(focus)
        return true
    end
    return focusNewestAlert(focus) or false
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
            popupFocusContainer = false
            popupFocusOwner = false
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
        popupFocusContainer = false
        popupFocusOwner = false
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