function love.conf(t)
    t.identity = "language-arena"
    t.version = "11.4"
    t.console = false
    
    t.window.title = "Language Arena"
    t.window.width = 1920
    t.window.height = 1080
    t.window.resizable = true
    
    t.modules.joystick = true
    t.modules.audio = true
    t.modules.data = true
    t.modules.event = true
    t.modules.font = true
    t.modules.graphics = true
    t.modules.image = true
    t.modules.keyboard = true
    t.modules.math = true
    t.modules.mouse = true
    t.modules.physics = true
    t.modules.sound = true
    t.modules.system = true
    t.modules.thread = true
    t.modules.timer = true
    t.modules.touch = true
    t.modules.video = true
    t.modules.window = true
end 