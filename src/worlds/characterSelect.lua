local Concord = require("lib.concord")
local Constants = require("constants")
local logger = require("lib.logger")
local PlayerDetector = require("src.systems.playerDetector")
local CharacterSelector = require("src.systems.characterSelector")
local CharacterSelectRenderer = require("src.systems.characterSelectRenderer")
local PlayerController = require("src.systems.playerController")

local CharacterSelect = Concord.world()

-- Initialize world state
CharacterSelect.players = {}
CharacterSelect.selectedCharacters = {}
CharacterSelect.connectedJoysticks = {}
-- Add systems
-- CharacterSelect:addSystem(PlayerDetector, "update")
-- CharacterSelect:addSystem(CharacterSelector, "update")
CharacterSelect:addSystem(PlayerController, "fixedUpdate")
CharacterSelect:addSystem(CharacterSelectRenderer, "draw")

return CharacterSelect
