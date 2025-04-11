local Concord = require("lib.concord.init")
local Constants = require("constants")

local PlatformRender = Concord.system({
    pool = {"platform", "position", "dimensions"}
})

function PlatformRender:draw()
    for _, entity in ipairs(self.pool) do
        local platform = entity.platform
        local x = tonumber(entity.position.x)
        local y = tonumber(entity.position.y)
        local width = tonumber(entity.dimensions.width)
        local height = tonumber(entity.dimensions.height)

        -- Draw platform
        love.graphics.setColor(0.2, 0.2, 0.2)  -- Dark gray color
        love.graphics.rectangle("fill", x, y, width, height)

        -- Draw platform border
        love.graphics.setColor(0.4, 0.4, 0.4)  -- Lighter gray for border
        love.graphics.rectangle("line", x, y, width, height)

        -- If platform is bouncy, draw a special indicator
        if platform.isBouncy then
            love.graphics.setColor(0.8, 0.2, 0.2)  -- Red color for bouncy platforms
            love.graphics.rectangle("line", x + 2, y + 2, width - 4, height - 4)
        end
    end
end

return PlatformRender 