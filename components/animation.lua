-- Animation component
local Concord = require("lib.concord")

local Animation = Concord.component("animation", function(c, currentAnimation, currentFrame, animationTimer)
    c.currentAnimation = currentAnimation or "idle"
    c.currentFrame = currentFrame or 1
    c.animationTimer = animationTimer or 0
    c.animationSpeed = 0.1
    c.maxFrames = {
        idle = 23,  -- Number of frames in idle animation
        walk = 12,  -- Number of frames in walk animation
        run = 12,   -- Number of frames in run animation
        jump = 8,   -- Number of frames in jump animation
        kick = 6,   -- Number of frames in kick animation
        ko = 10     -- Number of frames in KO animation
    }
end)

return Animation 