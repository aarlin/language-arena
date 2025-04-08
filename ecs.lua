-- ECS (Entity Component System) setup using Concord
local Concord = require("lib.concord")
local Constants = require("constants")

-- Import components
local Position = require("components.position")
local Velocity = require("components.velocity")
local Dimensions = require("components.dimensions")
local Player = require("components.player")
local Box = require("components.box")
local Controller = require("components.controller")
local Animation = require("components.animation")
local PlayerControls = require("components.player_controls")

-- Import systems
local PlayerMovement = require("systems.player_movement")
local BoxMovement = require("systems.box_movement")
local Collision = require("systems.collision")
local PlayerCombat = require("systems.player_combat")
local Rendering = require("systems.rendering")

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
        error("Concord library not properly loaded. Check the path to lib.concord")
    end
    
    -- Register components with Concord
    self:registerComponents()
    
    -- Create a new world
    self.world = Concord.world()
    if not self.world then
        error("Failed to create Concord world")
    end
    
    -- Register all systems
    self:registerSystems()
    
    -- Create initial entities
    self:createInitialEntities()
    
    -- Return self to allow method chaining
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
    safeRegister("player_controls", PlayerControls)
end

-- Register all systems
function ECS:registerSystems()
    -- Register systems in the order they should be executed
    self.world:addSystem(PlayerMovement)
    self.world:addSystem(BoxMovement)
    self.world:addSystem(Collision)
    self.world:addSystem(PlayerCombat)
    self.world:addSystem(Rendering)
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
    local entity = self.world:newEntity()
        :give("player", {
            name = "Player",
            score = 0,
            characterType = "default",
            speed = Constants.PLAYER_SPEED,
            runSpeed = Constants.PLAYER_RUN_SPEED,
            jumpForce = Constants.PLAYER_JUMP_FORCE,
            gravity = Constants.PLAYER_GRAVITY,
            isJumping = false,
            isRunning = false,
            isKicking = false,
            isKnockback = false,
            isInvulnerable = false,
            isImmobile = false,
            facingRight = true,
            kickTimer = 0,
            knockbackTimer = 0,
            invulnerabilityTimer = 0,
            immobilityTimer = 0
        })
        :give("position", {
            x = x,
            y = y
        })
        :give("velocity", {x = 0, y = 0})
        :give("dimensions", {
            width = Constants.PLAYER_WIDTH,
            height = Constants.PLAYER_HEIGHT
        })
        :give("player_controls")
        :give("animation", {
            currentAnimation = "idle",
            currentFrame = 1,
            frameTimer = 0
        })
    
    return entity
end

-- Create a box entity
function ECS:createBox(x, y, character, speed, meaning, isPoop)
    local entity = self.world:entity()
        :give("box", {
            character = character,
            meaning = meaning,
            isPoop = isPoop
        })
        :give("position", {
            x = x,
            y = y
        })
        :give("velocity", {
            x = 0,
            y = speed
        })
        :give("dimensions", {
            width = Constants.BOX_WIDTH,
            height = Constants.BOX_HEIGHT
        })
    
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