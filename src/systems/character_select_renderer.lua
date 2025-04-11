local Concord = require("lib.concord.init")
local Constants = require("constants")
local logger = require("logger")

-- Character select renderer system
local CharacterSelectRenderer = Concord.system({
    players = {"player", "character", "selectionState"}
})

function CharacterSelectRenderer:draw()
    for _, entity in ipairs(self.players) do
        local player = entity.player
        local character = entity.character
        local selectionState = entity.selectionState
        
        -- Only render for non-bot players
        if not player.isBot then
            -- Draw character selection grid
            self:drawCharacterGrid(player, character, selectionState)
        end
    end
end

function CharacterSelectRenderer:drawCharacterGrid(player, character, selectionState)
    -- Grid settings
    local gridX = Constants.GRID_START_X
    local gridY = Constants.GRID_START_Y
    local cellSize = Constants.GRID_CELL_SIZE
    local cellsPerRow = Constants.GRID_CELLS_PER_ROW
    local startX = gridX - (cellSize * cellsPerRow) / 2
    local startY = gridY - (cellSize * cellsPerRow) / 2
    
    -- Draw grid title
    love.graphics.setColor(Constants.COLORS.WHITE)
    love.graphics.setFont(player.font)
    local gridTitle = "Character Selection"
    local gridTitleWidth = player.font:getWidth(gridTitle)
    love.graphics.print(gridTitle, gridX - gridTitleWidth/2, startY - 40)
    
    -- Draw grid cells
    for i, char in ipairs(Constants.CHARACTERS) do
        local row = math.floor((i-1) / cellsPerRow)
        local col = (i-1) % cellsPerRow
        
        local x = startX + col * cellSize
        local y = startY + row * cellSize
        
        -- Draw cell background
        if i == selectionState.selectedIndex then
            -- Selected cell
            love.graphics.setColor(Constants.COLORS.YELLOW)
        else
            -- Normal cell
            love.graphics.setColor(Constants.COLORS.DARK_GRAY_TRANSPARENT)
        end
        love.graphics.rectangle("fill", x, y, cellSize, cellSize)
        
        -- Draw cell border
        love.graphics.setColor(Constants.COLORS.WHITE)
        love.graphics.rectangle("line", x, y, cellSize, cellSize)
        
        -- Draw character
        love.graphics.setColor(char.color)
        love.graphics.setFont(player.cjkFont)
        local charText = char.character
        local charWidth = player.cjkFont:getWidth(charText)
        local charHeight = player.cjkFont:getHeight()
        love.graphics.print(charText, x + (cellSize - charWidth)/2, y + (cellSize - charHeight)/2)
        
        -- Draw meaning
        love.graphics.setColor(Constants.COLORS.WHITE)
        love.graphics.setFont(player.smallFont)
        local meaningText = char.meaning
        local meaningWidth = player.smallFont:getWidth(meaningText)
        love.graphics.print(meaningText, x + (cellSize - meaningWidth)/2, y + cellSize - 20)
        
        -- Draw enabled/disabled indicator
        if character.isEnabled then
            love.graphics.setColor(Constants.COLORS.GREEN)
        else
            love.graphics.setColor(Constants.COLORS.RED)
        end
        love.graphics.circle("fill", x + 5, y + 5, 5)
    end
end

return CharacterSelectRenderer 