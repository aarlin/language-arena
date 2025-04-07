-- Controller component
local Concord = require("lib.concord.init")

local Controller = Concord.component("controller", function(c, joystick, isBot)
    c.joystick = joystick
    c.isBot = isBot or false
end)

return Controller 