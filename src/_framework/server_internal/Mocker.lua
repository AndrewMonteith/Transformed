local Mock = {}

function Mock.Instance(className)
    local inst = Instance.new(className)

    return setmetatable({ClassName = className},
                        {__index = function(self, ind) return rawget(self, ind) or inst[ind] end})
end

function Mock.Method()
    return setmetatable({_calls = {}}, {
        __call = function(self, ...) self._calls[#self._calls + 1] = {...} end,
        __tostring = function(self) return "MockMethod" end
    })
end

local DefaultPlayerProperties = {UserId = 1}

function Mock.Player(state, playerName)
    --[[
        Special attention is required to the functionality and how we mock the person since
        we'll have no actual Instance to play around with. We'll add properties as we need them
    ]]

    local mockPlayer = {Name = playerName, ClassName = playerName}

    function mockPlayer:JoinGame() state.game.Players.PlayerAdded:Fire(mockPlayer) end

    mockPlayer.LoadCharacter = Mock.Method()
    mockPlayer.CharacterAdded = Mock.Event()
    mockPlayer.PlayerGui = Instance.new("Folder")

    return setmetatable(mockPlayer, {
        __index = function(tab, ind)
            local val = rawget(tab, ind) or DefaultPlayerProperties[ind]

            if val then
                return val
            end

            error("Indexed an unsupported thing " .. ind, 2)
        end,

        __tostring = function(self) return "Mock" .. self.Name end
    })
end

function Mock.Event()
    local MockConnection = {Disconnect = function() end, Destroy = function() end}

    return setmetatable({
        _fired = {},
        _connections = {},

        Fire = function(self, ...) self._fired[#self._fired + 1] = {...} end,

        Connect = function(self, func)
            self._connections[#self._connections + 1] = func
            return MockConnection
        end,

        IsFinished = function() return true end,

        IsMock = true
    }, {__tostring = function() return "MockEvent" end})
end

return Mock
