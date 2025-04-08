-- Main game file
local logger = require("logger")
local Constants = require("constants")
local W = require("worlds")

-- Set up graphics
love.graphics.setBackgroundColor(0.1, 0.1, 0.1)
love.graphics.setDefaultFilter("nearest", "nearest")

-- Initialize current world
currentWorld = W.title

-- Love2D callbacks
function love.load()
    -- Set up window
    love.window.setMode(Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT)
    love.window.setTitle("Language Arena")
    
    -- Load the current world
    currentWorld:emit("load")
end

function love.update(dt)
    -- Update the current world
    local nextWorld = currentWorld:emit("update", dt)
    if nextWorld then
        currentWorld = W[nextWorld]
        currentWorld:emit("load")
    end
end

function love.draw()
    currentWorld:emit("draw")
end

function love.quit()
    logger:info("Game shutting down")
    if logger.close then
        logger:close()
    end
end 