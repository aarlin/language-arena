-- Box Spawner System
local Concord = require("lib.concord")
local Constants = require("constants")
local logger = require("logger")
local Orbs = require("orbs")
local tick = require("lib.rxi.tick")

local BoxSpawner = Concord.system({
    players = {"player"}
})

function BoxSpawner:init()
    self.gameTimer = 0
    
    -- Create a tick timer for spawning
    self.spawnTimer = tick.delay(function()
        -- Determine if we should spawn a poop (20% chance)
        local isPoop = love.math.random() < 0.2
        
        -- Spawn a new box
        local x = love.math.random(Constants.BOX_SPAWN_MIN_X, Constants.BOX_SPAWN_MAX_X)
        local speed = love.math.random(Constants.BOX_MIN_SPEED, Constants.BOX_MAX_SPEED)
        
        -- Get a random character from the Chinese characters list or create a poop orb
        local orbData
        if isPoop then
            orbData = Orbs.createPoopOrb()
        else
            orbData = Orbs.getRandomChineseCharacter()
        end
        
        -- Create the box entity
        self:getWorld():entity()
            :give("box", {
                character = orbData.character,
                meaning = orbData.meaning,
                isPoop = isPoop,
                characterType = orbData.characterType,
                collected = false
            })
            :give("position", {
                x = x,
                y = Constants.BOX_SPAWN_Y
            })
            :give("velocity", {
                x = 0,
                y = speed
            })
            :give("dimensions", {
                width = Constants.BOX_WIDTH,
                height = Constants.BOX_HEIGHT
            })
        
        -- Log the spawn
        logger:debug("Spawned %s at (%d, %d) with speed %d", 
            isPoop and "poop" or "character", x, Constants.BOX_SPAWN_Y, speed)
            
        -- Schedule next spawn
        self.spawnTimer = tick.delay(function()
            self:spawnBox()
        end, Constants.SPAWN_INTERVAL)
    end, Constants.SPAWN_INTERVAL)
end

function BoxSpawner:update(dt)
    -- Update game timer
    self.gameTimer = self.gameTimer + dt
    
    -- Update tick timers
    tick.update(dt)
end

return BoxSpawner 