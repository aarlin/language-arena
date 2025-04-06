local logger = require("logger")  -- Import the logger
local config = require("config")  -- Import the config module
local Constants = require("constants")  -- Import the constants module

-- Animation states
local ANIMATION_STATES = {
    IDLE = "idle",
    WALK = "walk",
    RUN = "run",
    JUMP = "jump",
    CROUCH = "crouch",
    KO = "ko",
    DANCE = "dance",
    KICK = "kick"  -- New kick animation state
}

-- Helper function to set color with alpha
local function setColor(colorName, alpha)
    -- If colorName is already a table (RGB values), use it directly
    if type(colorName) == "table" then
        if alpha then
            love.graphics.setColor(colorName[1], colorName[2], colorName[3], alpha)
        else
            love.graphics.setColor(colorName)
        end
        return
    end
    
    -- Otherwise, look up the color in Constants.COLORS
    local color = Constants.COLORS[colorName]
    if color then
        if alpha then
            love.graphics.setColor(color[1], color[2], color[3], alpha)
        else
            love.graphics.setColor(color)
        end
    else
        logger:error("Unknown color: %s", tostring(colorName))
        love.graphics.setColor(Constants.COLORS.WHITE)  -- Default to white
    end
end

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
    self.speed = Constants.PLAYER_SPEED
    self.runSpeed = Constants.PLAYER_RUN_SPEED
    self.jumpForce = -Constants.PLAYER_JUMP_FORCE  -- Make jump force negative to move upward
    self.gravity = Constants.PLAYER_GRAVITY
    self.isJumping = false
    self.isRunning = false
    self.isKicking = false
    self.kickTimer = 0
    self.kickDuration = Constants.PLAYER_KICK_DURATION
    self.score = 0
    self.collectedApples = {}
    self.name = "Player " .. (controls and controls.controller or "Unknown")
    self.facingRight = true
    self.currentAnimation = ANIMATION_STATES.IDLE
    self.animationTimer = 0
    self.animationSpeed = Constants.PLAYER_ANIMATION_SPEED
    self.currentFrame = 1
    self.animations = {}
    self.width = Constants.PLAYER_WIDTH
    self.height = Constants.PLAYER_HEIGHT
    
    -- Hitbox properties
    self.hitboxWidth = Constants.HITBOX_WIDTH
    self.hitboxHeight = Constants.HITBOX_HEIGHT
    self.hitboxOffset = Constants.HITBOX_OFFSET  -- Distance from player center
    self.hitboxXOffset = Constants.HITBOX_X_OFFSET  -- No horizontal offset
    self.hitboxYOffset = Constants.HITBOX_Y_OFFSET  -- Move hitbox 100px down
    
    -- Invulnerability and immobility properties
    self.isInvulnerable = false
    self.invulnerabilityTimer = 0
    self.invulnerabilityDuration = Constants.PLAYER_INVULNERABILITY_DURATION
    self.isImmobile = false
    self.immobilityTimer = 0
    self.immobilityDuration = Constants.PLAYER_IMMOBILITY_DURATION
    
    -- Check if running on Nintendo Switch
    self.isSwitch = love._console == "Switch"
    
    -- Initialize fonts based on platform
    if self.isSwitch then
        -- On Switch, use the "standard" font
        self.font = love.graphics.newFont("standard", Constants.FONT_SIZE)
        self.smallFont = love.graphics.newFont("standard", Constants.SMALL_FONT_SIZE)
        self.titleFont = love.graphics.newFont("standard", Constants.TITLE_FONT_SIZE)
        self.subtitleFont = love.graphics.newFont("standard", Constants.SUBTITLE_FONT_SIZE)
        self.instructionFont = love.graphics.newFont("standard", Constants.INSTRUCTION_FONT_SIZE)
        self.cjkFont = love.graphics.newFont("standard", Constants.CJK_FONT_SIZE)
    else
        -- On PC, use SourceHanSansSC font
        self.font = love.graphics.newFont("assets/fonts/SourceHanSansSC-Regular.otf", Constants.FONT_SIZE)
        self.smallFont = love.graphics.newFont("assets/fonts/SourceHanSansSC-Regular.otf", Constants.SMALL_FONT_SIZE)
        self.titleFont = love.graphics.newFont("assets/fonts/SourceHanSansSC-Regular.otf", Constants.TITLE_FONT_SIZE)
        self.subtitleFont = love.graphics.newFont("assets/fonts/SourceHanSansSC-Regular.otf", Constants.SUBTITLE_FONT_SIZE)
        self.instructionFont = love.graphics.newFont("assets/fonts/SourceHanSansSC-Regular.otf", Constants.INSTRUCTION_FONT_SIZE)
        self.cjkFont = love.graphics.newFont("assets/fonts/SourceHanSansSC-Regular.otf", Constants.CJK_FONT_SIZE)
    end
    
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
    
    -- Load idle animation (sequential frames)
    local idleFrames = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}
    for _, frameNum in ipairs(idleFrames) do
        local frameNumber = string.format("%04d", frameNum)
        local success, image = pcall(function() 
            return love.graphics.newImage("assets/characters/raccoon/idle/" .. frameNumber .. ".png")
        end)
        
        if success then
            table.insert(self.animations[ANIMATION_STATES.IDLE].frames, image)
            logger:debug("Loaded idle animation frame: idle%s.png", frameNumber)
        else
            logger:error("Failed to load idle animation frame: idle%s.png - %s", frameNumber, image)
        end
    end
    
    -- Load walk animation (sequential frames)
    local walkFrames = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}
    for _, frameNum in ipairs(walkFrames) do
        local frameNumber = string.format("%04d", frameNum)
        local success, image = pcall(function() 
            return love.graphics.newImage("assets/characters/raccoon/walk/" .. frameNumber .. ".png")
        end)
        
        if success then
            table.insert(self.animations[ANIMATION_STATES.WALK].frames, image)
            logger:debug("Loaded walk animation frame: walk%s.png", frameNumber)
        else
            logger:error("Failed to load walk animation frame: walk%s.png - %s", frameNumber, image)
        end
    end
    
    -- Load run animation (sequential frames)
    local runFrames = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}
    for _, frameNum in ipairs(runFrames) do
        local frameNumber = string.format("%04d", frameNum)
        local success, image = pcall(function() 
            return love.graphics.newImage("assets/characters/raccoon/run/" .. frameNumber .. ".png")
        end)
        
        if success then
            table.insert(self.animations[ANIMATION_STATES.RUN].frames, image)
            logger:debug("Loaded run animation frame: run%s.png", frameNumber)
        else
            logger:error("Failed to load run animation frame: run%s.png - %s", frameNumber, image)
        end
    end
    
    -- Load jump animation (sequential frames)
    local jumpFrames = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}
    for _, frameNum in ipairs(jumpFrames) do
        local frameNumber = string.format("%04d", frameNum)
        local success, image = pcall(function() 
            return love.graphics.newImage("assets/characters/raccoon/jump/" .. frameNumber .. ".png")
        end)
        
        if success then
            table.insert(self.animations[ANIMATION_STATES.JUMP].frames, image)
            logger:debug("Loaded jump animation frame: jump%s.png", frameNumber)
        else
            logger:error("Failed to load jump animation frame: jump%s.png - %s", frameNumber, image)
        end
    end
    
    -- Load crouch animation (sequential frames)
    local crouchFrames = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}
    for _, frameNum in ipairs(crouchFrames) do
        local frameNumber = string.format("%04d", frameNum)
        local success, image = pcall(function() 
            return love.graphics.newImage("assets/characters/raccoon/crouch/" .. frameNumber .. ".png")
        end)
        
        if success then
            table.insert(self.animations[ANIMATION_STATES.CROUCH].frames, image)
            logger:debug("Loaded crouch animation frame: crouch%s.png", frameNumber)
        else
            logger:error("Failed to load crouch animation frame: crouch%s.png - %s", frameNumber, image)
        end
    end
    
    -- Load kick animation (sequential frames)
    local kickFrames = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}
    for _, frameNum in ipairs(kickFrames) do
        local frameNumber = string.format("%04d", frameNum)
        local success, image = pcall(function() 
            return love.graphics.newImage("assets/characters/raccoon/kick/" .. frameNumber .. ".png")
        end)
        
        if success then
            table.insert(self.animations[ANIMATION_STATES.KICK].frames, image)
            logger:debug("Loaded kick animation frame: kick%s.png", frameNumber)
        else
            logger:error("Failed to load kick animation frame: kick%s.png - %s", frameNumber, image)
        end
    end
    
    -- Load KO animation (sequential frames)
    local koFrames = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18}
    for _, frameNum in ipairs(koFrames) do
        local frameNumber = string.format("%04d", frameNum)
        local success, image = pcall(function() 
            return love.graphics.newImage("assets/characters/raccoon/ko/" .. frameNumber .. ".png")
        end)
        
        if success then
            table.insert(self.animations[ANIMATION_STATES.KO].frames, image)
            logger:debug("Loaded KO animation frame: ko%s.png", frameNumber)
        else
            logger:error("Failed to load KO animation frame: ko%s.png - %s", frameNumber, image)
        end
    end
    
    -- Load dance animation (sequential frames)
    local danceFrames = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}
    for _, frameNum in ipairs(danceFrames) do
        local frameNumber = string.format("%04d", frameNum)
        local success, image = pcall(function() 
            return love.graphics.newImage("assets/characters/raccoon/dance/" .. frameNumber .. ".png")
        end)
        
        if success then
            table.insert(self.animations[ANIMATION_STATES.DANCE].frames, image)
            logger:debug("Loaded dance animation frame: dance%s.png", frameNumber)
        else
            logger:error("Failed to load dance animation frame: dance%s.png - %s", frameNumber, image)
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
                -- If KO animation is complete, reset to idle
                if self.currentAnimation == ANIMATION_STATES.KO then
                    -- Reset to idle animation with proper frame initialization
                    self.currentAnimation = ANIMATION_STATES.IDLE
                    self.currentFrame = 1
                    self.animationTimer = 0
                    self.animationSpeed = Constants.PLAYER_ANIMATION_SPEED  -- Reset to default animation speed
                    self.isImmobile = false  -- Allow movement after KO animation completes
                    self.isKnockback = false  -- Reset knockback state
                    logger:debug("Player %s KO animation complete, returning to idle", self.name)
                else
                    self.currentFrame = 1
                end
            end
        end
        
        -- Update invulnerability timer
        if self.isInvulnerable then
            self.invulnerabilityTimer = self.invulnerabilityTimer + dt
            if self.invulnerabilityTimer >= self.invulnerabilityDuration then
                self.isInvulnerable = false
                self.invulnerabilityTimer = 0
                logger:debug("Player %s is no longer invulnerable", self.name)
            end
        end
        
        -- Update immobility timer
        if self.isImmobile then
            self.immobilityTimer = self.immobilityTimer + dt
            if self.immobilityTimer >= self.immobilityDuration then
                self.isImmobile = false
                self.immobilityTimer = 0
                logger:debug("Player %s can move again", self.name)
            end
        end
        
        -- Update kick timer
        if self.isKicking then
            self.kickTimer = self.kickTimer + dt
            if self.kickTimer >= self.kickDuration then
                self.isKicking = false
                self.kickTimer = 0
                self:setAnimation(ANIMATION_STATES.IDLE)
                logger:debug("Player %s finished kicking", self.name)
            end
        end
        
        -- Apply gravity
        self.velocity.y = self.velocity.y + self.gravity * dt
        
        -- Apply velocity (only if not immobile)
        if not self.isImmobile then
            self.x = self.x + self.velocity.x * dt
            self.y = self.y + self.velocity.y * dt
        end
        
        -- Screen boundaries
        if self.x < 0 then
            self.x = 0
            self.velocity.x = 0
        elseif self.x > Constants.SCREEN_WIDTH - self.width then
            self.x = Constants.SCREEN_WIDTH - self.width
            self.velocity.x = 0
        end
        
        -- Ground collision
        if self.y > Constants.SCREEN_HEIGHT - self.height then
            self.y = Constants.SCREEN_HEIGHT - self.height
            self.velocity.y = 0
            self.isJumping = false
            if self.currentAnimation == ANIMATION_STATES.JUMP then
                self:setAnimation(ANIMATION_STATES.IDLE)
            end
        end
        
        -- Handle controller input (only if not immobile)
        if self.controller and not self.isImmobile then
            -- Check for kick input first (highest priority)
            if self.controls.kick and self.controller:isGamepadDown(self.controls.kick) and not self.isKicking then
                self:kick()
            end
            
            -- Movement (only if not kicking)
            if not self.isKicking then
                local moveX = self.controller:getGamepadAxis("leftx")
                if math.abs(moveX) > 0.1 then
                    -- Determine if running
                    local isRunningNow = false
                    if self.controls.down then
                        isRunningNow = self.controller:isGamepadDown(self.controls.down)
                    end
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
                    if not self.isJumping and not self.isKicking then
                        self:setAnimation(ANIMATION_STATES.IDLE)
                    end
                end
                
                -- Jumping
                if self.controls.jump and self.controller:isGamepadDown(self.controls.jump) and not self.isJumping then
                    self.velocity.y = self.jumpForce
                    self.isJumping = true
                    self:setAnimation(ANIMATION_STATES.JUMP)
                    logger:debug("Player %s jumped", self.name)
                end
                
                -- Crouching
                if self.controls.down and self.controller:isGamepadDown(self.controls.down) and not self.isRunning and not self.isJumping then
                    self:setAnimation(ANIMATION_STATES.CROUCH)
                end
            end
        end
        
        -- Log player state periodically (every 5 seconds)
        if math.floor(love.timer.getTime() * 2) % 10 == 0 then
            logger:logPlayerState(self)
        end
    end)
    
    -- If an error occurred, log it
    if not success and config.logging.levels.error then
        logger:error("Error updating player %s: %s", self.name, errorMsg)
        -- Try to recover by resetting to a safe state
        self.velocity = {x = 0, y = 0}
        self.isJumping = false
        self.isKicking = false
        self.isKnockback = false
        self:setAnimation(ANIMATION_STATES.IDLE)
    end
