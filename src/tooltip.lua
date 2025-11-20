-- adapted from the Lönn map editor, also based on OlympUI: https://github.com/CelestialCartographers/Loenn/blob/ui-olympUI/src/ui/tooltip.lua

local ui = require("ui")
local uie = require("ui.elements")
local uiu = require("ui.utils")

local log = require("logger")("tooltip")

local tooltipWaitDuration = 0.5
local lastX, lastY = 0, 0
local waitedDuration = 0

local targetElement
local tooltipExists = false
local tooltipWindow

local tooltipHandler = {}

local function getUsableSize()
    local root = ui.root
    return root.width - 32, root.height - 32
end

local function moveWindow(window, newX, newY, clamp)
    local usableWidth, usableHeight = getUsableSize()
    local currentX, currentY = window.x, window.y

    if clamp ~= false then
        newX = math.max(math.min(usableWidth - window.width + 16, newX), 16)
        newY = math.max(math.min(usableHeight - window.height + 16, newY), 16)
    end

    if math.abs(currentX - newX) > 4 or math.abs(currentY - newY) > 4 then
        window.x = newX
        window.realX = newX
        window.y = newY
        window.realY = newY

        if window.parent then
            window.parent:reflow()
        end

        ui.root:recollect(false, true)
    end
end

function tooltipHandler.tooltipWindowUpdate(orig, self, dt)
    orig(self, dt)

    local cursorX, cursorY = love.mouse.getPosition()
    local hovered = ui.hovering
    local waitedEnough = waitedDuration >= tooltipWaitDuration

    if not waitedEnough then
        if cursorX == lastX and cursorY == lastY then
            waitedDuration = waitedDuration + dt

        else
            lastX, lastY = cursorX, cursorY
            waitedDuration = 0
        end
    end

    if hovered ~= targetElement then
        waitedDuration = 0

        if hovered then
            local tooltipText = rawget(hovered, "tooltipText")
            tooltipWaitDuration = rawget(hovered, "tooltipWaitDuration") or 0.5

            if tooltipText then
                tooltipWindow.children[1]:setText(tooltipText)
                log.debug("Hovering over element with tooltip", tooltipText)
            end

            targetElement = hovered
            tooltipExists = not not tooltipText

        else
            targetElement = false
            tooltipExists = false
        end
    end

    if tooltipExists and waitedEnough then
        moveWindow(tooltipWindow, cursorX, cursorY - tooltipWindow.height)

    elseif tooltipWindow.x ~= -1024 or tooltipWindow.y ~= -1024 then
        moveWindow(tooltipWindow, -1024, -1024, false)
    end
end

function tooltipHandler.getTooltipWindow()
    if not tooltipWindow then
        tooltipWindow = uie.panel({
            uie.label("Test")
        }):with({
            interactive = -2,
            updateHidden = true
        }):hook({
            update = tooltipHandler.tooltipWindowUpdate
        })
    end

    return tooltipWindow
end

return tooltipHandler