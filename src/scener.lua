
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
        local path = scene
        scene = require(scener.pathPrefix .. path)
        scene.path = scene.path or path
        scene.name = scene.name or path
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

function scener.pop(count)
    if count then
        for i = 1, count do
            if not scener.pop() then
                return false
            end
        end

        return count > 0
    end

    local scene = scener.current
    if scene and scene.leave then
        if scene.leave() == false then
            return false
        end
    end

    if #scener.stack <= 0 then
        return false
    end

    scener.set(table.remove(scener.stack))
    return true
end

return scener
