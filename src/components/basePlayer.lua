-- Player component
local Concord = require("lib.concord.init")
local Constants = require("constants")

local Player = Concord.component("player", function(c, name, color, controls)
    c.name = name or "Player"
    c.color = color or {1, 1, 1}
    c.controls = controls or {}
    c.isJumping = false
    c.isRunning = false
    c.isKicking = false
    c.isKnockback = false
    c.isInvulnerable = false
    c.isImmobile = false
    c.facingRight = true
    c.speed = Constants.PLAYER_SPEED
    c.runSpeed = Constants.PLAYER_RUN_SPEED
    c.jumpForce = Constants.PLAYER_JUMP_FORCE
    c.gravity = Constants.PLAYER_GRAVITY
    c.invulnerabilityTimer = 0
    c.immobilityTimer = 0
    c.knockbackTimer = 0
    c.kickTimer = 0
    c.bounceCount = 0
    c.maxBounces = 3
    c.bounceHeight = Constants.KNOCKBACK_FORCE_Y
    c.bounceDecay = 0.7
    c.flashTimer = 0
    c.flashInterval = 0.1
    c.isFlashing = false
end)

return Player 