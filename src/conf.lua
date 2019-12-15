function love.conf(t)
    t.window.title = "Everest.Olympus"
    t.window.width = 800
    t.window.minwidth = 800
    t.window.height = 600
    t.window.minheight = 600
    t.window.borderless = false
    t.window.resizable = true -- when borderless, true causes a flickering border on Windows
    t.window.vsync = 1
    t.window.highdpi = true
    t.console = false
end
