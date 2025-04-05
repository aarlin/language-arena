-- Logger module for Language Arena
-- Provides logging functionality for debugging

local Logger = {}
Logger.__index = Logger

-- Log levels
Logger.LEVELS = {
    DEBUG = 1,
    INFO = 2,
    WARNING = 3,
    ERROR = 4
}

-- Current log level (change this to control verbosity)
Logger.currentLevel = Logger.LEVELS.DEBUG

-- Flag to completely disable all logging
Logger.enabled = true

-- Log file path
Logger.logFile = "language_arena.log"

-- Initialize the logger
function Logger.new()
    local self = setmetatable({}, Logger)
    
    -- Open log file in append mode
    self.file = io.open(Logger.logFile, "a")
    if not self.file then
        print("Warning: Could not open log file for writing")
    end
    
    -- Log startup message
    self:info("Logger initialized")
    
    return self
end

-- Enable or disable all logging
function Logger:setEnabled(enabled)
    Logger.enabled = enabled
    if enabled then
        self:info("Logging enabled")
    else
        print("Logging disabled")
    end
end

-- Toggle logging on/off
function Logger:toggle()
    self:setEnabled(not Logger.enabled)
    return Logger.enabled
end

-- Log a debug message
function Logger:debug(message, ...)
    if Logger.enabled and Logger.currentLevel <= Logger.LEVELS.DEBUG then
        self:log("DEBUG", message, ...)
    end
end

-- Log an info message
function Logger:info(message, ...)
    if Logger.enabled and Logger.currentLevel <= Logger.LEVELS.INFO then
        self:log("INFO", message, ...)
    end
end

-- Log a warning message
function Logger:warning(message, ...)
    if Logger.enabled and Logger.currentLevel <= Logger.LEVELS.WARNING then
        self:log("WARNING", message, ...)
    end
end

-- Log an error message
function Logger:error(message, ...)
    if Logger.enabled and Logger.currentLevel <= Logger.LEVELS.ERROR then
        self:log("ERROR", message, ...)
    end
end

-- Internal logging function
function Logger:log(level, message, ...)
    -- Format the message with any additional arguments
    local formattedMessage = string.format(message, ...)
    
    -- Get current timestamp
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    
    -- Create log entry
    local logEntry = string.format("[%s] [%s] %s\n", timestamp, level, formattedMessage)
    
    -- Write to console
    print(logEntry)
    
    -- Write to file if available
    if self.file then
        self.file:write(logEntry)
        self.file:flush()  -- Ensure it's written immediately
    end
end

-- Log controller information
function Logger:logController(controller, player)
    self:debug("Controller: %s, Player: %s", 
        controller and controller:getName() or "None",
        player and player.name or "None")
    
    if controller then
        self:debug("  Buttons: %s", table.concat(controller:getButtons(), ", "))
        self:debug("  Axes: %s", table.concat(controller:getAxes(), ", "))
    end
end

-- Log game state
function Logger:logGameState(game)
    self:debug("Game State: %s", game.gameState)
    self:debug("Current Character: %s (%s)", 
        game.currentCharacter and game.currentCharacter.name or "None",
        game.currentCharacter and game.currentCharacter.meaning or "None")
    self:debug("Game Timer: %.2f / %.2f", game.gameTimer, game.gameDuration)
    self:debug("Character Timer: %.2f / %.2f", game.characterTimer, game.characterChangeTime)
    self:debug("Boxes: %d", #game.boxes)
    self:debug("Players: %d", #game.controllers)
end

-- Log player state
function Logger:logPlayerState(player)
    self:debug("Player: %s", player.name)
    self:debug("  Position: (%.2f, %.2f)", player.x, player.y)
    self:debug("  Velocity: (%.2f, %.2f)", player.velocity.x, player.velocity.y)
    self:debug("  Score: %d", player.score)
    self:debug("  Animation: %s", player.currentAnimation)
    self:debug("  Collected Characters: %d", #player.collectedCharacters)
end

-- Log collision information
function Logger:logCollision(obj1, obj2, result)
    self:debug("Collision Check: %s with %s = %s", 
        obj1.name or "Object1", 
        obj2.name or "Object2", 
        result and "true" or "false")
    
    if result then
        self:debug("  Object1: (%.2f, %.2f, %.2f, %.2f)", 
            obj1.x, obj1.y, obj1.width or 0, obj1.height or 0)
        self:debug("  Object2: (%.2f, %.2f, %.2f, %.2f)", 
            obj2.x, obj2.y, obj2.width or 0, obj2.height or 0)
    end
end

-- Close the log file
function Logger:close()
    if self.file then
        self:info("Logger closing")
        self.file:close()
        self.file = nil
    end
end

-- Create a singleton instance
local logger = Logger.new()

-- Return the singleton instance
return logger 