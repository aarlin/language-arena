local logger = require("logger")  -- Import the logger
-- Player definitions for the game

local AvailableCharacters = {}

-- Available playable characters
AvailableCharacters.AVAILABLE = {
    {id = "raccoon", name = "Raccoon", image = nil},
    {id = "sheep", name = "Sheep", image = nil},
    {id = "pig", name = "Pig", image = nil},
    {id = "cow", name = "Cow", image = nil},
    {id = "chicken", name = "Chicken", image = nil}
}

-- Function to load player images
function AvailableCharacters.loadImages()
    for i, player in ipairs(AvailableCharacters.AVAILABLE) do
        local success, image = pcall(function()
            return love.graphics.newImage("assets/characters/" .. player.id .. "/" .. player.id .. ".png")
        end)
        
        if success then
            player.image = image
            logger:info("Loaded player image: %s", player.id)
        else
            logger:error("Failed to load player image: %s - %s", player.id, image)
        end
    end
end

-- Function to get a player by ID
function AvailableCharacters.getById(id)
    for _, player in ipairs(AvailableCharacters.AVAILABLE) do
        if player.id == id then
            return player
        end
    end
    return nil
end

return AvailableCharacters 