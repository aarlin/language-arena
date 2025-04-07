-- Box component
local Concord = require("lib.concord")
local Constants = require("constants")

local Box = Concord.component("box", function(c, meaning, speed)
    c.meaning = meaning or ""
    c.speed = speed or Constants.BOX_MIN_SPEED
    c.collected = false
end)

return Box 