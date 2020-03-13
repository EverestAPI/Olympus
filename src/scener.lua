
local scener = {}

function scener.onChange(prev, next)
end

function scener.set(scene)
    local prev = scener.scene
    if prev and prev.leave then
        prev.leave()
    end

    scener.scene = scene

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
end

return scener
