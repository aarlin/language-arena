-- ECS (Entity Component System) setup using Concord
local Concord = require("lib.concord.init")
local Constants = require("constants")

-- Import components
local Position = require("src.components.position")
local Velocity = require("src.components.velocity")
local Dimensions = require("src.components.dimensions")
local Player = require("src.components.player")
local Box = require("src.components.box")
local Controller = require("src.components.controller")
local Animation = require("src.components.animation")
local Platform = require("src.components.platform")

-- Import systems
local PlayerMovement = require("src.systems.player_movement")
local BoxMovement = require("src.systems.box_movement")
local Collision = require("src.systems.collision")
local PlayerCombat = require("src.systems.player_combat")
local Rendering = require("src.systems.rendering")
local PlatformManager = require("src.systems.platform_manager")
local PlatformRender = require("src.systems.platform_render")
local PlatformCollision = require("src.systems.platform_collision")
local PlayerRender = require("src.systems.player_render")

-- Create the ECS world
local ECS = {
    world = nil,
    entities = {},
    systems = {},
    componentsRegistered = false
}

-- Initialize the ECS
function ECS:init()
    -- Check if Concord is properly loaded
    if not Concord or not Concord.world then
        error("Concord library not properly loaded. Check the path to lib.concord.init")
    end
    
    -- Register components with Concord
    self:registerComponents()
    
    -- Create a new world
    self.world = Concord.world.new()
    
    -- Register all systems
    self:registerSystems()
    
    -- Create initial entities
    self:createInitialEntities()
    
    return self
end

-- Register components with Concord
function ECS:registerComponents()
    -- Safely register each component with Concord
    local function safeRegister(name, component)
        local success, err = pcall(function()
            Concord.component(name, component)
        end)
        if not success then
            -- If the error is about the component already being registered, we can ignore it
            if not string.find(err, "was already registerd") then
                print("Warning: Failed to register component '" .. name .. "': " .. err)
            end
        end
    end
    
    -- Register each component
    safeRegister("position", Position)
    safeRegister("velocity", Velocity)
    safeRegister("dimensions", Dimensions)
    safeRegister("player", Player)
    safeRegister("box", Box)
    safeRegister("controller", Controller)
    safeRegister("animation", Animation)
    safeRegister("platform", Platform)
end

-- Register all systems
function ECS:registerSystems()
    -- Register systems in the order they should be executed
    self.world:addSystem(PlatformManager)
    self.world:addSystem(PlayerMovement)
    self.world:addSystem(BoxMovement)
    self.world:addSystem(PlatformCollision)
    self.world:addSystem(Collision)
    self.world:addSystem(PlayerCombat)
    self.world:addSystem(PlayerRender)
    self.world:addSystem(Rendering)
    self.world:addSystem(PlatformRender)
end

-- Create initial entities
function ECS:createInitialEntities()
    -- We'll add entities here as we create them
end

-- Update the ECS world
function ECS:update(dt)
    self.world:emit("update", dt)
end

-- Draw the ECS world
function ECS:draw()
    self.world:emit("draw")
end

-- Create a new entity
function ECS:createEntity()
    if not self.world then
        error("ECS world not initialized. Call ECS:init() first.")
    end
    local entity = Concord.entity.new(self.world)
    table.insert(self.entities, entity)
    return entity
end

-- Remove an entity
function ECS:removeEntity(entity)
    for i, e in ipairs(self.entities) do
        if e == entity then
            table.remove(self.entities, i)
            entity:destroy()
            break
        end
    end
end

-- Create a player entity
function ECS:createPlayer(x, y, color, controls, joystick, isBot)
    local entity = self:createEntity()
    
    -- Add components
    entity:give("position", x, y)
    entity:give("velocity", 0, 0)
    entity:give("dimensions", Constants.PLAYER_WIDTH, Constants.PLAYER_HEIGHT)
    entity:give("player", "Player", color, controls)
    entity:give("controller", joystick, isBot, controls)
    entity:give("animation", "idle", 1, 0)
    
    -- Set default character type if not specified
    if not entity.player.characterType then
        entity.player.characterType = "raccoon"  -- Default character
    end
    
    return entity
end

-- Create a box entity
function ECS:createBox(x, y, meaning, speed, characterType, isPoop)
    local entity = self:createEntity()
    
    -- Determine image path based on character type or if it's a poop
    local imagePath = ""
    if isPoop then
        imagePath = "assets/falling-objects/stinky.png"
    elseif characterType and characterType ~= "" then
        imagePath = "assets/falling-objects/" .. characterType .. ".png"
    end
    
    -- Add components
    entity:give("position", x, y)
    entity:give("dimensions", Constants.BOX_WIDTH, Constants.BOX_HEIGHT)
    entity:give("box", meaning, speed, characterType, imagePath, isPoop)
    
    return entity
end

-- Cleanup function
function ECS:cleanup()
    -- Clean up all entities
    for _, entity in ipairs(self.entities) do
        entity:destroy()
    end
    self.entities = {}
    
    -- Reset world
    self.world = nil
    
    -- Reset components registered flag
    self.componentsRegistered = false
end

return ECS 