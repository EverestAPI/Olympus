local ui, uiu, uie = require("ui").quick()
local threader = require("threader")

local alert = {}


function alert.init(root)
    alert.root = root
end


function alert.show(data)
    local container = uie.group({}):with({
        time = 0,
        style = {
            bg = {},
            padding = 0,
            radius = 0
        },
        clip = false,
        cacheable = false
    }):with(uiu.fill)

    local bg = uie.group({}):hook({
        onClick = function(orig, self, x, y, button)
            orig(self, x, y, button)
            if not data.force then
                container.close("bypass")
            end
        end
    }):with({
        interactive = 1,
        style = {
            bg = { 0.1, 0.1, 0.1, 0 },
            padding = 0,
            radius = 0
        },
        clip = false,
        cacheable = false
    }):with(uiu.fill)
    container:addChild(bg)

    if type(data) == "string" then
        data = {
            body = data,
            buttons = {
                { "OK", function()
                    container.close("ok")
                end }
            }
        }
    end

    local box = uie.column({}):with({
        interactive = 2,
        style = {
            padding = 16
        },
        cachePadding = 0,
        cacheForce = true
    }):hook({
        layoutLateLazy = function(orig, self)
            -- Always reflow this child whenever its parent gets reflowed.
            self:layoutLate()
        end,

        layoutLate = function(orig, self)
            orig(self)
            self.x = math.floor(self.parent.innerWidth * 0.5 - self.width * 0.5)
            self.realX = math.floor(self.parent.width * 0.5 - self.width * 0.5)
            self.y = math.floor(self.parent.innerHeight * 0.5 - self.height * 0.5)
            self.realY = math.floor(self.parent.height * 0.5 - self.height * 0.5)
        end
    })
    local boxBG = box.style.bg
    box.style.bg = { boxBG[1], boxBG[2], boxBG[3], 1 }

    if data.title then
        box:addChild(uie.label(data.title, ui.fontBig))
    end

    if data.body then
        if type(data.body) == "string" then
            box:addChild(uie.label(data.body))
        else
            box:addChild(data.body)
        end
    end

    if data.buttons then
        local row = uie.row():with({
            style = {
                bg = {},
                padding = 0,
                radius = 0
            },
            clip = false
        }):with(uiu.rightbound)
        for i = 1, #data.buttons do
            local btn = data.buttons[i]
            btn = uie.button(table.unpack(btn))
            row:addChild(btn)
        end
        box:addChild(row)
    end

    container:addChild(box)


    function container.close(reason)
        if container.closing then
            return
        end
        container.closing = true
        container.time = 0
        if data.cb then
            data.cb(reason)
        end
    end


    container:hook({
        update = function(orig, self, dt)
            orig(self, dt)

            local time = container.time
            if container.closing then
                time = time + dt
                if time >= 0.3 then
                    self:removeSelf()
                    return
                end
                bg.style.bg[4] = math.min(0.6, 1 - time * 6)
                box.fade = math.min(1, 1 - time * 7)

            else
                time = time + dt
                if time > 1 then
                    time = 1
                end
                bg.style.bg[4] = math.min(0.6, time * 6)
                box.fade = math.min(1, time * 7)
            end

            container.time = time
        end
    })

    box:hook({
        __drawCachedCanvas = function(orig, self, canvas, x, y, width, height, padding)
            local fade = box.fade
            if not uiu.setColor(fade, fade, fade, fade) then
                return
            end
            local sfade = math.sin(fade * math.pi * 0.5)
            local scale = 0.7 + 0.3 * sfade
            local hw = math.floor(width * 0.5)
            local hh = math.floor(height * 0.5)
            love.graphics.setBlendMode("alpha", "premultiplied")
            love.graphics.draw(canvas, x - padding + hw, y - padding + hh + 20 * (1 - sfade), 0.1 * math.max(0, 0.7 - sfade * 1.2), scale, scale, hw, hh)
            love.graphics.setBlendMode("alpha", "alphamultiply")
        end,
    })

    alert.root:addChild(container)
    return container
end


local mtAlert = {
    __call = function(self, ...)
        self.show(...)
    end
}

setmetatable(alert, mtAlert)

return alert
