
local scener = {}

function scener.onChange(prev, next)
end

function scener.set(scene)
    local prev = scener.scene
    if prev then
        prev.leave()
    end

    scener.scene = scene

    if not scene.loaded then
        scene.load()
        scene.loaded = true
    end

    scene.enter()

    scener.onChange(prev, scene)
end

return scener
