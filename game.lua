local Player = require("player")
local characters = require("characters")
local logger = require("logger")  -- Import the logger

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

-- Character definitions
local CHARACTERS = {
    {
        name = "猫",
        meaning = "Cat",
        color = {1, 0.5, 0}  -- Orange
    },
    {
        name = "犬",
        meaning = "Dog",
        color = {0.5, 0.5, 0.5}  -- Gray
    },
    {
        name = "鳥",
        meaning = "Bird",
        color = {0, 0.8, 1}  -- Light blue
    },
    {
        name = "魚",
        meaning = "Fish",
        color = {0, 0.5, 1}  -- Blue
    },
    {
        name = "熊",
        meaning = "Bear",
        color = {0.6, 0.3, 0}  -- Brown
    },
    {
        name = "兔",
        meaning = "Rabbit",
        color = {1, 1, 1}  -- White
    },
    {
        name = "虎",
        meaning = "Tiger",
        color = {1, 0.5, 0}  -- Orange
    },
    {
        name = "龍",
        meaning = "Dragon",
        color = {1, 0, 0}  -- Red
    },
    {
        name = "馬",
        meaning = "Horse",
        color = {0.5, 0.25, 0}  -- Dark brown
    },
    {
        name = "羊",
        meaning = "Sheep",
        color = {0.9, 0.9, 0.9}  -- Light gray
    },
    {
        name = "蛇",
        meaning = "Snake",
        color = {0, 0.8, 0}  -- Green
    },
    {
        name = "雞",
        meaning = "Rooster",
        color = {1, 0.8, 0}  -- Yellow
    },
    {
        name = "豬",
        meaning = "Pig",
        color = {1, 0.7, 0.7}  -- Pink
    },
    {
        name = "牛",
        meaning = "Ox",
        color = {0.5, 0.25, 0}  -- Brown
    },
    {
        name = "猴",
        meaning = "Monkey",
        color = {0.6, 0.3, 0}  -- Brown
    },
    {
        name = "鼠",
        meaning = "Mouse",
        color = {0.7, 0.7, 0.7}  -- Gray
    }
}

