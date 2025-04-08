local Concord = require("lib.concord")
local Baton = require("lib.baton")
local logger = require("logger")

local PlayerControls = Concord.component("player_controls", function(e)
   print("Initializing player controls component")
   logger:info("Initializing player controls component")
   
   local controls = {
      up = {"key:up", "key:w", "axis:lefty-", "button:dpup"},
      down = {"key:down", "key:s", "axis:lefty+", "button:dpdown"},
      left = {"key:left", "key:a", "axis:leftx-", "button:dpleft"},
      right = {"key:right", "key:d", "axis:leftx+", "button:dpright"},
      jump = {"key:space", "button:a"},
      kick = {"key:x", "button:x"},
      start = {"key:return", "button:start"}
   }

   local pairs = {
      move = {"left", "right", "up", "down"}
   }

   local joystick = love.joystick.getJoysticks()[1]
   print("Using joystick:", joystick and joystick:getName() or "none")
   logger:info("Using joystick: %s", joystick and joystick:getName() or "none")

   e.controller = Baton.new({
      controls = controls,
      pairs = pairs,
      joystick = joystick
   })
   
   print("Player controls initialized successfully")
   logger:info("Player controls initialized successfully")
end)

return PlayerControls 