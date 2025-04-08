-- Logger module for Language Arena
-- Provides logging functionality for debugging

local logger = {
    logFile = nil,
    logPath = "game.log"
}

function logger:init()
    -- Try to open the log file in append mode
    local success, file = pcall(function()
        return io.open(self.logPath, "a")
    end)
    
    if success and file then
        self.logFile = file
        self:info("Logger initialized")
    else
        -- If we can't write to the file, just print to console
        print("Warning: Could not open log file, falling back to console output")
        self.logFile = false -- Use false to indicate console-only mode
    end
end

function logger:log(level, message, ...)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local formattedMessage = string.format(message, ...)
    local logEntry = string.format("[%s] [%s] %s", timestamp, level, formattedMessage)
    
    -- Always print to console
    print(logEntry)
    
    -- If we have a file, write to it too
    if self.logFile and self.logFile ~= false then
        self.logFile:write(logEntry .. "\n")
        self.logFile:flush()
    end
end

function logger:info(message, ...)
    self:log("INFO", message, ...)
end

function logger:error(message, ...)
    self:log("ERROR", message, ...)
end

function logger:close()
    if self.logFile and self.logFile ~= false then
        self.logFile:close()
        self.logFile = nil
    end
end

-- Initialize the logger
logger:init()

return logger 