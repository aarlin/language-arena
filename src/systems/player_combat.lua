local Components = require("src.components.components")
local Concord = require("lib.concord")

local PlayerCombat = Concord.system({
    player = Components.Player,
    controller = Components.Controller
})

function PlayerCombat:update(dt)
    for _, e in ipairs(self.pool) do
        local player = e[Components.Player]
        local controller = e[Components.Controller]
        
        -- Handle combat input
        if controller.joystick then
            if controller.joystick:isGamepadDown(controller.controls.kick) then
                player.isKicking = true
                player.kickTimer = 0.5 -- Kick duration
            end
        end
        
        -- Update timers
        if player.kickTimer > 0 then
            player.kickTimer = player.kickTimer - dt
            if player.kickTimer <= 0 then
                player.isKicking = false
            end
        end
        
        if player.knockbackTimer > 0 then
            player.knockbackTimer = player.knockbackTimer - dt
            if player.knockbackTimer <= 0 then
                player.isKnockback = false
            end
        end
        
        if player.invulnerabilityTimer > 0 then
            player.invulnerabilityTimer = player.invulnerabilityTimer - dt
            if player.invulnerabilityTimer <= 0 then
                player.isInvulnerable = false
            end
        end
        
        if player.immobilityTimer > 0 then
            player.immobilityTimer = player.immobilityTimer - dt
            if player.immobilityTimer <= 0 then
                player.isImmobile = false
            end
        end
    end
end

return PlayerCombat 