-- Player component
local Concord = require("lib.concord.init")
local Constants = require("constants")
local logger = require("logger")

-- Animation states
local ANIMATION_STATES = {
    IDLE = "idle",
    WALK = "walk",
    RUN = "run",
    JUMP = "jump",
    CROUCH = "crouch",
    KO = "ko",
    DANCE = "dance",
    KICK = "kick",
    AIR_DODGE = "air_dodge",
    WAVE_DASH = "wave_dash",
    WAVE_LAND = "wave_land"
}

local Player = Concord.component("player", function(p, name, color, controls, characterType)
    -- Basic properties
    p.name = name or "Player"
    p.color = color or {1, 1, 1}
    p.controls = controls or {}
    p.characterType = characterType or "raccoon"
    
    -- Movement properties
    p.isGrounded = false
    p.isJumping = false
    p.isRunning = false
    p.isCrouching = false
    p.isAirDodging = false
    p.isWaveDashing = false
    p.isWaveLanding = false
    p.facingRight = true
    
    -- Combat properties
    p.isKicking = false
    p.kickTimer = 0
    p.isInvulnerable = false
    p.invulnerabilityTimer = 0
    p.isImmobile = false
    p.immobilityTimer = 0
    p.isKnockback = false
    p.knockbackTimer = 0
    p.bounceCount = 0
    
    -- Animation properties
    p.currentAnimation = ANIMATION_STATES.IDLE
    p.animationTimer = 0
    p.currentFrame = 1
    p.animations = {}
    
    -- Game properties
    p.score = 0
    p.collectedApples = {}
    
    -- Load animations
    p:loadAnimations()
end)

-- Animation loading function
function Player:loadAnimations()
    -- Initialize animation tables
    for _, state in pairs(ANIMATION_STATES) do
        self.animations[state] = {frames = {}}
    end
    
    -- Load idle animation
    local idleFrames = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}
    for _, frameNum in ipairs(idleFrames) do
        local frameNumber = string.format("%04d", frameNum)
        local success, image = pcall(function() 
            return love.graphics.newImage("assets/characters/" .. self.characterType .. "/idle/" .. frameNumber .. ".png")
        end)
        
        if success then
            table.insert(self.animations[ANIMATION_STATES.IDLE].frames, image)
        end
    end
    
    -- Load walk animation
    local walkFrames = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}
    for _, frameNum in ipairs(walkFrames) do
        local frameNumber = string.format("%04d", frameNum)
        local success, image = pcall(function() 
            return love.graphics.newImage("assets/characters/" .. self.characterType .. "/walk/" .. frameNumber .. ".png")
        end)
        
        if success then
            table.insert(self.animations[ANIMATION_STATES.WALK].frames, image)
        end
    end
    
    -- Load run animation
    local runFrames = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}
    for _, frameNum in ipairs(runFrames) do
        local frameNumber = string.format("%04d", frameNum)
        local success, image = pcall(function() 
            return love.graphics.newImage("assets/characters/" .. self.characterType .. "/run/" .. frameNumber .. ".png")
        end)
        
        if success then
            table.insert(self.animations[ANIMATION_STATES.RUN].frames, image)
        end
    end
    
    -- Load jump animation
    local jumpFrames = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}
    for _, frameNum in ipairs(jumpFrames) do
        local frameNumber = string.format("%04d", frameNum)
        local success, image = pcall(function() 
            return love.graphics.newImage("assets/characters/" .. self.characterType .. "/jump/" .. frameNumber .. ".png")
        end)
        
        if success then
            table.insert(self.animations[ANIMATION_STATES.JUMP].frames, image)
        end
    end
    
    -- Load crouch animation
    local crouchFrames = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}
    for _, frameNum in ipairs(crouchFrames) do
        local frameNumber = string.format("%04d", frameNum)
        local success, image = pcall(function() 
            return love.graphics.newImage("assets/characters/" .. self.characterType .. "/crouch/" .. frameNumber .. ".png")
        end)
        
        if success then
            table.insert(self.animations[ANIMATION_STATES.CROUCH].frames, image)
        end
    end
    
    -- Load kick animation
    local kickFrames = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}
    for _, frameNum in ipairs(kickFrames) do
        local frameNumber = string.format("%04d", frameNum)
        local success, image = pcall(function() 
            return love.graphics.newImage("assets/characters/" .. self.characterType .. "/kick/" .. frameNumber .. ".png")
        end)
        
        if success then
            table.insert(self.animations[ANIMATION_STATES.KICK].frames, image)
        end
    end
    
    -- Load air dodge animation
    local airDodgeFrames = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}
    for _, frameNum in ipairs(airDodgeFrames) do
        local frameNumber = string.format("%04d", frameNum)
        local success, image = pcall(function() 
            return love.graphics.newImage("assets/characters/" .. self.characterType .. "/airDodge/" .. frameNumber .. ".png")
        end)
        
        if success then
            table.insert(self.animations[ANIMATION_STATES.AIR_DODGE].frames, image)
        end
    end
    
    -- Load wave dash animation
    local waveDashFrames = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}
    for _, frameNum in ipairs(waveDashFrames) do
        local frameNumber = string.format("%04d", frameNum)
        local success, image = pcall(function() 
            return love.graphics.newImage("assets/characters/" .. self.characterType .. "/waveDash/" .. frameNumber .. ".png")
        end)
        
        if success then
            table.insert(self.animations[ANIMATION_STATES.WAVE_DASH].frames, image)
        end
    end
    
    -- Load wave land animation
    local waveLandFrames = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}
    for _, frameNum in ipairs(waveLandFrames) do
        local frameNumber = string.format("%04d", frameNum)
        local success, image = pcall(function() 
            return love.graphics.newImage("assets/characters/" .. self.characterType .. "/waveLand/" .. frameNumber .. ".png")
        end)
        
        if success then
            table.insert(self.animations[ANIMATION_STATES.WAVE_LAND].frames, image)
        end
    end
end

return Player 