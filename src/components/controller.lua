-- Controller component
local Concord = require("lib.concord.init")

local Controller = Concord.component("controller", function(c, joystick, isBot, controls)
    c.joystick = joystick
    c.isBot = isBot or false
    c.controls = controls or {
        left = "dpleft",
        right = "dpright",
        jump = "a",
        down = "dpdown",
        run = "b",
        kick = "leftshoulder",
        start = "start",
        back = "back"
    }
end)

return Controller 