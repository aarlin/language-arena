-- Player Movement System
local Concord = require("lib.concord.init")
local Constants = require("constants")
local logger = require("logger")
local InputManager = require("input_manager")
local flux = require("lib.rxi.flux")

local PlayerMovement = Concord.system({
    pool = {"player", "position", "velocity", "dimensions", "controller", "animation"}
})

function PlayerMovement:init()
    self.flux = flux.group()
end

function PlayerMovement:update(dt)
    for _, e in ipairs(self.pool) do
        local player = e.player
        local position = e.position
        local velocity = e.velocity
        local controller = e.controller
        local animation = e.animation
        
        -- Skip if player is in knockback or immobile
        if player.isKnockback or player.isImmobile then
            -- Update knockback timer
            if player.isKnockback then
                player.knockbackTimer = player.knockbackTimer + dt
                if player.knockbackTimer >= Constants.KNOCKBACK_DURATION then
                    player.isKnockback = false
                    player.knockbackTimer = 0
                end
            end
            
            -- Update immobility timer
            if player.isImmobile then
                player.immobilityTimer = player.immobilityTimer + dt
                if player.immobilityTimer >= Constants.IMMOBILITY_DURATION then
                    player.isImmobile = false
                    player.immobilityTimer = 0
                end
            end
            
            -- Skip movement updates
            goto continue
        end
        
        -- Get input from the input manager
        local input = InputManager:getPlayerInput(player.controller)
        if not input then goto continue end
        
        -- Get movement input
        local moveX, moveY = input:get("move")
        
        -- Handle horizontal movement
        if math.abs(moveX) > 0.1 then
            -- Set running state based on input
            player.isRunning = input:down("down")
            
            -- Calculate speed based on running state
            local speed = player.isRunning and player.runSpeed or player.speed
            
            -- Apply movement
            velocity.x = moveX * speed
            
            -- Update facing direction
            player.facingRight = moveX > 0
            
            -- Update animation
            animation.currentAnimation = player.isRunning and "run" or "walk"
        else
            velocity.x = 0
            animation.currentAnimation = "idle"
        end
        
        -- Handle jumping
        if input:pressed("jump") and not player.isJumping then
            velocity.y = player.jumpForce
            player.isJumping = true
            animation.currentAnimation = "jump"
        end
        
        -- Apply gravity
        velocity.y = velocity.y + player.gravity * dt
        
        -- Update position
        position.x = position.x + velocity.x * dt
        position.y = position.y + velocity.y * dt
        
        -- Check for ground collision
        if position.y >= Constants.GROUND_Y - player.dimensions.height then
            position.y = Constants.GROUND_Y - player.dimensions.height
            velocity.y = 0
            player.isJumping = false
        end
        
        -- Handle kicking
        if input:pressed("kick") and not player.isKicking then
            player.isKicking = true
            player.kickTimer = 0
            animation.currentAnimation = "kick"
        end
        
        -- Update kick timer
        if player.isKicking then
            player.kickTimer = player.kickTimer + dt
            if player.kickTimer >= Constants.KICK_DURATION then
                player.isKicking = false
                player.kickTimer = 0
            end
        end
        
        ::continue::
    end
end

function PlayerMovement:applyKnockback(entity, direction)
    local player = entity.player
    local position = entity.position
    
    -- Skip if player is invulnerable
    if player.isInvulnerable then return end
    
    -- Set knockback state
    player.isKnockback = true
    player.isInvulnerable = true
    player.knockbackTimer = 0
    player.invulnerabilityTimer = 0
    
    -- Calculate knockback distance
    local knockbackDistance = 100  -- pixels
    local targetX = position.x + (direction * knockbackDistance)
    
    -- Create knockback animation
    self.flux:to(position, 1.5, {x = targetX})
        :ease("outQuad")
        :oncomplete(function()
            player.isKnockback = false
            player.isInvulnerable = false
        end)
end

return PlayerMovement 