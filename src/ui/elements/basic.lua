local ui = require("ui.main")
local uie = require("ui.elements.main")
local uiu = require("ui.utils")


-- Special root element.
uie.add("root", {
    id = "root",
    cacheable = false,
    init = function(self, children)
        self.children = children or {}
    end,

    calcSize = function(self)
        local width = 0
        local height = 0

        local children = self.children
        for i = 1, #children do
            local c = children[i]
            width = math.max(width, c.x + c.width)
            height = math.max(height, c.y + c.height)
        end

        self.innerWidth = width
        self.innerHeight = height
        self.width = width
        self.height = height
    end,

    layoutLate = function(self)
        self:layoutLateChildren()
        self:collect(false)
    end,

    recollect = function(self)
        self.recollecting = true
    end,

    collect = function(self, basic)
        self.recollecting = false

        local all = {}

        local function collectAll(el)
            local children = el.children
            if children then
                for i = 1, #children do
                    local c = children[i]
                    c.parent = el
                    c.visible = false
                    all[#all + 1] = c
                    collectAll(c)
                end
            end
        end

        collectAll(self)
        self.all = all

        if basic then
            return
        end

        local allI = {}

        local function collectAllI(el, px, py, pl, pt, pr, pb, pi)
            local children = el.children
            if children then
                local erl = px + el.realX
                local ert = py + el.realY
                local err = erl + el.width
                local erb = ert + el.height

                local bl = math.max(erl, pl)
                local bt = math.max(ert, pt)
                local br = math.min(err, pr)
                local bb = math.min(erb, pb)

                for i = 1, #children do
                    local c = children[i]
                    if c:intersects(bl, bt, br, bb) then
                        c.visible = true

                        local interactive = c.interactive

                        if pi and interactive >= 0 then
                            if interactive >= 1 then
                                allI[#allI + 1] = c
                            end

                            collectAllI(c, erl, ert, bl, bt, br, bb, true)
                        else
                            collectAllI(c, erl, ert, bl, bt, br, bb, false)
                        end
                    end
                end
            end
        end
        
        collectAllI(self, 0, 0, 0, 0, love.graphics.getWidth(), love.graphics.getHeight(), true)
        self.allI = allI
    end,

    getChildAt = function(self, mx, my)
        local allI = self.allI
        if allI ~= nil then
            for i = #allI, 1, -1 do
                local retc = allI[i]

                local c = retc
                retc = nil
                while c ~= nil do
                    local ex = c.screenX
                    local ey = c.screenY
                    local ew = c.width
                    local eh = c.height
            
                    if
                        mx < ex or ex + ew < mx or
                        my < ey or ey + eh < my
                    then
                        retc = nil
                        break
                    end

                    if retc == nil then
                        retc = c
                    end

                    c = c.parent
                end

                if retc ~= nil then
                    return retc
                end
            end
        end

        return nil
    end,
})


-- Basic panel with children elements.
uie.add("panel", {
    init = function(self, children)
        self.children = children or {}
        self.width = -1
        self.height = -1
        self.minWidth = -1
        self.minHeight = -1
        self.maxWidth = -1
        self.maxHeight = -1
        self.forceWidth = -1
        self.forceHeight = -1
        self.clip = true
    end,

    style = {
        bg = { 0.08, 0.08, 0.08, 0.2 },
        border = { 0, 0, 0, 0 },
        padding = 8,
        radius = 3
    },

    calcSize = function(self, width, height)
        local manualWidth = self.width
        manualWidth = manualWidth ~= -1 and manualWidth or nil
        local manualHeight = self.height
        manualHeight = manualHeight ~= -1 and manualHeight or nil

        local forceWidth
        if self.__autoWidth ~= manualWidth then
            forceWidth = manualWidth or -1
            self.forceWidth = forceWidth
        else
            forceWidth = self.forceWidth or -1
        end

        local forceHeight
        if self.__autoHeight ~= manualHeight then
            forceHeight = manualHeight or -1
            self.forceHeight = forceHeight
        else
            forceHeight = self.forceHeight or -1
        end

        width = forceWidth >= 0 and forceWidth or width or -1
        height = forceHeight >= 0 and forceHeight or height or -1

        if width < 0 and height < 0 then
            local children = self.children
            for i = 1, #children do
                local c = children[i]
                width = math.max(width, c.x + c.width)
                height = math.max(height, c.y + c.height)
            end

        elseif width < 0 then
            local children = self.children
            for i = 1, #children do
                local c = children[i]
                width = math.max(width, c.x + c.width)
            end

        elseif height < 0 then
            local children = self.children
            for i = 1, #children do
                local c = children[i]
                height = math.max(height, c.y + c.height)
            end
        end
        
        if self.minWidth >= 0 and width < self.minWidth then
            width = self.minWidth
        end
        if self.maxWidth >= 0 and self.maxWidth < width then
            width = self.maxWidth
        end

        if self.minHeight >= 0 and height < self.minHeight then
            height = self.minHeight
        end
        if self.maxHeight >= 0 and self.maxHeight < height then
            height = self.maxHeight
        end

        self.innerWidth = width
        self.innerHeight = height

        width = width + self.style.padding * 2
        height = height + self.style.padding * 2

        self.__autoWidth = width
        self.__autoHeight = height
        self.width = width
        self.height = height
    end,

    layoutChildren = function(self)
        local padding = self.style.padding
        local children = self.children
        for i = 1, #children do
            local c = children[i]
            c.parent = self
            c:layoutLazy()
            c.realX = c.x + padding
            c.realY = c.y + padding
        end
    end,

    repositionChildren = function(self)
        local padding = self.style.padding
        local children = self.children
        for i = 1, #children do
            local c = children[i]
            c.parent = self
            c.realX = c.x + padding
            c.realY = c.y + padding
        end
    end,

    draw = function(self)
        local x = self.screenX
        local y = self.screenY
        local w = self.width
        local h = self.height

        local radius = self.style.radius
        local bg = self.style.bg
        if bg and #bg ~= 0 and bg[4] ~= 0 then
            love.graphics.setColor(bg)
            love.graphics.rectangle("fill", x, y, w, h, radius, radius)
        end

        if w >= 0 and h >= 0 then
            local sX, sY, sW, sH
            local clip = self.clip and not self.cachedCanvas
            if clip then
                sX, sY, sW, sH = love.graphics.getScissor()
                local scissorX, scissorY = love.graphics.transformPoint(x, y)
                love.graphics.intersectScissor(scissorX, scissorY, w, h)
            end

            local children = self.children
            for i = 1, #children do
                local c = children[i]
                if c.visible then
                    c:drawLazy()
                end
            end

            if clip then
                love.graphics.setScissor(sX, sY, sW, sH)
            end
        end


        local border = self.style.border
        if border and #border ~= 0 and border[4] ~= 0 then
            love.graphics.setColor(border)
            love.graphics.rectangle("line", x, y, w, h, radius, radius)
        end
    end
})


-- Panel which doesn't display as one by default.
uie.add("group", {
    base = "panel",

    cachePadding = 0,

    style = {
        bg = {},
        border = {},
        padding = 0,
        radius = 0
    },

    init = function(self, ...)
        uie.__panel.init(self, ...)
        self.clip = false
    end
})


-- Basic label.
uie.add("label", {
    cacheable = false,

    style = {
        color = { 1, 1, 1, 1 }
    },

    init = function(self, text)
        self.text = text or ""
        self.dynamic = false
    end,

    getText = function(self)
        return self._textStr
    end,

    setText = function(self, value)
        if value == self._textStr then
            return
        end
        self._textStr = value

        if type(value) ~= "userdata" then
            if not self._text then
                self._text = love.graphics.newText(love.graphics.getFont(), value)
            else
                self._text:set(value)
            end
        else
            self._text = value
        end

        if not self.dynamic and (self.width ~= math.ceil(self._text:getWidth()) or self.height ~= math.ceil(self._text:getHeight())) then
            self:reflow()
        else
            self:repaint()
        end
    end,

    calcWidth = function(self)
        return math.ceil(self._text:getWidth())
    end,

    calcHeight = function(self)
        return math.ceil(self._text:getHeight())
    end,

    draw = function(self)
        love.graphics.setColor(self.style.color)
        love.graphics.draw(self._text, self.screenX, self.screenY)
    end
})


-- Basic image.
uie.add("image", {
    cacheable = false,

    style = {
        color = { 1, 1, 1, 1 }
    },

    quad = nil,
    transform = nil,

    init = function(self, image)
        if type(image) == "string" then
            self.id = image
            image = uiu.image(image)
        end
        self._image = image
    end,

    calcSize = function(self)
        local image = self._image
        local width, height = image:getWidth(), image:getHeight()

        local transform = self.transform
        if transform then
            width, height = transform:transformPoint(width, height)
        end

        self.width = width
        self.height = height
    end,

    draw = function(self)
        love.graphics.setColor(self.style.color)

        local transform = self.transform
        local quad = self.quad
        if quad then
            if transform then
                love.graphics.draw(self._image, quad, transform)
            else
                love.graphics.draw(self._image, quad, self.screenX, self.screenY)
            end

        else
            if transform then
                love.graphics.draw(self._image, transform)

            else
                love.graphics.draw(self._image, self.screenX, self.screenY)
            end
        end
    end
})


return uie
