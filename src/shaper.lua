local utils = require("utils")
local uiStatus, ui = pcall(require, "ui")

local shaper = {}


function shaper.tonumbers(...)
    local input = {...}
    local output = {}
    for i = 1, #input do
        output[i] = tonumber(input[i])
    end
    return table.unpack(output)
end


function shaper.drawTextDebug(r, g, b, a, x, y, text)
    local font = ui and ui.fontDebug or nil

    x = math.round(x)
    y = math.round(y)

    love.graphics.setColor(r * 0.1, g * 0.1, b * 0.1, a * a * a)
    local pos = love.math.newTransform(x, y)
    pos:translate(0, -1)
    love.graphics.print(text, font, pos)
    pos:translate(0, 2)
    love.graphics.print(text, font, pos)
    pos:translate(-1, -1)
    love.graphics.print(text, font, pos)
    pos:translate(2, 0)
    love.graphics.print(text, font, pos)
    pos:translate(-1, 0)

    love.graphics.setColor(r, g, b, a)
    love.graphics.print(text, font, pos)
end


function shaper.drawSegment(seg, xo, yo)
    love.graphics.push()
    love.graphics.translate(xo, yo)

    love.graphics.setLineWidth(3)
    local p = {}

    for ji = 1, #seg.joins, 2 do
        local x, y = seg.joins[ji], seg.joins[ji + 1]
        for i = 1, 32 do
            local f = i / 32 * math.pi * 2
            p[(i - 1) * 2 + 1] = x + math.sin(f) * 4
            p[(i - 1) * 2 + 2] = y + math.cos(f) * 4
        end

        love.graphics.line(p)

        love.graphics.circle("fill", x, y, 4)
    end

    love.graphics.setLineWidth(12)
    love.graphics.line(seg.path)

    love.graphics.pop()
end