function Game.new()
    local self = setmetatable({}, Game)
    self.controllers = {}
    self.boxes = {}
    
    -- Initialize character selection
    self.characterEnabled = {}
    for i, char in ipairs(CHARACTERS) do
        self.characterEnabled[i] = true  -- All characters enabled by default
    end
    
    -- Select a random starting character from enabled characters
    local enabledCharacters = {}
    for i, char in ipairs(CHARACTERS) do
        if self.characterEnabled[i] then
            table.insert(enabledCharacters, char)
        end
    end
    
    -- If no characters are enabled, use all characters
    if #enabledCharacters == 0 then
        enabledCharacters = CHARACTERS
    end
    
    -- Select random character
    self.currentCharacter = enabledCharacters[love.math.random(1, #enabledCharacters)]
    logger:info("[INIT] Starting character randomized to: %s (%s)", 
        self.currentCharacter.name, self.currentCharacter.meaning)
    
    self.characterTimer = 0
    self.characterChangeTime = love.math.random(15, 25)  -- Random time between 15-25 seconds
    self.spawnTimer = 0
    self.spawnInterval = 1  -- Decreased from 2 to 1 second for more frequent spawns
    self.background = love.graphics.newImage("assets/background/forest.jpg")
    self.font = love.graphics.newFont(24)
    self.smallFont = love.graphics.newFont(16)
    self.titleFont = love.graphics.newFont(48)
    self.subtitleFont = love.graphics.newFont(24)
    self.instructionFont = love.graphics.newFont(18)
    self.cjkFont = love.graphics.newFont("assets/fonts/SourceHanSansSC-Regular.otf", 24)  -- CJK font for Chinese/Japanese characters
    self.countdownFont = love.graphics.newFont(120)  -- Large font for countdown
    self.gameState = "title"  -- title, countdown, game, gameover
    self.winner = nil
    self.gameTimer = 0
    self.gameDuration = 120  -- 2 minutes game time
    self.botCount = 0  -- Default to no bots
    self.selectedBotCount = 0  -- Currently selected bot count in menu
    self.debugMode = true  -- Debug mode for hitbox visualization
    self.selectedCharacterIndex = 1  -- Currently selected character in the grid
    self.characterSelectionCooldown = 0  -- Cooldown timer for character selection
    
    -- Countdown variables
    self.countdownTimer = 0
    self.countdownNumber = 3
    self.countdownDuration = 1  -- Each number shows for 1 second
    self.countdownAlpha = 1  -- For fade effect
    
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
            -- Alternate player positions between left and right sides
            local xPos = i % 2 == 1 and 100 or 1100  -- Left side for odd numbers, right side for even
            local player = Player.new(xPos, 600 - 500,  -- Position higher on the screen
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
            -- Alternate bot positions between left and right sides
            local xPos = botIndex % 2 == 1 and 100 or 1100  -- Left side for odd numbers, right side for even
            local player = Player.new(xPos, 600 - 500,
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
                    self.gameState = "countdown"  -- Start countdown instead of going directly to game
                    self.countdownTimer = 0
                    self.countdownNumber = 3
                    self.countdownAlpha = 1
                    self.gameTimer = 0
                    self.botCount = self.selectedBotCount  -- Set the actual bot count when starting the game
                    
                    -- Setup controllers again to add bots
                    self:setupControllers()
                    
                    logger:info("Starting countdown sequence")
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
                            self.selectedCharacterIndex = #CHARACTERS
                        end
                        self.characterSelectionCooldown = 0.2  -- Set cooldown to 0.2 seconds
                        logger:debug("Selected character: %d", self.selectedCharacterIndex)
                        break
                    end
                    if controller.joystick:isGamepadDown("dpdown") then
                        self.selectedCharacterIndex = self.selectedCharacterIndex + 8
                        if self.selectedCharacterIndex > #CHARACTERS then
                            self.selectedCharacterIndex = 1
                        end
                        self.characterSelectionCooldown = 0.2  -- Set cooldown to 0.2 seconds
                        logger:debug("Selected character: %d", self.selectedCharacterIndex)
                        break
                    end
                    if controller.joystick:isGamepadDown("dpleft") then
                        self.selectedCharacterIndex = self.selectedCharacterIndex - 1
                        if self.selectedCharacterIndex < 1 then
                            self.selectedCharacterIndex = #CHARACTERS
                        end
                        self.characterSelectionCooldown = 0.2  -- Set cooldown to 0.2 seconds
                        logger:debug("Selected character: %d", self.selectedCharacterIndex)
                        break
                    end
                    if controller.joystick:isGamepadDown("dpright") then
                        self.selectedCharacterIndex = self.selectedCharacterIndex + 1
                        if self.selectedCharacterIndex > #CHARACTERS then
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
                        CHARACTERS[self.selectedCharacterIndex].name,
                        self.characterEnabled[self.selectedCharacterIndex] and "enabled" or "disabled")
                    break
                end
                
                -- Toggle debug mode with Y button
                if controller.joystick:isGamepadDown("y") then
                    self.debugMode = not self.debugMode
                    logger:info("Debug mode %s", self.debugMode and "enabled" or "disabled")
                    break
                end
            end
        end
        return
    elseif self.gameState == "countdown" then
        -- Update countdown
        self.countdownTimer = self.countdownTimer + dt
        
        -- Fade effect
        if self.countdownTimer < self.countdownDuration * 0.8 then
            self.countdownAlpha = 1
        else
            self.countdownAlpha = 1 - ((self.countdownTimer - self.countdownDuration * 0.8) / (self.countdownDuration * 0.2))
        end
        
        -- Check if it's time to change number
        if self.countdownTimer >= self.countdownDuration then
            self.countdownTimer = 0
            self.countdownNumber = self.countdownNumber - 1
            self.countdownAlpha = 1
            
            if self.countdownNumber < 0 then
                -- Countdown finished, start the game
                self.gameState = "game"
                logger:info("Countdown finished, game starting")
            elseif self.countdownNumber == 0 then
                -- Show "FIGHT!" instead of 0
                logger:info("Showing FIGHT!")
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
            newIndex = love.math.random(1, #CHARACTERS)
        until CHARACTERS[newIndex].name ~= self.currentCharacter.name
        
        logger:info("Character changed from %s to %s", 
            self.currentCharacter.name, CHARACTERS[newIndex].name)
        
        self.currentCharacter = CHARACTERS[newIndex]
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
    love.graphics.draw(self.background, 0, 0, 0, 1.5, 1.5)
    
    if self.gameState == "title" then
        self:drawTitle()
        return
    elseif self.gameState == "countdown" then
        -- Draw the game elements in the background
        self:drawGameElements()
        
        -- Draw the countdown number
        love.graphics.setColor(1, 1, 1, self.countdownAlpha)
        love.graphics.setFont(self.countdownFont)
        
        local countdownText
        if self.countdownNumber > 0 then
            countdownText = tostring(self.countdownNumber)
        else
            countdownText = "FIGHT!"
        end
        
        local textWidth = self.countdownFont:getWidth(countdownText)
        local textHeight = self.countdownFont:getHeight()
        love.graphics.print(countdownText, 600 - textWidth/2, 300 - textHeight/2)
        return
    elseif self.gameState == "gameover" then
        self:drawGameOver()
        return
    end
    
    -- Draw game elements
    self:drawGameElements()
end

function Game:drawGameElements()
    -- Draw timer and scoreboard on the left side
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.smallFont)
    local timeLeft = math.ceil(self.gameDuration - self.gameTimer)
    local timerText = string.format("Time: %d", timeLeft)
    local timerWidth = self.smallFont:getWidth(timerText)
    love.graphics.print(timerText, 50, 20)
    
    -- Draw character change timer
    local changeTimeLeft = math.ceil(self.characterChangeTime - self.characterTimer)
    local changeText = string.format("Next character: %d", changeTimeLeft)
    local changeWidth = self.smallFont:getWidth(changeText)
    love.graphics.print(changeText, 50, 50)
    
    -- Draw leaderboard
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.smallFont)
    local leaderboardTitle = "Leaderboard"
    local leaderboardWidth = self.smallFont:getWidth(leaderboardTitle)
    love.graphics.print(leaderboardTitle, 50, 80)
    
    for i, controller in ipairs(self.controllers) do
        local scoreText = string.format("Player %d: %d points", i, controller.player.score)
        love.graphics.print(scoreText, 50, 100 + i * 20)
    end
    
    -- Draw large character on the right side (300x300)
    love.graphics.setColor(self.currentCharacter.color)
    love.graphics.setFont(self.cjkFont)
    
    -- Create a larger font for the character
    local largeCjkFont = love.graphics.newFont("assets/fonts/SourceHanSansSC-Regular.otf", 300)
    love.graphics.setFont(largeCjkFont)
    
    -- Draw the character in the new position (moved down 100px from current position)
    local characterText = self.currentCharacter.name
    local textWidth = largeCjkFont:getWidth(characterText)
    local textHeight = largeCjkFont:getHeight()
    love.graphics.print(characterText, 750 - textWidth/2, 100 - textHeight/2)  -- Changed from 0 to 100
    
    -- Draw meaning below the large character
    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(1, 1, 1)  -- White
    local meaningWidth = self.smallFont:getWidth(self.currentCharacter.meaning)
    love.graphics.print(self.currentCharacter.meaning, 750 - meaningWidth/2, 75)  -- Changed from 50 to 150
    
    -- Draw falling characters
    for _, box in ipairs(self.boxes) do
        -- Draw character image
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(box.image, box.x, box.y)
        
        -- Draw meaning text
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(self.smallFont)
        local textWidth = self.smallFont:getWidth(box.meaning)
        love.graphics.print(box.meaning, box.x + box.width/2 - textWidth/2, box.y - 20)
    end
    
    -- Draw players
    for _, controller in ipairs(self.controllers) do
        controller.player:draw()
        
        -- Draw hitbox for debugging (red rectangle) only if debug mode is enabled
        if self.debugMode then
            local player = controller.player
            -- Draw the expanded hitbox
            love.graphics.setColor(1, 0, 0, 0.3)  -- Semi-transparent red
            local expansionX = player.width * 1.5  -- 150% expansion on each side (3x total width)
            local expansionY = player.height * 1.5  -- 150% expansion on each side (3x total height)
            love.graphics.rectangle("fill", 
                player.x - expansionX, 
                player.y - expansionY, 
                player.width + expansionX * 2, 
                player.height + expansionY * 2)
            
            -- Draw the original player rectangle (in green)
            love.graphics.setColor(0, 1, 0, 0.5)  -- Green for the player model
            love.graphics.rectangle("line", player.x, player.y, player.width, player.height)
            
            -- Draw the collection hitbox (red outline)
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
                    -- Player moving right, kick hitbox on the right
                    kickX = player.x + player.width + 100
                else
                    -- Player moving left or stationary, kick hitbox on the left
                    kickX = player.x - 100 - 50  -- 50 is the width of the hitbox
                end
                local kickY = player.y + player.height/2 - 50  -- Centered vertically
                love.graphics.rectangle("fill", kickX, kickY, 50, 100)  -- 50x100 kick hitbox
                love.graphics.setColor(1, 0.5, 0, 1)  -- Solid orange for outline
                love.graphics.rectangle("line", kickX, kickY, 50, 100)  -- Outline for kick hitbox
            end
        end
    end
end

function Game:drawTitle()
    -- Draw title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.titleFont)
    local titleText = "Language Arena"
    local titleWidth = self.titleFont:getWidth(titleText)
    love.graphics.print(titleText, 600 - titleWidth/2, 100)
    
    -- Draw subtitle
    love.graphics.setFont(self.subtitleFont)
    local subtitleText = "Catch the matching characters!"
    local subtitleWidth = self.subtitleFont:getWidth(subtitleText)
    love.graphics.print(subtitleText, 600 - subtitleWidth/2, 160)
    
    -- Draw bot count selection
    love.graphics.setFont(self.instructionFont)
    local botText = string.format("Bots: %d (Press A to increase, B to decrease)", self.selectedBotCount)
    local botWidth = self.instructionFont:getWidth(botText)
    love.graphics.print(botText, 600 - botWidth/2, 220)
    
    -- Draw debug mode toggle
    local debugText = string.format("Debug Mode: %s (Press Y to toggle)", self.debugMode and "ON" or "OFF")
    local debugWidth = self.instructionFont:getWidth(debugText)
    love.graphics.print(debugText, 600 - debugWidth/2, 260)
    
    -- Draw character selection instructions
    local charSelectText = "Use D-pad to select, X to toggle characters"
    local charSelectWidth = self.instructionFont:getWidth(charSelectText)
    love.graphics.print(charSelectText, 600 - charSelectWidth/2, 300)
    
    -- Draw instructions
    local instructionText = "Press START to begin"
    local instructionWidth = self.instructionFont:getWidth(instructionText)
    love.graphics.print(instructionText, 600 - instructionWidth/2, 340)
    
    -- Draw character selection grid (moved below other text)
    self:drawCharacterGrid()
end

function Game:drawGameOver()
    -- Draw game over text
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.titleFont)
    local gameOverText = "Game Over!"
    local gameOverWidth = self.titleFont:getWidth(gameOverText)
    love.graphics.print(gameOverText, 600 - gameOverWidth/2, 200)
    
    -- Draw winner
    if self.winner then
        love.graphics.setFont(self.subtitleFont)
        local winnerText = string.format("Winner: %s with %d points!", 
            self.winner.name, self.winner.score)
        local winnerWidth = self.subtitleFont:getWidth(winnerText)
        love.graphics.print(winnerText, 600 - winnerWidth/2, 280)
    else
        love.graphics.setFont(self.subtitleFont)
        local tieText = "It's a tie!"
        local tieWidth = self.subtitleFont:getWidth(tieText)
        love.graphics.print(tieText, 600 - tieWidth/2, 280)
    end
    
    -- Draw instructions
    love.graphics.setFont(self.instructionFont)
    local instructionText = "Press BACK to return to title"
    local instructionWidth = self.instructionFont:getWidth(instructionText)
    love.graphics.print(instructionText, 600 - instructionWidth/2, 400)
    
    -- Draw final scores
    love.graphics.setFont(self.smallFont)
    local scoresTitle = "Final Scores:"
    local scoresTitleWidth = self.smallFont:getWidth(scoresTitle)
    love.graphics.print(scoresTitle, 600 - scoresTitleWidth/2, 450)
    
    local startY = 480
    for i, controller in ipairs(self.controllers) do
        local scoreText = string.format("Player %d: %d points", i, controller.player.score)
        local scoreWidth = self.smallFont:getWidth(scoreText)
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
        for i, char in ipairs(CHARACTERS) do
            if self.characterEnabled[i] then
                table.insert(enabledCharacters, char)
            end
        end
        
        -- If no enabled characters, use all characters
        if #enabledCharacters == 0 then
            enabledCharacters = CHARACTERS
        end
        
        repeat
            randomCharacter = enabledCharacters[love.math.random(1, #enabledCharacters)]
        until randomCharacter.meaning ~= self.currentCharacter.meaning
        logger:debug("Spawning random character with meaning: %s", randomCharacter.meaning)
    end
    
    -- Load the character image from assets/characters directory
    local imagePath = "assets/characters/" .. string.lower(randomCharacter.meaning) .. ".png"
    local success, image = pcall(function()
        return love.graphics.newImage(imagePath)
    end)
    
    if not success then
        logger:warning("Failed to load character image: %s, using fallback", imagePath)
        -- Create a fallback image if the character image can't be loaded
        local size = 48
        local canvas = love.graphics.newCanvas(size, size)
        love.graphics.setCanvas(canvas)
        
        -- Draw circle background
        love.graphics.setColor(randomCharacter.color)
        love.graphics.circle("fill", size/2, size/2, size/2)
        
        -- Draw character text
        love.graphics.setFont(self.cjkFont)
        love.graphics.setColor(1, 1, 1)  -- White text
        local text = randomCharacter.name
        local textWidth = self.cjkFont:getWidth(text)
        local textHeight = self.cjkFont:getHeight()
        love.graphics.print(text, size/2 - textWidth/2, size/2 - textHeight/2)
        
        -- Reset canvas
        love.graphics.setCanvas()
        
        image = canvas
    end
    
    -- Create a scaled down version of the image
    local originalWidth = image:getWidth()
    local originalHeight = image:getHeight()
    local targetSize = 48 * 1.5  -- Increased target size by 1.5 times
    
    -- Create a canvas for the scaled image
    local scaledCanvas = love.graphics.newCanvas(targetSize, targetSize)
    love.graphics.setCanvas(scaledCanvas)
    
    -- Draw the original image scaled down
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(image, 0, 0, 0, targetSize/originalWidth, targetSize/originalHeight)
    
    -- Reset canvas
    love.graphics.setCanvas()
    
    local box = {
        x = love.math.random(100, 1100),
        y = -20,  -- Start above the screen
        meaning = randomCharacter.meaning,
        character = randomCharacter,  -- Store the entire character object
        speed = love.math.random(100, 200),  -- Increased minimum speed from 50 to 100
        width = targetSize,
        height = targetSize,
        image = scaledCanvas  -- Store the scaled character image
    }
    table.insert(self.boxes, box)
    
    logger:debug("Spawned character with meaning: %s at position (%.2f, %.2f) with speed %.2f", 
        box.meaning, box.x, box.y, box.speed)
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
        for i, box in ipairs(self.boxes) do
            -- Use the new character collection function
            local collision = self:checkCharacterCollection(controller.player, box)
            logger:logCollision(controller.player, box, collision)
            
            if collision then
                -- Collect the character
                controller.player:collectCharacter(box)
                
                -- Check if the meaning matches the current character
                if box.meaning == self.currentCharacter.meaning then
                    -- Correct match! Add points
                    controller.player.score = controller.player.score + 10
                    -- Show a victory animation
                    controller.player:setAnimation(ANIMATION_STATES.VICTORY)
                    logger:info("Player %s collected correct character: %s", 
                        controller.player.name, box.meaning)
                else
                    -- Wrong match! Subtract points
                    controller.player.score = controller.player.score - 10
                    logger:info("Player %s collected wrong character: %s (-10 points)", 
                        controller.player.name, box.meaning)
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
    love.graphics.setFont(self.font)
    local gridTitle = "Character Selection"
    local gridTitleWidth = self.font:getWidth(gridTitle)
    love.graphics.print(gridTitle, gridX - gridTitleWidth/2, startY - 40)
    
    -- Draw grid cells
    for i, char in ipairs(CHARACTERS) do
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
        love.graphics.setFont(self.cjkFont)
        local charText = char.name
        local charWidth = self.cjkFont:getWidth(charText)
        local charHeight = self.cjkFont:getHeight()
        love.graphics.print(charText, x + (cellSize - charWidth)/2, y + (cellSize - charHeight)/2)
        
        -- Draw meaning
        love.graphics.setColor(1, 1, 1)  -- White
        love.graphics.setFont(self.smallFont)
        local meaningText = char.meaning
        local meaningWidth = self.smallFont:getWidth(meaningText)
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