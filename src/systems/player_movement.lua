local Concord = require("lib.concord")
local Constants = require("constants")

local PlayerMovementSystem = Concord.system({
    pool = {"player", "position", "velocity", "controller"}
})

function PlayerMovementSystem:update(dt)
    for _, e in ipairs(self.pool) do
        local controller = e.controller
        local joystick = controller.joystick
        
        -- Handle horizontal movement
        local axis = joystick:getAxis(1) -- leftx axis
        if math.abs(axis) > 0.1 then
            e.velocity.x = axis * Constants.PLAYER_SPEED
        else
            e.velocity.x = 0
        end
        
        -- Handle jumping
        if joystick:isGamepadDown(controller.controls.jump) and e.position.y >= Constants.GROUND_Y - Constants.PLAYER_HEIGHT then
            e.velocity.y = -Constants.JUMP_FORCE
        end
        
        -- Apply gravity
        e.velocity.y = e.velocity.y + Constants.GRAVITY * dt
        
        -- Update position
        e.position.x = e.position.x + e.velocity.x * dt
        e.position.y = e.position.y + e.velocity.y * dt
        
        -- Ground collision
        if e.position.y > Constants.GROUND_Y - Constants.PLAYER_HEIGHT then
            e.position.y = Constants.GROUND_Y - Constants.PLAYER_HEIGHT
            e.velocity.y = 0
        end
    end
end

return PlayerMovementSystem 