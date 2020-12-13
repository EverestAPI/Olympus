local ui, uiu, uie = require("ui").quick()

local notify = {}

notify.spacing = 16


function notify.init(root)
    notify.root = root
end


function notify.show(data)
    local prevs = {}
    for i = 1, #notify.root.children do
        prevs[i] = notify.root.children[i]
    end

    local notif = uie.column({}):with({
        time = 0,
        offs = 0,
        interactive = 2,
        cacheForce = true
    }):hook({
        layoutLateLazy = function(orig, self)
            -- Always reflow this child whenever its parent gets reflowed.
            self:layoutLate()
        end,

        layoutLate = function(orig, self)
            orig(self)
            self.x = 32
            self.realX = 32 + (self.parent.style:get("padding") or 0)
            self.y = self.parent.innerHeight - 32 - self.height - self.offs
            self.realY = self.parent.height - 32 - self.height - self.offs
            local style = self.style
            style.bg = nil
            local boxBG = style.bg
            style.bg = { boxBG[1], boxBG[2], boxBG[3], 1 }
        end
    }):as("notif")

    if type(data) == "string" then
        data = {
            body = data
        }
    end

    if not data.time then
        data.time = 3
    end

    if data.title then
        notif:addChild(uie.label(data.title, ui.fontBig):as("title"))
    end

    if data.body then
        if type(data.body) == "string" then
            notif:addChild(uie.label(data.body):as("body"))
        else
            notif:addChild(data.body:as("body"))
        end
    end

    function notif.close(self)
        if notif.closing then
            return
        end
        notif.closing = true
        notif.time = 0
        if data.cb then
            data.cb(self)
        end
    end

    notif:hook({
        update = function(orig, self, dt)
            orig(self, dt)

            local time = notif.time
            if notif.closing then
                time = time + dt
                if time >= 0.2 then
                    self:removeSelf()
                    return
                end
                notif.fade = math.min(1, 1 - time * 7)

            else
                local otime = time * 9
                local odt = dt * 9
                if otime > 1 then
                    odt = 0
                elseif otime < 1 and otime + odt > 1 then
                    odt = 1 - otime
                end

                odt = odt * (self.height + notify.spacing)

                for i = 1, #prevs do
                    local prev = prevs[i]
                    prev.offs = prev.offs + odt
                    prev.y = prev.y - odt
                    prev.realY = prev.realY - odt
                end

                time = time + dt
                local t = time > 1 and 1 or time
                notif.fade = math.min(1, t * 7)
                if time >= data.time then
                    notif.close()
                    time = 0
                end
            end

            notif.time = time
        end,

        __drawCachedCanvas = function(orig, self, canvas, x, y, width, height, padding)
            local fade = notif.fade
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

    if data.init then
        data.init(notif)
    end

    notify.root:addChild(notif)
    return notif
end


return setmetatable(notify, {
    __call = function(self, ...)
        return self.show(...)
    end
})
