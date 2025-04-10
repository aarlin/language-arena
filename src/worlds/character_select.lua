local logger = require("logger")
local Constants = require("constants")
local config = require("config")

-- Character selection screen
local CharacterSelect = {}
CharacterSelect.__index = CharacterSelect

-- Available characters
local CHARACTERS = {
    {id = "raccoon", name = "Raccoon", image = nil},
    {id = "sheep", name = "Sheep", image = nil},
    {id = "pig", name = "Pig", image = nil},
    {id = "cow", name = "Cow", image = nil},
    {id = "chicken", name = "Chicken", image = nil},
}

function CharacterSelect.new()
    local self = setmetatable({}, CharacterSelect)
    
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
    
    -- Player selection state
    self.players = {}
    self.selectedCharacters = {}
    self.currentPlayerIndex = 1
    self.selectionComplete = false
    
    -- UI properties
    self.characterBoxWidth = 150
    self.characterBoxHeight = 200
    self.characterSpacing = 20
    self.startY = 200
    
    -- Calculate total width of character selection area
    self.totalWidth = (#CHARACTERS * self.characterBoxWidth) + ((#CHARACTERS - 1) * self.characterSpacing)
    self.startX = (Constants.SCREEN_WIDTH - self.totalWidth) / 2
    
    logger:info("Character selection screen initialized")
    
    return self
end

function CharacterSelect:addPlayer(player)
    table.insert(self.players, player)
    self.selectedCharacters[player] = nil
    -- Initialize button press tracking
    player.buttonStates = {
        a = false,
        b = false
    }
    logger:info("Added player to character selection: %s", player.name)
end

function CharacterSelect:update(dt)
    -- Handle player input for character selection
    for i, player in ipairs(self.players) do
        if player.controller then
            -- Only allow D-pad navigation if player hasn't locked in a character yet
            if not player.characterLocked then
                -- Handle D-pad navigation with reduced sensitivity
                if player.controller:isGamepadDown("dpleft") and not player.dpadPressed then
                    -- Move selection left
                    local currentChar = self.selectedCharacters[player]
                    if currentChar then
                        local currentIndex = 1
                        for j, char in ipairs(CHARACTERS) do
                            if char.id == currentChar then
                                currentIndex = j
                                break
                            end
                        end
                        
                        -- Find next available character to the left
                        local newIndex = currentIndex
                        for j = currentIndex - 1, 1, -1 do
                            local isAvailable = true
                            for _, selectedChar in pairs(self.selectedCharacters) do
                                if selectedChar == CHARACTERS[j].id then
                                    isAvailable = false
                                    break
                                end
                            end
                            
                            if isAvailable then
                                newIndex = j
                                break
                            end
                        end
                        
                        if newIndex ~= currentIndex then
                            self.selectedCharacters[player] = CHARACTERS[newIndex].id
                            logger:debug("Player %s selected character: %s", player.name, CHARACTERS[newIndex].id)
                        end
                    else
                        -- Select first available character
                        for _, char in ipairs(CHARACTERS) do
                            local isAvailable = true
                            for _, selectedChar in pairs(self.selectedCharacters) do
                                if selectedChar == char.id then
                                    isAvailable = false
                                    break
                                end
                            end
                            
                            if isAvailable then
                                self.selectedCharacters[player] = char.id
                                logger:debug("Player %s selected character: %s", player.name, char.id)
                                break
                            end
                        end
                    end
                    player.dpadPressed = true
                elseif player.controller:isGamepadDown("dpright") and not player.dpadPressed then
                    -- Move selection right
                    local currentChar = self.selectedCharacters[player]
                    if currentChar then
                        local currentIndex = 1
                        for j, char in ipairs(CHARACTERS) do
                            if char.id == currentChar then
                                currentIndex = j
                                break
                            end
                        end
                        
                        -- Find next available character to the right
                        local newIndex = currentIndex
                        for j = currentIndex + 1, #CHARACTERS do
                            local isAvailable = true
                            for _, selectedChar in pairs(self.selectedCharacters) do
                                if selectedChar == CHARACTERS[j].id then
                                    isAvailable = false
                                    break
                                end
                            end
                            
                            if isAvailable then
                                newIndex = j
                                break
                            end
                        end
                        
                        if newIndex ~= currentIndex then
                            self.selectedCharacters[player] = CHARACTERS[newIndex].id
                            logger:debug("Player %s selected character: %s", player.name, CHARACTERS[newIndex].id)
                        end
                    else
                        -- Select first available character
                        for _, char in ipairs(CHARACTERS) do
                            local isAvailable = true
                            for _, selectedChar in pairs(self.selectedCharacters) do
                                if selectedChar == char.id then
                                    isAvailable = false
                                    break
                                end
                            end
                            
                            if isAvailable then
                                self.selectedCharacters[player] = char.id
                                logger:debug("Player %s selected character: %s", player.name, char.id)
                                break
                            end
                        end
                    end
                    player.dpadPressed = true
                end
                
                -- Reset D-pad pressed state when button is released
                if not player.controller:isGamepadDown("dpleft") and not player.controller:isGamepadDown("dpright") then
                    player.dpadPressed = false
                end
            end
            
            -- Handle selection with A button (lock in character)
            local aPressed = player.controller:isGamepadDown("a")
            if aPressed and not player.buttonStates.a then
                -- Button was just pressed
                player.buttonStates.a = true
                
                -- If player already has a character, lock it in
                if self.selectedCharacters[player] and not player.characterLocked then
                    player.characterLocked = true
                    logger:debug("Player %s locked in character: %s", player.name, self.selectedCharacters[player])
                end
            elseif not aPressed then
                -- Button was released
                player.buttonStates.a = false
            end
            
            -- Handle deselection with B button (unlock character)
            local bPressed = player.controller:isGamepadDown("b")
            if bPressed and not player.buttonStates.b then
                -- Button was just pressed
                player.buttonStates.b = true
                
                -- If player has a locked character, unlock it
                if player.characterLocked then
                    player.characterLocked = false
                    logger:debug("Player %s unlocked character: %s", player.name, self.selectedCharacters[player])
                end
            elseif not bPressed then
                -- Button was released
                player.buttonStates.b = false
            end
            
            -- Handle start button to begin game
            if player.controller:isGamepadDown("start") then
                -- Check if all players have selected and locked characters
                local allSelected = true
                for _, p in ipairs(self.players) do
                    if not self.selectedCharacters[p] or not p.characterLocked then
                        allSelected = false
                        break
                    end
                end
                
                if allSelected then
                    self.selectionComplete = true
                    logger:info("Character selection complete, all players have chosen characters")
                else
                    logger:warning("Cannot start game, not all players have selected and locked characters")
                end
            end
        end
    end
end

function CharacterSelect:draw()
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
        for player, selectedChar in pairs(self.selectedCharacters) do
            if selectedChar == char.id then
                isSelected = true
                selectedBy = player
                isLocked = player.characterLocked
                break
            end
        end
        
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
            love.graphics.printf(selectedBy.name, x, y + self.characterBoxHeight - 20, self.characterBoxWidth, "center")
        end
    end
    
    -- Draw instructions
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Use D-pad to select character", 0, self.startY + self.characterBoxHeight + 40, Constants.SCREEN_WIDTH, "center")
    love.graphics.printf("Press A to lock in selection", 0, self.startY + self.characterBoxHeight + 70, Constants.SCREEN_WIDTH, "center")
    love.graphics.printf("Press B to unlock selection", 0, self.startY + self.characterBoxHeight + 100, Constants.SCREEN_WIDTH, "center")
    love.graphics.printf("Press START when all players have locked in", 0, self.startY + self.characterBoxHeight + 130, Constants.SCREEN_WIDTH, "center")
    
    -- Draw warning if not all players have selected characters
    local allSelected = true
    for _, player in ipairs(self.players) do
        if not self.selectedCharacters[player] or not player.characterLocked then
            allSelected = false
            break
        end
    end
    
    if not allSelected and #self.players > 0 then
        love.graphics.setColor(1, 0, 0, 1)  -- Red for warning
        love.graphics.printf("All players must select and lock in a character", 0, Constants.SCREEN_HEIGHT - 50, Constants.SCREEN_WIDTH, "center")
    end
end

function CharacterSelect:isComplete()
    return self.selectionComplete
end

function CharacterSelect:getSelectedCharacters()
    return self.selectedCharacters
end

return CharacterSelect 