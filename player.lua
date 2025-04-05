local logger = require("logger")  -- Import the logger

-- Animation states
local ANIMATION_STATES = {
    IDLE = "idle",
    WALK = "walk",
    RUN = "run",
    JUMP = "jump",
    CROUCH = "crouch",
    KO = "ko",
    VICTORY = "victory",
    DROPKICK = "dropkick"
}

-- Player class
local Player = {}
Player.__index = Player

function Player.new(x, y, color, controls)
    local self = setmetatable({}, Player)
    self.x = x
    self.y = y
    self.color = color
    self.controls = controls or {}
    self.velocity = {x = 0, y = 0}
    self.speed = 300
    self.runSpeed = 600
    self.jumpForce = -500
    self.gravity = 1000
    self.isJumping = false
    self.isRunning = false
    self.isCrouching = false
    self.isKicking = false
    self.isSliding = false
    self.isKO = false
    self.isVictory = false
    self.kickTimer = 0
    self.kickDuration = 0.3
    self.slideTimer = 0
    self.slideDuration = 0.5
    self.slideCooldown = 0
    self.slideCooldownDuration = 2
    self.controller = nil
    self.score = 0
    self.collectedCharacters = {}  -- Changed from collectedApples
    self.name = "Player " .. (controls and controls.controller or "Unknown")
    self.facingRight = true
    self.currentAnimation = ANIMATION_STATES.IDLE
    self.animationTimer = 0
    self.animationSpeed = 0.1
    self.currentFrame = 1
    self.animations = {}
    self.width = 48  -- Reduced from 64 to make player smaller
    self.height = 48 -- Reduced from 64 to make player smaller
    self.isBot = false  -- Flag to indicate if this is a bot
    self.botTimer = 0
    self.botActionInterval = 2  -- Bot decides new action every 2 seconds
    self.botTargetX = 0
    self.botTargetY = 0
    self.botState = "idle"  -- Current bot state: idle, moving, jumping, kicking
    self.isKnockback = false
    self.knockbackTimer = 0
    self.knockbackDuration = 0.5  -- Knockback lasts for 0.5 seconds
    self.invulnerableTimer = 0
    self.invulnerableDuration = 2  -- Invulnerability lasts for 2 seconds
    self.flashTimer = 0
    self.flashInterval = 0.1  -- Flash every 0.1 seconds
    self.health = 100  -- Add health field
    self.maxHealth = 100  -- Add maxHealth field
    
    -- Load animations
    self:loadAnimations()
    
    logger:info("Player created: %s at position (%.2f, %.2f)", self.name, self.x, self.y)
    
    return self
end

