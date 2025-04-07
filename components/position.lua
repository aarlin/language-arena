-- Position component
local Concord = require("lib.concord.init")

local Position = Concord.component("position", function(c, x, y)
    c.x = x or 0
    c.y = y or 0
end)

return Position 