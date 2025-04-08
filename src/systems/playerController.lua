local Concord = require("lib.concord")

local playerControls = require("src.components.playerControls")

local PlayerController = Concord.system({
    pool = {"playerControls"}
})

function PlayerController:fixedUpdate(dt)
   local world = self:getWorld()

   for _, e in ipairs(self.pool) do
      local playerControls = e[playerControls]

      local controller = playerControls.controller

      controller:update()

      local x, y = controller:get("move")

      local anim
      if x == 0 and y == 0 then
         anim = "idle"
      elseif x > y then
         anim = "walk_right"
      elseif x < -y then
         anim = "walk_left"
      else
         anim = "walk_down"
      end


   end
end


return PlayerController
