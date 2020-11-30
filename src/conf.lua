require("prethread")("main")

function love.conf(t)
    local configStatus, config = pcall(require, "config")
    if configStatus then
        config.load()
    else
        config = {
            csd = false,
            vsync = true
        }
    end

    t.window.title = "Everest.Olympus"
    t.window.width = 1100
    t.window.minwidth = 1100
    t.window.height = 600
    t.window.minheight = 600
    t.window.borderless = config.csd
    t.window.resizable = true -- when borderless, true causes a flickering border on Windows
    t.window.vsync = config.vsync and 1 or 0
    t.window.highdpi = true
    t.console = false
end
