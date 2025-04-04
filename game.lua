local Player = require("player")
local characters = require("characters")

local Game = {}
Game.__index = Game

function Game.new()
    local self = setmetatable({}, Game)
    self.state = "menu" -- menu, playing, gameover
    self.selectedLanguage = nil
    self.currentCharacter = nil
    self.players = {}
    self.boxes = {}
    self.spawnTimer = 0
    self.spawnInterval = 3
    self.controllers = {}
    self.lastButtonPressed = "none"
    
    -- Initialize controllers
    self:setupControllers()
    
    return self
end

function Game:setupControllers()
    -- Clear existing controllers
    self.controllers = {}
    
    -- Get all connected joysticks
    local joysticks = love.joystick.getJoysticks()
    
    -- Setup up to 4 controllers
    for i = 1, math.min(4, #joysticks) do
        local joystick = joysticks[i]
        if joystick:isGamepad() then
            local player = Player.new(100 + (i-1) * 200, 500, 
                {love.math.random(), love.math.random(), love.math.random()},
                {
                    controller = i,
                    left = "rightx",  -- Changed to right stick
                    right = "rightx", -- Changed to right stick
                    jump = "a",      -- A button on Switch
                    down = "b",      -- B button on Switch
                    punch = "x",     -- X button on Switch
                    start = "start", -- Plus button on Switch
                    back = "back"    -- Minus button on Switch
                }
            )
            player:setController(joystick)
            table.insert(self.controllers, {
                joystick = joystick,
                player = player
            })
        end
    end
end

function Game:update(dt)
    if self.state == "menu" then
        -- Check for button presses on all controllers
        for _, controller in ipairs(self.controllers) do
            local joystick = controller.joystick
            if joystick:isGamepadDown("a") then
                self.selectedLanguage = "chinese"
                self.state = "playing"
                self:spawnNewCharacter()
                break
            elseif joystick:isGamepadDown("b") then
                self.selectedLanguage = "japanese"
                self.state = "playing"
                self:spawnNewCharacter()
                break
            elseif joystick:isGamepadDown("start") then
                love.event.quit()
            end
        end
    elseif self.state == "playing" then
        -- Update players
        for _, controller in ipairs(self.controllers) do
            controller.player:update(dt)
        end
        
        -- Spawn boxes
        self.spawnTimer = self.spawnTimer + dt
        if self.spawnTimer >= self.spawnInterval then
            self:spawnBox()
            self.spawnTimer = 0
        end
        
        -- Check collisions
        self:checkCollisions()
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
    else
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
    local width, height = love.graphics.getDimensions()
    
    if self.state == "menu" then
        -- Set up title screen
        love.graphics.setColor(1, 1, 1)
        
        -- Game Title
        love.graphics.setFont(love.graphics.newFont(48))
        love.graphics.print("Language Arena", width/2 - 200, height/4)
        
        -- Subtitle
        love.graphics.setFont(love.graphics.newFont(24))
        love.graphics.print("A Multiplayer Language Learning Game", width/2 - 250, height/4 + 60)
        
        -- Instructions
        love.graphics.setFont(love.graphics.newFont(18))
        love.graphics.print("Select Language:", width/2 - 100, height/2)
        love.graphics.print("Press A for Chinese", width/2 - 100, height/2 + 40)
        love.graphics.print("Press B for Japanese", width/2 - 100, height/2 + 70)
        
        -- Controller Status
        love.graphics.print("Connected Controllers: " .. #self.controllers, width/2 - 100, height/2 + 120)
        
        -- Display detailed controller info
        local yOffset = height/2 + 150
        for i, controller in ipairs(self.controllers) do
            local joystick = controller.joystick
            local name = joystick:getName()
            local guid = joystick:getGUID()
            local isGamepad = joystick:isGamepad()
            local buttonCount = joystick:getButtonCount()
            local axisCount = joystick:getAxisCount()
            
            love.graphics.print("Controller " .. i .. ":", width/2 - 100, yOffset)
            love.graphics.print("Name: " .. name, width/2 - 100, yOffset + 20)
            love.graphics.print("GUID: " .. guid, width/2 - 100, yOffset + 40)
            love.graphics.print("Type: " .. (isGamepad and "Gamepad" or "Joystick"), width/2 - 100, yOffset + 60)
            love.graphics.print("Buttons: " .. buttonCount, width/2 - 100, yOffset + 80)
            love.graphics.print("Axes: " .. axisCount, width/2 - 100, yOffset + 100)
            
            -- Show current button state
            love.graphics.print("Last Button: " .. self.lastButtonPressed, width/2 - 100, yOffset + 120)
            
            yOffset = yOffset + 160
        end
        
        -- Version Info
        love.graphics.setFont(love.graphics.newFont(12))
        love.graphics.print("Press + to quit", 10, height - 30)
    elseif self.state == "playing" then
        -- Draw colorful arena background
        love.graphics.setColor(0.2, 0.2, 0.3) -- Dark blue floor
        love.graphics.rectangle("fill", 0, 600, width, height - 600)
        
        -- Draw colorful arena walls
        love.graphics.setColor(0.3, 0.2, 0.4) -- Purple left wall
        love.graphics.rectangle("fill", 0, 0, 50, height)
        love.graphics.setColor(0.4, 0.2, 0.3) -- Purple right wall
        love.graphics.rectangle("fill", width - 50, 0, 50, height)
        
        -- Draw arena ceiling
        love.graphics.setColor(0.1, 0.1, 0.2) -- Darker blue ceiling
        love.graphics.rectangle("fill", 0, 0, width, 50)
        
        -- Draw white billboard for character
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", 550, 50, 100, 100)
        love.graphics.setColor(0, 0, 0)
        love.graphics.setFont(love.graphics.newFont(48))
        love.graphics.print(self.currentCharacter.character, 580, 70)
        
        -- Draw players
        for _, controller in ipairs(self.controllers) do
            controller.player:draw()
        end
        
        -- Draw boxes
        for _, box in ipairs(self.boxes) do
            love.graphics.setColor(0, 1, 0)
            love.graphics.rectangle("fill", box.x, box.y, 20, 20)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(box.meaning, box.x, box.y - 20)
        end
        
        -- Draw scores
        for i, controller in ipairs(self.controllers) do
            love.graphics.setColor(controller.player.color)
            love.graphics.print("Player " .. i .. ": " .. controller.player.score, 50, 50 + (i-1) * 30)
        end
    end
end

function Game:spawnNewCharacter()
    local filteredChars = {}
    for _, char in ipairs(characters) do
        if char.language == self.selectedLanguage then
            table.insert(filteredChars, char)
        end
    end
    self.currentCharacter = filteredChars[love.math.random(#filteredChars)]
end

function Game:spawnBox()
    local box = {
        x = love.math.random(100, 1100),
        y = love.math.random(100, 500),
        meaning = self.currentCharacter.meaning
    }
    table.insert(self.boxes, box)
end

function Game:checkCollisions()
    -- Check player-box collisions
    for _, controller in ipairs(self.controllers) do
        if not controller.player.heldBox then
            for i, box in ipairs(self.boxes) do
                if self:checkCollision(controller.player, box) then
                    controller.player.heldBox = box
                    table.remove(self.boxes, i)
                    break
                end
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
    return a.x < b.x + 20 and
           a.x + a.width > b.x and
           a.y < b.y + 20 and
           a.y + a.height > b.y
end

return Game 