local Concord = require("lib.concord.init")
local Constants = require("constants")

local PlatformCollision = Concord.system({
    pool = {"platform", "position", "dimensions"}
})

function PlatformCollision:update(dt)
    -- Get all players from the world
    local players = self:getWorld():getResource("players") or {}
    
    -- For each platform
    for _, platform in ipairs(self.pool) do
        local platformX = tonumber(platform.position.x)
        local platformY = tonumber(platform.position.y)
        local platformWidth = tonumber(platform.dimensions.width)
        local platformHeight = tonumber(platform.dimensions.height)
        
        -- For each player
        for _, player in ipairs(players) do
            local playerX = tonumber(player.position.x)
            local playerY = tonumber(player.position.y)
            local playerWidth = tonumber(player.dimensions.width)
            local playerHeight = tonumber(player.dimensions.height)
            local playerVelY = tonumber(player.velocity.y)
            
            -- Calculate player's bottom edge with offset
            local playerBottom = playerY + playerHeight
            local landingOffset = 20  -- How high above the platform the player lands
            
            -- Calculate platform's top edge
            local platformTop = platformY
            
            -- Check if player is above the platform
            if playerBottom > platformTop then
                -- Check horizontal overlap
                if playerX + playerWidth > platformX and playerX < platformX + platformWidth then
                    -- Check if player is falling (positive Y velocity)
                    if playerVelY > 0 then
                        -- Check if player's bottom is close to platform's top
                        if playerBottom - platformTop < landingOffset then
                            -- Check if player is trying to drop through (holding down)
                            local isTryingToDrop = false
                            if player.controls then
                                local downButton = player.controls.down
                                if downButton and player.joystick then
                                    isTryingToDrop = player.joystick:isGamepadDown(downButton)
                                end
                            end
                            
                            if not isTryingToDrop then
                                -- Land on platform
                                player.position.y = platformTop - playerHeight + 10  -- Slight offset to prevent sticking
                                player.velocity.y = 0
                                
                                -- If platform is bouncy, apply bounce force
                                if platform.platform.isBouncy then
                                    player.velocity.y = -platform.platform.bounceForce
                                end
                                
                                -- Set player as grounded
                                player.isGrounded = true
                                player.isJumping = false
                            end
                        end
                    end
                end
            end
        end
    end
end

return PlatformCollision 