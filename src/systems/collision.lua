local Components = require("src.components.components")

local Collision = System({
    position = Components.Position,
    dimensions = Components.Dimensions
})

function Collision:update(dt)
    for _, e1 in ipairs(self.pool) do
        local pos1 = e1[Components.Position]
        local dim1 = e1[Components.Dimensions]
        
        for _, e2 in ipairs(self.pool) do
            if e1 ~= e2 then
                local pos2 = e2[Components.Position]
                local dim2 = e2[Components.Dimensions]
                
                -- Check for collision
                if pos1.x < pos2.x + dim2.width and
                   pos1.x + dim1.width > pos2.x and
                   pos1.y < pos2.y + dim2.height and
                   pos1.y + dim1.height > pos2.y then
                    -- Handle collision
                    self:getWorld():emit("collision", e1, e2)
                end
            end
        end
    end
end

return Collision 