end

function Player:draw()
    -- Set color to white to prevent tinting the sprites
    setColor("WHITE")
    
    -- Draw the current animation frame
    if self.animations[self.currentAnimation] and self.animations[self.currentAnimation].frames[self.currentFrame] then
        local image = self.animations[self.currentAnimation].frames[self.currentFrame]
        
        -- Save the current transformation
        love.graphics.push()
        
        -- Set the scale to the player scale constant
        love.graphics.scale(Constants.PLAYER_SCALE, Constants.PLAYER_SCALE)
        
        -- Calculate draw position with offset based on facing direction
        local drawX = self.x + self.width/2
        if self.facingRight then
            -- Move character slightly to the left when facing right
            drawX = drawX - Constants.MODEL_OFFSET_X
        else
            -- Move character slightly to the right when facing left
            drawX = drawX + Constants.MODEL_OFFSET_X
        end
        
        -- Flip the image if facing left
        if not self.facingRight then
            love.graphics.draw(image, (drawX + self.width) * Constants.PLAYER_DRAW_MULTIPLIER, self.y * Constants.PLAYER_DRAW_MULTIPLIER, 0, -1, 1)
        else
            love.graphics.draw(image, drawX * Constants.PLAYER_DRAW_MULTIPLIER, self.y * Constants.PLAYER_DRAW_MULTIPLIER)
        end
        
        -- Restore the transformation
        love.graphics.pop()
    else
        -- Fallback if animation frame is missing - draw a colored rectangle based on animation state
        local fallbackColor = "WHITE"
        
        -- Set different colors for different animation states
        if self.currentAnimation == ANIMATION_STATES.KO then
            fallbackColor = "RED"
        elseif self.currentAnimation == ANIMATION_STATES.KICK then
            fallbackColor = "ORANGE"
        elseif self.currentAnimation == ANIMATION_STATES.JUMP then
            fallbackColor = "GREEN"
        elseif self.currentAnimation == ANIMATION_STATES.RUN then
            fallbackColor = "BLUE"
        elseif self.currentAnimation == ANIMATION_STATES.WALK then
            fallbackColor = "YELLOW"
        elseif self.currentAnimation == ANIMATION_STATES.CROUCH then
            fallbackColor = "PURPLE"
        elseif self.currentAnimation == ANIMATION_STATES.DANCE then
            fallbackColor = "PINK"
        end
        
        -- Draw the fallback rectangle with the appropriate color
        setColor(fallbackColor)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
        
        -- Log the missing frame issue
        logger:warning("Missing animation frame for player %s: %s frame %d", 
            self.name, self.currentAnimation, self.currentFrame)
    end
    
    -- Draw hitbox for debugging
    if config.debug.showHitboxes then
        -- Calculate hitbox position (used for all visualizations)
        local hitboxX = self.facingRight and (self.x + self.width/2 + self.hitboxOffset) or (self.x + self.width/2 - self.hitboxOffset - self.hitboxWidth)
        hitboxX = hitboxX + self.hitboxXOffset  -- Apply horizontal offset (now 0)
        local hitboxY = self.y + self.height/2 - self.hitboxHeight/2 + self.hitboxYOffset  -- Apply vertical offset (now 100)

        -- Draw player model box at offset position
        setColor("RED", 0.5)  -- Semi-transparent red
        local modelX = hitboxX
        if self.facingRight then
            -- Move character slightly to the left when facing right
            modelX = modelX - Constants.MODEL_OFFSET_X
        else
            -- Move character slightly to the right when facing left
            modelX = modelX + Constants.MODEL_OFFSET_X
        end
        local modelY = hitboxY + Constants.MODEL_OFFSET_Y  -- 50px down
        love.graphics.rectangle("fill", modelX, modelY, self.hitboxWidth, self.hitboxHeight)
        setColor("WHITE")  -- White text
        love.graphics.print("Player Model", modelX, modelY - Constants.DEBUG_LABEL_OFFSET)

        -- Draw hitbox
        setColor("GREEN", 0.5)  -- Semi-transparent green
        love.graphics.rectangle("fill", hitboxX, hitboxY, self.hitboxWidth, self.hitboxHeight)
        love.graphics.print("Hitbox", hitboxX, hitboxY - Constants.DEBUG_LABEL_OFFSET * 2)

        -- Draw collection box at offset position
        setColor("BLUE", 0.5)  -- Semi-transparent blue
        local collectionX = hitboxX + (self.facingRight and Constants.COLLECTION_OFFSET_X or -Constants.COLLECTION_OFFSET_X)  -- 50px right if facing right, 50px left if facing left
        local collectionY = hitboxY + Constants.COLLECTION_OFFSET_Y  -- 50px down
        love.graphics.rectangle("fill", collectionX, collectionY, self.hitboxWidth, self.hitboxHeight)
        love.graphics.print("Collection Box", collectionX, collectionY - Constants.DEBUG_LABEL_OFFSET * 3)
    end
    
    -- Draw player name
    setColor("WHITE")  -- White
    -- Use system font on Switch
    if self.isSwitch then
        if self.font then
            love.graphics.setFont(self.font)
        end
        love.graphics.print(self.name, self.x, self.y - 20)
    else
        love.graphics.setFont(love.graphics.getFont())
        love.graphics.print(self.name, self.x, self.y - 20)
    end
    
    -- Draw score
    love.graphics.print("Score: " .. self.score, self.x, self.y - 40)
    
    -- Draw animation state for debugging
    if not self.isSwitch then
        love.graphics.print("Animation: " .. self.currentAnimation .. " Frame: " .. self.currentFrame, 
            self.x, self.y - 60)
    end
    
    -- Draw invulnerability indicator
    if self.isInvulnerable then
        setColor("BLUE", 0.7)  -- Blue
        love.graphics.circle("fill", self.x + self.width/2, self.y + self.height/2, 30)
    end
    
    -- Draw immobility indicator
    if self.isImmobile then
        setColor("ORANGE", 0.7)  -- Orange
        love.graphics.rectangle("fill", self.x, self.y - 30, self.width, 5)
    end
    
    -- Draw collected apples
    for i, apple in ipairs(self.collectedApples) do
        setColor("RED")  -- Red apple
        love.graphics.circle("fill", self.x + 20 + (i-1) * 30, self.y - 30, 10)
        
        -- Draw stem
        setColor("GREEN")  -- Green stem
        love.graphics.rectangle("fill", self.x + 20 + (i-1) * 30 - 1, self.y - 40, 2, 5)
    end
