-- Import required modules
local ECS = require("ecs")
local CharacterSelect = require("character_select")
local logger = require("logger")
local Constants = require("constants")
local config = require("config")
local PlayerMovement = require("systems.player_movement")  -- Import the PlayerMovement system

-- Game states
local GAME_STATES = {
    TITLE = "title",
    CHARACTER_SELECT = "character_select",
    PLAYING = "playing",
    GAME_OVER = "game_over"
}

-- Global variables
local gameState = GAME_STATES.TITLE
local ecs = nil
local characterSelect = nil
local controllers = {}
local gameTimer = 0
local spawnTimer = 0

-- Initialize the game
function love.load()
    -- Set up logging
    logger:init(config.logging)
    logger:info("Game starting...")
    
    -- Initialize ECS
    ecs = ECS:init()
    
    -- Initialize character select
    characterSelect = CharacterSelect.new()
    
    -- Set up controllers
    for i, joystick in ipairs(love.joystick.getJoysticks()) do
        if joystick:isGamepad() then
            table.insert(controllers, joystick)
            logger:info("Controller %d connected: %s", i, joystick:getName())
        end
    end
    
    -- Create players based on connected controllers
    for i, joystick in ipairs(controllers) do
        local controls = {
            controller = i,
            left = "leftx",  -- Use appropriate stick for movement
            jump = "a",      -- A button on Switch
            down = "b",      -- B button on Switch (now used for running)
            kick = "leftshoulder",     -- X button on Switch
            start = "start", -- Plus button on Switch
            back = "back"    -- Minus button on Switch
        }
        
        -- Create player entity
        local color = {love.math.random(), love.math.random(), love.math.random()}
        ecs:createPlayer(100 + (i-1) * 200, Constants.GROUND_Y - Constants.PLAYER_HEIGHT, color, controls, joystick, false)
        
        -- Add to character select
        characterSelect:addPlayer({
            name = "Player " .. i,
            controller = joystick,
            controls = controls
        })
        
        logger:info("Added player: Player %d", i)
    end
    
    -- If no controllers are connected, create a keyboard player
    if #controllers == 0 then
        logger:info("No controllers connected, creating keyboard player")
        
        -- Create keyboard player entity
        local color = {love.math.random(), love.math.random(), love.math.random()}
        ecs:createPlayer(100, Constants.GROUND_Y - Constants.PLAYER_HEIGHT, color, {}, nil, false)
        
        -- Add to character select
        characterSelect:addPlayer({
            name = "Keyboard Player",
            controller = nil,
            controls = {}
        })
    end
end

-- Update the game
function love.update(dt)
    if gameState == GAME_STATES.TITLE then
        -- Title screen logic
    elseif gameState == GAME_STATES.CHARACTER_SELECT then
        -- Character select logic
        characterSelect:update(dt)
        
        -- Check if character selection is complete
        if characterSelect:isComplete() then
            -- Get selected characters
            local selectedCharacters = characterSelect:getSelectedCharacters()
            
            -- Apply selected characters to players
            local playerMovementSystem = ecs.world:getSystem(PlayerMovement)
            if playerMovementSystem then
                for _, entity in ipairs(playerMovementSystem.pool) do
                    local player = entity.player
                    local controller = entity.controller
                    
                    -- Find the player in the character select
                    for selectPlayer, characterType in pairs(selectedCharacters) do
                        if selectPlayer.controller and controller.joystick and 
                           selectPlayer.controller == controller.joystick then
                            -- Set the character type
                            player.characterType = characterType
                            logger:info("Player %s assigned character: %s", player.name, characterType)
                            break
                        end
                    end
                end
            end
            
            -- Set game state to playing
            gameState = GAME_STATES.PLAYING
            logger:info("Starting game")
        end
    elseif gameState == GAME_STATES.PLAYING then
        -- Update game timer
        gameTimer = gameTimer + dt
        
        -- Update spawn timer
        spawnTimer = spawnTimer + dt
        if spawnTimer >= Constants.SPAWN_INTERVAL then
            -- Spawn a new box
            local x = love.math.random(Constants.BOX_SPAWN_MIN_X, Constants.BOX_SPAWN_MAX_X)
            local meaning = "Test"  -- This would be replaced with actual character data
            local speed = love.math.random(Constants.BOX_MIN_SPEED, Constants.BOX_MAX_SPEED)
            ecs:createBox(x, Constants.BOX_SPAWN_Y, meaning, speed)
            
            spawnTimer = 0
        end
        
        -- Update ECS
        ecs:update(dt)
    elseif gameState == GAME_STATES.GAME_OVER then
        -- Game over logic
    end
