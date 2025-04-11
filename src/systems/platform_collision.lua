local Concord = require("lib.concord.init")
local Constants = require("constants")

local PlatformCollision = Concord.system({
    pool = {"platform", "position", "dimensions"},
    player = {"player", "position", "dimensions", "velocity"}
})

function PlatformCollision:update(dt)
    local player = self.player[1]
    if not player then return end

    -- Get player bounds
    local playerX = tonumber(player.position.x)
    local playerY = tonumber(player.position.y)
    local playerWidth = tonumber(player.dimensions.width)
    local playerHeight = tonumber(player.dimensions.height)
    local playerVelY = tonumber(player.velocity.y)

    -- Check collision with each platform
    for _, entity in ipairs(self.pool) do
        local platform = entity.platform
        local platX = tonumber(entity.position.x)
        local platY = tonumber(entity.position.y)
        local platWidth = tonumber(entity.dimensions.width)
        local platHeight = tonumber(entity.dimensions.height)

        -- Check if player is above platform and falling
        if playerVelY > 0 and
           playerX + playerWidth > platX and
           playerX < platX + platWidth and
           playerY + playerHeight > platY and
           playerY < platY + platHeight then

            -- Handle platform collision
            player.position.y = platY - playerHeight
            player.velocity.y = 0
            player.isJumping = false

            -- Handle bouncy platforms
            if platform.isBouncy then
                player.velocity.y = -platform.bounceForce
                player.isJumping = true
            end
        end
    end
end

return PlatformCollision 