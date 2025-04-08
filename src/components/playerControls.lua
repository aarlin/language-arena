local Concord = require("lib.concord")
local Baton   = require("lib.baton")

return Concord.component("playerControls", function(self, up, down, left, right)
   local controls = {
      up    = up,
      down  = down,
      left  = left,
      right = right,
   }

   local pairs = {
      move = {
         "left", "right", "up", "down",
      }
   }

   self.controller = Baton.new({
      controls = controls,
      pairs    = pairs,
      joystick = love.joystick.getJoysticks()[1],
   })
end)
