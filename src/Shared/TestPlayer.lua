--[[
	This service allows you to make shallow players that are basically a datamodel and character.
	This is useful for testing in Play Solo in the lobby when you want to just test things induvidually
]] local TestPlayer = {}

local function createValueObject(type)
    if type == "string" then
        return Instance.new("StringValue")
    elseif type == "number" then
        return Instance.new("NumberValue")
    elseif type == "Instance" then
        return Instance.new("ObjectValue")
    elseif type == "boolean" then
        return Instance.new("BoolValue")
    elseif type == "BrickColor" then
        return Instance.new("BrickColorValue")
    else
        error("Unknown value type " .. type)
    end
end

local function getState(rootPlayer, overloadProperties)
    local state = game:GetService("Players"):FindFirstChild(overloadProperties.Name)

    if state then
        return state
    end

    if game:GetService("RunService"):IsServer() then
        local state = Instance.new("StringValue", game.Players)
        state.Name = overloadProperties.Name

        overloadProperties.RootPlayer = rootPlayer

        local mockBackpack = Instance.new("Folder", state)
        mockBackpack.Name = "MockBackpack"
        overloadProperties.Backpack = mockBackpack

        for property, value in pairs(overloadProperties) do
            local isNilProperty = typeof(value) == "table"
            local objType = isNilProperty and value.type or typeof(value)

            local valObj = createValueObject(objType)
            valObj.Value = (not isNilProperty) and value or nil
            valObj.Name = property
            valObj.Parent = state
        end

        return state
    else
        error("Could not load state for local player " .. overloadProperties.Name)
    end
end

function TestPlayer.new(rootPlayer, overloadProperties, isFirstLoad)
    local testPlayer = TestPlayer.fromState(getState(rootPlayer, overloadProperties))

    if isFirstLoad then
        delay(math.random(4), function() testPlayer.CharacterAdded:Fire(testPlayer.Character) end)
    end

    return testPlayer
end

function TestPlayer.isOne(player) return typeof(player) == "table" and player.__isTestPlayer end

local Events = {}

-- We define MockEvent here rather than using the Shared Event module 
-- since this module is used by the AeroServer/AeroClient script
-- which means it cannot have any external dependencies referenced via injected properties
local function MockEvent(objId, eventId)
    if not Events[objId] then
        Events[objId] = {}
    end

    if not Events[objId][eventId] then
        Events[objId][eventId] = {}
    end

    local connections = Events[objId][eventId]
    local mockEvent = {}

    function mockEvent:Connect(func)
        connections[#connections + 1] = func
        return mockEvent
    end

    function mockEvent:Fire(...)
        for _, func in pairs(connections) do
            func(...)
        end
    end

    return mockEvent
end

function TestPlayer.fromState(state)
    local isServer = game:GetService("RunService"):IsServer()

    local proxyObject = {__isTestPlayer = true, __state = state}

    local self = setmetatable(proxyObject, {
        __index = function(tab, ind)
            local value = rawget(proxyObject, ind)
            if value then
                return value
            end

            local valueObject = state:FindFirstChild(ind)

            if valueObject then
                return valueObject.Value
            else
                warn("[TestPlayer] - Did not intercept call:", ind)
                return state.RootPlayer.Value[ind]
            end
        end,

        __newindex = function(_, index, value)
            if not isServer then
                error("[TestPlayer] - Test player object is readonly")
            elseif typeof(value) == "function" or index == "CharacterAdded" then
                return rawset(proxyObject, index, value)
            end

            local valueObject = state:FindFirstChild(index)

            if valueObject then
                valueObject.Value = value
            else
                local valObj = createValueObject(typeof(value))
                valObj.Value = value
                valObj.Name = index
                valObj.Parent = state
            end
        end,

        __tostring = function() return proxyObject.Name end
    })

    if isServer then
        function proxyObject:LoadCharacter()
            if self.Character then
                self.Character:Destroy()
            end

            self.Character = game.ServerStorage.TestPlayerModel:Clone()
            self.Character.Parent = workspace
            self.Character.Name = self.Name
            self.Character.Humanoid.DisplayName = self.Name
            self.Character:MoveTo(self.RespawnLocation.Position)
            Instance.new("BoolValue", self.Character).Name = "IsTestPlayer"
            print("[TestPlayer] - Spawned character", self.Character, " at ",
                  self.RespawnLocation.Position)

            proxyObject.CharacterAdded:Fire(self.Character)
        end

        proxyObject.CharacterAdded = MockEvent(self.Name, "CharacterAdded")
    end

    return self
end

return TestPlayer
