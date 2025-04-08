local Concord = require("lib.concord")
local Constants = require("constants")
local logger = require("lib.logger")

local Title = Concord.world()

function Title:emit(event, ...)
    if event == "load" then
        logger:info("Loading title screen")
    elseif event == "update" then
        local dt = ...
        -- Check for keyboard input
        if love.keyboard.isDown("return") or love.keyboard.isDown("space") then
            CurrentWorld = require("src.worlds.character_select")
        end
        
        -- Check for gamepad input
        local joysticks = love.joystick.getJoysticks()
        if #joysticks > 0 then
            local joystick = joysticks[1]
            if joystick:isGamepadDown("start") or joystick:isGamepadDown("a") then
                CurrentWorld = require("src.worlds.character_select")
            end
        end
    elseif event == "draw" then
        -- Draw title screen
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Language Arena", 
            0, Constants.SCREEN_HEIGHT / 3, Constants.SCREEN_WIDTH, "center")
        love.graphics.printf("Press Enter or Start to Begin", 
            0, Constants.SCREEN_HEIGHT / 2, Constants.SCREEN_WIDTH, "center")
    elseif event == "gamepadpressed" then
        local joystick, button = ...
        if button == "start" or button == "a" then
            CurrentWorld = require("src.worlds.character_select")
        end
    end
end

return Title 