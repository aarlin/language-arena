local Concord = require("lib.concord")

local Animation = Concord.component("animation", function(self, currentAnimation, currentFrame, frameTimer)
    self.currentAnimation = currentAnimation or "idle"
    self.currentFrame = currentFrame or 1
    self.frameTimer = frameTimer or 0
end)

return Animation 