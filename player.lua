local Player = {}
Player.__index = Player

function Player.new(x, y, color, controls)
    local self = setmetatable({}, Player)
    self.x = x
    self.y = y
    self.width = 32
    self.height = 48
    self.color = color
    self.controls = controls
    self.velocity = {x = 0, y = 0}
    self.speed = 200
    self.jumpForce = -400
    self.gravity = 800
    self.isGrounded = false
    self.canDoubleJump = false
    self.hasDoubleJumped = false
    self.isPunching = false
    self.punchCooldown = 0
    self.knockbackTime = 0
    self.heldBox = nil
    self.score = 0
    self.controller = nil
    
    return self
end

function Player:setController(joystick)
    self.controller = joystick
end

function Player:update(dt)
    if not self.controller then return end
    
    -- Handle knockback
    if self.knockbackTime > 0 then
        self.knockbackTime = self.knockbackTime - dt
        self.x = self.x + self.knockbackVelocity.x * dt
        self.y = self.y + self.knockbackVelocity.y * dt
        return
    end
    
    -- Handle punch cooldown
    if self.punchCooldown > 0 then
        self.punchCooldown = self.punchCooldown - dt
    end
    
    -- Movement using right stick
    local axisX = self.controller:getAxis(self.controls.left)
    local axisY = self.controller:getAxis("righty") -- Add vertical movement
    
    -- Invert the axis values for proper movement
    axisX = -axisX
    axisY = -axisY
    
    -- Horizontal movement
    if math.abs(axisX) > 0.2 then  -- Dead zone
        self.velocity.x = axisX * self.speed
    else
        self.velocity.x = 0
    end
    
    -- Vertical movement (only when not grounded)
    if not self.isGrounded and math.abs(axisY) > 0.2 then
        self.velocity.y = axisY * self.speed
    end
    
    -- Apply gravity
    self.velocity.y = self.velocity.y + self.gravity * dt
    
    -- Update position
    self.x = self.x + self.velocity.x * dt
    self.y = self.y + self.velocity.y * dt
    
    -- Ground collision
    if self.y > 600 - self.height then
        self.y = 600 - self.height
        self.velocity.y = 0
        self.isGrounded = true
        self.hasDoubleJumped = false
    end
end

function Player:gamepadpressed(button)
    if not self.controller then return end
    
    if button == self.controls.jump and self.isGrounded then
        self.velocity.y = self.jumpForce
        self.isGrounded = false
        self.canDoubleJump = true
    elseif button == self.controls.jump and self.canDoubleJump and not self.hasDoubleJumped then
        self.velocity.y = self.jumpForce * 0.8
        self.hasDoubleJumped = true
    elseif button == self.controls.down and not self.isGrounded then
        self.velocity.y = 800
    elseif button == self.controls.punch and self.punchCooldown <= 0 then
        self:punch()
    end
end

function Player:draw()
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    
    -- Draw punch animation
    if self.isPunching then
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("fill", self.x + self.width, self.y + self.height/2, 20, 10)
    end
    
    -- Draw held box
    if self.heldBox then
        love.graphics.setColor(0, 1, 0)
        love.graphics.rectangle("fill", self.x + self.width/2 - 10, self.y - 20, 20, 20)
    end
end

function Player:punch()
    self.isPunching = true
    self.punchCooldown = 0.5
    -- Reset punch animation after 0.2 seconds
    love.timer.after(0.2, function()
        self.isPunching = false
    end)
end

function Player:takeKnockback(velocity)
    self.knockbackTime = 0.5
    self.knockbackVelocity = velocity
    if self.heldBox then
        self.heldBox = nil
    end
end

return Player 