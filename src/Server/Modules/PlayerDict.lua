local PlayerDict = {}

function PlayerDict.new()
	local self = setmetatable({}, PlayerDict)

	self.event = game:GetService("Players").PlayerRemoving:Connect(function(player)
		self:Remove(player)
	end)

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

return PlayerDict
