local Concord = require("lib.concord")

-- Component to track character selection state for a player
local selectionState = Concord.component("selectionState", function(c)
    c.characterId = nil -- ID of the selected character (e.g., "raccoon")
    c.locked = false      -- Whether the player has locked in their choice
    c.dpadPressed = false -- To handle single D-pad presses
    c.buttonStates = {    -- To handle single button presses
        a = false,
        b = false
    }
end) 

return selectionState