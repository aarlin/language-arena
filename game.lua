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
    }
}

function Game.new()
    local self = setmetatable({}, Game)
    self.controllers = {}
    self.boxes = {}
    self.currentCharacter = CHARACTERS[1]
    self.characterTimer = 0
    self.characterChangeTime = love.math.random(15, 25)  -- Random time between 15-25 seconds
    self.spawnTimer = 0
    self.spawnInterval = 2
    self.background = love.graphics.newImage("assets/background/forest.jpg")
    self.font = love.graphics.newFont(24)
    self.smallFont = love.graphics.newFont(16)
    self.titleFont = love.graphics.newFont(48)
    self.subtitleFont = love.graphics.newFont(24)
    self.instructionFont = love.graphics.newFont(18)
    self.gameState = "title"  -- title, game, gameover
    self.winner = nil
    self.gameTimer = 0
    self.gameDuration = 120  -- 2 minutes game time
    
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
                    punch = "x",     -- X button on Switch
                    slide = "leftshoulder",  -- Left shoulder button (LB) for sliding
                    start = "start", -- Plus button on Switch
                    back = "back"    -- Minus button on Switch
                }
            )
            player:setController(joystick)
            table.insert(self.controllers, {
                joystick = joystick,
                player = player
            })
            logger:info("Controller %d setup: %s", i, joystick:getName())
        end
    end
end

function Game:update(dt)
    if self.gameState == "title" then
        -- Check for start button press
        for _, controller in ipairs(self.controllers) do
            if controller.joystick:isGamepadDown(controller.player.controls.start) then
                self.gameState = "game"
                self.gameTimer = 0
                logger:info("Game started")
                break
            end
        end
        return
    elseif self.gameState == "gameover" then
        -- Check for back button press to return to title
        for _, controller in ipairs(self.controllers) do
            if controller.joystick:isGamepadDown(controller.player.controls.back) then
                self.gameState = "title"
                -- Reset game state
                self.boxes = {}
                self:setupControllers()
                logger:info("Returned to title screen")
                break
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
            if controller.joystick == joystick then
                controller.player:gamepadpressed(button)
                break
            end
        end
    end
end

function Game:gamepadreleased(joystick, button)
    -- Handle button releases if needed
    for _, controller in ipairs(self.controllers) do
        if controller.joystick == joystick then
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
    elseif self.gameState == "gameover" then
        self:drawGameOver()
        return
    end
    
    -- Draw current character on top center of the forest background
    love.graphics.setColor(self.currentCharacter.color)
    love.graphics.setFont(self.font)
    local textWidth = self.font:getWidth(self.currentCharacter.name)
    love.graphics.print(self.currentCharacter.name, 600 - textWidth/2, 2000)  -- Moved to bottom of screen
    
    -- Draw meaning below character
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.smallFont)
    local meaningWidth = self.smallFont:getWidth(self.currentCharacter.meaning)
    love.graphics.print(self.currentCharacter.meaning, 600 - meaningWidth/2, 2000)  -- Moved to bottom of screen
    
    -- Draw timer
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.smallFont)
    local timeLeft = math.ceil(self.gameDuration - self.gameTimer)
    local timerText = string.format("Time: %d", timeLeft)
    local timerWidth = self.smallFont:getWidth(timerText)
    love.graphics.print(timerText, 600 - timerWidth/2, 20)
    
    -- Draw character change timer
    local changeTimeLeft = math.ceil(self.characterChangeTime - self.characterTimer)
    local changeText = string.format("Next character: %d", changeTimeLeft)
    local changeWidth = self.smallFont:getWidth(changeText)
    love.graphics.print(changeText, 600 - changeWidth/2, 50)
    
    -- Draw boxes (apples)
    for _, box in ipairs(self.boxes) do
        -- Draw apple
        love.graphics.setColor(1, 0, 0)  -- Red apple
        love.graphics.circle("fill", box.x + box.width/2, box.y + box.height/2, box.width/2)
        
        -- Draw stem
        love.graphics.setColor(0, 0.8, 0)  -- Green stem
        love.graphics.rectangle("fill", box.x + box.width/2 - 1, box.y, 2, 5)
        
        -- Draw meaning text
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(self.smallFont)
        local textWidth = self.smallFont:getWidth(box.meaning)
        love.graphics.print(box.meaning, box.x + box.width/2 - textWidth/2, box.y - 20)
    end
    
    -- Draw players
    for _, controller in ipairs(self.controllers) do
        controller.player:draw()
        
        -- Draw score
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(self.smallFont)
        local scoreText = string.format("Score: %d", controller.player.score)
        love.graphics.print(scoreText, controller.player.x, controller.player.y - 40)
    end
end

