local Game = require("game")
local logger = require("logger")  -- Import the logger

-- Game instance
local game

function love.load()
    logger:info("Language Arena starting up")
    
    -- Set up window
    love.window.setMode(1200, 800)
    love.window.setTitle("Language Arena")
    
    -- Create game instance
    game = Game.new()
    
    logger:info("Game initialized successfully")
end

function love.update(dt)
    if game then
        game:update(dt)
    end
end

function love.draw()
    if game then
        game:draw()
    end
end

function love.gamepadpressed(joystick, button)
    logger:debug("Gamepad button pressed: %s on %s", button, joystick:getName())
    
    if game then
        game:gamepadpressed(joystick, button)
    end
end

function love.gamepadreleased(joystick, button)
    logger:debug("Gamepad button released: %s on %s", button, joystick:getName())
    
    if game then
        game:gamepadreleased(joystick, button)
    end
end

function love.joystickadded(joystick)
    if joystick:isGamepad() then
        game:setupControllers()
    end
end

function love.joystickremoved(joystick)
    game:setupControllers()
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "f1" then
        -- Toggle logging on/off with F1 key
        local isEnabled = logger:toggle()
        print("Logging " .. (isEnabled and "enabled" or "disabled"))
    end
end

function love.quit()
    logger:info("Game shutting down")
    logger:close()  -- Close the log file
end 