local ui, uiu, uie = require("ui").quick()


uie.add("buttonGreen", {
    base = "button",
    style = {
        normalBG = { 0.2, 0.4, 0.2, 0.8 },
        hoveredBG = { 0.3, 0.6, 0.3, 0.9 },
        pressedBG = { 0.2, 0.6, 0.2, 0.9 }
    }
})

uie.add("listItemGreen", {
    base = "listItem",
    style = {
        normalBG = { 0.2, 0.4, 0.2, 0.8 },
        hoveredBG = { 0.36, 0.46, 0.39, 0.9 },
        pressedBG = { 0.1, 0.5, 0.2, 0.9 },
        selectedBG = { 0.5, 0.8, 0.5, 0.9 }
    }
})

uie.add("listItemYellow", {
    base = "listItem",
    style = {
        normalBG = { 0.5, 0.4, 0.1, 0.8 },
        hoveredBG = { 0.8, 0.7, 0.3, 0.9 },
        pressedBG = { 0.5, 0.4, 0.2, 0.9 },
        selectedBG = { 0.8, 0.7, 0.3, 0.9 }
    }
})


return uie
