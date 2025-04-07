-- Rendering System
local Concord = require("lib.concord.init")
local Constants = require("constants")
local config = require("config")
local logger = require("logger")

-- Load background image
local backgroundImage = love.graphics.newImage("assets/background/forest.jpg")

-- Define the rendering system with all the component pools it needs
local Rendering = Concord.system({
    players = {"player", "position", "dimensions", "animation"},
    boxes = {"box", "position", "dimensions"},
    controllers = {"controller", "player"}
})

function Rendering:draw()
    -- Draw background
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(backgroundImage, 0, 0, 0, Constants.SCREEN_WIDTH / backgroundImage:getWidth(), Constants.SCREEN_HEIGHT / backgroundImage:getHeight())
    
    -- Draw players
    for _, entity in ipairs(self.players) do
        local player = entity.player
        local position = entity.position
        local dimensions = entity.dimensions
        local animation = entity.animation
        
        -- Set color based on player color
        love.graphics.setColor(player.color)
        
        -- Draw player as animal character
        if player.characterType and player.characterType ~= "" then
            -- Determine animation state and frame number
            local animationState = "idle"
            local frameNumber = 1
            
            if player.isKicking then
                animationState = "kick"
            elseif player.isJumping then
                animationState = "jump"
            elseif player.isRunning then
                animationState = "run"
            elseif player.isImmobile then
                animationState = "ko"
            end
            
            -- Load character image based on character type and animation state
            local success, characterImage = pcall(function()
                return love.graphics.newImage("assets/characters/" .. player.characterType .. "/" .. animationState .. "/" .. frameNumber .. ".png")
            end)
            
            if success then
                -- Draw character with proper scaling
                local scale = dimensions.width / characterImage:getWidth()
                local drawX = position.x
                local drawY = position.y
                
                -- Flip image if facing left
                if not player.facingRight then
                    love.graphics.draw(characterImage, drawX + dimensions.width, drawY, 0, -scale, scale)
                else
                    love.graphics.draw(characterImage, drawX, drawY, 0, scale, scale)
                end
            else
                -- Fallback to rectangle if image loading fails
                love.graphics.rectangle("fill", position.x, position.y, dimensions.width, dimensions.height)
                logger:debug("Failed to load character image: %s", characterImage)
            end
        else
            -- Fallback to rectangle if no character type
            love.graphics.rectangle("fill", position.x, position.y, dimensions.width, dimensions.height)
        end
        
        -- Draw player name
        love.graphics.setColor(Constants.COLORS.WHITE)
        love.graphics.print(player.name, position.x, position.y - 20)
        
        -- Draw invulnerability indicator (flashing outline)
        if player.isInvulnerable and player.isFlashing then
            love.graphics.setColor(Constants.COLORS.BLUE)
            love.graphics.rectangle("line", position.x - 2, position.y - 2, 
                dimensions.width + 4, dimensions.height + 4)
        end
        
        -- Draw kick indicator
        if player.isKicking then
            love.graphics.setColor(Constants.COLORS.ORANGE)
            local kickX, kickWidth
            if player.facingRight then
                kickX = position.x + dimensions.width + Constants.KICK_HITBOX_OFFSET_X
                kickWidth = Constants.KICK_HITBOX_WIDTH
            else
                kickX = position.x - Constants.KICK_HITBOX_OFFSET_X - Constants.KICK_HITBOX_WIDTH
                kickWidth = Constants.KICK_HITBOX_WIDTH
            end
            local kickY = position.y + dimensions.height/2 - Constants.KICK_HITBOX_OFFSET_Y
            love.graphics.rectangle("fill", kickX, kickY, kickWidth, Constants.KICK_HITBOX_HEIGHT)
        end
    end
    
    -- Draw boxes
    for _, entity in ipairs(self.boxes) do
        local box = entity.box
        local position = entity.position
        local dimensions = entity.dimensions
        
        -- Draw box (simple rectangle for now)
        love.graphics.setColor(Constants.COLORS.YELLOW)
        love.graphics.rectangle("fill", position.x, position.y, dimensions.width, dimensions.height)
        
        -- Draw box meaning
        love.graphics.setColor(Constants.COLORS.WHITE)
        love.graphics.print(box.meaning, position.x, position.y - 20)
    end
    
    -- Draw debug info if enabled
    if config.debug.enabled then
        love.graphics.setColor(Constants.COLORS.WHITE)
        
        if config.debug.showFPS then
            love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
        end
        
        if config.debug.showPlayerInfo then
            love.graphics.print("Players: " .. #self.players, 10, 30)
            love.graphics.print("Boxes: " .. #self.boxes, 10, 50)
        end
        
        -- Add joystick movement debug info
        if config.debug.showJoystickMovement then
            local debugY = 100
            for i, entity in ipairs(self.controllers) do
                local controller = entity.controller
                local player = entity.player
                
                if not controller.isBot and controller.joystick then
                    -- Get joystick values
                    local leftX = controller.joystick:getAxis(1)  -- Left stick X
                    local leftY = controller.joystick:getAxis(2)  -- Left stick Y
                    local rightX = controller.joystick:getAxis(3)  -- Right stick X
                    local rightY = controller.joystick:getAxis(4)  -- Right stick Y
                    
                    -- Print player name and joystick values
                    love.graphics.print(string.format("Player %d: %s", i, player.name), 10, debugY)
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