end

-- Draw the game
function love.draw()
    if gameState == GAME_STATES.TITLE then
        -- Title screen drawing
        love.graphics.setColor(Constants.COLORS.WHITE)
        love.graphics.print("Language Arena", Constants.SCREEN_WIDTH / 2 - 100, Constants.SCREEN_HEIGHT / 2 - 50)
        love.graphics.print("Press A for Chinese, B for Japanese, or Start to quit", Constants.SCREEN_WIDTH / 2 - 200, Constants.SCREEN_HEIGHT / 2)
    elseif gameState == GAME_STATES.CHARACTER_SELECT then
        -- Character select drawing
        characterSelect:draw()
    elseif gameState == GAME_STATES.PLAYING then
        -- Draw ECS
        ecs:draw()
        
        -- Draw game timer
        love.graphics.setColor(Constants.COLORS.WHITE)
        love.graphics.print("Time: " .. math.floor(gameTimer), Constants.SCREEN_WIDTH - 200, 10)
    elseif gameState == GAME_STATES.GAME_OVER then
        -- Game over drawing
        love.graphics.setColor(Constants.COLORS.WHITE)
        love.graphics.print("Game Over", Constants.SCREEN_WIDTH / 2 - 100, Constants.SCREEN_HEIGHT / 2 - 50)
        love.graphics.print("Press Start to return to title", Constants.SCREEN_WIDTH / 2 - 150, Constants.SCREEN_HEIGHT / 2)
    end
end

-- Handle key presses
function love.keypressed(key)
    if gameState == GAME_STATES.TITLE then
        if key == "escape" then
            love.event.quit()
        end
    elseif gameState == GAME_STATES.PLAYING then
        if key == "escape" then
            gameState = GAME_STATES.TITLE
        end
    elseif gameState == GAME_STATES.GAME_OVER then
        if key == "escape" then
            gameState = GAME_STATES.TITLE
        end
    end
end

-- Handle gamepad button presses
function love.gamepadpressed(joystick, button)
    if gameState == GAME_STATES.TITLE then
        if button == "a" then
            gameState = GAME_STATES.CHARACTER_SELECT
        elseif button == "b" then
            gameState = GAME_STATES.CHARACTER_SELECT
        elseif button == "start" then
            love.event.quit()
        end
    elseif gameState == GAME_STATES.CHARACTER_SELECT then
        -- Character select already handles button presses in its update method
        -- No need to call a separate method
    elseif gameState == GAME_STATES.PLAYING then
        -- Find the player with this controller and pass the button press
        local playerMovementSystem = ecs.world:getSystem(PlayerMovement)
        if playerMovementSystem then
            for _, entity in ipairs(playerMovementSystem.pool) do
                if entity.controller and entity.controller.joystick == joystick then
                    -- Handle button press
                    if button == "start" then
                        gameState = GAME_STATES.TITLE
                    end
                    break
                end
            end
        end
    elseif gameState == GAME_STATES.GAME_OVER then
        if button == "start" then
            gameState = GAME_STATES.TITLE
        end
    end
end

-- Handle gamepad button releases
function love.gamepadreleased(joystick, button)
    -- Handle button releases if needed
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
    if ecs then
        ecs:cleanup()
    end
    logger:close()  -- Close the log file
end 