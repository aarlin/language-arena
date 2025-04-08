-- Import required modules
local ECS = require("src.core.ecs")
local logger = require("lib.logger")
local Constants = require("constants")
local Components = require("src.components.components")

-- Game state
local worlds = require("src.worlds")
CurrentWorld = worlds.title

-- Initialize the game
function love.load()
    -- Set up logging
    logger:info("Game starting...")

    CurrentWorld:emit("load")
end

-- Update the game
function love.update(dt)
    local nextWorld = CurrentWorld:emit("update", dt)
    if nextWorld and worlds[nextWorld] then
        CurrentWorld = worlds[nextWorld]
        CurrentWorld:emit("load")
    end
end

-- Draw the game
function love.draw()
    CurrentWorld:emit("draw")
end

-- Handle key presses
function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end

-- Handle gamepad button presses
function love.gamepadpressed(joystick, button)
    local nextWorld = CurrentWorld:emit("gamepadpressed", joystick, button)
    if nextWorld and worlds[nextWorld] then
        CurrentWorld = worlds[nextWorld]
        CurrentWorld:emit("load")
    end
end

-- Handle gamepad button releases
function love.gamepadreleased(joystick, button)
    CurrentWorld:emit("gamepadreleased", joystick, button)
end

function love.resize(w, h)
    -- Recalculate scaling factors when window is resized
    local targetWidth = 1200  -- Target width for the game
    local targetHeight = 800  -- Target height for the game
    
    -- Calculate scale to fit the screen while maintaining aspect ratio
    scale = math.min(w / targetWidth, h / targetHeight)
    
    -- Calculate offsets to center the game
    offsetX = (w - (targetWidth * scale)) / 2
    offsetY = (h - (targetHeight * scale)) / 2
    
    logger:info("Window resized to %dx%d, Scale: %.2f, Offset: (%.2f, %.2f)", 
        w, h, scale, offsetX, offsetY)
end

function love.quit()
    logger:info("Game shutting down")
    logger:close()
end 