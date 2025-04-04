local Game = require("game")

local game

function love.load()
    game = Game.new()
end

function love.update(dt)
    game:update(dt)
end

function love.draw()
    game:draw()
end

function love.gamepadpressed(joystick, button)
    game:gamepadpressed(joystick, button)
end

function love.gamepadreleased(joystick, button)
    game:gamepadreleased(joystick, button)
end

function love.joystickadded(joystick)
    if joystick:isGamepad() then
        game:setupControllers()
    end
end

function love.joystickremoved(joystick)
    game:setupControllers()
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end 