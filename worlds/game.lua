local Concord = require("lib.concord")
local Constants = require("constants")
local logger = require("logger")
local ECS = require("ecs")

local Game = Concord.world()

function Game:emit(event, ...)
    if event == "load" then
        -- Initialize ECS if needed
        if not ECS.world then
            ECS:init()
        end
    elseif event == "update" then
        local dt = ...
        
        -- Update ECS
        if ECS.world then
            ECS.world:emit("update", dt)
        end
    elseif event == "draw" then
        -- Draw ECS
        if ECS.world then
            ECS.world:emit("draw")
            
            -- Draw score
            love.graphics.setColor(1, 1, 1)
            
            -- Find player score from the ECS world
            local playerScore = 0
            
            -- Get all entities and filter for players
            for _, e in ipairs(ECS.entities) do
                if e.player then
                    playerScore = e.player.score or 0
                end
            end
            
            love.graphics.print("Score: " .. playerScore, 10, 10)
        end
    end
end

return Game 