local Mock = {}

local TestUtil = require(script.Parent.TestUtil)

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

function Mock.Method()
    return setmetatable({_args = {}},
                        {__call = function(self, ...) self._args[#self._args + 1] = {...} end})
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
    return {
        _fired = {},

        Fire = function(self, ...) self._fired[#self._fired + 1] = {...} end,

        Connect = function(self, func) end
    }
end

return Mock
