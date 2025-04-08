-- Dimensions component
local Concord = require("lib.concord")

local Dimensions = Concord.component("dimensions", function(c, width, height)
    c.width = width or 100
    c.height = height or 100
end)

return Dimensions 