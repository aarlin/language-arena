local Concord = require("lib.concord")
local Constants = require("constants")
local logger = require("logger")
local ECS = require("ecs")

local Title = Concord.world()

-- Store the player entity
local player = nil

function Title:emit(event, ...)
    if event == "load" then
        -- Initialize ECS if needed
        if not ECS.world then
            ECS:init()
        end
        
        -- Create the player
        player = ECS:createPlayer(
            Constants.SCREEN_WIDTH / 2,
            Constants.GROUND_Y - Constants.PLAYER_HEIGHT,
            {love.math.random(), love.math.random(), love.math.random()},
            nil,
            nil,
            false
        )
    elseif event == "update" then
        local dt = ...
        
        -- Update ECS
        if ECS.world then
            ECS.world:emit("update", dt)
        end
        
        -- Check for start button press
        if player and player.player_controls and player.player_controls.controller then
            if player.player_controls.controller:pressed("start") then
                logger:info("Start button pressed, transitioning to character select")
                return "character_select"
            end
        end
    elseif event == "draw" then
        -- Draw title screen
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("LANGUAGE ARENA", 
            0, Constants.SCREEN_HEIGHT / 3, Constants.SCREEN_WIDTH, "center")
        love.graphics.printf("Press START to begin", 
            0, Constants.SCREEN_HEIGHT / 2, Constants.SCREEN_WIDTH, "center")
    end
end

return Title 