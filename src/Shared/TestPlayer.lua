--[[
	This service allows you to make shallow players that are basically a datamodel and character.
	This is useful for testing in Play Solo in the lobby when you want to just test things induvidually
]]

local TestPlayer = {}

local logger

local function createValueObject(index, value)
	local valueObject;
	if typeof(value) == "string" then
		valueObject = Instance.new("StringValue")
	elseif typeof(value) == "number" then
		valueObject = Instance.new("NumberValue")
	elseif typeof(value) == "Instance" then
		valueObject = Instance.new("ObjectValue")
	elseif typeof(value) == "boolean" then
		valueObject = Instance.new("BoolValue")
	elseif typeof(value) == "BrickColor" then
		valueObject = Instance.new("BrickColorValue")
	else
		error("Unknown value type " .. typeof(value) .. " for property " .. index)
	end

	valueObject.Name = index
	valueObject.Value = value

	return valueObject
end

local function getState(rootPlayer, overloadProperties)
	local state = game:GetService("Players"):FindFirstChild(overloadProperties.Name)

	if state then 
		return state
	end

	if game:GetService("RunService"):IsServer() then
		Instance.new("BoolValue", overloadProperties.Character).Name = "IsTestPlayer"

		local state = Instance.new("StringValue", game.Players)
		state.Name = overloadProperties.Name

		overloadProperties.RootPlayer = rootPlayer

		local mockBackpack = Instance.new("Folder", state)
		mockBackpack.Name = "MockBackpack"
		overloadProperties.Backpack = mockBackpack

		for property, value in pairs(overloadProperties) do 
			createValueObject(property, value).Parent = state
		end

		return state
	else
		error("Could not load state for local player " .. overloadProperties.Name)
	end
end

function TestPlayer.new(rootPlayer, overloadProperties)
	return TestPlayer.fromState(getState(rootPlayer, overloadProperties))
end

function TestPlayer.fromState(state)
	local isServer = game:GetService("RunService"):IsServer()
	
	local proxyObject = {}
	
	if isServer then
		function proxyObject:LoadCharacter()
			logger:Log("LoadCharacter called but is not implemented")
		end

		proxyObject.CharacterAdded = TestPlayer.Shared.Event.new()
	end

	return setmetatable(proxyObject, {
		__index = function(tab, ind)
			local value = rawget(tab, ind)
			if value then
				return value
			end

			local valueObject = state:FindFirstChild(ind)

			if valueObject then
				return valueObject.Value
			else
				logger:Warn("Did not intercept call:", ind)
				return state.RootPlayer.Value[ind]
			end
		end;

		__newindex = function(_, ind, value)
			if not isServer then
				error("Test player object is readonly")
			end

			local valueObject = state:FindFirstChild(ind)

			if valueObject then
				valueObject.Value = value
			else
				createValueObject(ind, value).Parent = state
			end
		end;

		__tostring = function()
			return proxyObject.Name
		end
	})
end

function TestPlayer:Init()
	logger = self.Shared.Logger.new()
end


return TestPlayer