local Concord = require("lib.concord.init")

local Quicksand = Concord.component(function(e, sinkSpeed, maxSinkDepth)
    e.sinkSpeed = sinkSpeed or 50  -- How fast the player sinks
    e.maxSinkDepth = maxSinkDepth or 20  -- How deep the player can sink
    e.currentSinkDepth = 0  -- Current sink depth
    e.isSinking = false  -- Whether the player is currently sinking
end)

return Quicksand 