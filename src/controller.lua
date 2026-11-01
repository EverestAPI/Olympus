-- Gamepad / joystick support.
--
-- Always active: polls every connected joystick every frame and translates the
-- input into directional focus navigation (keynav.moveDir):
--   - d-pad / any analog stick ... move the focus cursor on screen
--   - A / X button ................ confirm (same code path as a mouse click)
--   - B button ..................... back / close the current thing (controller.onBack)
--
-- The LÖVE build Olympus ships may have the virtual "gamepad" API compiled out of
-- SDL, so every gamepad call is feature-detected and falls back to raw axes, hats
-- and buttons. Both analog sticks and every connected gamepad are honored.
-- Implemented entirely on the Olympus side, the OlympUI submodule is untouched.

local ui = require("ui.main")
local keynav = require("keynav")

local controller = {}

controller.onBack = false

controller.deadzone = 0.35
controller.dirRepeatDelay = 0.18
controller.dirRepeatRate = 0.08

local prevButtons = {}
local dirHeldX, dirHeldY = 0, 0
local dirTimer = 0

local gamepadButtons = {
    "a", "b", "x", "y",
    "back", "guide", "start",
    "leftstick", "rightstick",
    "leftshoulder", "rightshoulder",
    "dpup", "dpdown", "dpleft", "dpright"
}

local function hasGamepadAPI(js)
    return js.getGamepadButton ~= nil and js.getGamepadAxis ~= nil
end

local function stickInput(js, axisOffset)
    local x = js:getAxis(axisOffset)
    local y = js:getAxis(axisOffset + 1)
    if math.abs(x) >= controller.deadzone and math.abs(x) >= math.abs(y) then
        return x < 0 and -1 or 1, 0
    elseif math.abs(y) >= controller.deadzone then
        return 0, y < 0 and -1 or 1
    end
    return 0, 0
end


local function readDirection(js, gp)
    if gp then
        -- Virtual gamepad: d-pad plus both analog sticks.
        if js:getGamepadButton("dpleft") then
            return -1, 0
        elseif js:getGamepadButton("dpright") then
            return 1, 0
        elseif js:getGamepadButton("dpup") then
            return 0, -1
        elseif js:getGamepadButton("dpdown") then
            return 0, 1
        end

        local x = js:getGamepadAxis("leftx")
        local y = js:getGamepadAxis("lefty")
        if math.abs(x) >= controller.deadzone and math.abs(x) >= math.abs(y) then
            return x < 0 and -1 or 1, 0
        elseif math.abs(y) >= controller.deadzone then
            return 0, y < 0 and -1 or 1
        end

        x = js:getGamepadAxis("rightx")
        y = js:getGamepadAxis("righty")
        if math.abs(x) >= controller.deadzone and math.abs(x) >= math.abs(y) then
            return x < 0 and -1 or 1, 0
        elseif math.abs(y) >= controller.deadzone then
            return 0, y < 0 and -1 or 1
        end

        return 0, 0
    end

    -- Raw joystick: d-pad buttons, hat and both analog sticks (left = axes 1/2,
    -- right = axes 3/4). LÖVE's isDown is 1-based, so SDL buttons 11-15 map to
    -- 12 = dpup / 13 = dpdown / 14 = dpleft / 15 = dpright.
    if js:getButtonCount() >= 15 then
        if js:isDown(14) then
            return -1, 0
        elseif js:isDown(15) then
            return 1, 0
        elseif js:isDown(12) then
            return 0, -1
        elseif js:isDown(13) then
            return 0, 1
        end
    end

    if js:getHatCount() >= 1 then
        local hat = js:getHat(1)
        if hat == "l" or hat == "lu" or hat == "ld" then
            return -1, 0
        elseif hat == "r" or hat == "ru" or hat == "rd" then
            return 1, 0
        elseif hat == "u" then
            return 0, -1
        elseif hat == "d" then
            return 0, 1
        end
    end

    if js:getAxisCount() >= 2 then
        local dx, dy = stickInput(js, 1)
        if dx ~= 0 or dy ~= 0 then
            return dx, dy
        end
    end
    if js:getAxisCount() >= 4 then
        local dx, dy = stickInput(js, 3)
        if dx ~= 0 or dy ~= 0 then
            return dx, dy
        end
    end

    return 0, 0
end


local function readConfirmBack(js, gp)
    local confirm = false
    local back = false
    local prev = prevButtons[js:getID()]

    if gp then
        local a = js:getGamepadButton("a")
        local b = js:getGamepadButton("b")
        local x = js:getGamepadButton("x")
        if prev.a == false and (a or x) then
            confirm = true
        end
        if prev.b == false and b then
            back = true
        end
        prev.a = a
        prev.b = b
        prev.x = x

    else
        local count = js:getButtonCount()
        if count >= 1 then
            local a = js:isDown(1)
            local b = count >= 2 and js:isDown(2) or false
            local x = count >= 3 and js:isDown(3) or false
            if prev[1] == false and (a or x) then
                confirm = true
            end
            if prev[2] == false and b then
                back = true
            end
            prev[1] = a
            prev[2] = b
            prev[3] = x
        end
    end

    return confirm, back
end


local function doConfirm()
    local focus = ui.focusing
    if not focus or not focus.isRooted then
        -- Nothing focused yet: just highlight the first focusable element.
        keynav.moveDir(1, 0)
        return
    end
    keynav.confirm()
end


function controller.update()
    if not love.joystick then
        return false
    end

    local sticks = love.joystick.getJoysticks()
    local confirm = false
    local back = false

    for i = 1, #sticks do
        local js = sticks[i]
        local id = js:getID()

        if not prevButtons[id] then
            -- Baseline: treat the current state as "already pressed" so a button
            -- that is held when the controller is connected doesn't fire on spawn.
            prevButtons[id] = {}
            local prev = prevButtons[id]
            if hasGamepadAPI(js) and js:isGamepad() then
                for j = 1, #gamepadButtons do
                    prev[gamepadButtons[j]] = js:getGamepadButton(gamepadButtons[j])
                end
            else
                local count = js:getButtonCount()
                for j = 1, count do
                    prev[j] = js:isDown(j)
                end
            end
        end

        local gp = hasGamepadAPI(js) and js:isGamepad()
        local c, b = readConfirmBack(js, gp)
        confirm = confirm or c
        back = back or b
    end

    if back then
        -- An open dropdown gets dismissed first ("unselect"); only an unused
        -- back button bubbles up to the scene's back navigation.
        if not keynav.cancel() and controller.onBack then
            controller.onBack()
        end
    end
    if confirm then
        doConfirm()
    end

    keynav.syncFocus()

    local dx, dy = 0, 0
    for i = 1, #sticks do
        local gp = hasGamepadAPI(sticks[i]) and sticks[i]:isGamepad()
        dx, dy = readDirection(sticks[i], gp)
        if dx ~= 0 or dy ~= 0 then
            break
        end
    end

    if dx ~= 0 or dy ~= 0 then
        if dx ~= dirHeldX or dy ~= dirHeldY then
            dirHeldX, dirHeldY = dx, dy
            dirTimer = 0
            keynav.moveDir(dx, dy)

        else
            dirTimer = dirTimer + love.timer.getDelta()
            if dirTimer >= controller.dirRepeatDelay then
                dirTimer = controller.dirRepeatDelay - controller.dirRepeatRate
                keynav.moveDir(dx, dy)
            end
        end

    else
        dirHeldX, dirHeldY = 0, 0
        dirTimer = 0
    end

    return true
end


return controller