end

function Player:setAnimation(animation)
    -- KO animation takes absolute priority over everything
    if animation == ANIMATION_STATES.KO then
        self.currentAnimation = animation
        self.currentFrame = 1
        self.animationTimer = 0
        logger:debug("Player %s animation changed to %s (KO takes priority)", self.name, animation)
        return
    end
    
    -- Don't change animation if currently in KO state
    if self.currentAnimation == ANIMATION_STATES.KO then
        return
    end
    
    -- Don't change animation if currently kicking, unless explicitly setting to kick
    if self.isKicking and animation ~= ANIMATION_STATES.KICK then
        return
    end
    
    -- Don't change animation if currently jumping, unless explicitly setting to jump or kick
    if self.isJumping and animation ~= ANIMATION_STATES.JUMP and animation ~= ANIMATION_STATES.KICK then
        return
    end
    
    if self.currentAnimation ~= animation then
        self.currentAnimation = animation
        self.currentFrame = 1
        self.animationTimer = 0
        logger:debug("Player %s animation changed to %s", self.name, animation)
    end
end

function Player:kick()
    self.isKicking = true
    self.kickTimer = 0
    self:setAnimation(ANIMATION_STATES.KICK)
    
    -- Could add sound effects here
    -- love.audio.play(kickSound)
    
    logger:info("Player %s kicked", self.name)
