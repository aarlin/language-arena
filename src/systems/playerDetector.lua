local Concord = require("lib.concord")
local logger = require("lib.logger")

-- Add systems
local PlayerDetector = Concord.system({
    pool = {"player", "controller"}
})

function PlayerDetector:update(dt)
    -- Check for new players
    local joysticks = love.joystick.getJoysticks()
    for _, joystick in ipairs(joysticks) do
        if not self.world.connectedJoysticks[joystick] then
            -- New player detected
            local player = self.world:createEntity()
            player:give("player", "Player " .. (#self.world.players + 1), {1, 1, 1}, "default")
            
            local controls = {
                left = "leftx",
                right = "rightx",
                select = "a",
                back = "b",
                start = "start"
            }
            player:give("controller", joystick, controls)
            
            table.insert(self.world.players, player)
            self.world.connectedJoysticks[joystick] = true
            logger:info("New player connected: " .. player.player.name)
        end
    end
end

return PlayerDetector