local Logger = {}
Logger.__index = Logger

function Logger.new()
    local callerName = getfenv(2).script.Name

    local self = setmetatable({callerName = callerName}, Logger)

    return self
end

function Logger:FormatOutput(...)
    local output = table.concat(self.Shared.TableUtil.Map({...}, tostring), "")

    return ("[ %s ] : %s"):format(self.callerName, output)
end

function Logger:Log(...) print(self:FormatOutput(...)) end

function Logger:Warn(...) warn(self:FormatOutput(...)) end

return Logger
