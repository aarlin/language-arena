local Concord = require("lib.concord.init")
local Constants = require("constants")
local logger = require("logger")

-- Character component
local Character = Concord.component("character", function(self, characterType, meaning)
    self.characterType = characterType or "default"
    self.meaning = meaning or ""
    self.isEnabled = true
    self.isSelected = false
    
    -- Load character image
    local imagePath = "assets/characters/" .. self.characterType .. "/idle/0001.png"
    local success, image = pcall(function()
        return love.graphics.newImage(imagePath)
    end)
    
    if success then
        self.image = image
        logger:info("Loaded character image: %s", imagePath)
    else
        self.image = nil
        logger:error("Failed to load character image: %s - %s", imagePath, image)
    end
    
    return self
end)

return Character 