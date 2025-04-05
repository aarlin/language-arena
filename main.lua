local Game = require("game")
local logger = require("logger")  -- Import the logger

-- Initialize game state
local game = nil

-- Viewport scaling
local scale = 1
local offsetX = 0
local offsetY = 0

-- Set up error handling
love.errorhandler = function(msg)
    -- Get system info
    local systemInfo = string.format([[
System Information:
------------------
OS: %s
LÖVE Version: %s
Screen Resolution: %dx%d
]], 
        love._os or "Unknown",
        love.getVersion(),
        love.graphics.getWidth(),
        love.graphics.getHeight()
    )

    -- Get game state info
    local gameStateInfo = ""
    if game then
        gameStateInfo = string.format([[
Game State Information:
---------------------
Game State: %s
Controllers: %d
Boxes: %d
Game Timer: %.2f
]], 
            game.gameState or "Unknown",
            #(game.controllers or {}),
            #(game.boxes or {}),
            game.gameTimer or 0
        )
    end

    -- Get detailed traceback
    local traceback = debug.traceback()
    local detailedTrace = ""
    
    -- Parse the traceback to get more information
    for line in traceback:gmatch("[^\r\n]+") do
        if line:match("^%s*%d+%s*:") then
            -- This is a stack frame
            local file, lineNum, func = line:match("([^:]+):(%d+):%s*in%s*([^%(]+)")
            if file and lineNum and func then
                detailedTrace = detailedTrace .. string.format("File: %s\nLine: %s\nFunction: %s\n\n", 
                    file:gsub("^%s+", ""), 
                    lineNum, 
                    func:gsub("^%s+", ""))
            end
        end
    end

    -- Format the complete error log
    local errorLog = string.format([[
%s

Error Details:
------------
Error: %s

Detailed Traceback:
-----------------
%s

Game State:
%s
]], 
        systemInfo,
        msg,
        detailedTrace,
        gameStateInfo
    )

    -- Log the error
    logger:error(errorLog)
    
    -- Write to a file as backup
    local file = io.open("error_log.txt", "w")
    if file then
        file:write(errorLog)
        file:close()
    end
    
    -- Copy to clipboard if supported
    if love.system then
        love.system.setClipboardText(errorLog)
        logger:info("Error copied to clipboard")
    end
    
    return errorLog
end

-- Initialize game with error handling
local function initializeGame()
    local success, err = pcall(function()
        logger:info("[INIT] Starting game initialization sequence")
        
        -- Initialize game first
        logger:info("[INIT] Creating new game instance")
        game = Game.new()
        logger:info("[INIT] Game instance created successfully")
        
        -- Then handle platform-specific setup
        if love._os == "Switch" then
            logger:info("[INIT] Switch platform detected, setting resolution to 1280x720")
            love.window.setMode(1280, 720)
            
            -- Set default font for Switch (avoid Source Han Sans)
            logger:info("[INIT] Setting default font for Switch platform")
            local defaultFont = love.graphics.newFont(14)
            love.graphics.setFont(defaultFont)
        else
            logger:info("[INIT] %s platform detected, setting resolution to 1920x1080", love._os)
            love.window.setMode(1920, 1080)
        end
        
        logger:info("[INIT] Platform setup complete")
    end)
    
    if not success then
        logger:error("[INIT] Failed to initialize game: %s", err)
        return false
    end
    logger:info("[INIT] Game initialization completed successfully")
    return true
end

-- LÖVE callbacks with error handling
function love.load()
    logger:info("[LOAD] Starting game load sequence")
    if not initializeGame() then
        logger:error("[LOAD] Game initialization failed during load")
        error("Game initialization failed")
    end
    logger:info("[LOAD] Game load sequence completed")
end

function love.update(dt)
    if not game then 
        logger:error("[UPDATE] Update called with no game instance")
        return 
    end
    
    local success, err = pcall(function()
        game:update(dt)
    end)
    
    if not success then
        logger:error("[UPDATE] Update error: %s", err)
    end
end

function love.draw()
    if not game then 
        logger:error("[DRAW] Draw called with no game instance")
        return 
    end
    
    local success, err = pcall(function()
        game:draw()
    end)
    
    if not success then
        logger:error("[DRAW] Draw error: %s", err)
    end
end

function love.quit()
    logger:info("[QUIT] Starting game cleanup")
    if game then
        local success, err = pcall(function()
            game:cleanup()
        end)
        if not success then
            logger:error("[QUIT] Cleanup error: %s", err)
        end
    end
    logger:info("[QUIT] Game cleanup completed")
end

-- Controller handling with error checking
function love.joystickadded(joystick)
    logger:info("[JOYSTICK] Joystick added event received")
    if not game then
        logger:error("[JOYSTICK] Game not initialized when controller added")
        return
    end
    
    local success, err = pcall(function()
        if joystick:isGamepad() then
            logger:info("[JOYSTICK] Gamepad connected: %s", joystick:getName())
            game:setupControllers()
        end
    end)
    
    if not success then
        logger:error("[JOYSTICK] Controller setup error: %s", err)
    end
end

function love.joystickremoved(joystick)
    logger:info("[JOYSTICK] Joystick removed event received")
    if not game then 
        logger:error("[JOYSTICK] Game not initialized when controller removed")
        return 
    end
    
    local success, err = pcall(function()
        if joystick:isGamepad() then
            logger:info("[JOYSTICK] Gamepad disconnected: %s", joystick:getName())
            game:setupControllers()
        end
    end)
    
    if not success then
        logger:error("[JOYSTICK] Controller removal error: %s", err)
    end
end

-- Gamepad button handling with error checking
function love.gamepadpressed(joystick, button)
    logger:info("[GAMEPAD] Button pressed: %s", button)
    if not game then 
        logger:error("[GAMEPAD] Game not initialized when button pressed")
        return 
    end
    
    local success, err = pcall(function()
        game:gamepadpressed(joystick, button)
    end)
    
    if not success then
        logger:error("[GAMEPAD] Button press error: %s", err)
    end
end

function love.gamepadreleased(joystick, button)
    logger:info("[GAMEPAD] Button released: %s", button)
    if not game then 
        logger:error("[GAMEPAD] Game not initialized when button released")
        return 
    end
    
    local success, err = pcall(function()
        game:gamepadreleased(joystick, button)
    end)
    
    if not success then
        logger:error("[GAMEPAD] Button release error: %s", err)
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