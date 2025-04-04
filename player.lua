local Player = {}
Player.__index = Player

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

function Player.new(x, y, color, controls)
    local self = setmetatable({}, Player)
    self.x = x
    self.y = y
    self.width = 32
    self.height = 48
    self.color = color
    self.controls = controls
    self.velocity = {x = 0, y = 0}
    self.speed = 200
    self.jumpForce = -400
    self.gravity = 800
    self.isGrounded = false
    self.canDoubleJump = false
    self.hasDoubleJumped = false
    self.isPunching = false
    self.punchCooldown = 0
    self.knockbackTime = 0
    self.heldBox = nil
    self.score = 0
    self.controller = nil
    
    -- Animation properties
    self.currentAnimation = ANIMATION_STATES.IDLE
    self.animations = {}
    self.animationFrame = 1
    self.animationTimer = 0
    self.facingRight = true
    
    -- Load animations
    self:loadAnimations()
    
    return self
end

function Player:loadAnimations()
    -- Load idle animation
    self.animations[ANIMATION_STATES.IDLE] = {
        frames = {},
        frameTime = 0.15,  -- Slightly slower for idle
        currentFrame = 1,
        timer = 0
    }
    -- Load idle animation frames (using odd-numbered frames)
    local idleFrames = {1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21}
    for _, frameNum in ipairs(idleFrames) do
        local frameNumber = string.format("%04d", frameNum)
        table.insert(self.animations[ANIMATION_STATES.IDLE].frames, 
            love.graphics.newImage("assets/raccoon/idle/idle" .. frameNumber .. ".png"))
    end
    
    -- Load walk animation
    self.animations[ANIMATION_STATES.WALK] = {
        frames = {},
        frameTime = 0.1,
        currentFrame = 1,
        timer = 0
    }
    -- Load walk animation frames (using odd-numbered frames)
    local walkFrames = {1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21}
    for _, frameNum in ipairs(walkFrames) do
        local frameNumber = string.format("%04d", frameNum)
        table.insert(self.animations[ANIMATION_STATES.WALK].frames,
            love.graphics.newImage("assets/raccoon/walk/walk" .. frameNumber .. ".png"))
    end
    
    -- Load run animation
    self.animations[ANIMATION_STATES.RUN] = {
        frames = {},
        frameTime = 0.08,  -- Faster than walk
        currentFrame = 1,
        timer = 0
    }
    -- Load run animation frames (using odd-numbered frames)
    local runFrames = {1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23}
    for _, frameNum in ipairs(runFrames) do
        local frameNumber = string.format("%04d", frameNum)
        table.insert(self.animations[ANIMATION_STATES.RUN].frames,
            love.graphics.newImage("assets/raccoon/run/run" .. frameNumber .. ".png"))
    end
    
    -- Load jump animation
    self.animations[ANIMATION_STATES.JUMP] = {
        frames = {},
        frameTime = 0.1,
        currentFrame = 1,
        timer = 0
    }
    -- Load jump animation frames (using odd-numbered frames)
    local jumpFrames = {1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21}
    for _, frameNum in ipairs(jumpFrames) do
        local frameNumber = string.format("%04d", frameNum)
        table.insert(self.animations[ANIMATION_STATES.JUMP].frames,
            love.graphics.newImage("assets/raccoon/jump/jump" .. frameNumber .. ".png"))
    end
    
    -- Load crouch animation
    self.animations[ANIMATION_STATES.CROUCH] = {
        frames = {},
        frameTime = 0.1,
        currentFrame = 1,
        timer = 0
    }
    -- Load crouch animation frames (using odd-numbered frames)
    local crouchFrames = {1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23}
    for _, frameNum in ipairs(crouchFrames) do
        local frameNumber = string.format("%04d", frameNum)
        table.insert(self.animations[ANIMATION_STATES.CROUCH].frames,
            love.graphics.newImage("assets/raccoon/crouch/crouch" .. frameNumber .. ".png"))
    end
    
    -- Load victory animation
    self.animations[ANIMATION_STATES.VICTORY] = {
        frames = {},
        frameTime = 0.15,
        currentFrame = 1,
        timer = 0
    }
    -- Load victory animation frames (using odd-numbered frames)
    local victoryFrames = {1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27}
    for _, frameNum in ipairs(victoryFrames) do
        local frameNumber = string.format("%04d", frameNum)
        table.insert(self.animations[ANIMATION_STATES.VICTORY].frames,
            love.graphics.newImage("assets/raccoon/victory-dance/victory-dance" .. frameNumber .. ".png"))
    end
end

