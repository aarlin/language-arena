-- Collision System
local Concord = require("lib.concord.init")
local Constants = require("constants")
local logger = require("logger")

local Collision = Concord.system({
    players = {"player", "position", "velocity", "dimensions"},
    boxes = {"box", "position", "dimensions"}
})

function Collision:update(dt)
    -- Check collisions between players and boxes
    for _, playerEntity in ipairs(self.players) do
        local player = playerEntity.player
        local playerPos = playerEntity.position
        local playerVel = playerEntity.velocity
        local playerDims = playerEntity.dimensions
        
        -- Guard clause: Skip if player is invulnerable
        if player.isInvulnerable then
            -- Skip to next player
        else
            -- Check collision with each box
            for _, boxEntity in ipairs(self.boxes) do
                local box = boxEntity.box
                local boxPos = boxEntity.position
                local boxDims = boxEntity.dimensions
                
                -- Guard clause: Skip if box is already collected
                if box.collected then
                    -- Skip to next box
                else
                    -- Simple AABB collision detection
                    if playerPos.x < boxPos.x + boxDims.width and
                       playerPos.x + playerDims.width > boxPos.x and
                       playerPos.y < boxPos.y + boxDims.height and
                       playerPos.y + playerDims.height > boxPos.y then
                        
                        -- Box collected
                        box.collected = true
                        logger:debug("Player %s collected box with meaning: %s", player.name, box.meaning)
                        
                        -- Mark box for removal
                        boxEntity:destroy()
                        
                        -- Handle character collection logic here
                        -- This would replace the character collection logic from the original game
                    end
                end
            end
        end
    end
end

return Collision 