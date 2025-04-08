local Concord = require("lib.concord")
local logger = require("logger")

local PlayerController = Concord.system({player = true, player_controls = true, animation = true})

function PlayerController:update(dt)
   for _, e in ipairs(self.pool) do
      local controller = e.player_controls.controller
      local animation = e.animation

      -- Update the controller
      controller:update()

      -- Get movement from axis pair
      local x, y = controller:get("move")
      
      -- Debug input
      if controller:pressed("start") then
         print("Start button pressed")
         logger:info("Start button pressed")
      end

      -- Update position based on movement
      e.position.x = e.position.x + x * 200 * dt
      e.position.y = e.position.y + y * 200 * dt

      -- Update animation based on movement
      local anim
      if x == 0 and y == 0 then
         anim = "idle"
      elseif x > 0 then
         anim = "walk_right"
      elseif x < 0 then
         anim = "walk_left"
      else
         anim = "idle"
      end

      if animation.current ~= anim then
         animation:switch(anim)
      end

      -- Handle jump
      if controller:pressed("jump") then
         print("Jump pressed")
         -- Add jump logic here
      end

      -- Handle kick
      if controller:pressed("kick") then
         print("Kick pressed")
         -- Add kick logic here
      end
   end
end

return PlayerController 