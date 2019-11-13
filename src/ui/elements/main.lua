local ui = require("ui.main")

local uie = {}
ui.e = uie

-- Default element functions and values.
uie.__default = {
    x = 0,
    y = 0,
    width = 0,
    height = 0,
    reflowing = true,
    reflowingLate = true,
    visible = true,

    interactive = 0,

    parent = nil,
    id = nil,

    cacheable = true,
    cachedCanvas = nil,
    cachePadding = 4,
    __cachedWidth = 0,
    __cachedHeight = 0,

    getPath = function(self)
        local id = self.id
        if not id then
            id = "(" .. self.__type .. ":" .. self.__rawid .. ")"
        end

        local parent = self.parent
        if parent then
            return parent.path .. "." .. id
        end

        return id
    end,

    getRealX = function(self)
        return self.__realX or self.x
    end,

    setRealX = function(self, value)
        self.__realX = value
    end,

    getRealY = function(self)
        return self.__realY or self.y
    end,

    setRealY = function(self, value)
        self.__realY = value
    end,

    getScreenX = function(self)
        local pos = 0
        local el = self
        while el ~= nil do
            pos = pos + el.realX
            el = el.parent
            if el ~= nil then
                local padding = el.padding
                if padding then
                    pos = pos + padding
                end
            end
        end
        return pos
    end,

    getScreenY = function(self)
        local pos = 0
        local el = self
        while el ~= nil do
            pos = pos + el.realY
            el = el.parent
            if el ~= nil then
                local padding = el.padding
                if padding then
                    pos = pos + padding
                end
            end
        end
        return pos
    end,

    getInnerWidth = function(self)
        return self.width
    end,

    getInnerHeight = function(self)
        return self.height
    end,

    contains = function(self, mx, my)
        local ex = self.screenX
        local ey = self.screenY
        local ew = self.width
        local eh = self.height
    
        return not (
            mx < ex or ex + ew < mx or
            my < ey or ey + eh < my
        )
    end,

    intersects = function(self, ml, mt, mr, mb)
        local el = self.screenX
        local er = el + self.width
        local et = self.screenY
        local eb = et + self.height

        return not (
            mr < el or er < ml or
            mb < et or eb < mt
        )
    end,

    getHovered = function(self)
        local hovering = ui.hovering
        while hovering do
            if hovering == self then
                return true
            end
            hovering = hovering.parent
        end
        return false
    end,

    getPressed = function(self)
        local dragging = ui.dragging
        while dragging do
            if dragging == self then
                return self.hovered
            end
            dragging = dragging.parent
        end
        return false
    end,

    getDragged = function(self)
        local dragging = ui.dragging
        while dragging do
            if dragging == self then
                return true
            end
            dragging = dragging.parent
        end
        return false
    end,

    getFocused = function(self)
        local focusing = ui.focusing
        while focusing do
            if focusing == self then
                return true
            end
            focusing = focusing.parent
        end
        return false
    end,

    init = function(self)
    end,

    as = function(self, id)
        self.id = id
        return self
    end,

    with = function(self, props)
        for k, v in pairs(props) do
            self[k] = v
        end
        self:reflow()
        return self
    end,

    run = function(self, cb, ...)
        local rv = cb(self, ...)
        return rv or self
    end,

    reflow = function(self)
        local el = self
        while el ~= nil do
            el.reflowing = true
            el.reflowingLate = true
            el.cachedCanvas = nil
            el = el.parent
        end

        self:repaintDown()
    end,

    reflowDown = function(self)
        local children = self.children
        if children then
            for i = 1, #children do
                local c = children[i]
                c.reflowing = true
                c.reflowingLate = true
                c.cachedCanvas = nil
                c:reflowDown()
            end
        end
    end,

    repaint = function(self)
        local el = self
        while el ~= nil do
            el.cachedCanvas = nil
            el = el.parent
        end
    end,

    repaintDown = function(self)
        local children = self.children
        if children then
            for i = 1, #children do
                local c = children[i]
                c.cachedCanvas = nil
                c:repaintDown()
            end
        end
    end,

    --[[
    update = function(self)
    end,
    --]]

    layoutLazy = function(self)        
        if not self.reflowing then
            return false
        end
        self.reflowing = false

        self:layout()

        return true
    end,

    layout = function(self)
        self:layoutChildren()
        self:recalc()
    end,

    layoutChildren = function(self)
        local children = self.children
        if children then
            for i = 1, #children do
                local c = children[i]
                c.parent = self
                c:layoutLazy()
            end
        end
    end,

    layoutLateLazy = function(self)
        if not self.reflowingLate then
            return false
        end
        self.reflowingLate = false

        self:layoutLate()

        return true
    end,

    layoutLate = function(self)
        self:layoutLateChildren()
    end,

    layoutLateChildren = function(self)
        local children = self.children
        if children then
            for i = 1, #children do
                local c = children[i]
                c.parent = self
                c:layoutLateLazy()
            end
        end
    end,

    recalc = function(self)
        local eltype = self.__type
        local eltypeBase = eltype
        local calcset = {}
        while eltypeBase ~= nil do
            local default = uie["__" .. eltypeBase].__default
            for k, v in pairs(default) do
                if k:sub(1, 4) == "calc" then
                    local calced = false
                    for i = 1, #calcset do
                        local c = calcset[i]
                        if c == k then
                            calced = true
                            break
                        end
                    end

                    if not calced then
                        calcset[#calcset + 1] = k
                        self[k:sub(5, 5):lower() .. k:sub(6)] = v(self)
                    end
                end
            end
            eltypeBase = default.base
        end
    end,

    draw = function(self)
        local children = self.children
        if children then
            for i = 1, #children do
                local c = children[i]
                if c.visible then
                    c:drawLazy()
                end
            end
        end
    end,

    drawLazy = function(self)
        if not self.cacheable then
            self:draw()
            return
        end

        local width = self.width
        local height = self.height

        if width <= 0 or height <= 0 then
            return
        end

        local padding = self.cachePadding
        width = width + padding * 2
        height = height + padding * 2

        if width ~= self.__cachedWidth or height ~= self.__cachedHeight then
            local canvas = self.__cachedCanvas
            if canvas then
                canvas:release()
                canvas = nil
                self.__cachedCanvas = nil
            end

            self.__cachedWidth = width
            self.__cachedHeight = height
        end

        local canvas = self.cachedCanvas
        if not canvas then
            canvas = self.__cachedCanvas

            if not canvas then
                canvas = love.graphics.newCanvas(width, height)
                self.__cachedCanvas = canvas
            end
            self.cachedCanvas = canvas

            local sX, sY, sW, sH = love.graphics.getScissor()

            local canvasPrev = love.graphics.getCanvas()
            love.graphics.setCanvas(canvas)
            love.graphics.setScissor()
            love.graphics.clear(0, 0, 0, 0)

            love.graphics.push()
            love.graphics.origin()
            love.graphics.translate(-self.screenX + padding, -self.screenY + padding)

            if sX then
                love.graphics.setScissor(sX - self.realX, sY - self.realY, sW + padding, sH + padding)
            end

            self:draw()

            if sX then
                love.graphics.setScissor(sX, sY, sW, sH)
            end
            
            love.graphics.pop()

            love.graphics.setCanvas(canvasPrev)
        end

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setBlendMode("alpha", "premultiplied")
        love.graphics.draw(canvas, self.screenX - padding, self.screenY - padding)
        love.graphics.setBlendMode("alpha", "alphamultiply")
    end,

    getChildAt = function(self, mx, my)
        local interactive = self.interactive
        if interactive == -2 then
            return nil
        end
    
        --[[
        if not self:contains(mx, my) then
            return nil
        end
        --]]

        local ex = self.screenX
        local ey = self.screenY
        local ew = self.width
        local eh = self.height

        if
            mx < ex or ex + ew < mx or
            my < ey or ey + eh < my
        then
            return nil
        end
    
        local children = self.children
        if children then
            for i = #children, 1, -1 do
                local c = children[i]
                c = c:getChildAt(mx, my)
                if c then
                    return c
                end
            end
        end

        if interactive == -1 then
            return nil
        end
    
        return self
    end,

    --[[
    onEnter = function(self)
    end,
    onLeave = function(self)
    end,
    onPress = function(self, x, y, button, dragging)
    end,
    onRelease = function(self, x, y, button, dragging)
    end,
    onClick = function(self, x, y, button)
    end,
    onDrag = function(self, x, y, dx, dy)
    end,
    onScroll = function(self, x, y, dx, dy)
    end,
    --]]
}

-- Shared metatable for all style helper tables.
local mtStyle = {
    __name = "ui.element.style",

    __index = function(self, key)
        local v = rawget(self, key)
        if v ~= nil then
            return v
        end

        local el = rawget(self, "el")
        local eltype = el.__type

        local defaultStyle = el.__default.style
        if defaultStyle then
            v = defaultStyle[key]
            if v ~= nil then
                return v
            end
        end

        local template = el.__template
        local templateStyle = template and template.style
        if templateStyle then
            v = templateStyle[key]
            if v ~= nil then
                return v
            end
        end

        local baseStyle = el.__base.style
        if baseStyle then
            v = baseStyle[key]
            if v ~= nil then
                return v
            end
        end

        error("Unknown styling property: " .. eltype .. " [\"" .. tostring(key) .. "\"]")
    end
}

-- Shared metatable for all element tables.
local mtEl = {
    __name = "ui.element",

    __index = function(self, key)
        local v = rawget(self, key)
        if v ~= nil then
            return v
        end

        if key == "style" then
            return rawget(self, "__style")
        end

        local propcache = rawget(self, "__propcache")
        local cached = propcache[key]
        if cached then
            local ctype = cached.type
            
            if ctype == "get" then
                return cached.value(self)

            elseif ctype == "child" then
                local id = cached.id
                local children = self.children
                local c = children[cached.i]
                if c and c.id == id then
                    return c
                end
                for i = 1, #children do
                    local c = children[i]
                    if c.id == id then
                        cached.i = i
                        return c
                    end
                end
            end
        end

        local keyType = type(key)

        local keyGet = nil
        if keyType == "string" then
            local Key = key:sub(1, 1):upper() .. key:sub(2)
            keyGet = "get" .. Key
        end
            
        local default = rawget(self, "__default")
        if keyGet then
            v = default[keyGet]
            if v ~= nil then
                propcache[key] = { type = "get", value = v }
                return v(self)
            end
        end

        v = default[key]
        if v ~= nil then
            return v
        end

        local base = default.base
        if base then
            base = uie["__" .. default.base]

            if base then
                if keyGet then
                    v = base[keyGet]
                    if v ~= nil then
                        propcache[key] = { type = "get", value = v }
                        return v(self)
                    end
                end

                v = base[key]
                if v ~= nil then
                    return v
                end
            end
        end

        if key == "children" then
            return nil
        end
        
        if keyGet then
            v = uie.__default[keyGet]
            if v ~= nil then
                propcache[key] = { type = "get", value = v }
                return v(self)
            end
        end

        v = uie.__default[key]
        if v ~= nil then
            return v
        end

        local children = self.children
        if children then
            if keyType == "string" and key:sub(1, 1) == "_" then
                local id = key:sub(2)
                for i = 1, #children do
                    local c = children[i]
                    local cid = c.id
                    if cid and cid == id then
                        propcache[key] = { type = "child", i = i, id = id }
                        return c
                    end
                end
            end
        end
    end,

    __newindex = function(self, key, value)
        if key == "style" then
            local style = rawget(self, "__style")
            for k, v in pairs(value) do
                style[k] = v
            end
            return self
        end

        local keySet = nil
        if type(key) == "string" then
            keySet = "set" .. key:sub(1, 1):upper() .. key:sub(2)
        end

        if keySet then
            local cb = self.__default[keySet]
            if cb ~= nil then
                return cb(self, value)
            end

            cb = uie.__default[keySet]
            if cb then
                return cb(self, value)
            end
        end

        return rawset(self, key, value)
    end,

    __call = function(self, ...)
        local __call = self.__call
        if __call then
            return __call(...)
        end
        return self:with(...)
    end,

    __tostring = function(self)
        return self.path
    end
}

-- Function to register a new UI element.
function uie.add(eltype, default)
    local template

    local function new()
        local el = {}
        el.__ui = ui
        el.__type = eltype
        el.__default = default
        el.__template = template
        el.__style = setmetatable({ el = el }, mtStyle)
        el.__base = uie["__" .. (default.base or "default")] or uie.__default
        el.__propcache = {}
        el.__rawid = tostring(el):sub(8)

        uie.flatten(el)

        return setmetatable(el, mtEl)
    end

    template = new()
    uie["__" .. eltype] = template

    uie[eltype] = function(...)
        local el = new()
        el:init(...)
        return el
    end

    return new
end

local function _flatten(el, default)
    for k, v in pairs(default) do
        if k:sub(1, 1) ~= "_" and k ~= "style" and el[k] == nil then
            el[k] = v
        end
    end
end

function uie.flatten(el)
    local __default = uie.__default
    local default = el.__default
    while true do
        _flatten(el, default)
        default = uie["__" .. (default.base or "default")] or __default
        if default == __default then
            _flatten(el, default)
            break
        end
    end
end

return uie
