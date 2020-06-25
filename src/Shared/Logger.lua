local Logger = {}
Logger.__index = Logger

function Logger.new()
    local callerName = getfenv(2).script.Name

    local self = setmetatable({callerName = callerName}, Logger)

    return self
end

function Logger:FormatOutput(...)
    local output = {}
    for _, v in pairs({...}) do
        output[#output + 1] = tostring(v)
    end

    return ("[ %s ] : %s"):format(self.callerName, table.concat(output, ""))
end

function Logger:Log(...) print(self:FormatOutput(...)) end

function Logger:Warn(...) warn(self:FormatOutput(...)) end

return Logger
