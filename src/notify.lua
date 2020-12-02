local ui, uiu, uie = require("ui").quick()

local notify = {}

notify.notifications = {}


function notify.init(root)
    notify.root = root
end


function notify.show(data)
    local notif = uie.column({}):with({
        time = 0,
        interactive = 2,
        style = {
            padding = 16
        },
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
            local style = self.style
            style.bg = nil
            local boxBG = style.bg
            style.bg = { boxBG[1], boxBG[2], boxBG[3], 1 }
        end
    })

    if type(data) == "string" then
        data = {
            body = data
        }
    end

    if not data.time then
        data.time = 5
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

    function notif.close(self, reason)
        if notif.closing or (data.force and not reason) then
            return
        end
        notif.closing = true
        notif.time = 0
        if data.cb then
            data.cb(self, reason)
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
                time = time + dt
                if time > 1 then
                    time = 1
                end
                notif.fade = math.min(1, time * 7)
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


function notify.scene(scene)
    scene = scener.preload(scene)
    if not scene.loaded then
        if scene.load then
            scene.load()
        end
        scene.loaded = true
    end

    if scene.enter then
        scene.enter()
    end

    local container = notify({
        body = scene.root:with({
            style = {
                bg = {},
                padding = scene.root._fullroot and 0 or 16
            },

            cacheable = false,
            clip = false,
        }):with(uiu.fill),
        buttons = {}
    })

    container:findChild("box"):with({
        style = {
            padding = 0
        },

        cacheable = false,
        clip = false,
    }):with(uiu.fill(64))

    return container
end


return setmetatable(notify, {
    __call = function(self, ...)
        return self.show(...)
    end
})
