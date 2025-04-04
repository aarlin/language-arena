local logger = require("logger")  -- Import the logger

-- Animation states
local ANIMATION_STATES = {
    IDLE = "idle",
    WALK = "walk",
    RUN = "run",
    JUMP = "jump",
    CROUCH = "crouch",
    SLIDE = "slide",
    KO = "ko",
    VICTORY = "victory"
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
    self.isSliding = false
    self.slideTimer = 0
    self.slideDuration = 0.5
    self.slideCooldown = 0
    self.slideCooldownDuration = 3
    self.isPunching = false
    self.punchTimer = 0
    self.punchDuration = 0.2
    self.score = 0
    self.collectedApples = {}
    self.name = "Player " .. (controls and controls.controller or "Unknown")
    self.facingRight = true
    self.currentAnimation = ANIMATION_STATES.IDLE
    self.animationTimer = 0
    self.animationSpeed = 0.1
    self.currentFrame = 1
    self.animations = {}
    self.width = 48  -- Reduced from 64 to make player smaller
    self.height = 48 -- Reduced from 64 to make player smaller
    
    -- Load animations
    self:loadAnimations()
    
    logger:info("Player created: %s at position (%.2f, %.2f)", self.name, self.x, self.y)
    
    return self
end

function Player:loadAnimations()
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
    
    -- Load walk animation
    local walkFrames = {1, 2, 3, 4, 5, 6, 7, 8}
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
    
    -- Load run animation
    local runFrames = {1, 2, 3, 4, 5, 6, 7, 8}
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
    
    -- Load jump animation
    local jumpFrames = {1, 2, 3, 4}
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
    
    -- Load crouch animation
    local crouchFrames = {1, 2, 3, 4}
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
    
    -- Load slide animation
    local slideFrames = {}
    for i = 1, 23 do
        table.insert(slideFrames, i)
    end
    for _, frameNum in ipairs(slideFrames) do
        local frameNumber = string.format("%04d", frameNum)
        local success, image = pcall(function() 
            return love.graphics.newImage("assets/raccoon/slide/slide" .. frameNumber .. ".png")
        end)
        
        if success then
            table.insert(self.animations[ANIMATION_STATES.SLIDE].frames, image)
            logger:debug("Loaded slide animation frame: slide%s.png", frameNumber)
        else
            logger:error("Failed to load slide animation frame: slide%s.png - %s", frameNumber, image)
        end
    end
    
    -- Load KO animation
    local koFrames = {1, 2, 3, 4, 5, 6}
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
    
    -- Load victory animation
    local victoryFrames = {1, 2, 3, 4, 5, 6}
    for _, frameNum in ipairs(victoryFrames) do
        local frameNumber = string.format("%04d", frameNum)
        local success, image = pcall(function() 
            return love.graphics.newImage("assets/raccoon/victory/victory" .. frameNumber .. ".png")
        end)
        
        if success then
            table.insert(self.animations[ANIMATION_STATES.VICTORY].frames, image)
            logger:debug("Loaded victory animation frame: victory%s.png", frameNumber)
        else
            logger:error("Failed to load victory animation frame: victory%s.png - %s", frameNumber, image)
        end
    end
end

function Player:setController(joystick)
    self.controller = joystick
    logger:info("Controller set for player %s: %s", self.name, joystick:getName())
end

function Player:update(dt)
    -- Update animation
    self.animationTimer = self.animationTimer + dt
    if self.animationTimer >= self.animationSpeed then
        self.animationTimer = 0
        self.currentFrame = self.currentFrame + 1
        if self.currentFrame > #self.animations[self.currentAnimation].frames then
            self.currentFrame = 1
        end
    end
    
    -- Update slide cooldown
    if self.slideCooldown > 0 then
        self.slideCooldown = self.slideCooldown - dt
    end
    
    -- Update slide timer
    if self.isSliding then
        self.slideTimer = self.slideTimer + dt
        if self.slideTimer >= self.slideDuration then
            self.isSliding = false
            self.slideTimer = 0
            self:setAnimation(ANIMATION_STATES.IDLE)
            logger:debug("Player %s finished sliding", self.name)
        end
    end
    
    -- Update punch timer
    if self.isPunching then
        self.punchTimer = self.punchTimer + dt
        if self.punchTimer >= self.punchDuration then
            self.isPunching = false
            self.punchTimer = 0
            self:setAnimation(ANIMATION_STATES.IDLE)
            logger:debug("Player %s finished punching", self.name)
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
    
    -- Handle controller input
    if self.controller then
        -- Movement
        local moveX = self.controller:getGamepadAxis("leftx")
        if math.abs(moveX) > 0.1 then
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
            
            -- Set animation based on movement
            if self.isRunning then
                self:setAnimation(ANIMATION_STATES.RUN)
            else
                self:setAnimation(ANIMATION_STATES.WALK)
            end
            
            -- Update facing direction
            self.facingRight = moveX > 0
        else
            -- No horizontal movement
            self.velocity.x = 0
            if not self.isJumping and not self.isSliding and not self.isPunching then
                self:setAnimation(ANIMATION_STATES.IDLE)
            end
        end
        
        -- Jumping
        if self.controller:isGamepadDown(self.controls.jump) and not self.isJumping then
            self.velocity.y = self.jumpForce
            self.isJumping = true
            self:setAnimation(ANIMATION_STATES.JUMP)
            logger:debug("Player %s jumped", self.name)
        end
        
        -- Crouching
        if self.controller:isGamepadDown(self.controls.down) and not self.isRunning and not self.isJumping then
            self:setAnimation(ANIMATION_STATES.CROUCH)
        end
        
        -- Sliding
        if self.controller:isGamepadDown(self.controls.slide) and not self.isSliding and self.slideCooldown <= 0 then
            self:slide()
        end
        
        -- Punching
        if self.controller:isGamepadDown(self.controls.punch) and not self.isPunching then
            self:punch()
        end
    end
    
    -- Log player state periodically
    if math.floor(love.timer.getTime() * 2) % 10 == 0 then
        logger:logPlayerState(self)
    end
end

function Player:draw()
    -- Draw player
    love.graphics.setColor(1, 1, 1)
    
    -- Get current animation frame
    local frame = self.animations[self.currentAnimation].frames[self.currentFrame]
    if frame then
        -- Draw with proper facing direction
        local scaleX = self.facingRight and 1 or -1
        love.graphics.draw(frame, self.x + self.width/2, self.y + self.height/2, 0, scaleX, 1, self.width/2, self.height/2)
    else
        -- Fallback if animation frame is missing
        love.graphics.setColor(self.color)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
        logger:warning("Missing animation frame for %s: %s, frame %d", 
            self.name, self.currentAnimation, self.currentFrame)
    end
    
    -- Draw slide cooldown indicator
    if self.slideCooldown > 0 then
        love.graphics.setColor(1, 0, 0, 0.7)
        local cooldownWidth = 50 * (1 - self.slideCooldown / self.slideCooldownDuration)
        love.graphics.rectangle("fill", self.x, self.y - 10, cooldownWidth, 5)
    end
    
    -- Draw collected apples
    for i, apple in ipairs(self.collectedApples) do
        love.graphics.setColor(1, 0, 0)  -- Red apple
        love.graphics.circle("fill", self.x + 20 + (i-1) * 30, self.y - 30, 10)
        
        -- Draw stem
        love.graphics.setColor(0, 0.8, 0)  -- Green stem
        love.graphics.rectangle("fill", self.x + 20 + (i-1) * 30 - 1, self.y - 40, 2, 5)
    end
end

function Player:setAnimation(animation)
    if self.currentAnimation ~= animation then
        self.currentAnimation = animation
        self.currentFrame = 1
        self.animationTimer = 0
        logger:debug("Player %s animation changed to %s", self.name, animation)
    end
end

function Player:slide()
    self.isSliding = true
    self.slideTimer = 0
    self.slideCooldown = self.slideCooldownDuration
    self:setAnimation(ANIMATION_STATES.SLIDE)
    
    -- Add a slight upward velocity for a more dynamic slide
    self.velocity.y = -100
    
    -- Could add sound effects here
    -- love.audio.play(slideSound)
    
    -- Could add visual effects here
    -- particles:emit("slide", this.x, this.y)
    
    logger:info("Player %s started sliding", self.name)
end

function Player:punch()
    self.isPunching = true
    self.punchTimer = 0
    self:setAnimation(ANIMATION_STATES.IDLE)  -- No punch animation yet
    
    -- Could add sound effects here
    -- love.audio.play(punchSound)
    
    logger:info("Player %s punched", self.name)
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

function Player:collectApple(apple)
    table.insert(self.collectedApples, apple)
    logger:info("Player %s collected apple: %s", self.name, apple.meaning)
end

function Player:gamepadpressed(button)
    logger:debug("Player %s pressed button: %s", self.name, button)
end

return Player 