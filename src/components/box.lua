local Concord = require("lib.concord")

local Box = Concord.component("box", function(self, character, meaning, isPoop)
    self.character = character or ""
    self.meaning = meaning or ""
    self.isPoop = isPoop or false
end)

return Box 