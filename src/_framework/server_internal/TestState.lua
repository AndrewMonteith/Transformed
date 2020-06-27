local TestState = {}
local TestUtil = require(script.Parent.TestUtil)

function TestState.__tostring(self) return "TestState" end

function TestState.new(Aero)
    local state = setmetatable({
        _success = true,
        _aero = Aero,
        _mocks = {}, -- mocked players and instances
        _events = {}, -- all events the test is connected to
        _latches = {}, -- all services we've latched onto
        _globals = {} -- all globals the test has overriden
    }, TestState)

    state:OverrideGlobal("game", state:gameLoader())
    state:OverrideGlobal("RUNNING_TESTS", true)

    state.AllowLogging = false

    return state
end

function TestState:serviceLoader()
    return setmetatable({}, {
        __index = function(_, serviceName)
            local service = self._mocks[serviceName] or self._latches[serviceName]
            if not service then
                error(serviceName .. " has not been sandboxed for the test", 2)
            end

            return service
        end
    })
end

function TestState:moduleLoader(moduleType)
    return setmetatable({}, {
        __index = function(_, moduleName)
            if self._mocks[moduleName] then
                return self._mocks[moduleName]
            elseif moduleType == "Server" then
                return self._aero.Server.Modules[moduleName]
            elseif moduleType == "Client" then
                return self._aero.Client.Modules[moduleName]
            elseif moduleType == "Shared" then
                return self._aero.Shared.Modules[moduleName]
            else
                error("Unknown module type " .. moduleType)
            end
        end
    })
end

local OverridenRbxServiceMethods = {
    Players = {
        GetPlayers = function(state)
            local players = {}

            for _, mock in pairs(state._mocks) do
                if mock.ClassName == "Player" then
                    players[#players + 1] = mock
                end
            end

            return players
        end
    }
}
function TestState:rbxServiceLoader(rbxService)
    local service = game:GetService(rbxService)

    local overridenMethods = OverridenRbxServiceMethods[rbxService] or {}

    return setmetatable({}, {
        __index = function(_, propName)
            local override = overridenMethods[propName]
            if override then
                return function(_, ...) return override(self, ...) end
            end

            local property = service[propName]

            if typeof(property) == "RBXScriptSignal" then
                return self:createFakeEvent{BelongsTo = rbxService, EventName = propName}
            elseif typeof(property) == "function" then
                return function(_, ...) return service[propName](service, ...) end
            else
                return property
            end
        end
    })
end

function TestState:gameLoader()
    return setmetatable({}, {
        __index = function(_, index)
            if index == "GetService" then
                return function(_, service) return self:rbxServiceLoader(service) end
            elseif game:FindService(index) then
                return self:rbxServiceLoader(index)
            else
                return game[index]
            end
        end
    })
end

function TestState:waitUntilFinished()
    local allEventsFinshed = true

    repeat
        for _, event in pairs(self._events) do
            if not event:IsFinished() then
                allEventsFinshed = false
                break
            end
        end
        wait(.1)
    until allEventsFinshed
end

function TestState:Expect(value)
    self:waitUntilFinished()

    return require(script.Parent.Expecter)(self, value)
end

function TestState.__index(state, key)
    local inbuilt = rawget(TestState, key)

    if inbuilt then
        return inbuilt
    elseif key == "Services" then
        return state._aero.Services
    elseif key == "Shared" then
        return state._aero.Shared.Modules
    elseif key == "game" then
        return state:gameLoader()
    else
        error("Undefined key " .. key, 2)
    end
end

function TestState:OverrideGlobal(name, newVal) self._globals[name] = newVal end

function TestState:overrideGlobals(func)
    local env = setmetatable({}, {__index = function(_, ind)
        return self._globals[ind] or getfenv()[ind]
    end})

    setfenv(func, env)
end

function TestState:Success() return self._success end

function TestState:ErrorMsg() return self._errorMsg end

local Mock = require(script.Parent.Mocker)

function TestState:createFakeEvent(details)
    local eventName = (details.IsClientEvent and "Client_" or "") .. details.EventName

    local event = self._events[eventName]
    if event then
        return event
    end

    self._events[eventName] = TestUtil.FakeEvent()
    return self._events[eventName]
end

function TestState:MockInstance(className)
    local mock = Mock.Instance(className)
    self._mocks[#self._mocks + 1] = mock
    return mock
end

function TestState:MockPlayer(playerName)
    local mock = Mock.Player(self, playerName)
    self._mocks[#self._mocks + 1] = mock
    return mock
end

function TestState:MockService(service)
    local mockService = {}

    for name in pairs(service) do
        if name:sub(1, 2) ~= "__" then
            mockService[name] = Mock.Method()
        end
    end

    function mockService:ConnectEvent(eventName, callback) mockService[eventName] = Mock.Event() end

    self._mocks[service.__Name] = mockService

    return mockService
end

function TestState:Start()
    for _, latch in pairs(self._latches) do
        latch:Start()
    end
end

function TestState:logger(serviceName)
    if self.AllowLogging then
        return TestUtil.NewLogger(serviceName)
    else
        return {Log = function() end, Warn = function() end}
    end
end

function TestState:Latch(service)
    local function getEvent(name)
        local event = self._events[name]
        if not event then
            error("Event " .. name .. " does not exist", 3)
        end
        return event
    end

    -- To ensure all the tests are run in the same environment
    -- Anytime a module sets a self.<variable> = <value>
    -- It will be stored in this table which is new for each test
    local state = {}

    local latch = setmetatable({}, {
        __index = function(latch, index)
            if index == "Modules" then
                return self:moduleLoader("Server")
            elseif index == "Shared" then
                return self:moduleLoader("Shared")
            elseif index == "Services" then
                return self:serviceLoader()
            elseif index == "RegisterEvent" or index == "RegisterClientEvent" then
                local isClientEvent = index == "RegisterClientEvent"
                return function(_, eventName)
                    self:createFakeEvent{
                        BelongsTo = latch,
                        EventName = eventName,
                        IsClientEvent = isClientEvent
                    }
                end
            elseif index == "ConnectEvent" then
                return function(_, name, callback) getEvent(name):Connect(callback) end
            elseif index == "Fire" then
                return function(_, eventName, ...) getEvent(eventName):Fire(...) end
            elseif index == "_logger" then
                return self:logger(service.__Name)
            else
                local value =
                rawget(state, index) or -- is it a variable stored on the service (used by the service ModuleScript)
                service[index] or -- is it a function of the service (used by the service ModuleScript)
                self[index] -- is it a function of TestState (used by _Test files)

                if typeof(value) == "function" then
                    self:overrideGlobals(value)
                end

                return value
            end
        end,

        __newindex = function(_, ind, val)
            if ind ~= "_logger" then
                state[ind] = val
            end
        end
    })

    latch:Init()

    self._latches[#self._latches + 1] = latch

    return latch
end

return TestState
