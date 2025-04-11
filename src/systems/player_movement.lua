-- Player Movement System
local Concord = require("lib.concord.init")
local Constants = require("constants")
local logger = require("logger")

local PlayerMovement = Concord.system({
    players = {"player", "position", "velocity", "dimensions", "controller"},
    boxes = {"box", "position", "dimensions"},
    platforms = {"platform", "position", "dimensions"}
})

function PlayerMovement:update(dt)
    for _, entity in ipairs(self.players) do
        local player = entity.player
        local position = entity.position
        local dimensions = entity.dimensions
        local velocity = entity.velocity
        local controller = entity.controller
        
        -- Skip update if player is immobile
        if player.isImmobile then
            player.immobilityTimer = player.immobilityTimer - dt
            if player.immobilityTimer <= 0 then
                player.isImmobile = false
            end
            return
        end
        
        -- Handle knockback
        if player.isKnockback then
            player.knockbackTimer = player.knockbackTimer - dt
            
            -- Apply knockback force
            if player.knockbackTimer > 0 then
                velocity.x = player.knockbackDirectionX * Constants.KNOCKBACK_FORCE_X
                velocity.y = player.knockbackDirectionY * Constants.KNOCKBACK_FORCE_Y
            else
                -- End knockback
                player.isKnockback = false
                player.isInvulnerable = true
                player.invulnerabilityTimer = Constants.INVULNERABILITY_DURATION
            end
        end
        
        -- Check for collisions with platforms
        local onPlatform = false
        for _, platformEntity in ipairs(self.platforms) do
            local platform = platformEntity.platform
            local platformPosition = platformEntity.position
            local platformDimensions = platformEntity.dimensions
            
            -- Check if player is above platform and moving downward
            if velocity.y > 0 and
               position.x + dimensions.width > platformPosition.x and
               position.x < platformPosition.x + platformDimensions.width and
               position.y + dimensions.height <= platformPosition.y and
               position.y + dimensions.height + velocity.y * dt > platformPosition.y then
                
                -- Land on platform
                position.y = platformPosition.y - dimensions.height
                velocity.y = 0
                player.isJumping = false
                onPlatform = true
                
                -- Handle bouncy platforms
                if platform.isBouncy then
                    velocity.y = -platform.bounceForce
                    player.isJumping = true
                end
                
                break
            end
        end
        
        -- Check for collisions with boxes
        for _, boxEntity in ipairs(self.boxes) do
            local box = boxEntity.box
            local boxPosition = boxEntity.position
            local boxDimensions = boxEntity.dimensions
            
            -- Skip if box is already collected
            if box.collected then
                -- Skip to next box (guard clause)
            else
                -- Check for collision
                if not (position.x + dimensions.width < boxPosition.x or 
                       position.x > boxPosition.x + boxDimensions.width or 
                       position.y + dimensions.height < boxPosition.y or 
                       position.y > boxPosition.y + boxDimensions.height) then
                    
                    -- Mark box as collected
                    box.collected = true
                    
                    -- Handle poop collision (apply knockback)
                    if box.isPoop then
                        player.isKnockback = true
                        player.knockbackTimer = Constants.KNOCKBACK_DURATION
                        player.isImmobile = true
                        player.immobilityTimer = Constants.KNOCKBACK_DURATION
                        
                        -- Set knockback direction based on player position relative to box
                        if position.x < boxPosition.x then
                            player.knockbackDirectionX = -1  -- Knock back left
                        else
                            player.knockbackDirectionX = 1   -- Knock back right
                        end
                        player.knockbackDirectionY = -1  -- Knock back up
                        
                        -- Update animation
                        if entity.animation then
                            entity.animation.currentAnimation = "ko"
                            entity.animation.currentFrame = 1
                        end
                        
                        -- Log the collision
                        logger:info("Player %s hit poop, applying knockback for %f seconds", player.name, Constants.KNOCKBACK_DURATION)
                    else
                        -- Check if character type matches player's character type
                        if box.characterType == player.characterType then
                            -- Award points for matching character
                            player.score = (player.score or 0) + Constants.CORRECT_MATCH_SCORE
                            logger:info("Player %s collected matching character: %s, +%d points", 
                                player.name, box.characterType, Constants.CORRECT_MATCH_SCORE)
                        else
                            -- Wrong match, subtract points
                            player.score = math.max(0, (player.score or 0) - Constants.WRONG_MATCH_PENALTY)
                            logger:info("Player %s collected wrong character: %s, -%d points", 
                                player.name, box.characterType, Constants.WRONG_MATCH_PENALTY)
                        end
                    end
                    
                    -- Destroy the box entity
                    boxEntity:destroy()
                end
            end
        end
        
        -- Update timers (these should always run regardless of immobility)
        if player.isKicking then
            player.kickTimer = player.kickTimer - dt
            if player.kickTimer <= 0 then
                player.isKicking = false
            end
        end
        
        if player.isInvulnerable then
            player.invulnerabilityTimer = player.invulnerabilityTimer - dt
            if player.invulnerabilityTimer <= 0 then
                player.isInvulnerable = false
            else
                -- Flash effect
                player.isFlashing = math.floor(player.invulnerabilityTimer * 10) % 2 == 0
            end
        end
        
        if player.isImmobile then
            player.immobilityTimer = player.immobilityTimer - dt
            if player.immobilityTimer <= 0 then
                player.isImmobile = false
            end
        end
        
        if player.isKnockback then
            player.knockbackTimer = player.knockbackTimer - dt
            if player.knockbackTimer <= 0 then
                player.isKnockback = false
            end
        end
        
        -- Update animation state based on priority
        if entity.animation then
            -- Priority order: 1. knockback, 2. kick, 3. jump, 4. run, 5. walk, 6. idle
            if player.isKnockback then
                entity.animation.currentAnimation = "ko"
            elseif player.isKicking then
                entity.animation.currentAnimation = "kick"
            elseif player.isJumping then
                entity.animation.currentAnimation = "jump"
            elseif player.isRunning then
                entity.animation.currentAnimation = "run"
            elseif math.abs(velocity.x) > 0.1 and not player.isJumping then
                entity.animation.currentAnimation = "walk"
            else
                entity.animation.currentAnimation = "idle"
            end
        end
        
        -- Guard clause: Skip if player is immobile or if controller is a bot
        if player.isImmobile or controller.isBot then
            -- Still apply gravity and update position for immobile players
            if player.isJumping then
                velocity.y = velocity.y + player.gravity * dt
                position.y = position.y + velocity.y * dt
                
                -- Ground collision
                if position.y + dimensions.height > Constants.GROUND_Y then
                    position.y = Constants.GROUND_Y - dimensions.height
                    velocity.y = 0
                    player.isJumping = false
                end
            end
            -- Skip to next entity
        else
            -- Guard clause: Skip if no joystick
            if not controller.joystick then
                -- Skip to next entity
            else
                -- Movement (only if not kicking)
                if not player.isKicking then
                    local moveX = 0
                    
                    -- Use the control defined in the controller setup, or fall back to axis 1 if not defined
                    if player.controls.left then
                        -- Check if the control is a number (axis index) or a string (axis name)
                        if type(player.controls.left) == "number" then
                            moveX = controller.joystick:getAxis(player.controls.left)
                            
                            -- For Nintendo Switch, we need to handle the axis differently
                        else
                            -- If it's a string, use it as a gamepad axis name
                            moveX = controller.joystick:getGamepadAxis(player.controls.left)
                            logger:debug("Using gamepad axis %s for player %s", player.controls.left, player.name)
                        end
                    else
                        -- Fallback to default gamepad axis "leftx"
                        moveX = controller.joystick:getGamepadAxis("leftx")
                    end
                    
                    if math.abs(moveX) > 0.1 then
                        -- Determine if running
                        local isRunningNow = false
                        if player.controls.down then
                            isRunningNow = controller.joystick:isGamepadDown(player.controls.down)
                        end
                        if isRunningNow ~= player.isRunning then
                            player.isRunning = isRunningNow
                            logger:debug("Player %s %s", player.name, player.isRunning and "started running" or "stopped running")
                        end
                        
                        -- Set speed based on running state
                        local currentSpeed = player.isRunning and player.runSpeed or player.speed
                        
                        -- Apply movement
                        velocity.x = moveX * currentSpeed
                        
                        -- Update facing direction
                        player.facingRight = moveX > 0
                    else
                        -- No horizontal movement
                        velocity.x = 0
                    end
                    
                    -- Jumping (only if on ground or platform)
                    if player.controls.jump and controller.joystick:isGamepadDown(player.controls.jump) and (not player.isJumping or onPlatform) then
                        velocity.y = -player.jumpForce
                        player.isJumping = true
                        logger:debug("Player %s jumped", player.name)
                    end
                end
                
                -- Kicking
                if player.controls.kick and controller.joystick:isGamepadDown(player.controls.kick) and not player.isKicking then
                    player.isKicking = true
                    player.kickTimer = Constants.PLAYER_KICK_DURATION
                    logger:debug("Player %s kicked", player.name)
                end
                
                -- Apply gravity if not on platform
                if not onPlatform then
                    velocity.y = velocity.y + player.gravity * dt
                end
                
                -- Update position based on velocity
                position.x = position.x + velocity.x * dt
                position.y = position.y + velocity.y * dt
                
                -- Ground collision
                if position.y + dimensions.height > Constants.GROUND_Y then
                    position.y = Constants.GROUND_Y - dimensions.height
                    velocity.y = 0
                    player.isJumping = false
                end
                
                -- Screen boundaries
                if position.x < 0 then
                    position.x = 0
                elseif position.x + dimensions.width > Constants.SCREEN_WIDTH then
                    position.x = Constants.SCREEN_WIDTH - dimensions.width
                end
            end
        end
    end
end

return PlayerMovement 