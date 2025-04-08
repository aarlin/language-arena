-- Input Manager
local baton = require("lib.baton")
local logger = require("logger")

local InputManager = {
    input = nil,
    controls = {
        left = {'key:left', 'key:a', 'axis:leftx-', 'button:dpleft'},
        right = {'key:right', 'key:d', 'axis:leftx+', 'button:dpright'},
        up = {'key:up', 'key:w', 'axis:lefty-', 'button:dpup'},
        down = {'key:down', 'key:s', 'axis:lefty+', 'button:dpdown'},
        jump = {'key:space', 'button:a'},
        kick = {'key:x', 'button:leftshoulder'},
        start = {'key:return', 'button:start'},
        back = {'key:escape', 'button:back'}
    },
    pairs = {
        move = {'left', 'right', 'up', 'down'}
    }
}

function InputManager:init()
    local joystick = love.joystick.getJoysticks()[1]
    self.input = baton.new({
        controls = self.controls,
        pairs = self.pairs,
        joystick = joystick
    })
    logger:info("Input manager initialized with joystick: %s", joystick and joystick:getName() or "none")
end

function InputManager:update(dt)
    if self.input then
        self.input:update()
    end
end

function InputManager:getInput()
    return self.input
end

return InputManager 