end

function Player:takeKnockback(velocity)
    -- Only take knockback if not invulnerable
    if not self.isInvulnerable then
        self.velocity.x = velocity.x
        self.velocity.y = velocity.y
        self.isJumping = true
        self:setAnimation(ANIMATION_STATES.KO)
        
        -- Calculate animation speed based on KO duration and number of frames
        local numFrames = #self.animations[ANIMATION_STATES.KO].frames
        self.animationSpeed = Constants.PLAYER_KO_DURATION / numFrames
        
        -- Set invulnerability and immobility
        self.isInvulnerable = true
        self.invulnerabilityTimer = 0
        self.isImmobile = true
        self.immobilityTimer = 0
        
        -- Could add sound effects here
        -- love.audio.play(hitSound)
        
        logger:info("Player %s took knockback and is now invulnerable for %.1f seconds and immobile for %.1f seconds", 
            self.name, self.invulnerabilityDuration, self.immobilityDuration)
    else
        logger:debug("Player %s ignored knockback due to invulnerability", self.name)
    end
end

function Player:collectApple(apple)
    table.insert(self.collectedApples, apple)
    logger:info("Player %s collected apple: %s", self.name, apple.meaning)
end

function Player:gamepadpressed(button)
    logger:debug("Player %s pressed button: %s", self.name, button)