function Player:loadAnimations()
    -- Wrap the entire function in error handling
    local success, errorMsg = pcall(function()
        -- Initialize animation tables
        for _, state in pairs(ANIMATION_STATES) do
            self.animations[state] = {frames = {}}
        end
        
        -- Load idle animation (odd-numbered frames)
        local idleFrames = {1, 3, 5, 7, 9, 11}
        for _, frameNum in ipairs(idleFrames) do
            local frameNumber = string.format("%04d", frameNum)
            local success, image = pcall(function() 
                return love.graphics.newImage("assets/raccoon/idle/idle" .. frameNumber .. ".png")
            end)
            
            if success then
                table.insert(self.animations[ANIMATION_STATES.IDLE].frames, image)
                logger:debug("Loaded idle animation frame: idle%s.png", frameNumber)
            else
                logger:error("Failed to load idle animation frame: idle%s.png - %s", frameNumber, image)
            end
        end
        
        -- Load walk animation (odd-numbered frames)
        local walkFrames = {1, 3, 5, 7}
        for _, frameNum in ipairs(walkFrames) do
            local frameNumber = string.format("%04d", frameNum)
            local success, image = pcall(function() 
                return love.graphics.newImage("assets/raccoon/walk/walk" .. frameNumber .. ".png")
            end)
            
            if success then
                table.insert(self.animations[ANIMATION_STATES.WALK].frames, image)
                logger:debug("Loaded walk animation frame: walk%s.png", frameNumber)
            else
                logger:error("Failed to load walk animation frame: walk%s.png - %s", frameNumber, image)
            end
        end
        
        -- Load run animation (odd-numbered frames)
        local runFrames = {1, 3, 5, 7}
        for _, frameNum in ipairs(runFrames) do
            local frameNumber = string.format("%04d", frameNum)
            local success, image = pcall(function() 
                return love.graphics.newImage("assets/raccoon/run/run" .. frameNumber .. ".png")
            end)
            
            if success then
                table.insert(self.animations[ANIMATION_STATES.RUN].frames, image)
                logger:debug("Loaded run animation frame: run%s.png", frameNumber)
            else
                logger:error("Failed to load run animation frame: run%s.png - %s", frameNumber, image)
            end
        end
        
        -- Load jump animation (odd-numbered frames)
        local jumpFrames = {1, 3}
        for _, frameNum in ipairs(jumpFrames) do
            local frameNumber = string.format("%04d", frameNum)
            local success, image = pcall(function() 
                return love.graphics.newImage("assets/raccoon/jump/jump" .. frameNumber .. ".png")
            end)
            
            if success then
                table.insert(self.animations[ANIMATION_STATES.JUMP].frames, image)
                logger:debug("Loaded jump animation frame: jump%s.png", frameNumber)
            else
                logger:error("Failed to load jump animation frame: jump%s.png - %s", frameNumber, image)
            end
        end
        
        -- Load crouch animation (odd-numbered frames)
        local crouchFrames = {1, 3}
        for _, frameNum in ipairs(crouchFrames) do
            local frameNumber = string.format("%04d", frameNum)
            local success, image = pcall(function() 
                return love.graphics.newImage("assets/raccoon/crouch/crouch" .. frameNumber .. ".png")
            end)
            
            if success then
                table.insert(self.animations[ANIMATION_STATES.CROUCH].frames, image)
                logger:debug("Loaded crouch animation frame: crouch%s.png", frameNumber)
            else
                logger:error("Failed to load crouch animation frame: crouch%s.png - %s", frameNumber, image)
            end
        end
        
        -- Load KO animation (odd-numbered frames)
        local koFrames = {2, 4, 6}
        for _, frameNum in ipairs(koFrames) do
            local frameNumber = string.format("%04d", frameNum)
            local success, image = pcall(function() 
                return love.graphics.newImage("assets/raccoon/ko/ko" .. frameNumber .. ".png")
            end)
            
            if success then
                table.insert(self.animations[ANIMATION_STATES.KO].frames, image)
                logger:debug("Loaded KO animation frame: ko%s.png", frameNumber)
            else
                logger:error("Failed to load KO animation frame: ko%s.png - %s", frameNumber, image)
            end
        end
        
        -- Load victory animation (odd-numbered frames)
        local victoryFrames = {1, 3, 5}
        for _, frameNum in ipairs(victoryFrames) do
            local frameNumber = string.format("%04d", frameNum)
            local success, image = pcall(function() 
                return love.graphics.newImage("assets/raccoon/victory-dance/victory-dance" .. frameNumber .. ".png")
            end)
            
            if success then
                table.insert(self.animations[ANIMATION_STATES.VICTORY].frames, image)
                logger:debug("Loaded victory animation frame: victory%s.png", frameNumber)
            else
                logger:error("Failed to load victory animation frame: victory%s.png - %s", frameNumber, image)
            end
        end
        
        -- Load dropkick animation (odd-numbered frames)
        local dropkickFrames = {1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23}
        for _, frameNum in ipairs(dropkickFrames) do
            local frameNumber = string.format("%04d", frameNum)
            local success, image = pcall(function() 
                return love.graphics.newImage("assets/raccoon/dropkick/dropkick" .. frameNumber .. ".png")
            end)
            
            if success then
                table.insert(self.animations[ANIMATION_STATES.DROPKICK].frames, image)
                logger:debug("Loaded dropkick animation frame: dropkick%s.png", frameNumber)
            else
                logger:error("Failed to load dropkick animation frame: dropkick%s.png - %s", frameNumber, image)
            end
        end
        
        -- Create a fallback image for missing animations
        local fallbackImage = love.graphics.newCanvas(48, 48)
        love.graphics.setCanvas(fallbackImage)
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.rectangle("fill", 0, 0, 48, 48)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setCanvas()
        
        -- Set fallback image for any animation that has no frames
        for _, state in pairs(ANIMATION_STATES) do
            if #self.animations[state].frames == 0 then
                table.insert(self.animations[state].frames, fallbackImage)
                logger:info("Using fallback image for %s animation", state)
            end
        end
    end)
    
    -- If an error occurred, log it and create a basic fallback
    if not success then
        logger:error("Error loading animations for player %s: %s", self.name, errorMsg)
        
        -- Create a basic fallback image
        local fallbackImage = love.graphics.newCanvas(48, 48)
        love.graphics.setCanvas(fallbackImage)
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.rectangle("fill", 0, 0, 48, 48)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setCanvas()
        
        -- Set fallback image for all animations
        for _, state in pairs(ANIMATION_STATES) do
            self.animations[state] = {frames = {fallbackImage}}
            logger:info("Using fallback image for %s animation due to error", state)
        end
    end
