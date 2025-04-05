-- Logger module for Language Arena
-- Provides logging functionality for debugging

local config = require("config")

local logger = {}

-- Internal function to check if logging is enabled for a specific level and event type
local function shouldLog(level, eventType)
    if not config.logging.enabled then return false end
    if not config.logging.levels[level] then return false end
    if eventType and not config.logging.events[eventType] then return false end
    return true
end

-- Format the current time for log messages
local function getTimeStamp()
    return os.date("%Y-%m-%d %H:%M:%S")
end

-- Base logging function
local function log(level, message, ...)
    if not shouldLog(level) then return end
    local timestamp = getTimeStamp()
    local formattedMessage = string.format(message, ...)
    print(string.format("[%s][%s] %s", timestamp, level:upper(), formattedMessage))
end

-- Public logging functions
function logger:info(message, ...)
    log("info", message, ...)
end

function logger:debug(message, ...)
    log("debug", message, ...)
end

function logger:warning(message, ...)
    log("warning", message, ...)
end

function logger:error(message, ...)
    log("error", message, ...)
end

-- Specialized logging functions for specific event types
function logger:logPlayerState(player)
    if not shouldLog("debug", "playerMovement") then return end
    log("debug", "Player %s state - Pos: (%.2f, %.2f), Vel: (%.2f, %.2f), Animation: %s",
        player.name, player.x, player.y, player.velocity.x, player.velocity.y, player.currentAnimation)
end

function logger:logGameState(game)
    if not shouldLog("debug", "stateChanges") then return end
    log("debug", "Game state - Timer: %.2f, Players: %d, Boxes: %d",
        game.gameTimer, #game.controllers, #game.boxes)
end

function logger:logCollision(player, box, collision)
    if not shouldLog("debug", "collisions") then return end
    log("debug", "Collision check - Player: %s, Box: %s, Collided: %s",
        player.name, box.meaning, tostring(collision))
end

function logger:logCombatEvent(attacker, target, action, result)
    if not shouldLog("info", "combat") then return end
    log("info", "Combat - %s %s %s (Result: %s)",
        attacker.name, action, target.name, result)
end

function logger:logCharacterCollection(player, character)
    if not shouldLog("info", "characterCollection") then return end
    log("info", "Collection - Player %s collected character %s",
        player.name, character.meaning)
end

function logger:logAnimationChange(player, oldAnim, newAnim)
    if not shouldLog("debug", "animations") then return end
    log("debug", "Animation - Player %s changed from %s to %s",
        player.name, oldAnim, newAnim)
end

function logger:logInput(player, input, value)
    if not shouldLog("debug", "input") then return end
    log("debug", "Input - Player %s: %s = %s",
        player.name, input, tostring(value))
end

-- Add close function to handle cleanup
function logger:close()
    -- Currently just a placeholder for future cleanup if needed
    logger:info("Logger closing")
end

return logger 