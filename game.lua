local Player = require("player")
local characters = require("characters")
local logger = require("logger")  -- Import the logger
local config = require("config")  -- Import the config module
local Constants = require("constants")  -- Import the constants module

-- Import ANIMATION_STATES from player.lua
local ANIMATION_STATES = {
    IDLE = "idle",
    WALK = "walk",
    RUN = "run",
    JUMP = "jump",
    CROUCH = "crouch",
    KICK = "kick",
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
    self.characterChangeTime = love.math.random(Constants.CHARACTER_CHANGE_MIN_TIME, Constants.CHARACTER_CHANGE_MAX_TIME)
    self.spawnTimer = 0
    self.spawnInterval = Constants.SPAWN_INTERVAL
    self.titleBackground = love.graphics.newImage("assets/background/mainmenu.jpg")
    self.gameBackground = love.graphics.newImage("assets/background/forest.jpg")
    
    -- Check if running on Nintendo Switch
    self.isSwitch = love._console == "Switch"
    
    -- Load background music with platform-specific format
    if self.isSwitch then
        -- On Switch, use OGG format for better performance
        local success, titleMusic = pcall(function()
            return love.audio.newSource("assets/bgm/missing_you.mp3", "static")
        end)
        
        local success2, gameMusic = pcall(function()
            return love.audio.newSource("assets/bgm/suika.mp3", "static")
        end)
        
        if success and success2 then
            self.titleMusic = titleMusic
            self.gameMusic = gameMusic
            self.titleMusic:setLooping(true)
            self.gameMusic:setLooping(true)
            self.currentMusic = nil
            logger:info("Music loaded successfully (OGG format on Switch)")
        else
            self.titleMusic = nil
            self.gameMusic = nil
            self.currentMusic = nil
            logger:warning("Failed to load OGG music files on Switch")
        end
    else
        -- On PC, use MP3 format
        local success, titleMusic = pcall(function()
            return love.audio.newSource("assets/bgm/missing_you.mp3", "static")
        end)
        
        local success2, gameMusic = pcall(function()
            return love.audio.newSource("assets/bgm/suika.mp3", "static")
        end)
        
        if success and success2 then
            self.titleMusic = titleMusic
            self.gameMusic = gameMusic
            self.titleMusic:setLooping(true)
            self.gameMusic:setLooping(true)
            self.currentMusic = nil
            logger:info("Music loaded successfully (MP3 format on PC)")
        else
            self.titleMusic = nil
            self.gameMusic = nil
            self.currentMusic = nil
            logger:warning("Failed to load MP3 music files on PC")
        end
    end
    
    -- Use system fonts for all platforms
    logger:info("Using system fonts")
    -- Use system fonts with appropriate sizes
    if self.isSwitch then
        -- On Switch, use the "standard" font
        self.font = love.graphics.newFont("standard", Constants.FONT_SIZE)
        self.smallFont = love.graphics.newFont("standard", Constants.SMALL_FONT_SIZE)
        self.titleFont = love.graphics.newFont("standard", Constants.TITLE_FONT_SIZE)
        self.subtitleFont = love.graphics.newFont("standard", Constants.SUBTITLE_FONT_SIZE)
        self.instructionFont = love.graphics.newFont("standard", Constants.INSTRUCTION_FONT_SIZE)
        self.cjkFont = love.graphics.newFont("standard", Constants.CJK_FONT_SIZE)
    else
        -- On PC, use SourceHanSansSC font
        self.font = love.graphics.newFont("assets/fonts/SourceHanSansSC-Regular.otf", Constants.FONT_SIZE)
        self.smallFont = love.graphics.newFont("assets/fonts/SourceHanSansSC-Regular.otf", Constants.SMALL_FONT_SIZE)
        self.titleFont = love.graphics.newFont("assets/fonts/SourceHanSansSC-Regular.otf", Constants.TITLE_FONT_SIZE)
        self.subtitleFont = love.graphics.newFont("assets/fonts/SourceHanSansSC-Regular.otf", Constants.SUBTITLE_FONT_SIZE)
        self.instructionFont = love.graphics.newFont("assets/fonts/SourceHanSansSC-Regular.otf", Constants.INSTRUCTION_FONT_SIZE)
        self.cjkFont = love.graphics.newFont("assets/fonts/SourceHanSansSC-Regular.otf", Constants.CJK_FONT_SIZE)
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
    self.gameDuration = Constants.GAME_DURATION
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
        -- Try to load SVG file first
        local imagePath = "assets/falling-objects/" .. string.lower(char.meaning) .. "/" .. string.lower(char.meaning) .. ".svg"
        local success, image = pcall(function()
            return love.graphics.newImage(imagePath)
        end)
        
        if success then
            self.characterImages[char.meaning] = image
            logger:info("Preloaded character SVG image: %s", char.meaning)
        else
            -- If SVG fails, try PNG as fallback
            local imagePath2 = "assets/falling-objects/" .. string.lower(char.meaning) .. "/" .. string.lower(char.meaning) .. ".png"
            local success2, image2 = pcall(function()
                return love.graphics.newImage(imagePath2)
            end)
            
            if success2 then
                self.characterImages[char.meaning] = image2
                logger:info("Preloaded character PNG image: %s", char.meaning)
            else
                logger:warning("Failed to preload character image: %s, falling back to circle", char.meaning)
            end
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
            -- Check if we're on Nintendo Switch
            local isSwitch = love._console == "Switch"
            
            -- Determine which stick to use based on platform
            local movementStick = isSwitch and "leftx" or "rightx"
            
            local player = Player.new(100 + (i-1) * 200, Constants.GROUND_Y - 500,  -- Position higher on the screen
                {love.math.random(), love.math.random(), love.math.random()},
                {
                    controller = i,
                    left = movementStick,  -- Use appropriate stick for movement
                    right = movementStick, -- Use appropriate stick for movement
                    jump = "a",      -- A button on Switch
                    down = "b",      -- B button on Switch (now used for running)
                    kick = "leftshoulder",     -- X button on Switch
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
            logger:info("Controller %d setup: %s (using %s for movement)", i, joystick:getName(), movementStick)
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
            local player = Player.new(100 + (botIndex-1) * 200, Constants.GROUND_Y - 500,
                {love.math.random(), love.math.random(), love.math.random()},
                {
                    controller = botIndex,
                    left = "leftx",
                    right = "leftx",
                    jump = "a",
                    down = "b",
                    kick = "leftshoulder",
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
    -- Wrap the entire update function in error handling
    local success, errorMsg = pcall(function()
        -- Only play music in title screen if music is available (PC only)
        if not self.isSwitch and self.titleMusic then
            if self.gameState == "title" and self.currentMusic ~= self.titleMusic then
                -- Stop any playing music
                if self.currentMusic then
                    self.currentMusic:stop()
                end
                -- Start title music
                love.audio.play(self.titleMusic)
                self.currentMusic = self.titleMusic
                logger:info("Playing title music")
            elseif self.gameState ~= "title" and self.currentMusic then
                -- Stop music when leaving title screen
                self.currentMusic:stop()
                self.currentMusic = nil
                logger:info("Stopped music when leaving title screen")
            end
        end
        
        -- Update game state
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
                            self.selectedCharacterIndex = self.selectedCharacterIndex - Constants.GRID_CELLS_PER_ROW
                            if self.selectedCharacterIndex < 1 then
                                self.selectedCharacterIndex = #characters
                            end
                            self.characterSelectionCooldown = 0.2  -- Set cooldown to 0.2 seconds
                            logger:debug("Selected character: %d", self.selectedCharacterIndex)
                            break
                        end
                        if controller.joystick:isGamepadDown("dpdown") then
                            self.selectedCharacterIndex = self.selectedCharacterIndex + Constants.GRID_CELLS_PER_ROW
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
            self.characterChangeTime = love.math.random(Constants.CHARACTER_CHANGE_MIN_TIME, Constants.CHARACTER_CHANGE_MAX_TIME)
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
            if box.y > Constants.SCREEN_HEIGHT then
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
    end)
    
    if not success then
        logger:error("Error in update: %s", errorMsg)
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
    -- Draw background based on game state
    love.graphics.setColor(Constants.COLORS.WHITE)
    if self.gameState == "title" then
        love.graphics.draw(self.titleBackground, 0, 0)
    else
        love.graphics.draw(self.gameBackground, 0, 0)
    end
    
    -- Draw based on game state
    if self.gameState == "title" then
        self:drawTitle()
    elseif self.gameState == "game" then
        -- Draw boxes
        for _, box in ipairs(self.boxes) do
            if box.useCircle then
                -- Draw circle for character
                love.graphics.setColor(Constants.COLORS.YELLOW)  -- Yellow color for circles
                love.graphics.circle("fill", box.x + box.width/2, box.y + box.height/2, box.width/2)
                -- Draw character meaning in the circle
                love.graphics.setColor(Constants.COLORS.BLACK)  -- Black text
                self:safeSetFont(self.smallFont)
                local text = box.character
                local textWidth = self.smallFont:getWidth(text)
                love.graphics.print(text, box.x + (box.width - textWidth)/2, box.y + box.height/2 - 8)
            else
                -- Draw character image
                love.graphics.setColor(Constants.COLORS.WHITE)
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
        love.graphics.setColor(Constants.COLORS.WHITE)
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
                love.graphics.setColor(Constants.COLORS.RED_TRANSPARENT)  -- Semi-transparent red
                local expansionX = player.width * Constants.HITBOX_EXPANSION_X
                local expansionY = player.height * Constants.HITBOX_EXPANSION_Y
                love.graphics.rectangle("fill", 
                    player.x - expansionX, 
                    player.y - expansionY, 
                    player.width * 1.5, 
                    player.height * 1.5)
                
                -- Draw the original player rectangle
                love.graphics.setColor(Constants.COLORS.GREEN_TRANSPARENT)  -- Green for the player model
                love.graphics.rectangle("line", player.x, player.y, player.width, player.height)
                
                -- Draw the collection hitbox
                love.graphics.setColor(Constants.COLORS.RED_TRANSPARENT)  -- Red for the collection hitbox
                love.graphics.rectangle("line", 
                    player.x - expansionX, 
                    player.y - expansionY, 
                    player.width * 1.5, 
                    player.height * 1.5)
                
                -- Draw kick hitbox if player is kicking
                if player.isKicking then
                    love.graphics.setColor(Constants.COLORS.ORANGE_TRANSPARENT)  -- Orange for kick hitbox
                    local kickX
                    if player.velocity.x > 0 then
                        kickX = player.x + player.width + Constants.KICK_HITBOX_OFFSET_X
                    else
                        kickX = player.x - Constants.KICK_HITBOX_OFFSET_X - Constants.KICK_HITBOX_WIDTH
                    end
                    local kickY = player.y + player.height/2 - Constants.KICK_HITBOX_OFFSET_Y
                    love.graphics.rectangle("fill", kickX, kickY, Constants.KICK_HITBOX_WIDTH, Constants.KICK_HITBOX_HEIGHT)
                    love.graphics.setColor(Constants.COLORS.ORANGE)  -- Solid orange for outline
                    love.graphics.rectangle("line", kickX, kickY, Constants.KICK_HITBOX_WIDTH, Constants.KICK_HITBOX_HEIGHT)
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
    
    love.graphics.print(titleText, Constants.SCREEN_WIDTH/2 - titleWidth/2, 100)
    
    -- Draw subtitle
    self:safeSetFont(self.subtitleFont)
    local subtitleText = "Catch the matching characters!"
    local subtitleWidth = 300  -- Fixed width for Switch
    if self.subtitleFont then
        subtitleWidth = self.subtitleFont:getWidth(subtitleText)
    end
    love.graphics.print(subtitleText, Constants.SCREEN_WIDTH/2 - subtitleWidth/2, 160)
    
    -- Draw bot count selection
    self:safeSetFont(self.instructionFont)
    local botText = string.format("Bots: %d (Press A to increase, B to decrease)", self.selectedBotCount)
    local botWidth = 300  -- Fixed width for Switch
    if self.instructionFont then
        botWidth = self.instructionFont:getWidth(botText)
    end
    love.graphics.print(botText, Constants.SCREEN_WIDTH/2 - botWidth/2, 220)
    
    -- Draw character selection instructions
    local charSelectText = "Use D-pad to select, X to toggle characters"
    local charSelectWidth = 300  -- Fixed width for Switch
    if self.instructionFont then
        charSelectWidth = self.instructionFont:getWidth(charSelectText)
    end
    love.graphics.print(charSelectText, Constants.SCREEN_WIDTH/2 - charSelectWidth/2, 300)
    
    -- Draw instructions
    local instructionText = "Press START to begin"
    local instructionWidth = 300  -- Fixed width for Switch
    if self.instructionFont then
        instructionWidth = self.instructionFont:getWidth(instructionText)
    end
    love.graphics.print(instructionText, Constants.SCREEN_WIDTH/2 - instructionWidth/2, 340)
    
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
    love.graphics.print(currentCharText, Constants.SCREEN_WIDTH/2 - currentCharWidth/2, 50)
    
    -- Draw game timer
    local timeLeft = math.max(0, self.gameDuration - self.gameTimer)
    local timerText = string.format("Time: %d", math.ceil(timeLeft))
    local timerWidth = 300  -- Fixed width for Switch
    if self.font then
        timerWidth = self.font:getWidth(timerText)
    end
    love.graphics.print(timerText, Constants.SCREEN_WIDTH/2 - timerWidth/2, 100)
    
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
    love.graphics.print(gameOverText, Constants.SCREEN_WIDTH/2 - gameOverWidth/2, 200)
    
    -- Draw winner
    if self.winner then
        self:safeSetFont(self.subtitleFont)
        local winnerText = string.format("Winner: %s with %d points!", 
            self.winner.name, self.winner.score)
        local winnerWidth = 300  -- Fixed width for Switch
        if self.subtitleFont then
            winnerWidth = self.subtitleFont:getWidth(winnerText)
        end
        love.graphics.print(winnerText, Constants.SCREEN_WIDTH/2 - winnerWidth/2, 280)
    else
        self:safeSetFont(self.subtitleFont)
        local tieText = "It's a tie!"
        local tieWidth = 300  -- Fixed width for Switch
        if self.subtitleFont then
            tieWidth = self.subtitleFont:getWidth(tieText)
        end
        love.graphics.print(tieText, Constants.SCREEN_WIDTH/2 - tieWidth/2, 280)
    end
    
    -- Draw instructions
    self:safeSetFont(self.instructionFont)
    local instructionText = "Press BACK to return to title"
    local instructionWidth = 300  -- Fixed width for Switch
    if self.instructionFont then
        instructionWidth = self.instructionFont:getWidth(instructionText)
    end
    love.graphics.print(instructionText, Constants.SCREEN_WIDTH/2 - instructionWidth/2, 400)
    
    -- Draw final scores
    self:safeSetFont(self.smallFont)
    local scoresTitle = "Final Scores:"
    local scoresTitleWidth = 300  -- Fixed width for Switch
    if self.smallFont then
        scoresTitleWidth = self.smallFont:getWidth(scoresTitle)
    end
    love.graphics.print(scoresTitle, Constants.SCREEN_WIDTH/2 - scoresTitleWidth/2, 450)
    
    local startY = 480
    for i, controller in ipairs(self.controllers) do
        local scoreText = string.format("Player %d: %d points", i, controller.player.score)
        local scoreWidth = 300  -- Fixed width for Switch
        if self.smallFont then
            scoreWidth = self.smallFont:getWidth(scoreText)
        end
        love.graphics.print(scoreText, Constants.SCREEN_WIDTH/2 - scoreWidth/2, startY + (i-1) * 30)
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
        x = love.math.random(Constants.BOX_SPAWN_MIN_X, Constants.BOX_SPAWN_MAX_X),  -- Random x position
        y = Constants.BOX_SPAWN_Y,  -- Start above the screen
        width = Constants.BOX_WIDTH,  -- Match player width
        height = Constants.BOX_HEIGHT,  -- Match player height
        speed = love.math.random(Constants.BOX_MIN_SPEED, Constants.BOX_MAX_SPEED),  -- Random fall speed
        meaning = randomCharacter.meaning,
        character = randomCharacter.character,
        useCircle = love._console == "Switch" and config.rendering.useCirclesForCharacters or false  -- Store whether to use circle
    }
    
    -- Only load image if not using circles
    if not box.useCircle then
        -- Use preloaded image if available
        if self.characterImages[randomCharacter.meaning] then
            box.image = self.characterImages[randomCharacter.meaning]
        else
            -- Try to load SVG file first
            local imagePath = "assets/falling-objects/" .. string.lower(randomCharacter.meaning) .. "/" .. string.lower(randomCharacter.meaning) .. ".svg"
            local success, loadedImage = pcall(function()
                return love.graphics.newImage(imagePath)
            end)
            
            if success then
                box.image = loadedImage
                -- Cache the image for future use
                self.characterImages[randomCharacter.meaning] = loadedImage
                logger:info("Loaded character SVG image: %s", randomCharacter.meaning)
            else
                -- If SVG fails, try PNG as fallback
                local imagePath2 = "assets/falling-objects/" .. string.lower(randomCharacter.meaning) .. "/" .. string.lower(randomCharacter.meaning) .. ".png"
                local success2, loadedImage2 = pcall(function()
                    return love.graphics.newImage(imagePath2)
                end)
                
                if success2 then
                    box.image = loadedImage2
                    -- Cache the image for future use
                    self.characterImages[randomCharacter.meaning] = loadedImage2
                    logger:info("Loaded character PNG image: %s", randomCharacter.meaning)
                else
                    logger:warning("Failed to load character image: %s, falling back to circle", randomCharacter.meaning)
                    box.useCircle = true  -- Fall back to circle if image loading fails
                end
            end
        end
    end
    
    table.insert(self.boxes, box)
    logger:debug("Box spawned at (%.2f, %.2f) with meaning: %s", box.x, box.y, box.meaning)
end

function Game:checkCharacterCollection(player, character)
    -- Calculate the expanded hitbox (3x larger than the player model)
    local expansionX = player.width * Constants.HITBOX_EXPANSION_X  -- 150% expansion on each side (3x total width)
    local expansionY = player.height * Constants.HITBOX_EXPANSION_Y  -- 150% expansion on each side (3x total height)
    
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
        local playerLeft = player.x - player.width * Constants.HITBOX_EXPANSION_X
        local playerRight = player.x + player.width * (1 + Constants.HITBOX_EXPANSION_X)
        local playerTop = player.y - player.height * Constants.HITBOX_EXPANSION_Y
        local playerBottom = player.y + player.height * (1 + Constants.HITBOX_EXPANSION_Y)
        
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
                    controller.player.score = controller.player.score + Constants.CORRECT_MATCH_SCORE
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
                        controller.player.score = math.max(0, controller.player.score - Constants.WRONG_MATCH_PENALTY)
                        logger:info("Player %s collected wrong character: %s, lost %d points", 
                            controller.player.name, box.meaning, Constants.WRONG_MATCH_PENALTY)
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
                kickX = player1.x + player1.width + Constants.KICK_HITBOX_OFFSET_X
            else
                kickX = player1.x - Constants.KICK_HITBOX_OFFSET_X - Constants.KICK_HITBOX_WIDTH
            end
            local kickY = player1.y + player1.height/2 - Constants.KICK_HITBOX_OFFSET_Y
            
            -- Define kick hitbox boundaries
            local kickLeft = kickX
            local kickRight = kickX + Constants.KICK_HITBOX_WIDTH
            local kickTop = kickY
            local kickBottom = kickY + Constants.KICK_HITBOX_HEIGHT
            
            -- Check collision with all other players
            for j, controller2 in ipairs(self.controllers) do
                if i ~= j then  -- Don't check collision with self
                    local player2 = controller2.player
                    -- Only check if player2 is not already knocked back and not invulnerable
                    if not player2.isKnockback and not player2.isInvulnerable then
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
                                x = player1.facingRight and -Constants.KNOCKBACK_FORCE_X or Constants.KNOCKBACK_FORCE_X,  -- Push in opposite direction of kicker
                                y = -Constants.KNOCKBACK_FORCE_Y  -- Minimal upward knockback
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
    local isPlayerCharacterCollision = (a.width == Constants.PLAYER_WIDTH and a.height == Constants.PLAYER_HEIGHT) or (b.width == Constants.PLAYER_WIDTH and b.height == Constants.PLAYER_HEIGHT)
    
    if isPlayerCharacterCollision then
        -- For player-character collisions, use rectangle collision with expanded hitbox
        local player = (a.width == Constants.PLAYER_WIDTH and a.height == Constants.PLAYER_HEIGHT) and a or b
        local character = (a.width == Constants.PLAYER_WIDTH and a.height == Constants.PLAYER_HEIGHT) and b or a
        
        -- Calculate the expanded hitbox (3x larger than the player model)
        local expansionX = player.width * Constants.HITBOX_EXPANSION_X  -- 150% expansion on each side (3x total width)
        local expansionY = player.height * Constants.HITBOX_EXPANSION_Y  -- 150% expansion on each side (3x total height)
        
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
        local aCenterX = a.x + (a.width or Constants.PLAYER_WIDTH)/2
        local aCenterY = a.y + (a.height or Constants.PLAYER_HEIGHT)/2
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
    local gridX = Constants.GRID_START_X  -- Center of the grid
    local gridY = Constants.GRID_START_Y  -- Moved down to be below other text
    local cellSize = Constants.GRID_CELL_SIZE  -- Size of each cell
    local cellsPerRow = Constants.GRID_CELLS_PER_ROW  -- 8x8 grid
    local startX = gridX - (cellSize * cellsPerRow) / 2
    local startY = gridY - (cellSize * cellsPerRow) / 2
    
    -- Draw grid title
    love.graphics.setColor(Constants.COLORS.WHITE)
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
            love.graphics.setColor(Constants.COLORS.YELLOW)  -- Yellow highlight
        else
            -- Normal cell
            love.graphics.setColor(Constants.COLORS.DARK_GRAY_TRANSPARENT)  -- Dark gray
        end
        love.graphics.rectangle("fill", x, y, cellSize, cellSize)
        
        -- Draw cell border
        love.graphics.setColor(Constants.COLORS.WHITE)  -- White
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
        love.graphics.setColor(Constants.COLORS.WHITE)  -- White
        self:safeSetFont(self.smallFont)
        local meaningText = char.meaning
        local meaningWidth = 30  -- Fixed width for Switch
        if self.smallFont then
            meaningWidth = self.smallFont:getWidth(meaningText)
        end
        love.graphics.print(meaningText, x + (cellSize - meaningWidth)/2, y + cellSize - 20)
        
        -- Draw enabled/disabled indicator
        if self.characterEnabled[i] then
            love.graphics.setColor(Constants.COLORS.GREEN)  -- Green for enabled
        else
            love.graphics.setColor(Constants.COLORS.RED)  -- Red for disabled
        end
        love.graphics.circle("fill", x + 5, y + 5, 5)
    end
end

-- Add a function to stop all music
function Game:stopMusic()
    if self.currentMusic then
        self.currentMusic:stop()
        self.currentMusic = nil
    end
    logger:info("Stopped all background music")
end

-- Add a function to clean up resources
function Game:cleanup()
    self:stopMusic()
    -- Release audio sources only if they exist (PC only)
    if not self.isSwitch then
        if self.titleMusic then
            self.titleMusic:release()
        end
        if self.gameMusic then
            self.gameMusic:release()
        end
    end
    logger:info("Cleaned up game resources")
end

function Game:isGameOver()
    -- Game is over if we're in the gameover state
    return self.gameState == "gameover"
end

function Game:startGame()
    -- Stop any playing music
    if self.currentMusic then
        self.currentMusic:stop()
        self.currentMusic = nil
        logger:info("Stopped music when starting game")
    end
    
    self.gameState = "game"
    self.gameTimer = 0
    self.winner = nil
    
    -- Reset player scores
    for _, controller in ipairs(self.controllers) do
        controller.player.score = 0
        controller.player.collectedApples = {}
    end
    
    -- Clear boxes
    self.boxes = {}
    
    logger:info("Game started with %d players", #self.controllers)
end

function Game:addPlayer(x, y, color, controls, characterType)
    local Player = require("player")
    local player = Player.new(x, y, color, controls, characterType)
    table.insert(self.controllers, {
        joystick = nil,  -- Will be set by setController if needed
        player = player,
        isBot = false
    })
    logger:info("Added player to game: %s with character type %s", player.name, characterType)
    return player
end

return Game 