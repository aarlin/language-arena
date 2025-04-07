-- Game constants
local Constants = {}

-- Game settings
Constants.GAME_DURATION = 120  -- 2 minutes game time
Constants.CHARACTER_CHANGE_MIN_TIME = 15  -- Minimum time between character changes
Constants.CHARACTER_CHANGE_MAX_TIME = 25  -- Maximum time between character changes
Constants.SPAWN_INTERVAL = 2  -- Time between box spawns
Constants.SCREEN_WIDTH = love._console == "Switch" and 1280 or 1920  -- Game screen width
Constants.SCREEN_HEIGHT = love._console == "Switch" and 720 or 1080  -- Game screen height
Constants.GROUND_Y = Constants.SCREEN_HEIGHT - 50  -- Y position of the ground (100 pixels from bottom)

-- Player settings
Constants.PLAYER_SPEED = 300  -- Base movement speed
Constants.PLAYER_RUN_SPEED = 600  -- Running speed
Constants.PLAYER_JUMP_FORCE = 500  -- Jump force
Constants.PLAYER_GRAVITY = 1000  -- Gravity force
Constants.PLAYER_WIDTH = 100  -- Player width (reduced from 415)
Constants.PLAYER_HEIGHT = 100  -- Player height (reduced from 532)
Constants.PLAYER_INVULNERABILITY_DURATION = 2  -- Seconds of invulnerability after being hit
Constants.PLAYER_IMMOBILITY_DURATION = 1  -- Seconds of immobility after being hit
Constants.PLAYER_ANIMATION_SPEED = 0.1  -- Animation frame duration
Constants.PLAYER_KICK_DURATION = 0.5  -- Duration of kick animation
Constants.PLAYER_KO_DURATION = 1  -- Duration of KO animation
Constants.PLAYER_DANCE_DURATION = 3  -- Duration of dance animation

-- Hitbox settings
Constants.HITBOX_WIDTH = 100  -- Width of hitbox
Constants.HITBOX_HEIGHT = 100  -- Height of hitbox
Constants.HITBOX_OFFSET = 0  -- Offset of hitbox from player center
Constants.HITBOX_X_OFFSET = 0  -- Horizontal offset of hitbox
Constants.HITBOX_Y_OFFSET = 0  -- Vertical offset of hitbox

-- Font sizes
Constants.FONT_SIZE = 24  -- Default font size
Constants.SMALL_FONT_SIZE = 16  -- Small font size
Constants.TITLE_FONT_SIZE = 48  -- Title font size
Constants.SUBTITLE_FONT_SIZE = 24  -- Subtitle font size
Constants.INSTRUCTION_FONT_SIZE = 18  -- Instruction font size
Constants.CJK_FONT_SIZE = 24  -- CJK font size

-- Visual offsets
Constants.MODEL_OFFSET_X = 0  -- Horizontal offset for player model
Constants.MODEL_OFFSET_Y = 0  -- Vertical offset for player model
Constants.COLLECTION_OFFSET_X = 0  -- Horizontal offset for collection box
Constants.COLLECTION_OFFSET_Y = 0  -- Vertical offset for collection box
Constants.DEBUG_LABEL_OFFSET = 20  -- Offset for debug labels

-- Game mechanics
Constants.KNOCKBACK_FORCE_X = 800  -- Horizontal knockback force (increased to move players the full distance)
Constants.KNOCKBACK_FORCE_Y = 10  -- Vertical knockback force
Constants.KNOCKBACK_DISTANCE = 100  -- Distance to push a player when knocked back
Constants.KNOCKBACK_DURATION = 1.0  -- Duration of knockback effect in seconds
Constants.KICK_HITBOX_WIDTH = 50  -- Width of kick hitbox
Constants.KICK_HITBOX_HEIGHT = 100  -- Height of kick hitbox
Constants.KICK_HITBOX_OFFSET_X = 100  -- Horizontal offset of kick hitbox
Constants.KICK_HITBOX_OFFSET_Y = 50  -- Vertical offset of kick hitbox

-- Character grid settings
Constants.GRID_CELL_SIZE = 60  -- Size of each cell in character grid
Constants.GRID_CELLS_PER_ROW = 8  -- Number of cells per row in character grid
Constants.GRID_START_X = 600  -- Starting X position of grid
Constants.GRID_START_Y = 600  -- Starting Y position of grid

-- Score settings
Constants.CORRECT_MATCH_SCORE = 10  -- Points for correct character match
Constants.WRONG_MATCH_PENALTY = 10  -- Points lost for wrong character match

-- Box settings
Constants.BOX_WIDTH = 48  -- Width of falling boxes
Constants.BOX_HEIGHT = 48  -- Height of falling boxes
Constants.BOX_MIN_SPEED = 100  -- Minimum fall speed
Constants.BOX_MAX_SPEED = 200  -- Maximum fall speed
Constants.BOX_SPAWN_MIN_X = 100  -- Minimum X position for box spawn
Constants.BOX_SPAWN_MAX_X = 1100  -- Maximum X position for box spawn
Constants.BOX_SPAWN_Y = -50  -- Y position for box spawn (above screen)

-- Hitbox expansion
Constants.HITBOX_EXPANSION_X = 1  -- Horizontal expansion factor for hitbox
Constants.HITBOX_EXPANSION_Y = 1  -- Vertical expansion factor for hitbox

-- Visual settings
Constants.PLAYER_SCALE = 0.25  -- Scale factor for player model
Constants.PLAYER_DRAW_MULTIPLIER = 3.5  -- Multiplier for draw coordinates

-- Colors
Constants.COLORS = {
    RED = {1, 0, 0, 1},
    GREEN = {0, 1, 0, 1},
    BLUE = {0, 0, 1, 1},
    YELLOW = {1, 1, 0, 1},
    CYAN = {0, 1, 1, 1},
    MAGENTA = {1, 0, 1, 1},
    WHITE = {1, 1, 1, 1},
    BLACK = {0, 0, 0, 1},
    ORANGE = {1, 0.5, 0, 1},
    PURPLE = {0.5, 0, 0.5, 1},
    BROWN = {0.6, 0.3, 0, 1},
    GRAY = {0.5, 0.5, 0.5, 1},
    LIGHT_BLUE = {0.5, 0.8, 1, 1},
    LIGHT_GREEN = {0.5, 1, 0.5, 1},
    PINK = {1, 0.5, 0.5, 1},
    TRANSPARENT = {0, 0, 0, 0},
    SEMI_TRANSPARENT = {1, 1, 1, 0.5},
    RED_TRANSPARENT = {1, 0, 0, 0.5},
    GREEN_TRANSPARENT = {0, 1, 0, 0.5},
    ORANGE_TRANSPARENT = {1, 0.5, 0, 0.5},
    DARK_GRAY_TRANSPARENT = {0.2, 0.2, 0.2, 0.8}
}

return Constants 