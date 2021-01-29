local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local threader = require("threader")
local scener = require("scener")
local fs = require("fs")
local config = require("config")
local sharp = require("sharp")
local native = require("native")

local scene = {
    name = "Threader Test"
}


local root


function scene.reloadSharp()
    local all = root:findChild("all")

    local list = root:findChild("listSharp")
    if list then
        list.children = {}
    else
        list = uie.column({}):with(uiu.fillWidth)

        all:addChild(list:as("listSharp"))
    end

    list:addChild(uie.label("sharp", ui.fontBig))

    for i = 1, 10 do
        local item = uie.label(string.format("%02d | -", i), ui.fontMono)
        sharp.echo(string.format("%02d", i)):calls(function(t, text)
            item.text = string.format("%02d | %s", i, text)
        end)

        list:addChild(item)
    end

    list:addChild(uie.label("stresstest label please ignore #-"):with({
        stressCount = 1,
    }):hook({
        update = function(orig, self, ...)
            orig(self, ...)
            if not self.stress then
                self.stress = sharp.echo("stresstest label please ignore #" .. tostring(self.stressCount)):calls(function(t, text)
                    self.stress = false
                    self.text = text
                    self.stressCount = self.stressCount + 1
                end)
            end
        end
    }))

    list:addChild(uie.button("Reload", scene.reloadSharp))

    list:addChild(uie.button("Dummy Task", function()
        local installer = scener.push("installer")
        installer.sharpTask("dummyTask", 30, 500):calls(function(task, last)
            if not last then
                return
            end

            installer.update("done", 1, "done")
            installer.done({
                {
                    "OK",
                    function()
                        scener.pop()
                    end
                }
            })
        end)
    end))
end


function scene.reloadRun()
    local all = root:findChild("all")

    local list = root:findChild("listRun")
    if list then
        list.children = {}
    else
        list = uie.column({}):with(uiu.fillWidth)

        all:addChild(list:as("listRun"))
    end

    list:addChild(uie.label("run", ui.fontBig))

    for i = 1, 10 do
        local item = uie.label(string.format("%02d | -", i), ui.fontMono)
        threader.run(function()
            require("threader").sleep(require("love.math").random() * 0.01)
            return string.format("%02d", i)
        end):calls(function(t, text)
            item.text = string.format("%02d | %s", i, text)
        end)

        list:addChild(item)
    end

    list:addChild(uie.button("Reload", scene.reloadRun))
end


function scene.reloadRoutine()
    local all = root:findChild("all")

    local list = root:findChild("listRoutine")
    if list then
        list.children = {}
    else
        list = uie.column({}):with(uiu.fillWidth)

        all:addChild(list:as("listRoutine"))
    end

    list:addChild(uie.label("routine", ui.fontBig))

    for i = 1, 10 do
        local item = uie.label(string.format("%02d | -", i), ui.fontMono)
        threader.routine(function()
            require("threader").sleep(require("love.math").random() * 0.01)
            return string.format("%02d", i)
        end):calls(function(t, text)
            item.text = string.format("%02d | %s", i, text)
        end)

        list:addChild(item)
    end

    list:addChild(uie.button("Reload", scene.reloadRoutine))
end


function scene.reloadAll()
    root = uie.column({

        uie.scrollbox(
            uie.column({
            }):with({
                style = {
                    bg = {},
                    padding = 16,
                }
            }):with(uiu.fillWidth):as("all")
        ):with({
            style = {
                barPadding = 16,
            },
            clip = false,
            cacheable = false
        }):with(uiu.fillWidth):with(uiu.fillHeight(true)),

        uie.button("Reload", scene.reloadAll):with(uiu.bottombound)

    }):with({
        cacheable = false,
        _fullroot = true
    })
    scene.root = root
    scener.onChange(scener.current, scener.current)

    scene.reloadSharp()
    scene.reloadRun()
    scene.reloadRoutine()
end


function scene.load()
    scene.reloadAll()
end


function scene.enter()

end


return scene
