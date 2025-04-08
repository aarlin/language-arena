local Concord = require("lib.concord")

local Controller = Concord.component("controller", function(self, joystick, isBot, controls)
    self.joystick = joystick
    self.isBot = isBot or false
    self.controls = controls or {}
end)

return Controller 