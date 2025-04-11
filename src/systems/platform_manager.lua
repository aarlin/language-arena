local Concord = require("lib.concord.init")
local Constants = require("constants")

local PlatformManager = Concord.system({
    pool = {"platform", "position", "dimensions"}
})

function PlatformManager:init()
    self.platforms = {}
    self:spawnInitialPlatforms()
end

function PlatformManager:spawnInitialPlatforms()
    -- Spawn ground platform
    self:spawnPlatform(0, Constants.SCREEN_HEIGHT - 50, Constants.SCREEN_WIDTH, 50)

    -- Spawn some initial platforms
    self:spawnPlatform(100, Constants.SCREEN_HEIGHT - 100, 200, 20)
    self:spawnPlatform(400, Constants.SCREEN_HEIGHT - 200, 200, 20)
    self:spawnPlatform(700, Constants.SCREEN_HEIGHT - 300, 200, 20)

    -- Spawn a bouncy platform
    self:spawnPlatform(300, Constants.SCREEN_HEIGHT - 500, 200, 20, true)
end

function PlatformManager:spawnPlatform(x, y, width, height, isBouncy)
    local world = self:getWorld()
    local entity = Concord.entity(world)
        :give("platform", isBouncy or false)
        :give("position", x, y)
        :give("dimensions", width, height)
    table.insert(self.platforms, entity)
    return entity
end

function PlatformManager:update(dt)
    -- Check if we need to spawn new platforms
    local player = self:getWorld():getResource("player")
    if player then
        local playerY = tonumber(player.position.y)
        local highestPlatformY = Constants.SCREEN_HEIGHT

        -- Find the highest platform
        for _, platform in ipairs(self.platforms) do
            local platformY = tonumber(platform.position.y)
            if platformY < highestPlatformY then
                highestPlatformY = platformY
            end
        end

        -- If player is getting close to the top, spawn new platforms
        if playerY < highestPlatformY + 300 then
            self:spawnNewPlatforms()
        end
    end
end

function PlatformManager:spawnNewPlatforms()
    local lastPlatform = self.platforms[#self.platforms]
    if not lastPlatform then return end

    local lastX = tonumber(lastPlatform.position.x)
    local lastY = tonumber(lastPlatform.position.y)
    local lastWidth = tonumber(lastPlatform.dimensions.width)

    -- Spawn new platforms above the last one
    local newY = lastY - 200
    local newX = love.math.random(50, Constants.SCREEN_WIDTH - 250)
    local newWidth = love.math.random(150, 250)
    
    -- 20% chance to spawn a bouncy platform
    local isBouncy = love.math.random() < 0.2
    
    self:spawnPlatform(newX, newY, newWidth, 20, isBouncy)
end

return PlatformManager 