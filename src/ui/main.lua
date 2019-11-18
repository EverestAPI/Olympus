local uiu = require("ui.utils")
local uin = require("ui.native")

local ui = {}

ui.debug = false

ui.hovering = nil
ui.dragging = nil
ui.draggingCounter = 0
ui.focusing = nil
ui.mousePresses = 0

local prevWidth
local prevHeight
function ui.update()
    local root = ui.root
    if not root then
        return
    end

    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()

    root.focused = love.window.hasFocus()
    
    if prevWidth ~= width or prevHeight ~= height then
        prevWidth = width
        prevHeight = height

        root.width = width
        root.innerWidth = width
        root.height = height
        root.innerHeight = height
        root:reflow()

        if not root.all then
            root:layoutLazy()
            root:layoutLateLazy()
        end
    end

    local mouseX, mouseY = love.mouse.getPosition()
    local mouseState = false
    if uin then
        mouseX, mouseY, mouseState = uin.getGlobalMouseState()
        local windowX, windowY = uin.getWindowPosition()
        mouseX = mouseX - windowX
        mouseY = mouseY - windowY
        mouseState = mouseState
    else
        mouseState = false
    end

    ui.mousemoved(mouseX, mouseY)

    ui.delta = love.timer.getDelta()

    local all = root.all
    for i = 1, #all do
        local c = all[i]
        local cb = c.update
        if cb then
            cb(c)
        end
    end

    root:layoutLazy()
    root:layoutLateLazy()

    if root.recollecting then
        root:collect(false)
    end

end


function ui.draw()
    local root = ui.root
    
    root:drawLazy()
end


function ui.interactiveIterate(el, funcid, ...)
    if not el then
        return nil
    end

    local parent = el.parent
    if parent then
        parent = ui.interactiveIterate(parent, funcid, ...)
    end

    if funcid then
        local func = el[funcid]
        if func then
            func(el, ...)
        end
    end
    
    if el.interactive == 0 then
        return parent
    end
    return el
end


function ui.mousemoved(x, y, dx, dy)
    local ui = ui
    local root = ui.root
    if not root then
        return
    end

    if not dx or not dy then
        if not ui.mouseX or not ui.mouseY then
            dx = 0
            dy = 0
        else
            dx = x - ui.mouseX
            dy = y - ui.mouseY
        end
    end
    ui.mouseX = x
    ui.mouseY = y

    local hoveringPrev = ui.hovering
    local hoveringNext = root:getChildAt(x, y)
    ui.hovering = hoveringNext
    
    if hoveringPrev ~= hoveringNext then
        if hoveringPrev then
            local cb = hoveringPrev.onLeave
            if cb then
                cb(hoveringPrev)
            end
        end
        if hoveringNext then
            local cb = hoveringNext.onEnter
            if cb then
                cb(hoveringNext)
            end
        end
    end

    if dx ~= 0 or dy ~= 0 then
        local dragging = ui.dragging
        if dragging then
            local cb = dragging.onDrag
            if cb then
                cb(dragging, x, y, dx, dy)
            end
        end
    end
end

function ui.mousepressed(x, y, button, istouch, presses)
    local ui = ui

    if ui.mousePresses == 0 and uin then
        uin.captureMouse(true)
    end
    ui.mousePresses = ui.mousePresses + presses

    local root = ui.root
    if not root then
        return
    end

    ui.draggingCounter = ui.draggingCounter + 1

    local hovering = root:getChildAt(x, y)
    if ui.dragging == nil or ui.dragging == hovering then
        local el = ui.interactiveIterate(hovering, "onPress", x, y, button, true)
        ui.dragging = el
        ui.focusing = el
    else
        ui.interactiveIterate(hovering, "onPress", x, y, button, false)
    end
end

function ui.mousereleased(x, y, button, istouch, presses)
    local ui = ui

    ui.mousePresses = ui.mousePresses - presses
    if ui.mousePresses == 0 and uin then
        uin.captureMouse(false)
    end

    local root = ui.root
    if not root then
        return
    end

    ui.draggingCounter = ui.draggingCounter - 1

    local dragging = ui.dragging
    if dragging then
        if ui.draggingCounter == 0 then
            ui.dragging = nil
            ui.interactiveIterate(dragging, "onRelease", x, y, button, false)
            if dragging == ui.interactiveIterate(root:getChildAt(x, y)) then
                ui.interactiveIterate(dragging, "onClick", x, y, button)
            end
        else
            ui.interactiveIterate(dragging, "onRelease", x, y, button, true)
        end
    else
        local hovering = root:getChildAt(x, y)
        if hovering then
            ui.interactiveIterate(dragging, "onRelease", x, y, button, false)
        end
    end
end

function ui.wheelmoved(dx, dy)
    local ui = ui
    local root = ui.root
    if not root then
        return
    end

    local hovering = ui.hovering
    if hovering then
        ui.interactiveIterate(hovering, "onScroll", ui.mouseX, ui.mouseY, dx, dy)
    end
end


local hookedLove = false
function ui.hookLove()
    if hookedLove then
        return
    end
    hookedLove = true

    uiu.hook(love, {
        mousepressed = function(orig, ...)
            ui.mousepressed(...)
            return orig(...)
        end,

        mousereleased = function(orig, ...)
            ui.mousereleased(...)
            return orig(...)
        end,

        wheelmoved = function(orig, ...)
            ui.wheelmoved(...)
            return orig(...)
        end
    })
end


return ui
