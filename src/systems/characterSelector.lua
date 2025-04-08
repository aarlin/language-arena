local Concord = require("lib.concord")
local logger = require("lib.logger")

local CharacterSelector = Concord.system({
    pool = {"player", "controller"}
})

function CharacterSelector:update(dt)
    for _, player in ipairs(self.world.players) do
        if player.controller and player.controller.joystick then
            local joystick = player.controller.joystick

            if joystick:isGamepadDown("a") then
                self.world.selectedCharacters[player] = "chinese"
                logger:info(player.player.name .. " selected Chinese")
            end
        end 
    end
end

return CharacterSelector
