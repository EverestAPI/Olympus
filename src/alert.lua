local ui, uiu, uie = require("ui").quick()
local scener = require("scener")
local config = require("config")

local alert = {}


local panelDefaultBG = uie.panel.style.bg


uie.add("alertBG", {
    base = "group",

    interactive = 1,
    clip = false,
    cacheable = false,
    style = {
        patch = false,
        padding = 0,
        radius = 0,

        visibleBG = {panelDefaultBG[1], panelDefaultBG[2], panelDefaultBG[3], 0.98},
        visibleBlurBG = {panelDefaultBG[1], panelDefaultBG[2], panelDefaultBG[3], 0.93},
        hiddenBG = {panelDefaultBG[1], panelDefaultBG[2], panelDefaultBG[3], 0}
    },

    init = function(self, container)
        uie.panel.init(self, {})
        self.container = container
    end,

    revive = function(self)
        self._fadeBGStyle, self._fadeBG, self._fadeBGPrev = {table.unpack(self.style.hiddenBG)}, false, false
    end,

    update = function(self)
        local container = self.container
        local style = self.style
        local bg, bgPrev, bgNext = self._fadeBGStyle, self._fadeBG, nil

        if container.closing then
            bgNext = style.hiddenBG
        elseif config.quality.bgBlur then
            bgNext = style.visibleBlurBG
        else
            bgNext = style.visibleBG
        end

        _, style.bg, bgPrev, self._fadeBGPrev, self._fadeBG = uiu.fadeSwap(false, bg, self._fadeBGPrev, bgPrev, bgNext)
        if uiu.fade(false, container.time * 9, bg, bgPrev, bgNext) then
            self:repaint()
        end
    end,

})


function alert.init(root)
    alert.root = root
    alert.count = 0
end

function alert.show(data)
    scener.lock()
    alert.count = alert.count + 1

    local container = uie.group({}):with({
        time = 0,
        force = data.force,
        clip = false,
        cacheable = false,
        popup = true
    }):with(uiu.fill):as("container")

    local bg = uie.alertBG(container):hook({
        onClick = function(orig, self, x, y, button)
            orig(self, x, y, button)
            container:close(false)
        end
    }):with(uiu.fill):as("bg")
    container:addChild(bg)

    if type(data) == "string" then
        data = {
            body = data
        }
    end

    if type(data.body) == "table" and data.body.is and data.body:is("group")
        and data.body.clip and not data.body.skipAlertPadding then
        data.body:with({
            clipPadding = { 8, 4, 8, 8 },
            cachePadding = { 8, 4, 8, 8 }
        })
    end

    if not data.buttons then
        data.buttons = {
            { "OK", function(container)
                container:close("OK")
            end }
        }
    end

    local box = uie.column({}):with({
        interactive = 2,
        style = {
            padding = 16
        },
        cacheForce = true
    }):hook({
        layoutLateLazy = function(orig, self)
            -- Always reflow this child whenever its parent gets reflowed.
            self:layoutLate()
            self:repaint()
        end,

        layoutLate = function(orig, self)
            orig(self)
            self.x = math.floor(self.parent.innerWidth * 0.5 - self.width * 0.5)
            self.realX = math.floor(self.parent.width * 0.5 - self.width * 0.5)
            self.y = math.floor(self.parent.innerHeight * 0.5 - self.height * 0.5)
            self.realY = math.floor(self.parent.height * 0.5 - self.height * 0.5)
        end
    }):as("box")

    if data.title then
        box:addChild(uie.label(data.title, ui.fontBig):as("title"))
    end

    if data.body then
        if type(data.body) == "string" then
            box:addChild(uie.label(data.body):as("body"))
        else
            box:addChild(data.body:as("body"))
        end
    end

    if data.buttons then
        local row = uie.row():with({
            clip = false
        }):with(uiu.rightbound):with(uiu.bottombound):as("buttons")
        for i = 1, #data.buttons do
            local btndata = data.buttons[i]
            local btn = uie.button(btndata[1], function()
                if btndata[2] then
                    btndata[2](container)
                else
                    container:close(btndata[1])
                end
            end)
            row:addChild(btn)
        end
        box:addChild(row)
    end

    container:addChild(box)


    function container.close(self, reason)
        if container.closing or (container.force and not reason) then
            return
        end
        scener.unlock()
        alert.count = alert.count - 1
        container.closing = true
        container.time = 0
        if data.cb then
            data.cb(self, reason)
        end
    end


    container:hook({
        update = function(orig, self, dt)
            orig(self, dt)
            local time = container.time
            if container.closing then
                time = time + dt
                if not container.popup then
                    time = 1
                end

                if time >= 0.2 then
                    self:removeSelf()
                    return
                end
                box.fade = math.min(1, 1 - time * 7)

            else
                time = time + dt
                if not container.popup then
                    time = 1
                end

                if time > 1 then
                     time = 1
                 end
                box.fade = math.min(1, time * 7)
            end

            container.time = time
        end
    })

    box:hook({
        __drawCachedCanvas = function(orig, self, canvas, x, y, width, height, paddingL, paddingT, paddingR, paddingB)
            local fade = box.fade
            if not uiu.setColor(fade, fade, fade, fade) then
                return
            end
            local sfade = math.sin(fade * math.pi * 0.5)
            local scale = 0.7 + 0.3 * sfade
            local hw = math.floor(width * 0.5)
            local hh = math.floor(height * 0.5)
            uiu.drawCanvas(canvas, x - paddingL + hw, y - paddingT + hh + 20 * (1 - sfade), 0.1 * math.max(0, 0.7 - sfade * 1.2), scale, scale, hw, hh)
        end,
    })

    if data.init then
        data.init(container)
    end

    if data.big then
        if not data.title then
            box:with({
                style = {
                    padding = 0
                }
            })
        end
        box:with({
            cacheable = false,
            clip = false,
        }):with(uiu.fill(64))
    end

    alert.root:addChild(container)
    return container
end


function alert.scene(scene)
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

    local container = alert({
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


return setmetatable(alert, {
    __call = function(self, ...)
        return self.show(...)
    end
})