end

function Player:setController(joystick)
    self.controller = joystick
    logger:info("Controller set for player %s: %s", self.name, joystick:getName())
end

function Player:update(dt)
    -- Wrap the entire update function in error handling
    local success, errorMsg = pcall(function()
        -- Update animation
        self.animationTimer = self.animationTimer + dt
        if self.animationTimer >= self.animationSpeed then
            self.animationTimer = 0
            self.currentFrame = self.currentFrame + 1
            if self.currentFrame > #self.animations[self.currentAnimation].frames then
                self.currentFrame = 1
            end
        end
        
        -- Update kick timer
        if self.isKicking then
            self.kickTimer = self.kickTimer + dt
            if self.kickTimer >= self.kickDuration then
                self.isKicking = false
                self.kickTimer = 0
                if not self.isJumping then
                    self:setAnimation(ANIMATION_STATES.IDLE)
                end
            end
        end
        
        -- Update slide timer
        if self.isSliding then
            self.slideTimer = self.slideTimer + dt
            if self.slideTimer >= self.slideDuration then
                self.isSliding = false
                self.slideTimer = 0
                if not self.isJumping then
                    self:setAnimation(ANIMATION_STATES.IDLE)
                end
            end
        end
        
        -- Update slide cooldown
        if self.slideCooldown > 0 then
            self.slideCooldown = self.slideCooldown - dt
        end
        
        -- Update knockback and invulnerability timers
        if self.isKnockback then
            self.knockbackTimer = self.knockbackTimer + dt
            if self.knockbackTimer >= self.knockbackDuration then
                self.isKnockback = false
                self.knockbackTimer = 0
                -- Player can move again after knockback ends
                self.velocity.x = 0
            end
        end
        
        if self.invulnerableTimer > 0 then
            self.invulnerableTimer = self.invulnerableTimer - dt
            -- Update flash effect
            self.flashTimer = self.flashTimer + dt
            if self.flashTimer >= self.flashInterval then
                self.flashTimer = 0
            end
        end
        
        -- Apply gravity
        self.velocity.y = self.velocity.y + self.gravity * dt
        
        -- Apply velocity
        self.x = self.x + self.velocity.x * dt
        self.y = self.y + self.velocity.y * dt
        
        -- Screen boundaries
        if self.x < 0 then
            self.x = 0
            self.velocity.x = 0
        elseif self.x > 1200 - self.width then
            self.x = 1200 - self.width
            self.velocity.x = 0
        end
        
        -- Ground collision
        if self.y > 600 - self.height then
            self.y = 600 - self.height
            self.velocity.y = 0
            self.isJumping = false
            if self.currentAnimation == ANIMATION_STATES.JUMP then
                self:setAnimation(ANIMATION_STATES.IDLE)
            end
        end
        
        -- Handle controller input or bot behavior
        if self.controller then
            -- Human player input handling
            -- Movement
            local moveX = self.controller:getGamepadAxis("leftx")
            if math.abs(moveX) > 0.1 and not self.isKnockback then
                -- Determine if running
                local isRunningNow = self.controller:isGamepadDown(self.controls.down)
                if isRunningNow ~= self.isRunning then
                    self.isRunning = isRunningNow
                    logger:debug("Player %s %s", self.name, self.isRunning and "started running" or "stopped running")
                end
                
                -- Set speed based on running state
                local currentSpeed = self.isRunning and self.runSpeed or self.speed
                
                -- Apply movement
                self.velocity.x = moveX * currentSpeed
                
                -- Set animation based on movement (only if not kicking)
                if not self.isKicking and not self.isSliding then
                    if self.isRunning then
                        self:setAnimation(ANIMATION_STATES.RUN)
                    else
                        self:setAnimation(ANIMATION_STATES.WALK)
                    end
                end
                
                -- Update facing direction
                self.facingRight = moveX > 0
            else
                -- No horizontal movement
                self.velocity.x = 0
                if not self.isJumping and not self.isKicking and not self.isSliding then
                    self:setAnimation(ANIMATION_STATES.IDLE)
                end
            end
            
            -- Jumping
            if self.controller:isGamepadDown(self.controls.jump) and not self.isJumping and not self.isKnockback then
                self.velocity.y = self.jumpForce
                self.isJumping = true
                self:setAnimation(ANIMATION_STATES.JUMP)
                logger:debug("Player %s jumped", self.name)
            end
            
            -- Crouching
            if self.controller:isGamepadDown(self.controls.down) and not self.isRunning and not self.isJumping and not self.isKnockback then
                self:setAnimation(ANIMATION_STATES.CROUCH)
            end
            
            -- Kicking (using left trigger)
            local leftTrigger = self.controller:getGamepadAxis("triggerleft")
            if leftTrigger > 0.5 and not self.isKicking and not self.isKnockback then
                self:kick()
            end
            
            -- Sliding (using left shoulder button)
            if self.controller:isGamepadDown(self.controls.slide) and not self.isSliding and self.slideCooldown <= 0 and not self.isKnockback then
                self:slide()
            end
        elseif self.isBot then
            -- Bot behavior
            self.botTimer = self.botTimer + dt
            if self.botTimer >= self.botActionInterval then
                self.botTimer = 0
                self:updateBotBehavior()
            end
            
            -- Execute current bot action
            self:executeBotAction(dt)
        end
        
        -- Log player state periodically
        if math.floor(love.timer.getTime() * 2) % 10 == 0 then
            logger:logPlayerState(self)
        end
    end)
    
    -- If an error occurred, log it
    if not success then
        logger:error("Error updating player %s: %s", self.name, errorMsg)
        -- Try to recover by resetting to a safe state
        self.velocity = {x = 0, y = 0}
        self.isJumping = false
        self.isKicking = false
        self.isSliding = false
        self.isKnockback = false
        self:setAnimation(ANIMATION_STATES.IDLE)
    end
