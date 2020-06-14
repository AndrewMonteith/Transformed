local PlayerDict = {}

local isServer = game:GetService("RunService"):IsServer()

function PlayerDict.new()
    local self = setmetatable({}, PlayerDict)

    if isServer then
        self.event = game:GetService("Players").PlayerRemoving:Connect(
                     function(player)
            self:Remove(player)
        end)
    end

    return self
end

local function hasNameProperty(ind)
    return (typeof(ind) == "Instance" and ind:IsA("Player")) or (typeof(ind) == "table" and ind.Name)
end

function PlayerDict:__index(ind)
    if hasNameProperty(ind) then
        return self[ind.Name]
    elseif typeof(PlayerDict[ind]) == "function" then
        return PlayerDict[ind]
    else
        return rawget(self, ind)
    end
end

function PlayerDict:__newindex(ind, val)
    if hasNameProperty(ind) then
        self[ind.Name] = val
    else
        rawset(self, ind, val)
    end
end

function PlayerDict:Remove(key)
    local value = self[key]

    if typeof(value) == "RBXScriptConnection" then
        value:Disconnect()
    end

    self[key] = nil
end

function PlayerDict:Update(key, value)
    self:Remove(value)
    self[key] = value
end

function PlayerDict:Destroy()
    self.event:Disconnect()
    self.event = nil

    for k in pairs(self) do
        self:Remove(k)
    end
end

function PlayerDict:RawDictionary()
    local dict = {}

    for key, val in pairs(self) do
        dict[key] = val
    end

    if self.event then
        dict.event = nil
    end

    return dict
end

return PlayerDict
