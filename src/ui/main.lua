local ui = {}

ui.hovering = nil
ui.dragging = nil
ui.draggingCounter = 0
ui.focusing = nil
ui.mousemoving = false

function ui.update()
    local root = ui.root
    if not root then
        return
    end

    if not ui.mousemoving then
        local mouseX, mouseY = love.mouse.getPosition()
        ui.mousemoved(mouseX, mouseY, 0, 0)
    end
    ui.mousemoving = false

    ui.delta = love.timer.getDelta()

    local all = root.all
    if not all then
        root:collect(true)
        all = root.all
    end

    for i = 1, #all do
        local c = all[i]
        local cb = c.update
        if cb then
            cb(c)
        end
    end

    root:layoutLazy()
    root:layoutLateLazy()

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

    if ui.mousemoving then
        return
    end
    ui.mousemoving = true

    local hoveringPrev = ui.hovering
    local hoveringNext = root:getChildAt(x, y)
    ui.hovering = hoveringNext
    
    if hoveringPrev ~= hoveringNext then
        if hoveringPrev then
            local cb = hoveringPrev.onEnter
            if cb then
                cb(hoveringPrev)
            end
        end
        if hoveringNext then
            local cb = hoveringNext.onLeave
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

function ui.mousepressed(x, y, button)
    local ui = ui
    local root = ui.root
    if not root then
        return
    end

    ui.draggingCounter = ui.draggingCounter + 1

    local hovering = root:getChildAt(x, y)
    if hovering then
        if ui.dragging == nil or ui.dragging == hovering then
            local el = ui.interactiveIterate(hovering, "onPress", x, y, button, true)
            ui.dragging = el
            ui.focusing = el
        else
            ui.interactiveIterate(hovering, "onPress", x, y, button, false)
        end
    end
end

function ui.mousereleased(x, y, button)
    local ui = ui
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


return ui
