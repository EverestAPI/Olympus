function love.conf(t)
    local configStatus, config = pcall(require, "config")
    if config then
        config.load()
    else
        config = {
            csd = false
        }
    end

    t.window.title = "Everest.Olympus"
    t.window.width = 800
    t.window.minwidth = 800
    t.window.height = 600
    t.window.minheight = 600
    t.window.borderless = config.csd
    t.window.resizable = true -- when borderless, true causes a flickering border on Windows
    t.window.vsync = 0
    t.window.highdpi = true
    t.console = false
end
