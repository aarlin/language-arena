local Concord = require("lib.concord.init")

local Platform = Concord.component("platform", function(self, isBouncy)
    self.isBouncy = isBouncy or false
    self.bounceForce = 500  -- Default bounce force
end)

return Platform 