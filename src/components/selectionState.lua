local Concord = require("lib.concord.init")
local Constants = require("constants")
local logger = require("logger")

-- SelectionState component
local SelectionState = Concord.component("selectionState", function(self)
    self.isSelecting = false
    self.selectedIndex = 1
    self.cooldown = 0
    self.cooldownDuration = 0.2  -- 200ms cooldown between selections
    
    return self
end)

return SelectionState 