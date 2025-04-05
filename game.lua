local Player = require("player")
local characters = require("characters")
local logger = require("logger")  -- Import the logger
local config = require("config")  -- Import the config module

-- Import ANIMATION_STATES from player.lua
local ANIMATION_STATES = {
    IDLE = "idle",
    WALK = "walk",
    RUN = "run",
    JUMP = "jump",
    CROUCH = "crouch",
    SLIDE = "slide",
    KO = "ko",
    VICTORY = "victory"
}

-- Game state
local Game = {}
Game.__index = Game

function Game.new()
    local self = setmetatable({}, Game)
    self.controllers = {}
    self.boxes = {}
    self.currentCharacter = characters[1]
    self.characterTimer = 0
    self.characterChangeTime = love.math.random(15, 25)  -- Random time between 15-25 seconds
    self.spawnTimer = 0
    self.spawnInterval = 2  -- Increased from 1 to 2 seconds to reduce object creation
    self.background = love.graphics.newImage("assets/background/forest.jpg")
    
    -- Check if running on Nintendo Switch
    self.isSwitch = love._console == "Switch"
    
    -- Use system fonts for all platforms
    logger:info("Using system fonts")
    -- Use system fonts with appropriate sizes
    if self.isSwitch then
        -- On Switch, use the "standard" font
        self.font = love.graphics.newFont("standard", 24)
        self.smallFont = love.graphics.newFont("standard", 16)
        self.titleFont = love.graphics.newFont("standard", 48)
        self.subtitleFont = love.graphics.newFont("standard", 24)
        self.instructionFont = love.graphics.newFont("standard", 18)
        self.cjkFont = love.graphics.newFont("standard", 24)
    else
        -- On PC, use SourceHanSansSC font
        self.font = love.graphics.newFont("assets/fonts/SourceHanSansSC-Regular.otf", 24)
        self.smallFont = love.graphics.newFont("assets/fonts/SourceHanSansSC-Regular.otf", 16)
        self.titleFont = love.graphics.newFont("assets/fonts/SourceHanSansSC-Regular.otf", 48)
        self.subtitleFont = love.graphics.newFont("assets/fonts/SourceHanSansSC-Regular.otf", 24)
        self.instructionFont = love.graphics.newFont("assets/fonts/SourceHanSansSC-Regular.otf", 18)
        self.cjkFont = love.graphics.newFont("assets/fonts/SourceHanSansSC-Regular.otf", 24)
    end
    
    -- Helper function to safely set font
    self.safeSetFont = function(font)
        if font and type(font) == "userdata" then
            love.graphics.setFont(font)
        end
    end
    
    self.gameState = "title"  -- title, game, gameover
    self.winner = nil
    self.gameTimer = 0
    self.gameDuration = 120  -- 2 minutes game time
    self.botCount = 0  -- Default to no bots
    self.selectedBotCount = 0  -- Currently selected bot count in menu
    
    -- Character selection
    self.characterEnabled = {}
    for i, char in ipairs(characters) do
        self.characterEnabled[i] = true  -- All characters enabled by default
    end
    self.selectedCharacterIndex = 1  -- Currently selected character in the grid
    self.characterSelectionCooldown = 0  -- Cooldown timer for character selection
    
    -- Preload character images to avoid loading during gameplay
    self.characterImages = {}
    for _, char in ipairs(characters) do
        local imagePath = "assets/characters/" .. string.lower(char.meaning) .. ".png"
        local success, image = pcall(function()
            return love.graphics.newImage(imagePath)
        end)
        
        if success then
            self.characterImages[char.meaning] = image
        else
            logger:warning("Failed to preload character image: %s", imagePath)
        end
    end
    
    -- Setup controllers
    self:setupControllers()
    
    logger:info("Game initialized")
    return self
end

