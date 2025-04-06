local Game = require("game")
local logger = require("logger")  -- Import the logger

-- Game instance
local game

-- Viewport scaling
local scale = 1
local offsetX = 0
local offsetY = 0

function love.load()
    logger:info("Language Arena starting up")
    
    -- Set up window to use the full screen resolution
    local screenWidth, screenHeight
    
    -- Check if getMode is available (PC) or use default resolution (Switch)
    if love.window.getMode then
        screenWidth, screenHeight = love.window.getMode()
        love.window.setMode(screenWidth, screenHeight, {
            fullscreen = false,
            resizable = true,
            vsync = true
        })
    else
        -- Default resolution for Switch
        screenWidth, screenHeight = 1280, 720
        logger:info("Running on Switch, using default resolution: %dx%d", screenWidth, screenHeight)
    end
    
    love.window.setTitle("Language Arena")
    
    -- Calculate scaling factors
    local targetWidth = 1200  -- Target width for the game
    local targetHeight = 800  -- Target height for the game
    
    -- Calculate scale to fit the screen while maintaining aspect ratio
    scale = math.min(screenWidth / targetWidth, screenHeight / targetHeight)
    
    -- Calculate offsets to center the game
    offsetX = (screenWidth - (targetWidth * scale)) / 2
    offsetY = (screenHeight - (targetHeight * scale)) / 2
    
    logger:info("Screen resolution: %dx%d, Scale: %.2f, Offset: (%.2f, %.2f)", 
        screenWidth, screenHeight, scale, offsetX, offsetY)
    
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
    -- Apply scaling and offset
    love.graphics.push()
    love.graphics.translate(offsetX, offsetY)
    love.graphics.scale(scale, scale)
    
    if game then
        game:draw()
    end
    
    love.graphics.pop()
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

-- Handle joystick events
function love.joystickadded(joystick)
    logger:info("Joystick added: %s", joystick:getName())
    if game then
        game:setupControllers()
    end
end

function love.joystickremoved(joystick)
    logger:info("Joystick removed: %s", joystick:getName())
    if game then
        game:setupControllers()
    end
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
    logger:close()  -- Close the log file
end 