function shaper.drawSegmentDebug(seg, xo, yo)
    love.graphics.push()
    love.graphics.translate(xo, yo)

    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.setLineWidth(5)
    love.graphics.line(seg.path[1], seg.path[2], seg.path[#seg.path - 1], seg.path[#seg.path])

    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.circle("fill", seg.path[1], seg.path[2], 4)

    love.graphics.setColor(0, 0, 0, 1)
    for i = 3, #seg.path, 2 do
        love.graphics.circle("fill", seg.path[i], seg.path[i + 1], 3)
    end

    love.graphics.setColor(0.8, 0.8, 0, 0.8)
    love.graphics.setLineWidth(1)
    love.graphics.line(unpack(seg.path))

    love.graphics.setColor(1, 0, 0, 1)
    for i = 1, #seg.joins, 2 do
        love.graphics.circle("fill", seg.joins[i], seg.joins[i + 1], 1)
    end

    love.graphics.pop()

    shaper.drawTextDebug(1, 1, 1, 1, xo + seg.path[1], yo + seg.path[2], seg.name)
end


function shaper.drawShape(shape, xo, yo)
    for i = 1, #shape do
        shape[i]:draw(xo, yo)
    end
end


function shaper.drawShapeDebug(shape, xo, yo)
    love.graphics.push()
    love.graphics.translate(xo, yo)

    love.graphics.setColor(0.5, 0.5, 1, 0.1)
    love.graphics.rectangle("fill", 0, 0, shape.width, shape.height)
    love.graphics.setColor(0, 0, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", 0, 0, shape.width, shape.height)

    love.graphics.pop()

    for i = 1, #shape do
        shape[i]:drawDebug(xo, yo)
    end
end


function shaper.parsePath(data)
    local path = { 0, 0 }
    local lengths = {}
    local joins = {}

    local cmd
    local x = 0
    local y = 0

    local pos = 1

    local function get(pattern)
        pattern = "^(" .. pattern .. ")"
        local rv = {data:match(pattern, pos)}
        if rv[1] then
            pos = pos + #rv[1]
            if rv[2] then
                table.remove(rv, 1)
            end
        end
        return table.unpack(rv)
    end

    local function getXY(count)
        if not count then
            return shaper.tonumbers(get("(-?[%d.]+)[, ]?(-?[%d.]+)[, ]?"))
        end
        local pattern = ""
        for i = 1, count do
            pattern = pattern .. "(-?[%d.]+)[, ]?"
        end
        return shaper.tonumbers(get(pattern))
    end

    local function line(x2, y2)
        if x == x2 and y == y2 then
            return
        end

        path[#path + 1] = x2
        path[#path + 1] = y2
        lengths[#lengths + 1] = math.sqrt((x2 - x) * (x2 - x) + (y2 - y) * (y2 - y))
        x, y = x2, y2
    end

    local function join()
        if joins[#joins - 1] ~= x or joins[#joins] ~= y then
            joins[#joins + 1] = x
            joins[#joins + 1] = y
        end
    end

    while true do
        cmd = get("%D")
        if not cmd then
            break
        end

        if cmd == "M" then
            x, y = getXY()
            path[1] = x
            path[2] = y
            join()

        elseif cmd == "L" then
            join()
            line(getXY())
            join()

        elseif cmd == "A" then
            local rx, ry, angle, isBig, isSweepPositive, x2, y2 = getXY(7)

            if rx == 0 and ry == 0 then
                line(x2, y2)

            else
                -- Based off of https://github.com/vvvv/SVG/blob/master/Source/Paths/SvgArcSegment.cs

                rx = math.abs(rx)
                ry = math.abs(ry)
                isBig = isBig == 1
                isSweepPositive = isSweepPositive == 1

                local function calcVectorAngle(ux, uy, vx, vy)
                    local ta = math.atan2(uy, ux)
                    local tb = math.atan2(vy, vx)

                    if tb >= ta then
                        return tb - ta
                    end

                    return math.pi * 2 - (ta - tb)
                end

                local sinPhi = math.sin(angle * math.pi / 180)
                local cosPhi = math.cos(angle * math.pi / 180)

                local x1dash = cosPhi * (x - x2) / 2 + sinPhi * (y - y2) / 2
                local y1dash = -sinPhi * (x - x2) / 2 + cosPhi * (y - y2) / 2

                local root
                local numerator = rx * rx * ry * ry - rx * rx * y1dash * y1dash - ry * ry * x1dash * x1dash

                if numerator < 0 then
                    local s = math.sqrt(1 - numerator / (rx * rx * ry * ry))
                    rx = rx * s
                    ry = ry * s
                    root = 0

                else
                    local f
                    if (isBig and isSweepPositive) or (not isBig and not isSweepPositive) then
                        f = -1
                    else
                        f = 1
                    end
                    root = f * math.sqrt(numerator / (rx * rx * y1dash * y1dash + ry * ry * x1dash * x1dash))
                end

                local cxdash = root * rx * y1dash / ry
                local cydash = -root * ry * x1dash / rx

                local cx = cosPhi * cxdash - sinPhi * cydash + (x + x2) / 2
                local cy = sinPhi * cxdash + cosPhi * cydash + (y + y2) / 2

                local theta1 = calcVectorAngle(1, 0, (x1dash - cxdash) / rx, (y1dash - cydash) / ry)
                local dtheta = calcVectorAngle((x1dash - cxdash) / rx, (y1dash - cydash) / ry, (-x1dash - cxdash) / rx, (-y1dash - cydash) / ry)

                if not isSweepPositive and dtheta > 0 then
                    dtheta = dtheta - 2 * math.pi
                elseif isSweepPositive and dtheta < 0 then
                    dtheta = dtheta + 2 * math.pi
                end

                local segments = math.ceil(math.abs(dtheta / (math.pi / 2)))
                local delta = dtheta / segments
                local t = 8 / 3 * math.sin(delta / 4) * math.sin(delta / 4) / math.sin(delta / 2)

                local startX = x
                local startY = y

                for i = 0, segments - 1 do
                    local cosTheta1 = math.cos(theta1)
                    local sinTheta1 = math.sin(theta1)
                    local theta2 = theta1 + delta
                    local cosTheta2 = math.cos(theta2)
                    local sinTheta2 = math.sin(theta2)

                    local endpointX = cosPhi * rx * cosTheta2 - sinPhi * ry * sinTheta2 + cx
                    local endpointY = sinPhi * rx * cosTheta2 + cosPhi * ry * sinTheta2 + cy

                    local dx1 = t * (-cosPhi * rx * sinTheta1 - sinPhi * ry * cosTheta1)
                    local dy1 = t * (-sinPhi * rx * sinTheta1 + cosPhi * ry * cosTheta1)

                    local dxe = t * (cosPhi * rx * sinTheta2 + sinPhi * ry * cosTheta2)
                    local dye = t * (sinPhi * rx * sinTheta2 - cosPhi * ry * cosTheta2)

                    local bezier = love.math.newBezierCurve(startX, startY, (startX + dx1), (startY + dy1), (endpointX + dxe), (endpointY + dye), endpointX, endpointY)
                    local curve = bezier:render()
                    bezier:release()

                    join()
                    for ci = 1, #curve, 2 do
                        line(curve[ci], curve[ci + 1])
                    end
                    join()

                    theta1 = theta2
                    startX = endpointX
                    startY = endpointY
                end
            end

            x, y = x2, y2
        end
    end

    return {
        path = path,
        lengths = lengths,
        joins = joins
    }
end


function shaper.load(path)
    local shape = {}

    local svg = utils.loadXML(path).svg
    local paths = svg.g.path

    for i = 1, #paths do
        local raw = paths[i]
        local path = shaper.parsePath(raw._attr.d)
        path.name = raw._attr.name
        path.from, path.to = shaper.tonumbers(raw._attr.range:match("([%d.]+)[, ]([%d.]+)"))
        path.from = tonumber(path.from)
        path.to = tonumber(path.to)
        path.draw = shaper.drawSegment
        path.drawDebug = shaper.drawSegmentDebug
        shape[i] = path
    end

    shape.width = tonumber(svg._attr.width)
    shape.height = tonumber(svg._attr.height)
    shape.draw = shaper.drawShape
    shape.drawDebug = shaper.drawShapeDebug

    return shape
end


return shaper
