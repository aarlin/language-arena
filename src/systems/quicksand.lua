local Concord = require("lib.concord.init")
local Constants = require("constants")

local QuicksandSystem = Concord.system({
    pool = {"quicksand", "position", "dimensions"}
})

function QuicksandSystem:update(dt)
    -- Get all players from the world
    local players = self:getWorld():getResource("players") or {}
    
    -- For each quicksand platform
    for _, quicksand in ipairs(self.pool) do
        local quicksandX = tonumber(quicksand.position.x)
        local quicksandY = tonumber(quicksand.position.y)
        local quicksandWidth = tonumber(quicksand.dimensions.width)
        local quicksandHeight = tonumber(quicksand.dimensions.height)
        
        -- For each player
        for _, player in ipairs(players) do
            local playerX = tonumber(player.position.x)
            local playerY = tonumber(player.position.y)
            local playerWidth = tonumber(player.dimensions.width)
            local playerHeight = tonumber(player.dimensions.height)
            
            -- Check if player is on the quicksand
            if playerX + playerWidth > quicksandX and playerX < quicksandX + quicksandWidth then
                if playerY + playerHeight > quicksandY and playerY < quicksandY + quicksandHeight then
                    -- Player is on quicksand
                    quicksand.isSinking = true
                    
                    -- If player is not already at max sink depth
                    if quicksand.currentSinkDepth < quicksand.maxSinkDepth then
                        -- Increase sink depth
                        quicksand.currentSinkDepth = quicksand.currentSinkDepth + quicksand.sinkSpeed * dt
                        if quicksand.currentSinkDepth > quicksand.maxSinkDepth then
                            quicksand.currentSinkDepth = quicksand.maxSinkDepth
                        end
                        
                        -- Move player down
                        player.position.y = player.position.y + quicksand.sinkSpeed * dt
                    end
                else
                    -- Player is not on quicksand
                    quicksand.isSinking = false
                    quicksand.currentSinkDepth = 0
                end
            end
        end
    end
end

return QuicksandSystem 