end

function Player:draw()
    -- Draw player
    love.graphics.setColor(1, 1, 1)
    
    -- Get current animation frame
    local currentAnim = self.animations[self.currentAnimation]
    if currentAnim and currentAnim.frames and #currentAnim.frames > 0 then
        local frame = currentAnim.frames[self.currentFrame]
        if frame then
            -- Draw with proper facing direction
            local scaleX = self.facingRight and 0.5 or -0.5  -- Changed from 1 to 0.5 for smaller size
            
            -- Always draw at the same position, regardless of facing direction
            local drawX = self.x + self.width/2
            if self.facingRight then
                -- Move character slightly to the right when facing right
                drawX = drawX + 10
            else
                -- Move character slightly to the left when facing left
                drawX = drawX - 10
            end
            
            -- Apply flashing effect when invulnerable
            if self.invulnerableTimer > 0 and self.flashTimer < self.flashInterval/2 then
                love.graphics.setColor(1, 1, 1, 0.5)  -- Semi-transparent when flashing
            else
                love.graphics.setColor(1, 1, 1, 1)  -- Fully opaque otherwise
            end
            
            -- Draw the frame with proper scaling and origin point
            love.graphics.draw(frame, drawX, self.y + self.height/2, 0, scaleX, 0.5, frame:getWidth()/2, frame:getHeight()/2)  -- Changed scaleY from 1 to 0.5
        else
            -- Fallback: draw a simple rectangle if the frame is missing
            love.graphics.rectangle("fill", self.x, self.y, self.width/2, self.height/2)  -- Scaled down rectangle
            logger:debug("Missing animation frame for %s at index %d", self.currentAnimation, self.currentFrame)
        end
    else
        -- Fallback: draw a simple rectangle if the animation is missing
        love.graphics.rectangle("fill", self.x, self.y, self.width/2, self.height/2)  -- Scaled down rectangle
        logger:debug("Missing animation: %s", self.currentAnimation)
    end
    
    -- Draw collected characters (smaller and above player name)
    for i, char in ipairs(self.collectedCharacters) do
        -- Draw character image at a smaller size
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(char.image, self.x + 20 + (i-1) * 20, self.y - 130, 0, 0.3, 0.3)
    end
    
    -- Draw name at the top of the player model
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(self.name, self.x + self.width/2 - 20, self.y - 110)
end

