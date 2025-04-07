-- Box Movement System
local Concord = require("lib.concord.init")
local Constants = require("constants")
local logger = require("logger")

local BoxMovement = Concord.system({
    boxes = {"box", "position"}
})

function BoxMovement:update(dt)
    for _, entity in ipairs(self.boxes) do
        local box = entity.box
        local position = entity.position
        
        -- Move box down
        position.y = position.y + box.speed * dt
        
        -- Remove if off screen
        if position.y > Constants.SCREEN_HEIGHT then
            entity:destroy()
            logger:debug("Box removed (off screen)")
        end
    end
end

return BoxMovement 