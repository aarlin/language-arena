local Concord = require("lib.concord")
local Constants = require("constants")
local logger = require("logger")

local GameOver = Concord.world()

function GameOver:emit(event, ...)
    if event == "load" then
        logger:info("Loading game over screen")
    elseif event == "update" then
        local dt = ...
        -- For now, just transition back to title
        return "title"
    elseif event == "draw" then
        -- Draw game over screen
        love.graphics.setColor(1, 0, 0)
        love.graphics.printf("GAME OVER", 
            0, Constants.SCREEN_HEIGHT / 2 - 20, Constants.SCREEN_WIDTH, "center")
    end
end

return GameOver 