function Player:setAnimation(animation)
    -- Wrap the function in error handling
    local success, errorMsg = pcall(function()
        -- Check if the animation exists and has frames
        if self.animations[animation] and #self.animations[animation].frames > 0 then
            if self.currentAnimation ~= animation then
                self.currentAnimation = animation
                self.currentFrame = 1
                self.animationTimer = 0
                logger:debug("Player %s animation changed to %s", self.name, animation)
            end
        else
            -- If the animation doesn't exist or has no frames, use IDLE as fallback
            logger:warning("Animation %s not found or has no frames, using IDLE as fallback", animation)
            if self.currentAnimation ~= ANIMATION_STATES.IDLE then
                self.currentAnimation = ANIMATION_STATES.IDLE
                self.currentFrame = 1
                self.animationTimer = 0
            end
        end
    end)
    
    -- If an error occurred, log it and use IDLE as fallback
    if not success then
        logger:error("Error setting animation for player %s: %s", self.name, errorMsg)
        self.currentAnimation = ANIMATION_STATES.IDLE
        self.currentFrame = 1
        self.animationTimer = 0
    end
end

function Player:kick()
    self.isKicking = true
    self.kickTimer = 0
    self:setAnimation(ANIMATION_STATES.DROPKICK)  -- Using dropkick animation for kick
    logger:debug("Player %s kicked (using dropkick animation)", self.name)
end

function Player:slide()
    self.isSliding = true
    self.slideTimer = 0
    self.slideCooldown = self.slideCooldownDuration
    self:setAnimation(ANIMATION_STATES.DROPKICK)  -- Using dropkick animation for slide
    logger:debug("Player %s slid (using dropkick animation)", self.name)
end

function Player:takeKnockback(velocity)
    self.velocity.x = velocity.x
    self.velocity.y = velocity.y
    self.isJumping = true
    self:setAnimation(ANIMATION_STATES.KO)
    
    -- Could add sound effects here
    -- love.audio.play(hitSound)
    
    logger:info("Player %s took knockback", self.name)
end

function Player:collectCharacter(box)
    table.insert(self.collectedCharacters, box)
    logger:info("Player %s collected character: %s", self.name, box.meaning)
end

function Player:gamepadpressed(button)
    logger:debug("Player %s pressed button: %s", self.name, button)
end

-- Bot behavior functions
function Player:updateBotBehavior()
    -- Decide on a new action
    local actions = {"idle", "moving", "jumping", "dropkick"}
    self.botState = actions[love.math.random(1, #actions)]
    
    -- Set target position if moving
    if self.botState == "moving" then
        self.botTargetX = love.math.random(100, 1100 - self.width)
        self.botTargetY = 600 - self.height  -- Stay on the ground
    end
    
    logger:debug("Bot %s chose action: %s", self.name, self.botState)
end

function Player:executeBotAction(dt)
    if self.botState == "idle" then
        -- Do nothing
        self.velocity.x = 0
        self:setAnimation(ANIMATION_STATES.IDLE)
    elseif self.botState == "moving" then
        -- Move towards target
        local dx = self.botTargetX - self.x
        local dy = self.botTargetY - self.y
        
        -- Set velocity based on direction
        if math.abs(dx) > 10 then
            self.velocity.x = dx > 0 and self.speed or -self.speed
            self.facingRight = dx > 0
        else
            self.velocity.x = 0
        end
        
        -- Set animation
        self:setAnimation(ANIMATION_STATES.WALK)
    elseif self.botState == "jumping" and not self.isJumping then
        -- Jump
        self.velocity.y = self.jumpForce
        self.isJumping = true
        self:setAnimation(ANIMATION_STATES.JUMP)
        logger:debug("Bot %s jumped", self.name)
    elseif self.botState == "dropkick" and not self.isKicking then
        -- Kick
        self:kick()
    end
end

return Player 