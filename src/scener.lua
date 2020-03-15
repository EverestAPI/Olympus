
local scener = {
    pathPrefix = "scenes/",
    current = nil,
    stack = {}
}

function scener.onChange(prev, next)
end

function scener.set(scene)
    local prev = scener.scene
    if prev and prev.leave then
        prev.leave()
    end

    if type(scene) == "string" then
        scene = require(scener.pathPrefix .. scene)
    end

    scener.current = scene

    if not scene.loaded then
        if scene.load then
            scene.load()
        end
        scene.loaded = true
    end

    if scene.enter then
        scene.enter()
    end

    scener.onChange(prev, scene)

    return scene
end

function scener.push(scene)
    table.insert(scener.stack, scener.current)
    scener.set(scene)
end

function scener.pop()
    scener.set(table.remove(scener.stack))
end

return scener
