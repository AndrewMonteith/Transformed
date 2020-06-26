--[[
	There are 
]] local Mock = {}

local function hasEvent(inst, event)
    return pcall(function() return typeof(inst[event]) == "RBXScriptSignal" end)
end

local function hasProperty(inst, prop)
    return pcall(function()
        local t = typeof(inst[prop])

        return not (t == "function" or t == "RBXScriptSignal")
    end)
end

local function hasMethod(inst, method)
    return pcall(function() return typeof(inst[method]) == "function" end)
end

function Mock.Instance(className)
    local inst = Instance.new(className)

    return setmetatable({ClassName = className},
                        {__index = function(self, ind) return rawget(self, ind) or inst[ind] end})
end

local DefaultPlayerProperties = {UserId = 1}

function Mock.Player(state, playerName)
    --[[
        Special attention is required to the functionality and how we mock the person since
        we'll have no actual Instance to play around with. We'll add properties as we need them
    ]]

    local mockPlayer = {Name = playerName, ClassName = playerName}

    function mockPlayer:JoinGame() state.game.Players.PlayerAdded:Fire(mockPlayer) end
    function mockPlayer:LoadCharacter() end

    mockPlayer.CharacterAdded = {Connect = function() end}

    return setmetatable(mockPlayer, {
        __index = function(tab, ind)
            local val = rawget(tab, ind) or DefaultPlayerProperties[ind]

            if val then
                return val
            end

            error("Indexed an unsupported thing " .. ind, 2)
        end
    })
end

function Mock.Event()
    local mock = {}

    local connections = {}
    local isRunning, id = {}, 0

    function mock:Connect(func)
        local myId = id + 1
        id = id + 1

        local function connection(...)
            isRunning[myId] = true
            coroutine.wrap(func)(...)
            isRunning[myId] = false
        end

        connections[#connections + 1] = connection
        return {Disconnect = function() table.remove(connections, connection) end}
    end

    function mock:IsFinished()
        for _, running in pairs(isRunning) do
            if running then
                return false
            end
        end

        return true
    end

    function mock:Fire(...)
        for _, connection in pairs(connections) do
            connection(...)
        end
    end

    return mock
end

return Mock
