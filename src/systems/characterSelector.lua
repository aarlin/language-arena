local Concord = require("lib.concord")
local logger = require("lib.logger")

-- Keep CHARACTERS definition accessible, maybe move to constants.lua or config.lua
local CHARACTERS = {
    {id = "raccoon", name = "Raccoon"},
    {id = "sheep", name = "Sheep"},
    {id = "pig", name = "Pig"},
    {id = "cow", name = "Cow"},
    {id = "chicken", name = "Chicken"},
}

local CharacterSelector = Concord.system({
    pool = {"controller"}
})

-- Helper function to check if a character is available
local function isCharacterAvailable(world, characterId)
    if not world or not world.players then return true end -- Safety check

    -- for _, pEntity in ipairs(world.players) do
    --     if pEntity:has("selectionState") and pEntity.selectionState.characterId == characterId then
    --         return false -- Character is taken
    --     end
    -- end
    return true -- Character is available
end

-- Helper function to find the index of a character by ID
local function findCharacterIndex(id)
    for i, char in ipairs(CHARACTERS) do
        if char.id == id then
            return i
        end
    end
    return nil
end

function CharacterSelector:update(dt)
    local allLocked = true
    local anyPlayers = #self.pool > 0

    for _, entity in ipairs(self.pool) do
        local controller = entity.controller
        local state = entity.selectionState
        local joystick = controller.joystick

        -- Only process input if joystick is present
        if not joystick then goto continue end

        -- D-Pad Navigation (only if not locked)
        if not state.locked then
            local dpleft = joystick:isGamepadDown(controller.controls.left)
            local dpright = joystick:isGamepadDown(controller.controls.right)

            if (dpleft or dpright) and not state.dpadPressed then
                local currentIndex = state.characterId and findCharacterIndex(state.characterId) or 0
                local direction = dpleft and -1 or 1
                local nextIndex = currentIndex

                -- Loop to find the next *available* character
                for i = 1, #CHARACTERS do
                    nextIndex = nextIndex + direction
                    -- Wrap around
                    if nextIndex > #CHARACTERS then nextIndex = 1 end
                    if nextIndex < 1 then nextIndex = #CHARACTERS end

                    if isCharacterAvailable(self.world, CHARACTERS[nextIndex].id) then
                        state.characterId = CHARACTERS[nextIndex].id
                        logger:debug("Player %s selected %s", entity.player.name, state.characterId)
                        break -- Found an available character
                    end

                    -- Prevent infinite loop if all characters are somehow taken
                    if nextIndex == currentIndex then break end
                end
                 state.dpadPressed = true
            elseif not dpleft and not dpright then
                state.dpadPressed = false
            end
        end -- end D-pad navigation

        -- A Button (Select/Lock)
        local aPressed = joystick:isGamepadDown(controller.controls.select)
        if aPressed and not state.buttonStates.a then
            if state.characterId and not state.locked then
                state.locked = true
                logger:debug("Player %s locked %s", entity.player.name, state.characterId)
            end
            state.buttonStates.a = true
        elseif not aPressed then
            state.buttonStates.a = false
        end

        -- B Button (Unlock/Back)
        local bPressed = joystick:isGamepadDown(controller.controls.back)
        if bPressed and not state.buttonStates.b then
            if state.locked then
                state.locked = false
                logger:debug("Player %s unlocked %s", entity.player.name, state.characterId)
                -- Optional: Deselect character entirely on unlock?
                -- state.characterId = nil
            else
                -- If not locked, B acts as back to title screen
                 return "title" -- Signal state change
            end
            state.buttonStates.b = true
        elseif not bPressed then
            state.buttonStates.b = false
        end

        -- Check if this player contributes to "all locked" status
        if not state.characterId or not state.locked then
            allLocked = false
        end

        ::continue::
    end -- end player loop

    -- Start Button (Check if game can start)
    -- Check only one controller for start, or designate Player 1?
    -- Let's assume any player can press Start.
    local startPressed = false
    if self.world.players and #self.world.players > 0 then
         local p1Entity = self.world.players[1] -- Check Player 1's controller for Start
         if p1Entity and p1Entity:has("controller") and p1Entity.controller.joystick then
            startPressed = p1Entity.controller.joystick:isGamepadDown(p1Entity.controller.controls.start)
         end
         -- Or check all controllers:
         -- for _, pEntity in ipairs(self.world.players) do ... end
    end

    if startPressed and anyPlayers and allLocked then
         logger:info("Selection complete, starting game.")
         -- We need to pass selected character info to the game world
         -- Store it on the world temporarily or pass via state manager
         self.world.finalSelections = {}
         for _, entity in ipairs(self.pool) do
             self.world.finalSelections[entity.player.name] = entity.selectionState.characterId
         end
         return "game" -- Signal state change
    end

    -- If B was pressed to go back, it would have returned earlier.
end

return CharacterSelector
