-- Box component
local Concord = require("lib.concord.init")
local Constants = require("constants")

local Box = Concord.component("box", function(c, meaning, speed, characterType, imagePath, isPoop)
    c.meaning = meaning or ""
    c.speed = speed or Constants.BOX_MIN_SPEED
    c.collected = false
    c.characterType = characterType or ""  -- The character type this box represents
    c.imagePath = imagePath or ""  -- Path to the image for this box
    c.isPoop = isPoop or false  -- Whether this is a poop that causes knockback
end)

return Box 