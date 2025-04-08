local Concord = require("lib.concord")

local Velocity = Concord.component("velocity", function(self, x, y)
    self.x = x or 0
    self.y = y or 0
end)

return Velocity 