end

-- New function to check if an apple is within the player's hitbox
function Player:isAppleInHitbox(apple)
    -- Calculate hitbox position based on player position and facing direction
    local hitboxX = self.facingRight and (self.x + self.width/2 + self.hitboxOffset) or (self.x + self.width/2 - self.hitboxOffset - self.hitboxWidth)
    hitboxX = hitboxX + self.hitboxXOffset  -- Apply horizontal offset (now 0)
    local hitboxY = self.y + self.height/2 - self.hitboxHeight/2 + self.hitboxYOffset  -- Apply vertical offset (now 100)
    
    -- Calculate player model position (offset in opposite direction of facing)
    local modelX = hitboxX
    if self.facingRight then
        -- Move character slightly to the left when facing right
        modelX = modelX - Constants.MODEL_OFFSET_X
    else
        -- Move character slightly to the right when facing left
        modelX = modelX + Constants.MODEL_OFFSET_X
    end
    local modelY = hitboxY + Constants.MODEL_OFFSET_Y  -- 50px down
    
    -- Check if apple is within player model box
    return apple.x >= modelX and 
           apple.x <= modelX + self.hitboxWidth and
           apple.y >= modelY and 
           apple.y <= modelY + self.hitboxHeight
end

-- New function to collect an apple if it's in the hitbox
function Player:tryCollectApple(apple)
    if self:isAppleInHitbox(apple) then
        self:collectApple(apple)
        return true
    end
    return false
end

return Player 