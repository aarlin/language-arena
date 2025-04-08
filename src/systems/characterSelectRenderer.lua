local Concord = require("lib.concord")
local Constants = require("constants")
local logger = require("lib.logger")

-- Available characters
local CHARACTERS = {
    {id = "raccoon", name = "Raccoon", image = nil},
    {id = "sheep", name = "Sheep", image = nil},
    {id = "pig", name = "Pig", image = nil},
    {id = "cow", name = "Cow", image = nil},
    {id = "chicken", name = "Chicken", image = nil},
}

local CharacterSelectRenderer = Concord.system({
    pool = {"player"}
})

function CharacterSelectRenderer:init()
    -- Load character images
    for i, char in ipairs(CHARACTERS) do
        local success, image = pcall(function()
            return love.graphics.newImage("assets/characters/" .. char.id .. "/" .. char.id .. ".png")
        end)
        
        if success then
            char.image = image
            logger:info("Loaded character image: %s", char.id)
        else
            logger:error("Failed to load character image: %s - %s", char.id, image)
        end
    end
    
    -- UI properties
    self.characterBoxWidth = 150
    self.characterBoxHeight = 200
    self.characterSpacing = 20
    self.startY = 200
    
    -- Calculate total width of character selection area
    self.totalWidth = (#CHARACTERS * self.characterBoxWidth) + ((#CHARACTERS - 1) * self.characterSpacing)
    self.startX = (Constants.SCREEN_WIDTH - self.totalWidth) / 2
end

function CharacterSelectRenderer:update(dt)

end

function CharacterSelectRenderer:draw()
    -- Draw title
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Select Your Character", 0, 100, Constants.SCREEN_WIDTH, "center")
    
    -- Draw character boxes
    for i, char in ipairs(CHARACTERS) do
        local x = self.startX + (i-1) * (self.characterBoxWidth + self.characterSpacing)
        local y = self.startY
        
        -- Check if character is already selected
        local isSelected = false
        local selectedBy = nil
        local isLocked = false
        
        -- Draw character box
        if isSelected then
            if isLocked then
                love.graphics.setColor(0.3, 0.3, 0.3, 1)  -- Dark grey for locked characters
            else
                love.graphics.setColor(0.5, 0.5, 0.5, 1)  -- Grey for selected characters
            end
        else
            love.graphics.setColor(1, 1, 1, 1)  -- White for available characters
        end
        love.graphics.rectangle("line", x, y, self.characterBoxWidth, self.characterBoxHeight)
        
        -- Draw character image if available
        if char.image then
            love.graphics.setColor(1, 1, 1, isSelected and 0.5 or 1)
            
            -- Calculate scaling to fit within the box
            local imgWidth = char.image:getWidth()
            local imgHeight = char.image:getHeight()
            local maxWidth = self.characterBoxWidth - 20  -- Leave 10px padding on each side
            local maxHeight = self.characterBoxHeight - 60  -- Leave space for name and player
            
            -- Calculate scale to fit within the box while maintaining aspect ratio
            local scaleX = maxWidth / imgWidth
            local scaleY = maxHeight / imgHeight
            local scale = math.min(scaleX, scaleY)
            
            -- Calculate position to center the image
            local scaledWidth = imgWidth * scale
            local scaledHeight = imgHeight * scale
            local imgX = x + (self.characterBoxWidth - scaledWidth) / 2
            local imgY = y + 20  -- Position at top of box with some padding
            
            -- Draw the image with calculated scale
            love.graphics.draw(char.image, imgX, imgY, 0, scale, scale)
        end
        
        -- Draw character name
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(char.name, x, y + self.characterBoxHeight - 40, self.characterBoxWidth, "center")
        
        -- Draw player name if selected
        if isSelected and selectedBy then
            if isLocked then
                love.graphics.setColor(0, 1, 0, 1)  -- Green for locked in player
            else
                love.graphics.setColor(1, 1, 0, 1)  -- Yellow for selected player
            end
            love.graphics.printf(selectedBy.player.name, x, y + self.characterBoxHeight - 20, self.characterBoxWidth, "center")
        end
    end
    
    -- Draw instructions
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Use D-pad to select character", 0, self.startY + self.characterBoxHeight + 40, Constants.SCREEN_WIDTH, "center")
    love.graphics.printf("Press A to lock in selection", 0, self.startY + self.characterBoxHeight + 70, Constants.SCREEN_WIDTH, "center")
    love.graphics.printf("Press B to unlock selection", 0, self.startY + self.characterBoxHeight + 100, Constants.SCREEN_WIDTH, "center")
    love.graphics.printf("Press START when all players have locked in", 0, self.startY + self.characterBoxHeight + 130, Constants.SCREEN_WIDTH, "center")
    

end

return CharacterSelectRenderer
