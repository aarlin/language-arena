local Concord = require("lib.concord")
local Constants = require("constants")
local logger = require("lib.logger")
local PlayerDetector = require("src.systems.playerDetector")
local CharacterSelector = require("src.systems.characterSelector")
local CharacterSelectRenderer = require("src.systems.characterSelectRenderer")

local CharacterSelect = Concord.world()

-- Initialize world state
CharacterSelect.players = {}
CharacterSelect.selectedCharacters = {}
CharacterSelect.connectedJoysticks = {}
-- Add systems
-- CharacterSelect:addSystem(PlayerDetector, "update")
-- CharacterSelect:addSystem(CharacterSelector, "update")
CharacterSelect:addSystem(CharacterSelectRenderer, "draw")

return CharacterSelect

-- function CharacterSelect:emit(event, ...)
--     if event == "load" then
--         logger:info("Loading character select screen")
        
        
--         -- Initialize renderer
--         if self.systems[3] and self.systems[3].init then
--             self.systems[3]:init()
--         end
--     elseif event == "update" then
--         local dt = ...
--         -- Update systems
--         if self.systems[1] and self.systems[1].update then
--             local result = self.systems[1]:update(dt)
--             if result then return result end
--         end
--         if self.systems[2] and self.systems[2].update then
--             local result = self.systems[2]:update(dt)
--             if result then return result end
--         end
--     elseif event == "draw" then
--         -- Draw systems
--         if self.systems[3] and self.systems[3].draw then
--             self.systems[3]:draw()
--         end
--     elseif event == "gamepadpressed" then
--         local joystick, button = ...
--         if button == "back" then
--             return "title"
--         end
--     end
-- end

-- return CharacterSelect 