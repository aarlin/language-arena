-- Rendering System
local Concord = require("lib.concord")
local Constants = require("constants")
local config = require("config")
local logger = require("logger")

-- Load background image
local backgroundImage = love.graphics.newImage("assets/background/forest.jpg")

-- Define the rendering system with all the component pools it needs
local Rendering = Concord.system({
    pool = {"position", "dimensions", "player", "box", "animation", "controller"}
})

-- Update animation frames
function Rendering:update(dt)
    for _, e in ipairs(self.pool) do
        if e.player and e.animation then
            local player = e.player
            local animation = e.animation
            
            if player.characterType and player.characterType ~= "" then
                -- Update animation timer
                animation.animationTimer = animation.animationTimer + dt
                
                -- Update frame when timer exceeds animation speed
                if animation.animationTimer >= animation.animationSpeed then
                    animation.animationTimer = 0
                    animation.currentFrame = animation.currentFrame + 1
                    
                    -- Loop back to first frame if we've reached the end
                    local maxFrames = animation.maxFrames[animation.currentAnimation] or 1
                    if animation.currentFrame > maxFrames then
                        animation.currentFrame = 1
                    end
                end
            end
        end
    end
end

function Rendering:draw()
    -- Draw background
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(backgroundImage, 0, 0, 0, Constants.SCREEN_WIDTH / backgroundImage:getWidth(), Constants.SCREEN_HEIGHT / backgroundImage:getHeight())
    
    -- Draw all entities in the pool
    for _, e in ipairs(self.pool) do
        local position = e.position
        local dimensions = e.dimensions
        
        -- Draw player
        if e.player then
            local player = e.player
            local animation = e.animation
            
            -- Set color based on player state
            if player.isInvulnerable and math.floor(player.invulnerabilityTimer * 10) % 2 == 0 then
                love.graphics.setColor(1, 1, 1, 0.5)  -- Flash effect
            else
                love.graphics.setColor(1, 1, 1, 1)
            end
            
            -- Draw player rectangle
            love.graphics.rectangle(
                "fill",
                position.x,
                position.y,
                dimensions.width,
                dimensions.height
            )
            
            -- Draw player name and score
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(player.name, position.x, position.y - 20)
            love.graphics.print("Score: " .. (player.score or 0), position.x, position.y - 40)
            
            -- Draw current animation state
            if animation then
                love.graphics.print(animation.currentAnimation, position.x, position.y - 60)
            end
        end
        
        -- Draw box
        if e.box then
            local box = e.box
            
            -- Set color based on box type
            if box.isPoop then
                love.graphics.setColor(0.5, 0.25, 0, 1)  -- Brown for poop
            else
                love.graphics.setColor(0.8, 0.8, 0.8, 1)  -- Gray for normal boxes
            end
            
            -- Draw box rectangle
            love.graphics.rectangle(
                "fill",
                position.x,
                position.y,
                dimensions.width,
                dimensions.height
            )
            
            -- Draw character and meaning
            love.graphics.setColor(0, 0, 0)
            love.graphics.print(box.character, position.x + 5, position.y + 5)
            love.graphics.print(box.meaning, position.x + 5, position.y + 25)
        end
    end
    
    -- Draw debug info if enabled
    if config.debug.enabled then
        love.graphics.setColor(Constants.COLORS.WHITE)
        
        if config.debug.showFPS then
            love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
        end
        
        if config.debug.showPlayerInfo then
            local playerCount = 0
            local boxCount = 0
            for _, e in ipairs(self.pool) do
                if e.player then playerCount = playerCount + 1 end
                if e.box then boxCount = boxCount + 1 end
            end
            love.graphics.print("Players: " .. playerCount, 10, 30)
            love.graphics.print("Boxes: " .. boxCount, 10, 50)
        end
        
        -- Add joystick movement debug info
        if config.debug.showJoystickMovement then
            local debugY = 100
            for _, e in ipairs(self.pool) do
                if e.player and e.controller and not e.controller.isBot and e.controller.joystick then
                    local controller = e.controller
                    local player = e.player
                    
                    -- Get joystick values
                    local leftX = controller.joystick:getAxis(1)  -- Left stick X
                    local leftY = controller.joystick:getAxis(2)  -- Left stick Y
                    local rightX = controller.joystick:getAxis(3)  -- Right stick X
                    local rightY = controller.joystick:getAxis(4)  -- Right stick Y
                    
                    -- Print player name and joystick values
                    love.graphics.print(string.format("Player %d: %s", player.controller, player.name), 10, debugY)
                    love.graphics.print(string.format("Left: (%.2f, %.2f)", leftX, leftY), 10, debugY + 20)
                    love.graphics.print(string.format("Right: (%.2f, %.2f)", rightX, rightY), 10, debugY + 40)
                    
                    -- Draw visual representation of joystick movement
                    local stickSize = 50
                    local centerX = 200
                    local centerY = debugY + 30
                    
                    -- Draw left stick
                    love.graphics.setColor(Constants.COLORS.WHITE)
                    love.graphics.circle("line", centerX, centerY, stickSize/2)
                    love.graphics.setColor(Constants.COLORS.BLUE)
                    love.graphics.circle("fill", centerX + leftX * stickSize/2, centerY + leftY * stickSize/2, 5)
                    
                    -- Draw right stick
                    love.graphics.setColor(Constants.COLORS.WHITE)
                    love.graphics.circle("line", centerX + 100, centerY, stickSize/2)
                    love.graphics.setColor(Constants.COLORS.RED)
                    love.graphics.circle("fill", centerX + 100 + rightX * stickSize/2, centerY + rightY * stickSize/2, 5)
                    
                    debugY = debugY + 80
                end
            end
        end
    end
end

return Rendering 