function Player:updateAnimation(dt)
    local anim = self.animations[self.currentAnimation]
    if not anim then return end
    
    anim.timer = anim.timer + dt
    if anim.timer >= anim.frameTime then
        anim.timer = 0
        anim.currentFrame = anim.currentFrame + 1
        if anim.currentFrame > #anim.frames then
            anim.currentFrame = 1
        end
    end
end

function Player:setAnimation(animation)
    if self.currentAnimation ~= animation then
        self.currentAnimation = animation
        self.animations[animation].currentFrame = 1
        self.animations[animation].timer = 0
    end
end

function Player:setController(joystick)
    self.controller = joystick
end

function Player:update(dt)
    if not self.controller then return end
    
    -- Handle knockback
    if self.knockbackTime > 0 then
        self.knockbackTime = self.knockbackTime - dt
        self.x = self.x + self.knockbackVelocity.x * dt
        self.y = self.y + self.knockbackVelocity.y * dt
        self:setAnimation(ANIMATION_STATES.KO)
        return
    end
    
    -- Handle punch cooldown
    if self.punchCooldown > 0 then
        self.punchCooldown = self.punchCooldown - dt
    end
    
    -- Movement using left stick
    local axisX = self.controller:getAxis(self.controls.left)
    local axisY = self.controller:getAxis("lefty")
    
    -- Invert the axis values for proper movement
    axisX = -axisX
    axisY = -axisY
    
    -- Update facing direction
    if axisX > 0.2 then
        self.facingRight = true
    elseif axisX < -0.2 then
        self.facingRight = false
    end
    
    -- Horizontal movement
    if math.abs(axisX) > 0.2 then  -- Dead zone
        self.velocity.x = axisX * self.speed
        -- Use run animation if moving fast
        if math.abs(axisX) > 0.8 then
            self:setAnimation(ANIMATION_STATES.RUN)
        else
            self:setAnimation(ANIMATION_STATES.WALK)
        end
    else
        self.velocity.x = 0
        self:setAnimation(ANIMATION_STATES.IDLE)
    end
    
    -- Vertical movement (only when not grounded)
    if not self.isGrounded and math.abs(axisY) > 0.2 then
        self.velocity.y = axisY * self.speed
        self:setAnimation(ANIMATION_STATES.JUMP)
    elseif axisY < -0.2 and self.isGrounded then
        self:setAnimation(ANIMATION_STATES.CROUCH)
    end
    
    -- Apply gravity
    self.velocity.y = self.velocity.y + self.gravity * dt
    
    -- Update position
    self.x = self.x + self.velocity.x * dt
    self.y = self.y + self.velocity.y * dt
    
    -- Ground collision
    if self.y > 600 - self.height then
        self.y = 600 - self.height
        self.velocity.y = 0
        self.isGrounded = true
        self.hasDoubleJumped = false
    end
    
    -- Update animation
    self:updateAnimation(dt)
end

function Player:gamepadpressed(button)
    if not self.controller then return end
    
    if button == self.controls.jump and self.isGrounded then
        self.velocity.y = self.jumpForce
        self.isGrounded = false
        self.canDoubleJump = true
    elseif button == self.controls.jump and self.canDoubleJump and not self.hasDoubleJumped then
        self.velocity.y = self.jumpForce * 0.8
        self.hasDoubleJumped = true
    elseif button == self.controls.down and not self.isGrounded then
        self.velocity.y = 800
    elseif button == self.controls.punch and self.punchCooldown <= 0 then
        self:punch()
    end
end

function Player:draw()
    local anim = self.animations[self.currentAnimation]
    if not anim or not anim.frames[anim.currentFrame] then return end
    
    local frame = anim.frames[anim.currentFrame]
    local scale = 0.35  -- Adjusted scale for better fit
    
    -- Draw the raccoon sprite
    love.graphics.setColor(1, 1, 1)  -- Reset color to white for sprites
    if self.facingRight then
        love.graphics.draw(frame, self.x, self.y, 0, scale, scale)
    else
        love.graphics.draw(frame, self.x + frame:getWidth() * scale, self.y, 0, -scale, scale)
    end
    
    -- Draw punch animation
    if self.isPunching then
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("fill", self.x + (self.facingRight and self.width or -20), 
            self.y + self.height/2, 20, 10)
    end
    
    -- Draw held box
    if self.heldBox then
        love.graphics.setColor(0, 1, 0)
        love.graphics.rectangle("fill", self.x + self.width/2 - 10, self.y - 20, 20, 20)
    end
end

function Player:punch()
    self.isPunching = true
    self.punchCooldown = 0.5
    -- Reset punch animation after 0.2 seconds
    love.timer.after(0.2, function()
        self.isPunching = false
    end)
end

function Player:takeKnockback(velocity)
    self.knockbackTime = 0.5
    self.knockbackVelocity = velocity
    if self.heldBox then
        self.heldBox = nil
    end
end

return Player 