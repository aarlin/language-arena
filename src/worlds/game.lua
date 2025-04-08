local Concord = require("lib.concord")
local Components = require("src.components.components")
local Constants = require("constants")
local logger = require("lib.logger")

local Game = Concord.world()

function Game:emit(event, ...)
    if event == "load" then
        logger:info("Loading game world")
        
        -- Create player entity
        local player = self:createEntity()
        player:give("player", "Player 1", {1, 1, 1}, "default")
        player:give("position", 100, Constants.GROUND_Y - Constants.PLAYER_HEIGHT)
        player:give("velocity", 0, 0)
        player:give("size", Constants.PLAYER_WIDTH, Constants.PLAYER_HEIGHT)
        
        -- Set up controller if available
        local joysticks = love.joystick.getJoysticks()
        if #joysticks > 0 then
            local controls = {
                left = "leftx",
                jump = "a",
                down = "b",
                kick = "leftshoulder",
                start = "start",
                back = "back"
            }
            player:give("controller", joysticks[1], controls)
        end
    elseif event == "update" then
        local dt = ...
        self:emit("update", dt)
    elseif event == "draw" then
        self:emit("draw")
    elseif event == "gamepadpressed" then
        local joystick, button = ...
        if button == "start" then
            return "title"
        end
    end
end

return Game 