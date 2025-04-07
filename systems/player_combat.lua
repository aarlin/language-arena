-- Player Combat System
local Concord = require("lib.concord.init")
local Constants = require("constants")
local logger = require("logger")

local PlayerCombat = Concord.system({
    players = {"player", "position", "velocity", "dimensions"}
})

function PlayerCombat:update(dt)
    -- Check for player collisions (kicking)
    for i, player1Entity in ipairs(self.players) do
        local player1 = player1Entity.player
        local player1Pos = player1Entity.position
        local player1Vel = player1Entity.velocity
        local player1Dims = player1Entity.dimensions
        
        -- Guard clause: Skip if player1 is not kicking
        if not player1.isKicking then
            -- Skip to next player1
        else
            -- Check collision with other players
            for j, player2Entity in ipairs(self.players) do
                -- Guard clause: Skip self
                if i == j then
                    -- Skip to next player2
                else
                    local player2 = player2Entity.player
                    local player2Pos = player2Entity.position
                    local player2Vel = player2Entity.velocity
                    local player2Dims = player2Entity.dimensions
                    
                    -- Guard clause: Skip if player2 is invulnerable
                    if player2.isInvulnerable then
                        -- Skip to next player2
                    else
                        -- Calculate kick hitbox
                        local kickX, kickWidth
                        if player1.facingRight then
                            kickX = player1Pos.x + player1Dims.width + Constants.KICK_HITBOX_OFFSET_X
                            kickWidth = Constants.KICK_HITBOX_WIDTH
                        else
                            kickX = player1Pos.x - Constants.KICK_HITBOX_OFFSET_X - Constants.KICK_HITBOX_WIDTH
                            kickWidth = Constants.KICK_HITBOX_WIDTH
                        end
                        local kickY = player1Pos.y + player1Dims.height/2 - Constants.KICK_HITBOX_OFFSET_Y
                        
                        -- Check if player2 is in kick hitbox
                        if player2Pos.x < kickX + kickWidth and
                           player2Pos.x + player2Dims.width > kickX and
                           player2Pos.y < kickY + Constants.KICK_HITBOX_HEIGHT and
                           player2Pos.y + player2Dims.height > kickY then
                            
                            -- Player2 is hit
                            logger:debug("Player %s kicked player %s", player1.name, player2.name)
                            
                            -- Apply knockback
                            player2.isKnockback = true
                            player2.knockbackTimer = 1.0  -- 1 second of knockback
                            
                            -- Set velocity based on kicker's facing direction
                            if player1.facingRight then
                                player2Vel.x = Constants.KNOCKBACK_FORCE_X
                            else
                                player2Vel.x = -Constants.KNOCKBACK_FORCE_X
                            end
                            
                            -- Apply upward velocity for bounce effect
                            player2Vel.y = -Constants.KNOCKBACK_FORCE_Y
                            
                            -- Set invulnerability and immobility
                            player2.isInvulnerable = true
                            player2.invulnerabilityTimer = Constants.PLAYER_INVULNERABILITY_DURATION
                            player2.isImmobile = true
                            player2.immobilityTimer = Constants.PLAYER_IMMOBILITY_DURATION
                            
                            -- Initialize flashing effect
                            player2.isFlashing = true
                        end
                    end
                end
            end
        end
    end
end

return PlayerCombat 