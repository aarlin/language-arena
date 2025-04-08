local Components = require("src.components.components")

function Rendering:draw()
    for _, e in ipairs(self.pool) do
        local position = e[Components.Position]
        local dimensions = e[Components.Dimensions]
        local animation = e[Components.Animation]
        
        if animation then
            local frame = animation.frames[animation.currentFrame]
            love.graphics.draw(frame, position.x, position.y)
        else
            love.graphics.rectangle("fill", position.x, position.y, dimensions.width, dimensions.height)
        end
    end
end

return Rendering 