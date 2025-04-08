local Concord = require("lib.concord")

local Player = Concord.component("player", function(self, name, score, characterType, speed, runSpeed, jumpForce, gravity)
    self.name = name or "Player"
    self.score = score or 0
    self.characterType = characterType or "default"
    self.speed = speed or 200
    self.runSpeed = runSpeed or 400
    self.jumpForce = jumpForce or -400
    self.gravity = gravity or 800
    self.isJumping = false
    self.isRunning = false
    self.isKicking = false
    self.isKnockback = false
    self.isInvulnerable = false
    self.isImmobile = false
    self.facingRight = true
    self.kickTimer = 0
    self.knockbackTimer = 0
    self.invulnerabilityTimer = 0
    self.immobilityTimer = 0
    self.controller = 0
end)

return Player 