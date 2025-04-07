-- Import required modules
local Game = require("game")
local CharacterSelect = require("character_select")
local logger = require("logger")
local Constants = require("constants")
local config = require("config")

-- Game states
local GAME_STATES = {
    TITLE = "title",
    CHARACTER_SELECT = "character_select",
    PLAYING = "playing",
    GAME_OVER = "game_over"
}

-- Global variables
local gameState = GAME_STATES.TITLE
local game = nil
local characterSelect = nil
local players = {}
local controllers = {}

-- Initialize the game
function love.load()
    -- Set up logging
    logger:init(config.logging)
    logger:info("Game starting...")
    
    -- Initialize game objects
    game = Game.new()
    characterSelect = CharacterSelect.new()
    
    -- Set up controllers
    for i, joystick in ipairs(love.joystick.getJoysticks()) do
        if joystick:isGamepad() then
            table.insert(controllers, joystick)
            logger:info("Controller %d connected: %s", i, joystick:getName())
        end
    end
    
    -- Create players based on connected controllers
    for i, controller in ipairs(controllers) do
        local player = {
            name = "Player " .. i,
            controller = controller,
            controls = {
                controller = i,
                left = "leftx",
                right = "rightx",
                jump = "a",      -- A button on Switch
                down = "b",      -- B button on Switch (now used for running)
                kick = "leftshoulder",     -- X button on Switch
                start = "start", -- Plus button on Switch
                back = "back"    -- Minus button on Switch
            }
        }
        table.insert(players, player)
        characterSelect:addPlayer(player)
        logger:info("Added player: %s", player.name)
    end
    
    -- If no controllers are connected, create a keyboard player
    if #players == 0 then
        local keyboardPlayer = {
            name = "Keyboard Player",
            controller = nil,
            controls = {
                jump = "space",
                kick = "lctrl",
                down = "down"
            }
        }
        table.insert(players, keyboardPlayer)
        characterSelect:addPlayer(keyboardPlayer)
        logger:info("Added keyboard player")
    end
end

-- Update game state
function love.update(dt)
    if gameState == GAME_STATES.TITLE then
        -- Check for start button press to begin character selection
        for _, player in ipairs(players) do
            if player.controller and player.controller:isGamepadDown("start") then
                gameState = GAME_STATES.CHARACTER_SELECT
                logger:info("Entering character selection screen")
                break
            end
        end
    elseif gameState == GAME_STATES.CHARACTER_SELECT then
        -- Update character selection
        characterSelect:update(dt)
        
        -- Check if character selection is complete
        if characterSelect:isComplete() then
            -- Get selected characters
            local selectedCharacters = characterSelect:getSelectedCharacters()
            
            -- Create players with selected characters
            game.controllers = {}  -- Clear existing controllers
            for i, player in ipairs(players) do
                local characterType = selectedCharacters[player]
                local x = 100 + (i-1) * 200
                local y = Constants.SCREEN_HEIGHT - 200
                local color = Constants.COLORS["PLAYER" .. i] or {1, 1, 1}  -- Default to white if color not found
                local newPlayer = game:addPlayer(x, y, color, player.controls, characterType)
                if player.controller then
                    newPlayer:setController(player.controller)
                end
                logger:info("Created player %s with character %s", newPlayer.name, characterType)
            end
            
            -- Set game state to playing
            game.gameState = "game"
            
            -- Start the game
            gameState = GAME_STATES.PLAYING
            logger:info("Starting game with %d players", #game.controllers)
        end
    elseif gameState == GAME_STATES.PLAYING then
        -- Update game
        game:update(dt)
        
        -- Check for game over
        if game:isGameOver() then
            gameState = GAME_STATES.GAME_OVER
            logger:info("Game over")
        end
        
        -- Check for start button to return to title
        for _, player in ipairs(players) do
            if player.controller and player.controller:isGamepadDown("start") then
                -- Don't allow returning to character select during gameplay
                -- Only allow returning to title screen
                gameState = GAME_STATES.TITLE
                logger:info("Returning to title screen")
                break
            end
        end
    elseif gameState == GAME_STATES.GAME_OVER then
        -- Check for start button to return to title
        for _, player in ipairs(players) do
            if player.controller and player.controller:isGamepadDown("start") then
                gameState = GAME_STATES.TITLE
                logger:info("Returning to title screen")
                break
            end
        end
    end
end

-- Draw game state
function love.draw()
    if gameState == GAME_STATES.TITLE then
        -- Draw title screen
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("Language Arena", 0, 100, Constants.SCREEN_WIDTH, "center")
        love.graphics.printf("Press START to begin", 0, 300, Constants.SCREEN_WIDTH, "center")
    elseif gameState == GAME_STATES.CHARACTER_SELECT then
        -- Draw character selection screen
        characterSelect:draw()
    elseif gameState == GAME_STATES.PLAYING then
        -- Draw game
        game:draw()
    elseif gameState == GAME_STATES.GAME_OVER then
        -- Draw game over screen
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("Game Over", 0, 100, Constants.SCREEN_WIDTH, "center")
        love.graphics.printf("Press START to return to title", 0, 300, Constants.SCREEN_WIDTH, "center")
    end
end

-- Handle controller connections/disconnections
function love.joystickadded(joystick)
    if joystick:isGamepad() then
        -- Check if this joystick is already in our controllers list
        local alreadyExists = false
        for _, controller in ipairs(controllers) do
            if controller == joystick then
                alreadyExists = true
                break
            end
        end
        
        -- Only add if it's not already in our list
        if not alreadyExists then
            table.insert(controllers, joystick)
            logger:info("Controller connected: %s", joystick:getName())
            
            -- Add player for new controller
            local player = {
                name = "Player " .. (#players + 1),
                controller = joystick,
                controls = {
                    jump = "a",
                    kick = "b",
                    down = "dpdown"
                }
            }
            table.insert(players, player)
            characterSelect:addPlayer(player)
            logger:info("Added player: %s", player.name)
        end
    end
end

function love.joystickremoved(joystick)
    for i, controller in ipairs(controllers) do
        if controller == joystick then
            table.remove(controllers, i)
            logger:info("Controller disconnected: %s", joystick:getName())
            
            -- Remove player for disconnected controller
            for j, player in ipairs(players) do
                if player.controller == joystick then
                    table.remove(players, j)
                    logger:info("Removed player: %s", player.name)
                    break
                end
            end
            break
        end
    end
end

-- Handle keyboard input for title screen
function love.keypressed(key)
    if gameState == GAME_STATES.TITLE and key == "return" then
        gameState = GAME_STATES.CHARACTER_SELECT
        logger:info("Moving to character selection screen")
    elseif gameState == GAME_STATES.GAME_OVER and key == "return" then
        gameState = GAME_STATES.TITLE
        logger:info("Returning to title screen")
    end
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
    if game then
        game:cleanup()
    end
    logger:close()  -- Close the log file
end 