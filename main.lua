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

function love.quit()
    logger:info("Game shutting down")
    logger:close()
end 