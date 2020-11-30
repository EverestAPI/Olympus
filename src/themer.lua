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

    for id, tel in pairs(theme) do
        local el = uie["__" .. id]
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
end

themer.default = themer.dump()

return themer
