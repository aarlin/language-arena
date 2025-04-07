-- Player Movement System
local Concord = require("lib.concord.init")
local Constants = require("constants")
local logger = require("logger")

local PlayerMovement = Concord.system({
    pool = {"player", "position", "velocity", "dimensions", "controller"}
})

function PlayerMovement:update(dt)
    for _, entity in ipairs(self.pool) do
        local player = entity.player
        local position = entity.position
        local velocity = entity.velocity
        local controller = entity.controller
        
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
        
        -- Guard clause: Skip if player is immobile or if controller is a bot
        if player.isImmobile or controller.isBot then
            -- Still apply gravity and update position for immobile players
            if player.isJumping then
                velocity.y = velocity.y + player.gravity * dt
                position.y = position.y + velocity.y * dt
                
                -- Ground collision
                if position.y + entity.dimensions.height > Constants.GROUND_Y then
                    position.y = Constants.GROUND_Y - entity.dimensions.height
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
                        else
                            -- If it's a string, try to use it as an axis name
                            -- For now, default to axis 1 (leftx) if it's a string
                            moveX = controller.joystick:getAxis(1)
                            logger:debug("Using default axis 1 for player %s (control: %s)", player.name, player.controls.left)
                        end
                    else
                        -- Fallback to default axis 1 (leftx)
                        moveX = controller.joystick:getAxis(1)
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
                    
                    -- Jumping
                    if player.controls.jump and controller.joystick:isGamepadDown(player.controls.jump) and not player.isJumping then
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
                
                -- Apply gravity
                if player.isJumping then
                    velocity.y = velocity.y + player.gravity * dt
                end
                
                -- Update position based on velocity
                position.x = position.x + velocity.x * dt
                position.y = position.y + velocity.y * dt
                
                -- Ground collision
                if position.y + entity.dimensions.height > Constants.GROUND_Y then
                    position.y = Constants.GROUND_Y - entity.dimensions.height
                    velocity.y = 0
                    player.isJumping = false
                end
                
                -- Screen boundaries
                if position.x < 0 then
                    position.x = 0
                elseif position.x + entity.dimensions.width > Constants.SCREEN_WIDTH then
                    position.x = Constants.SCREEN_WIDTH - entity.dimensions.width
                end
            end
        end
    end
end

return PlayerMovement 