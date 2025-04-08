-- Component definitions
local Concord = require("lib.concord.init")

-- Position component
local Position = Concord.component("position", function(self, x, y)
    self.x = x or 0
    self.y = y or 0
end)

-- Velocity component
local Velocity = Concord.component("velocity", function(self, x, y)
    self.x = x or 0
    self.y = y or 0
end)

-- Dimensions component
local Dimensions = Concord.component("dimensions", function(self, width, height)
    self.width = width or 0
    self.height = height or 0
end)

-- Player component
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

-- Box component
local Box = Concord.component("box", function(self, character, meaning, isPoop)
    self.character = character or ""
    self.meaning = meaning or ""
    self.isPoop = isPoop or false
end)

-- Controller component
local Controller = Concord.component("controller", function(self, joystick, isBot, controls)
    self.joystick = joystick
    self.isBot = isBot or false
    self.controls = controls or {}
end)

-- Animation component
local Animation = Concord.component("animation", function(self, currentAnimation, currentFrame, frameTimer)
    self.currentAnimation = currentAnimation or "idle"
    self.currentFrame = currentFrame or 1
    self.frameTimer = frameTimer or 0
end)

-- Return the components
return {
    Position = Position,
    Velocity = Velocity,
    Dimensions = Dimensions,
    Player = Player,
    Box = Box,
    Controller = Controller,
    Animation = Animation
} 