-- Velocity component
local Concord = require("lib.concord")

local Velocity = Concord.component("velocity", function(c, x, y)
    c.x = x or 0
    c.y = y or 0
end)

return Velocity 