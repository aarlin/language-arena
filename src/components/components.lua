local Concord = require("lib.concord")

-- Basic components
Concord.component("position", function(c, x, y)
    c.x = x or 0
    c.y = y or 0
end)

Concord.component("velocity", function(c, x, y)
    c.x = x or 0
    c.y = y or 0
end)

Concord.component("size", function(c, width, height)
    c.width = width or 0
    c.height = height or 0
end)

-- Player specific components
Concord.component("player", function(c, name, color, character)
    c.name = name or "Player"
    c.color = color or {1, 1, 1}
    c.character = character or "default"
end)

-- Controller component
Concord.component("controller", function(c, joystick, controls)
    c.joystick = joystick
    c.controls = controls or {
        left = "leftx",
        jump = "a",
        down = "b",
        kick = "leftshoulder",
        start = "start",
        back = "back"
    }
end)

-- Animation component
Concord.component("animation", function(c, frames, currentFrame, frameTime)
    c.frames = frames or {}
    c.currentFrame = currentFrame or 1
    c.frameTime = frameTime or 0.1
    c.timer = 0
end)

-- Box component for collision
Concord.component("box", function(c, width, height)
    c.width = width or 0
    c.height = height or 0
end)

return Concord 