function Game:setupControllers()
    -- Clear existing controllers
    self.controllers = {}
    
    -- Get all connected joysticks
    local joysticks = love.joystick.getJoysticks()
    
    logger:info("Found %d joysticks", #joysticks)
    
    -- Setup up to 4 controllers
    for i = 1, math.min(4, #joysticks) do
        local joystick = joysticks[i]
        if joystick:isGamepad() then
            local player = Player.new(100 + (i-1) * 200, 600 - 500,  -- Position higher on the screen (changed from 570 to 500)
                {love.math.random(), love.math.random(), love.math.random()},
                {
                    controller = i,
                    left = "leftx",  -- Use left stick for movement
                    right = "leftx", -- Use left stick for movement
                    jump = "a",      -- A button on Switch
                    down = "b",      -- B button on Switch (now used for running)
                    kick = "x",     -- X button on Switch
                    slide = "leftshoulder",  -- Left shoulder button (LB) for sliding
                    start = "start", -- Plus button on Switch
                    back = "back"    -- Minus button on Switch
                }
            )
            player:setController(joystick)
            table.insert(self.controllers, {
                joystick = joystick,
                player = player,
                isBot = false
            })
            logger:info("Controller %d setup: %s", i, joystick:getName())
        end
    end
    
    -- Add bots if in game state and bot count is set
    if self.gameState == "game" and self.botCount > 0 then
        -- Calculate how many bots to add based on player count
        local playerCount = #self.controllers
        local maxBots = 4 - playerCount  -- Maximum bots allowed (4 total players)
        local botsToAdd = math.min(self.botCount, maxBots)
        
        logger:info("Adding %d bots (max allowed: %d)", botsToAdd, maxBots)
        
        -- Add bots
        for i = 1, botsToAdd do
            local botIndex = #self.controllers + 1
            local player = Player.new(100 + (botIndex-1) * 200, 600 - 500,
                {love.math.random(), love.math.random(), love.math.random()},
                {
                    controller = botIndex,
                    left = "leftx",
                    right = "leftx",
                    jump = "a",
                    down = "b",
                    kick = "x",
                    slide = "leftshoulder",
                    start = "start",
                    back = "back"
                }
            )
            player.name = "Bot " .. i
            table.insert(self.controllers, {
                joystick = nil,  -- Bots don't have controllers
                player = player,
                isBot = true
            })
            logger:info("Bot %d added", i)
        end
    end
end

function Game:update(dt)
    if self.gameState == "title" then
        -- Update character selection cooldown
        if self.characterSelectionCooldown > 0 then
            self.characterSelectionCooldown = self.characterSelectionCooldown - dt
        end
        
        -- Check for start button press
        for _, controller in ipairs(self.controllers) do
            -- Only process input for non-bot controllers
            if not controller.isBot then
                if controller.joystick:isGamepadDown(controller.player.controls.start) then
                    self.gameState = "game"
                    self.gameTimer = 0
                    self.botCount = self.selectedBotCount  -- Set the actual bot count when starting the game
                    
                    -- Setup controllers again to add bots
                    self:setupControllers()
                    
                    logger:info("Game started with %d bots", self.botCount)
                    break
                end
            end
        end
        
        -- Check for bot count selection
        for _, controller in ipairs(self.controllers) do
            -- Only process input for non-bot controllers
            if not controller.isBot then
                -- Use A button to increase bot count
                if controller.joystick:isGamepadDown("a") then
                    self.selectedBotCount = math.min(3, self.selectedBotCount + 1)
                    logger:info("Bot count increased to %d", self.selectedBotCount)
                    break
                end
                -- Use B button to decrease bot count
                if controller.joystick:isGamepadDown("b") then
                    self.selectedBotCount = math.max(0, self.selectedBotCount - 1)
                    logger:info("Bot count decreased to %d", self.selectedBotCount)
                    break
                end
                
                -- Character selection with D-pad (only if cooldown is 0)
                if self.characterSelectionCooldown <= 0 then
                    if controller.joystick:isGamepadDown("dpup") then
                        self.selectedCharacterIndex = self.selectedCharacterIndex - 8
                        if self.selectedCharacterIndex < 1 then
                            self.selectedCharacterIndex = #characters
                        end
                        self.characterSelectionCooldown = 0.2  -- Set cooldown to 0.2 seconds
                        logger:debug("Selected character: %d", self.selectedCharacterIndex)
                        break
                    end
                    if controller.joystick:isGamepadDown("dpdown") then
                        self.selectedCharacterIndex = self.selectedCharacterIndex + 8
                        if self.selectedCharacterIndex > #characters then
                            self.selectedCharacterIndex = 1
                        end
                        self.characterSelectionCooldown = 0.2  -- Set cooldown to 0.2 seconds
                        logger:debug("Selected character: %d", self.selectedCharacterIndex)
                        break
                    end
                    if controller.joystick:isGamepadDown("dpleft") then
                        self.selectedCharacterIndex = self.selectedCharacterIndex - 1
                        if self.selectedCharacterIndex < 1 then
                            self.selectedCharacterIndex = #characters
                        end
                        self.characterSelectionCooldown = 0.2  -- Set cooldown to 0.2 seconds
                        logger:debug("Selected character: %d", self.selectedCharacterIndex)
                        break
                    end
                    if controller.joystick:isGamepadDown("dpright") then
                        self.selectedCharacterIndex = self.selectedCharacterIndex + 1
                        if self.selectedCharacterIndex > #characters then
                            self.selectedCharacterIndex = 1
                        end
                        self.characterSelectionCooldown = 0.2  -- Set cooldown to 0.2 seconds
                        logger:debug("Selected character: %d", self.selectedCharacterIndex)
                        break
                    end
                end
                
                -- Toggle character with X button
                if controller.joystick:isGamepadDown("x") then
                    self.characterEnabled[self.selectedCharacterIndex] = not self.characterEnabled[self.selectedCharacterIndex]
                    logger:info("Character %d (%s) %s", 
                        self.selectedCharacterIndex, 
                        characters[self.selectedCharacterIndex].character,
                        self.characterEnabled[self.selectedCharacterIndex] and "enabled" or "disabled")
                    break
                end
            end
        end
        return
    elseif self.gameState == "gameover" then
        -- Check for back button press to return to title
        for _, controller in ipairs(self.controllers) do
            -- Only process input for non-bot controllers
            if not controller.isBot then
                if controller.joystick:isGamepadDown(controller.player.controls.back) then
                    self.gameState = "title"
                    -- Reset game state
                    self.boxes = {}
                    self:setupControllers()
                    logger:info("Returned to title screen")
                    break
                end
            end
        end
        return
    end
    
    -- Update game timer
    self.gameTimer = self.gameTimer + dt
    if self.gameTimer >= self.gameDuration then
        self:endGame()
        return
    end
    
    -- Update character rotation timer
    self.characterTimer = self.characterTimer + dt
    if self.characterTimer >= self.characterChangeTime then
        -- Change to a random character (different from current)
        local newIndex
        repeat
            newIndex = love.math.random(1, #characters)
        until characters[newIndex].character ~= self.currentCharacter.character
        
        logger:info("Character changed from %s to %s", 
            self.currentCharacter.character, characters[newIndex].character)
        
        self.currentCharacter = characters[newIndex]
        self.characterTimer = 0
        self.characterChangeTime = love.math.random(15, 25)  -- Random time between 15-25 seconds
    end
    
    -- Update spawn timer
    self.spawnTimer = self.spawnTimer + dt
    if self.spawnTimer >= self.spawnInterval then
        self:spawnBox()
        self.spawnTimer = 0
    end
    
    -- Update boxes
    for i = #self.boxes, 1, -1 do
        local box = self.boxes[i]
        box.y = box.y + box.speed * dt
        
        -- Remove if off screen
        if box.y > 800 then
            table.remove(self.boxes, i)
            logger:debug("Box removed (off screen)")
        end
    end
    
    -- Update players
    for _, controller in ipairs(self.controllers) do
        controller.player:update(dt)
    end
    
    -- Check collisions
    self:checkCollisions()
    
    -- Log game state periodically (every 5 seconds)
    if math.floor(self.gameTimer * 2) % 10 == 0 then
        logger:logGameState(self)
    end
end

function Game:gamepadpressed(joystick, button)
    self.lastButtonPressed = button
    
    if self.state == "menu" then
        if button == "a" then
            self.selectedLanguage = "chinese"
            self.state = "playing"
            self:spawnNewCharacter()
        elseif button == "b" then
            self.selectedLanguage = "japanese"
            self.state = "playing"
            self:spawnNewCharacter()
        elseif button == "start" then
            love.event.quit()
        end
    elseif self.state == "playing" then
        -- Find the player with this controller and pass the button press
        for _, controller in ipairs(self.controllers) do
            -- Only process input for non-bot controllers
            if not controller.isBot and controller.joystick == joystick then
                controller.player:gamepadpressed(button)
                break
            end
        end
    end
end

function Game:gamepadreleased(joystick, button)
    -- Handle button releases if needed
    for _, controller in ipairs(self.controllers) do
        -- Only process input for non-bot controllers
        if not controller.isBot and controller.joystick == joystick then
            -- Add any button release handling here
            break
        end
    end
end

function Game:draw()
    -- Draw background
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.background, 0, 0)
    
    -- Draw based on game state
    if self.gameState == "title" then
        self:drawTitle()
    elseif self.gameState == "game" then
        -- Draw boxes
        for _, box in ipairs(self.boxes) do
            if box.useCircle then
                -- Draw circle for character
                love.graphics.setColor(1, 0.8, 0)  -- Yellow color for circles
                love.graphics.circle("fill", box.x + box.width/2, box.y + box.height/2, box.width/2)
                -- Draw character meaning in the circle
                love.graphics.setColor(0, 0, 0)  -- Black text
                self:safeSetFont(self.smallFont)
                local text = box.character
                local textWidth = self.smallFont:getWidth(text)
                love.graphics.print(text, box.x + (box.width - textWidth)/2, box.y + box.height/2 - 8)
            else
                -- Draw character image
                love.graphics.setColor(1, 1, 1)
                love.graphics.draw(box.image, box.x, box.y)
            end
        end
        
        -- Draw players
        for _, controller in ipairs(self.controllers) do
            controller.player:draw()
        end
    elseif self.gameState == "gameover" then
        self:drawGameOver()
    elseif self.gameState == "characterSelection" then
        self:drawCharacterSelection()
    end
    
    -- Draw debug info if enabled
    if config.debug.enabled then
        love.graphics.setColor(1, 1, 1)
        self:safeSetFont(self.font)
        
        if config.debug.showFPS then
            love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
        end
        
        if config.debug.showPlayerInfo then
            love.graphics.print("Players: " .. #self.controllers, 10, 30)
            love.graphics.print("Boxes: " .. #self.boxes, 10, 50)
            love.graphics.print("Game Time: " .. math.floor(self.gameTimer), 10, 70)
        end
        
        -- Draw hitboxes if enabled
        if config.debug.showHitboxes then
            for _, controller in ipairs(self.controllers) do
                local player = controller.player
                
                -- Draw the expanded hitbox
                love.graphics.setColor(1, 0, 0, 0.3)  -- Semi-transparent red
                local expansionX = player.width * 1.5
                local expansionY = player.height * 1.5
                love.graphics.rectangle("fill", 
                    player.x - expansionX, 
                    player.y - expansionY, 
                    player.width + expansionX * 2, 
                    player.height + expansionY * 2)
                
                -- Draw the original player rectangle
                love.graphics.setColor(0, 1, 0, 0.5)  -- Green for the player model
                love.graphics.rectangle("line", player.x, player.y, player.width, player.height)
                
                -- Draw the collection hitbox
                love.graphics.setColor(1, 0, 0, 0.5)  -- Red for the collection hitbox
                love.graphics.rectangle("line", 
                    player.x - expansionX, 
                    player.y - expansionY, 
                    player.width + expansionX * 2, 
                    player.height + expansionY * 2)
                
                -- Draw kick hitbox if player is kicking
                if player.isKicking then
                    love.graphics.setColor(1, 0.5, 0, 0.5)  -- Orange for kick hitbox
                    local kickX
                    if player.velocity.x > 0 then
                        kickX = player.x + player.width + 100
                    else
                        kickX = player.x - 100 - 50
                    end
                    local kickY = player.y + player.height/2 - 50
                    love.graphics.rectangle("fill", kickX, kickY, 50, 100)
                    love.graphics.setColor(1, 0.5, 0, 1)  -- Solid orange for outline
                    love.graphics.rectangle("line", kickX, kickY, 50, 100)
                end
            end
        end
    end
end

function Game:drawTitle()
    -- Draw title
    love.graphics.setColor(1, 1, 1)
    
    -- Set font
    self:safeSetFont(self.titleFont)
    
    local titleText = "Language Arena"
    local titleWidth = 300  -- Fixed width for Switch
    if self.titleFont then
        titleWidth = self.titleFont:getWidth(titleText)
    end
    
    love.graphics.print(titleText, 600 - titleWidth/2, 100)
    
    -- Draw subtitle
    self:safeSetFont(self.subtitleFont)
    local subtitleText = "Catch the matching characters!"
    local subtitleWidth = 300  -- Fixed width for Switch
    if self.subtitleFont then
        subtitleWidth = self.subtitleFont:getWidth(subtitleText)
    end
    love.graphics.print(subtitleText, 600 - subtitleWidth/2, 160)
    
    -- Draw bot count selection
    self:safeSetFont(self.instructionFont)
    local botText = string.format("Bots: %d (Press A to increase, B to decrease)", self.selectedBotCount)
    local botWidth = 300  -- Fixed width for Switch
    if self.instructionFont then
        botWidth = self.instructionFont:getWidth(botText)
    end
    love.graphics.print(botText, 600 - botWidth/2, 220)
    
    -- Draw character selection instructions
    local charSelectText = "Use D-pad to select, X to toggle characters"
    local charSelectWidth = 300  -- Fixed width for Switch
    if self.instructionFont then
        charSelectWidth = self.instructionFont:getWidth(charSelectText)
    end
    love.graphics.print(charSelectText, 600 - charSelectWidth/2, 300)
    
    -- Draw instructions
    local instructionText = "Press START to begin"
    local instructionWidth = 300  -- Fixed width for Switch
    if self.instructionFont then
        instructionWidth = self.instructionFont:getWidth(instructionText)
    end
    love.graphics.print(instructionText, 600 - instructionWidth/2, 340)
    
    -- Draw character selection grid (moved below other text)
    self:drawCharacterGrid()
end

function Game:drawGame()
    -- Draw current character
    love.graphics.setColor(1, 1, 1)
    self:safeSetFont(self.font)
    
    local currentCharText = "Current Character: " .. self.currentCharacter.character
    local currentCharWidth = 300  -- Fixed width for Switch
    if self.font then
        currentCharWidth = self.font:getWidth(currentCharText)
    end
    love.graphics.print(currentCharText, 600 - currentCharWidth/2, 50)
    
    -- Draw game timer
    local timeLeft = math.max(0, self.gameDuration - self.gameTimer)
    local timerText = string.format("Time: %d", math.ceil(timeLeft))
    local timerWidth = 300  -- Fixed width for Switch
    if self.font then
        timerWidth = self.font:getWidth(timerText)
    end
    love.graphics.print(timerText, 600 - timerWidth/2, 100)
    
    -- Draw boxes
    for _, box in ipairs(self.boxes) do
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(box.image, box.x, box.y)
    end
    
    -- Draw players
    for _, controller in ipairs(self.controllers) do
        controller.player:draw()
    end
end

function Game:drawGameOver()
    -- Draw game over text
    love.graphics.setColor(1, 1, 1)
    self:safeSetFont(self.titleFont)
    local gameOverText = "Game Over!"
    local gameOverWidth = 300  -- Fixed width for Switch
    if self.titleFont then
        gameOverWidth = self.titleFont:getWidth(gameOverText)
    end
    love.graphics.print(gameOverText, 600 - gameOverWidth/2, 200)
    
    -- Draw winner
    if self.winner then
        self:safeSetFont(self.subtitleFont)
        local winnerText = string.format("Winner: %s with %d points!", 
            self.winner.name, self.winner.score)
        local winnerWidth = 300  -- Fixed width for Switch
        if self.subtitleFont then
            winnerWidth = self.subtitleFont:getWidth(winnerText)
        end
        love.graphics.print(winnerText, 600 - winnerWidth/2, 280)
    else
        self:safeSetFont(self.subtitleFont)
        local tieText = "It's a tie!"
        local tieWidth = 300  -- Fixed width for Switch
        if self.subtitleFont then
            tieWidth = self.subtitleFont:getWidth(tieText)
        end
        love.graphics.print(tieText, 600 - tieWidth/2, 280)
    end
    
    -- Draw instructions
    self:safeSetFont(self.instructionFont)
    local instructionText = "Press BACK to return to title"
    local instructionWidth = 300  -- Fixed width for Switch
    if self.instructionFont then
        instructionWidth = self.instructionFont:getWidth(instructionText)
    end
    love.graphics.print(instructionText, 600 - instructionWidth/2, 400)
    
    -- Draw final scores
    self:safeSetFont(self.smallFont)
    local scoresTitle = "Final Scores:"
    local scoresTitleWidth = 300  -- Fixed width for Switch
    if self.smallFont then
        scoresTitleWidth = self.smallFont:getWidth(scoresTitle)
    end
    love.graphics.print(scoresTitle, 600 - scoresTitleWidth/2, 450)
    
    local startY = 480
    for i, controller in ipairs(self.controllers) do
        local scoreText = string.format("Player %d: %d points", i, controller.player.score)
        local scoreWidth = 300  -- Fixed width for Switch
        if self.smallFont then
            scoreWidth = self.smallFont:getWidth(scoreText)
        end
        love.graphics.print(scoreText, 600 - scoreWidth/2, startY + (i-1) * 30)
    end
end

function Game:endGame()
    -- Find winner
    local highestScore = 0
    local winner = nil
    
    for _, controller in ipairs(self.controllers) do
        if controller.player.score > highestScore then
            highestScore = controller.player.score
            winner = controller.player
        end
    end
    
    -- Check for ties
    local tie = false
    for _, controller in ipairs(self.controllers) do
        if controller.player.score == highestScore and controller.player ~= winner then
            tie = true
            break
        end
    end
    
    if tie then
        self.winner = nil
        logger:info("Game ended in a tie with score %d", highestScore)
    else
        self.winner = winner
        logger:info("Game ended. Winner: %s with score %d", 
            winner.name, winner.score)
    end
    
    -- Set game state to game over
    self.gameState = "gameover"
end

function Game:spawnBox()
    -- Determine if we should spawn a matching character (50% chance)
    local shouldSpawnMatching = love.math.random() < 0.5
    
    local randomCharacter
    if shouldSpawnMatching then
        -- Spawn a character with the current character's meaning
        randomCharacter = self.currentCharacter
        logger:debug("Spawning matching character with meaning: %s", randomCharacter.meaning)
    else
        -- Spawn a random character (different from current)
        local enabledCharacters = {}
        for i, char in ipairs(characters) do
            if self.characterEnabled[i] then
                table.insert(enabledCharacters, char)
            end
        end
        
        -- If no enabled characters, use all characters
        if #enabledCharacters == 0 then
            enabledCharacters = characters
        end
        
        repeat
            randomCharacter = enabledCharacters[love.math.random(1, #enabledCharacters)]
        until randomCharacter.meaning ~= self.currentCharacter.meaning
        logger:debug("Spawning random character with meaning: %s", randomCharacter.meaning)
    end
    
    -- Create a new box with the character
    local box = {
        x = love.math.random(100, 1100),  -- Random x position
        y = -50,  -- Start above the screen
        width = 48,  -- Match player width
        height = 48,  -- Match player height
        speed = love.math.random(100, 200),  -- Random fall speed
        meaning = randomCharacter.meaning,
        character = randomCharacter.character,
        useCircle = config.rendering.useCirclesForCharacters  -- Store whether to use circle
    }
    
    -- Only load image if not using circles
    if not box.useCircle then
        -- Use preloaded image if available
        if self.characterImages[randomCharacter.meaning] then
            box.image = self.characterImages[randomCharacter.meaning]
        else
            -- Load the character image from assets/characters directory
            local imagePath = "assets/characters/" .. string.lower(randomCharacter.meaning) .. ".png"
            local success, loadedImage = pcall(function()
                return love.graphics.newImage(imagePath)
            end)
            
            if success then
                box.image = loadedImage
                -- Cache the image for future use
                self.characterImages[randomCharacter.meaning] = loadedImage
            else
                logger:warning("Failed to load character image: %s, falling back to circle", imagePath)
                box.useCircle = true  -- Fall back to circle if image loading fails
            end
        end
    end
    
    table.insert(self.boxes, box)
    logger:debug("Box spawned at (%.2f, %.2f) with meaning: %s", box.x, box.y, box.meaning)
end

function Game:checkCharacterCollection(player, character)
    -- Calculate the expanded hitbox (3x larger than the player model)
    local expansionX = player.width * 1.5  -- 150% expansion on each side (3x total width)
    local expansionY = player.height * 1.5  -- 150% expansion on each side (3x total height)
    
    -- Check if character is within or touching the expanded player's rectangle
    local playerLeft = player.x - expansionX
    local playerRight = player.x + player.width + expansionX
    local playerTop = player.y - expansionY
    local playerBottom = player.y + player.height + expansionY
    
    local characterLeft = character.x
    local characterRight = character.x + character.width
    local characterTop = character.y
    local characterBottom = character.y + character.height
    
    -- Check for overlap
    return not (characterRight < playerLeft or 
               characterLeft > playerRight or 
               characterBottom < playerTop or 
               characterTop > playerBottom)
end

function Game:checkCollisions()
    -- Check player-box collisions
    for _, controller in ipairs(self.controllers) do
        local player = controller.player
        local playerLeft = player.x - player.width * 1.5
        local playerRight = player.x + player.width * 2.5
        local playerTop = player.y - player.height * 1.5
        local playerBottom = player.y + player.height * 2.5
        
        for i = #self.boxes, 1, -1 do
            local box = self.boxes[i]
            
            -- Quick AABB collision check
            if not (box.x + box.width < playerLeft or 
                   box.x > playerRight or 
                   box.y + box.height < playerTop or 
                   box.y > playerBottom) then
                
                -- Collect the character
                controller.player:collectApple(box)
                
                -- Check if the meaning matches the current character
                if box.meaning == self.currentCharacter.meaning then
                    -- Correct match! Add points
                    controller.player.score = controller.player.score + 10
                    -- Show a victory animation
                    controller.player:setAnimation(ANIMATION_STATES.VICTORY)
                    logger:info("Player %s collected correct character: %s", 
                        controller.player.name, box.meaning)
                else
                    -- Wrong match! Subtract points or remove an character
                    if #controller.player.collectedApples > 1 then
                        -- Remove the oldest character from the stack
                        table.remove(controller.player.collectedApples, 1)
                        logger:info("Player %s collected wrong character: %s, removed oldest character", 
                            controller.player.name, box.meaning)
                    else
                        -- If no characters in stack, subtract points
                        controller.player.score = math.max(0, controller.player.score - 5)
                        logger:info("Player %s collected wrong character: %s, lost 5 points", 
                            controller.player.name, box.meaning)
                    end
                end
                
                table.remove(self.boxes, i)
                break
            end
        end
    end
    
    -- Check player-player collisions for kicking
    for i, controller1 in ipairs(self.controllers) do
        local player1 = controller1.player
        if player1.isKicking then
            -- Calculate kick hitbox position based on player1's direction
            local kickX
            if player1.velocity.x > 0 then
                kickX = player1.x + player1.width + 100
            else
                kickX = player1.x - 100 - 50
            end
            local kickY = player1.y + player1.height/2 - 50
            
            -- Define kick hitbox boundaries
            local kickLeft = kickX
            local kickRight = kickX + 50
            local kickTop = kickY
            local kickBottom = kickY + 100
            
            -- Check collision with all other players
            for j, controller2 in ipairs(self.controllers) do
                if i ~= j then  -- Don't check collision with self
                    local player2 = controller2.player
                    -- Only check if player2 is not already knocked back and not invulnerable
                    if not player2.isKnockback and player2.invulnerableTimer <= 0 then
                        -- Check if player2 overlaps with kick hitbox
                        local player2Left = player2.x
                        local player2Right = player2.x + player2.width
                        local player2Top = player2.y
                        local player2Bottom = player2.y + player2.height
                        
                        if not (kickRight < player2Left or 
                               kickLeft > player2Right or 
                               kickBottom < player2Top or 
                               kickTop > player2Bottom) then
                            -- Kick hit! Apply knockback
                            local knockbackVel = {
                                x = player1.facingRight and 500 or -500,  -- Push in kicker's facing direction
                                y = -10  -- Minimal upward knockback
                            }
                            player2:takeKnockback(knockbackVel)
                            logger:info("Player %s kicked Player %s", player1.name, player2.name)
                        end
                    end
                end
            end
        end
    end
end

function Game:checkCollision(a, b)
    -- Check if either object is a player and the other is a character
    local isPlayerCharacterCollision = (a.width == 415 and a.height == 532) or (b.width == 415 and b.height == 532)
    
    if isPlayerCharacterCollision then
        -- For player-character collisions, use rectangle collision with expanded hitbox
        local player = (a.width == 415 and a.height == 532) and a or b
        local character = (a.width == 415 and a.height == 532) and b or a
        
        -- Calculate the expanded hitbox (3x larger than the player model)
        local expansionX = player.width * 1.5  -- 150% expansion on each side (3x total width)
        local expansionY = player.height * 1.5  -- 150% expansion on each side (3x total height)
        
        -- Check if character is within or touching the expanded player's rectangle
        local playerLeft = player.x - expansionX
        local playerRight = player.x + player.width + expansionX
        local playerTop = player.y - expansionY
        local playerBottom = player.y + player.height + expansionY
        
        local characterLeft = character.x
        local characterRight = character.x + character.width
        local characterTop = character.y
        local characterBottom = character.y + character.height
        
        -- Check for overlap
        return not (characterRight < playerLeft or 
                   characterLeft > playerRight or 
                   characterBottom < playerTop or 
                   characterTop > playerBottom)
    else
        -- For other collisions (player-player), use the existing circle-based collision
        local aRadius = a.width and a.width/3 or 10
        local bRadius = b.width and b.width/3 or 10
        
        -- Calculate center points
        local aCenterX = a.x + (a.width or 415)/2
        local aCenterY = a.y + (a.height or 532)/2
        local bCenterX = b.x + (b.width or 20)/2
        local bCenterY = b.y + (b.height or 20)/2
        
        -- Calculate distance between centers
        local dx = aCenterX - bCenterX
        local dy = aCenterY - bCenterY
        local distance = math.sqrt(dx*dx + dy*dy)
        
        -- Check if distance is less than sum of radii
        return distance < (aRadius + bRadius)
    end
end

function Game:drawCharacterGrid()
    -- Grid settings for 1920x1080 resolution
    local gridX = 600  -- Center of the grid
    local gridY = 600  -- Moved down to be below other text
    local cellSize = 60  -- Size of each cell
    local cellsPerRow = 8  -- 8x8 grid
    local startX = gridX - (cellSize * cellsPerRow) / 2
    local startY = gridY - (cellSize * cellsPerRow) / 2
    
    -- Draw grid title
    love.graphics.setColor(1, 1, 1)
    self:safeSetFont(self.font)
    local gridTitle = "Character Selection"
    local gridTitleWidth = 300  -- Fixed width for Switch
    if self.font then
        gridTitleWidth = self.font:getWidth(gridTitle)
    end
    love.graphics.print(gridTitle, gridX - gridTitleWidth/2, startY - 40)
    
    -- Draw grid cells
    for i, char in ipairs(characters) do
        local row = math.floor((i-1) / cellsPerRow)
        local col = (i-1) % cellsPerRow
        
        local x = startX + col * cellSize
        local y = startY + row * cellSize
        
        -- Draw cell background
        if i == self.selectedCharacterIndex then
            -- Selected cell
            love.graphics.setColor(1, 0.8, 0)  -- Yellow highlight
        else
            -- Normal cell
            love.graphics.setColor(0.2, 0.2, 0.2, 0.8)  -- Dark gray
        end
        love.graphics.rectangle("fill", x, y, cellSize, cellSize)
        
        -- Draw cell border
        love.graphics.setColor(1, 1, 1)  -- White
        love.graphics.rectangle("line", x, y, cellSize, cellSize)
        
        -- Draw character
        love.graphics.setColor(char.color)
        self:safeSetFont(self.cjkFont)
        local charText = char.character
        local charWidth = 30  -- Fixed width for Switch
        local charHeight = 30  -- Fixed height for Switch
        if self.cjkFont then
            charWidth = self.cjkFont:getWidth(charText)
            charHeight = self.cjkFont:getHeight()
        end
        love.graphics.print(charText, x + (cellSize - charWidth)/2, y + (cellSize - charHeight)/2)
        
        -- Draw meaning
        love.graphics.setColor(1, 1, 1)  -- White
        self:safeSetFont(self.smallFont)
        local meaningText = char.meaning
        local meaningWidth = 30  -- Fixed width for Switch
        if self.smallFont then
            meaningWidth = self.smallFont:getWidth(meaningText)
        end
        love.graphics.print(meaningText, x + (cellSize - meaningWidth)/2, y + cellSize - 20)
        
        -- Draw enabled/disabled indicator
        if self.characterEnabled[i] then
            love.graphics.setColor(0, 1, 0)  -- Green for enabled
        else
            love.graphics.setColor(1, 0, 0)  -- Red for disabled
        end
        love.graphics.circle("fill", x + 5, y + 5, 5)
    end
end

return Game 