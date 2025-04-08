local Concord = require("lib.concord")

local Dimensions = Concord.component("dimensions", function(self, width, height)
    self.width = width or 0
    self.height = height or 0
end)

return Dimensions 