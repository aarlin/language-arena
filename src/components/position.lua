local Concord = require("lib.concord")

local Position = Concord.component("position", function(self, x, y)
    self.x = x or 0
    self.y = y or 0
end)

return Position 