function Game:drawTitle()
    -- Draw title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.titleFont)
    local titleText = "Language Arena"
    local titleWidth = self.titleFont:getWidth(titleText)
    love.graphics.print(titleText, 600 - titleWidth/2, 200)
    
    -- Draw subtitle
    love.graphics.setFont(self.subtitleFont)
    local subtitleText = "Catch the matching characters!"
    local subtitleWidth = self.subtitleFont:getWidth(subtitleText)
    love.graphics.print(subtitleText, 600 - subtitleWidth/2, 280)
    
    -- Draw instructions
    love.graphics.setFont(self.instructionFont)
    local instructionText = "Press START to begin"
    local instructionWidth = self.instructionFont:getWidth(instructionText)
    love.graphics.print(instructionText, 600 - instructionWidth/2, 400)
    
    -- Draw character list
    love.graphics.setFont(self.smallFont)
    local listTitle = "Characters:"
    local listTitleWidth = self.smallFont:getWidth(listTitle)
    love.graphics.print(listTitle, 600 - listTitleWidth/2, 450)
    
    local startY = 480
    local itemsPerRow = 5
    local itemWidth = 100
    local itemHeight = 30
    
    for i, char in ipairs(CHARACTERS) do
        local row = math.floor((i-1) / itemsPerRow)
        local col = (i-1) % itemsPerRow
        
        local x = 300 + col * itemWidth
        local y = startY + row * itemHeight
        
        -- Draw character box
        love.graphics.setColor(0.2, 0.2, 0.2, 0.7)
        love.graphics.rectangle("fill", x, y, 90, 25)
        
        -- Draw character
        love.graphics.setColor(char.color)
        love.graphics.print(char.name, x + 10, y + 5)
        
        -- Draw meaning
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(char.meaning, x + 40, y + 5)
    end
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
        local winnerText = string.format("Winner: Player %d with %d points!", 
            self.winner.controller, self.winner.score)
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
    -- Select a random character for the apple
    local randomCharacter = CHARACTERS[love.math.random(1, #CHARACTERS)]
    
    local box = {
        x = love.math.random(100, 1100),
        y = -20,  -- Start above the screen
        meaning = randomCharacter.meaning,
        character = randomCharacter,  -- Store the entire character object
        speed = love.math.random(50, 150),  -- Random fall speed
        width = 30,  -- Increased size for better visibility
        height = 30  -- Increased size for better visibility
    }
    table.insert(self.boxes, box)
    
    logger:debug("Spawned box with meaning: %s at position (%.2f, %.2f)", 
        box.meaning, box.x, box.y)
end

function Game:checkCollisions()
    -- Check player-box collisions
    for _, controller in ipairs(self.controllers) do
        for i, box in ipairs(self.boxes) do
            local collision = self:checkCollision(controller.player, box)
            logger:logCollision(controller.player, box, collision)
            
            if collision then
                -- Collect the apple
                controller.player:collectApple(box)
                
                -- Check if the meaning matches the current character
                if box.meaning == self.currentCharacter.meaning then
                    -- Correct match! Add points
                    controller.player.score = controller.player.score + 10
                    -- Show a victory animation
                    controller.player:setAnimation(ANIMATION_STATES.VICTORY)
                    logger:info("Player %s collected correct apple: %s", 
                        controller.player.name, box.meaning)
                else
                    -- Wrong match! Subtract points or remove an apple
                    if #controller.player.collectedApples > 1 then
                        -- Remove the oldest apple from the stack
                        table.remove(controller.player.collectedApples, 1)
                        logger:info("Player %s collected wrong apple: %s, removed oldest apple", 
                            controller.player.name, box.meaning)
                    else
                        -- If no apples in stack, subtract points
                        controller.player.score = math.max(0, controller.player.score - 5)
                        logger:info("Player %s collected wrong apple: %s, lost 5 points", 
                            controller.player.name, box.meaning)
                    end
                end
                
                table.remove(self.boxes, i)
                break
            end
        end
    end
    
    -- Check player-player collisions for punching
    for i, controller1 in ipairs(self.controllers) do
        if controller1.player.isPunching then
            for j, controller2 in ipairs(self.controllers) do
                if i ~= j and self:checkCollision(controller1.player, controller2.player) then
                    local knockbackVel = {
                        x = (controller2.player.x - controller1.player.x) * 2,
                        y = -200
                    }
                    controller2.player:takeKnockback(knockbackVel)
                end
            end
        end
    end
end

function Game:checkCollision(a, b)
    -- Improved collision detection for apples and players
    -- For apples, use a smaller collision radius than the visual size
    local aRadius = a.width and a.width/3 or 10
    local bRadius = b.width and b.width/3 or 10
    
    -- Calculate center points
    local aCenterX = a.x + (a.width or 410)/2  -- Updated to match new player width
    local aCenterY = a.y + (a.height or 570)/2  -- Updated to match new player height
    local bCenterX = b.x + (b.width or 20)/2
    local bCenterY = b.y + (b.height or 20)/2
    
    -- Calculate distance between centers
    local dx = aCenterX - bCenterX
    local dy = aCenterY - bCenterY
    local distance = math.sqrt(dx*dx + dy*dy)
    
    -- Check if distance is less than sum of radii
    return distance < (aRadius + bRadius)
end

return Game 