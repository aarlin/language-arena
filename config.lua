-- Game configuration settings

local config = {
    -- Debug settings
    debug = {
        enabled = true,  -- Master switch for debug mode
        showHitboxes = true,  -- Show collision hitboxes
        showPlayerInfo = true,  -- Show player position, velocity, etc.
        showFPS = true,  -- Show FPS counter
        showCollisionPoints = true,  -- Show points where collisions occur
    },

    -- Rendering settings
    rendering = {
        useCirclesForCharacters = true,  -- Use circles instead of images for characters (helps with Switch performance)
    },

    -- Logging settings
    logging = {
        enabled = true,  -- Master switch for logging
        levels = {
            info = true,    -- Basic information
            debug = true,   -- Detailed debug information
            warning = true, -- Warnings
            error = true    -- Errors
        },
        -- What types of events to log
        events = {
            playerMovement = true,   -- Log player movement
            collisions = true,       -- Log collision events
            characterCollection = true, -- Log character collection
            combat = true,           -- Log combat events
            stateChanges = true,     -- Log game state changes
            animations = true,       -- Log animation changes
            input = true            -- Log input events
        }
    }
}

return config 