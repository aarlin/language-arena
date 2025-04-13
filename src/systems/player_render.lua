-- Player Render System
local Concord = require("lib.concord.init")
local Constants = require("constants")

local PlayerRender = Concord.system({
    pool = {"player", "position", "dimensions", "animation"}
})

function PlayerRender:draw()
    for _, e in ipairs(self.pool) do
        -- Get current animation frame
        local currentAnimation = e.player.currentAnimation
        local animation = e.player.animations[currentAnimation]
        local frame = animation and animation.frames[e.player.currentFrame] or nil
        
        if frame then
            -- Calculate draw position
            local x = e.position.x + Constants.MODEL_OFFSET_X
            local y = e.position.y + Constants.MODEL_OFFSET_Y
            
            -- Set color with flash effect
            if e.isFlashing then
                love.graphics.setColor(1, 1, 1, 1)  -- Flash to white
            else
                love.graphics.setColor(e.player.color)
            end
            
            -- Save current transformation
            love.graphics.push()
            
            -- Translate to player position
            love.graphics.translate(x, y)
            
            -- Scale and flip based on facing direction
            local scaleX = e.player.facingRight and Constants.PLAYER_SCALE or -Constants.PLAYER_SCALE
            love.graphics.scale(scaleX, Constants.PLAYER_SCALE)
            
            -- Draw the frame
            love.graphics.draw(frame, 0, 0, 0, 1, 1, frame:getWidth()/2, frame:getHeight()/2)
            
            -- Restore transformation
            love.graphics.pop()
            
            -- Reset color
            love.graphics.setColor(1, 1, 1, 1)
        end
    end
end

return PlayerRender 