local Concord = require("lib.concord")
local Constants = require("constants")

local System = Concord.system
local Components = require("src.components.components")

local BoxMovement = System({
    box = Components.Box,
    position = Components.Position
})

function BoxMovement:update(dt)
    for _, e in ipairs(self.pool) do
        local box = e[Components.Box]
        local position = e[Components.Position]
        
        -- Move box
        position.x = position.x + box.speed * dt
        
        -- Remove if off screen
        if position.x > Constants.SCREEN_WIDTH + 100 then
            self:getWorld():removeEntity(e)
        end
    end
end

return BoxMovement 