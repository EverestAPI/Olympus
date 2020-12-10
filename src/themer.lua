local ui, uiu, uie = require("ui").quick()

local themer = {}

function themer.dump()
    local theme = {}

    for id, el in pairs(uie) do
        id = id:match("__(.+)")
        if not id then
            goto next
        end

        local style = el.__default
        style = style and style.style
        if not style then
            style = {}
        end

        local sub = {}

        for key, value in pairs(style) do
            sub[key] = value
        end

        if sub then
            theme[id] = sub
        end

        ::next::
    end

    return theme
end

function themer.apply(theme)
    if not theme then
        return
    end

    if themer.current ~= themer.default and theme ~= themer.default then
        themer.apply(themer.default)
    end

    themer.current = theme

    for id, tel in pairs(theme) do
        local el = uie[id]
        if not el then
            goto next
        end

        local style = el.__default
        if not style then
            goto next
        end

        style = style and style.style
        if not style then
            style = {}
            el.__default.style = style
        end

        for key, value in pairs(tel) do
            style[key] = value
        end

        ::next::
    end

    if ui.root then
        ui.globalReflowID = ui.globalReflowID + 1
    end
end

function themer.skin(theme, el)
    theme = theme or themer.default

    local function skin(el)
        local style = el.style
        local types = el.__types

        local custom = {}
        for key, value in pairs(style) do
            custom[key] = value
        end

        for i = #types, 1, -1 do
            local type = types[i]
            local sub = uie[type]
            if sub then
                sub = sub.__default.style
                if sub then
                    for key, value in pairs(sub) do
                        if _G.type(value) == "table" then
                            local copy = {}
                            for k, v in pairs(value) do
                                copy[k] = v
                            end
                            value = copy
                        end
                        style[key] = value
                    end
                end
            end

            local sub = theme[type]
            if sub then
                for key, value in pairs(sub) do
                    if _G.type(value) == "table" then
                        local copy = {}
                        for k, v in pairs(value) do
                            copy[k] = v
                        end
                        value = copy
                    end
                    style[key] = value
                end
            end
        end

        for key, value in pairs(custom) do
            style[key] = value
        end

        local children = el.children
        if children then
            for i = 1, #children do
                skin(children[i])
            end
        end
    end

    if el then
        return skin(el)
    end
    return skin
end

themer.default = themer.dump()
themer.current = themer.default

return themer
