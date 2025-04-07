-- Animation component
local Concord = require("lib.concord")

local Animation = Concord.component("animation", function(c, currentAnimation, currentFrame, animationTimer)
    c.currentAnimation = currentAnimation or "idle"
    c.currentFrame = currentFrame or 1
    c.animationTimer = animationTimer or 0
    c.animationSpeed = 0.1
end)

return Animation 