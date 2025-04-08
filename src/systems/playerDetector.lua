local Concord = require("lib.concord")
local logger = require("lib.logger")

-- Add systems
local PlayerDetector = Concord.system({}) -- Doesn't need a pool, operates globally

function PlayerDetector:update(dt)
    local joysticks = love.joystick.getJoysticks()
    for _, joystick in ipairs(joysticks) do
        -- Check if this joystick is already associated with a player
        local found = false
        if self.world.connectedJoysticks then -- Ensure table exists
            if self.world.connectedJoysticks[joystick] then
                found = true
            end
        else
             self.world.connectedJoysticks = {} -- Initialize if missing
        end

        if not found then
            -- New player detected
            local playerName = "Player " .. (#self.world.players + 1)
            logger:info("New player detected: %s", playerName)

            local playerEntity = self.world:createEntity()
            playerEntity:give("player", playerName, {1, 1, 1}, "default") -- Adjust 'default' etc. as needed

            -- Define default controls here or fetch from config
            local controls = {
                left = "dpleft",  -- Using D-pad based on your example
                right = "dpright",
                select = "a",
                back = "b",
                start = "start"
                -- Add other necessary controls
            }
            playerEntity:give("controller", joystick, controls)
            playerEntity:give("selectionState")

            if not self.world.players then self.world.players = {} end -- Initialize if missing
            table.insert(self.world.players, playerEntity)
            self.world.connectedJoysticks[joystick] = playerEntity -- Store the entity itself for easy lookup if needed
        end
    end

    -- Optional: Handle disconnected players (more complex, requires tracking)
end

return PlayerDetector