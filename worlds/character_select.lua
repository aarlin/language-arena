local Concord = require("lib.concord")
local Constants = require("constants")
local logger = require("logger")

local CharacterSelect = Concord.world()

function CharacterSelect:emit(event, ...)
    if event == "load" then
        logger:info("Loading character select screen")
    elseif event == "update" then
        local dt = ...
        -- For now, just transition to game
        return "game"
    elseif event == "draw" then
        -- Draw character selection screen
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Select your character", 
            0, Constants.SCREEN_HEIGHT / 3, Constants.SCREEN_WIDTH, "center")
    end
end

return CharacterSelect 