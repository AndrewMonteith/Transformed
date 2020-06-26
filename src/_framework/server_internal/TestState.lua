local TestState = {}

function TestState.__tostring(self) return "TestState" end

function TestState.new(Aero)
    local state = setmetatable({
        _success = true,
        _aero = Aero,
        _mocks = {}, -- mocked players and instances
        _events = {}, -- all events the test is connected to
        _latches = {}, -- all services we've latched onto
        _overriden = {}, -- what functions we've overriden. TODO: Is this table necessary
        _globals = {RUNNING_TESTS = true} -- all globals the test has overriden
    }, TestState)

    state:OverrideGlobal("game", state:gameLoader())

    return state
end

function TestState:serviceLoader()
    return setmetatable({}, {
        __index = function(_, serviceName)
            local mock = self._mocks[serviceName]
            if mock then
                return mock
            end

            return self._aero.Services[serviceName]
        end
    })
end

function TestState:moduleLoader(moduleType)
    return setmetatable({}, {
        __index = function(_, moduleName)
            local mock = self._mocks[moduleName]
            if mock then
                return mock
            end

            if moduleType == "Server" then
                return self._aero.Server.Modules[moduleName]
            elseif moduleType == "Client" then
                return self._aero.Client.Modules[moduleName]
            elseif moduleType == "Shared" then
                return self._aero.SharedModules[moduleName]
            else
                error("Unknown module type " .. moduleType)
            end
        end
    })
end

function TestState:rbxServiceLoader(rbxService)
    -- TODO: Make the way we handle GetPlayers less hacky
    local service = game:GetService(rbxService)

    local function getPlayers()
        local players = {}
        for _, mock in pairs(self._mocks) do
            if mock.ClassName == "Player" then
                players[#players + 1] = mock
            end
        end
        return players
    end

    return setmetatable({}, {
        __index = function(_, propName)
            if propName == "GetPlayers" and rbxService == "Players" then
                return getPlayers
            end

            local property = service[propName]

            if typeof(property) == "RBXScriptSignal" then
                return self:mockEvent{BelongsTo = rbxService, EventName = propName}
            end
        end
    })
end

function TestState:gameLoader()
    return setmetatable({}, {
        __index = function(_, index)
            if game:FindService(index) then
                return self:rbxServiceLoader(index)
            elseif index == "GetService" then
                return function(_, index)
                    if game:FindService(index) then
                        return self:rbxServiceLoader(index)
                    else
                        error("Unknown service " .. index, 2)
                    end
                end
            else
                return game[index]
            end
        end
    })
end

function TestState:isFinished()
    for _, event in pairs(self._events) do
        if not event:IsFinished() then
            return false
        end
    end

    return true
end

function TestState:waitUntilFinished()
    local allEventsFinshed = true

    repeat
        for _, event in pairs(self._events) do
            if not event:IsFinished() then
                allEventsFinshed = false
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
    local inbuilt = rawget(TestState, key) -- or rawget(state, key)

    if inbuilt then
        return inbuilt
    elseif key == "Services" then
        return state:serviceLoader()
    elseif key == "game" then
        return state:gameLoader()
    else
        error("Undefined key " .. key, 2)
    end
end

function TestState:OverrideGlobal(name, newVal) self._globals[name] = newVal end

function TestState:overrideGlobals(func)
    self._overriden[func] = true

    local env = setmetatable({}, {__index = function(_, ind)
        return self._globals[ind] or getfenv()[ind]
    end})

    setfenv(func, env)
end

function TestState:Success() return self._success end

function TestState:ErrorMsg() return self._errorMsg end

local Mock = require(script.Parent.Mocker)

function TestState:mockEvent(details)
    local eventName = (details.IsClientEvent and "Client_" or "") .. details.EventName

    local event = self._events[eventName]
    if event then
        return event
    end

    self._events[eventName] = Mock.Event()
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

function TestState:MockService(serviceName)
    local originalService = self._aero.Services[serviceName]
    if not serviceName then
        error("Unknown service " .. serviceName, 2)
    end

    local mockService = {_orig = originalService}

    function mockService:ConnectEvent(eventName, callback)
        warn("need to implement ConnectEvent for mock service!")
    end

    self._mocks[serviceName] = mockService
    return mockService
end

function TestState:ClearState(service)
    -- To reset the state of a service we remove all fields beginning with
    -- an _ since this indicates a member variable. All services should store
    -- there state in a _ variable so by removing them we essentially reset the service
    for key in pairs(service) do
        if key:sub(1, 1) == "_" then
            service[key] = nil
        end
    end

    setmetatable(service, nil)
end

function TestState:StartServices()
    for _, latch in pairs(self._latches) do
        latch:Start()
    end
end

function TestState:Latch(service)
    self:ClearState(service)

    local function getEvent(name)
        local event = self._events[name]
        if not event then
            error("Event " .. name .. " does not exist", 3)
        end
        return event
    end

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
                    self:mockEvent{BelongsTo = latch, EventName = eventName, IsClientEvent = isClientEvent}
                end
            elseif index == "ConnectEvent" then
                return function(_, name, callback) getEvent(name):Connect(callback) end
            elseif index == "Fire" then
                return function(_, eventName, ...) getEvent(eventName):Fire(...) end
            else
                local value = rawget(latch, index) or service[index] or self[index]
                if typeof(value) == "function" and not self._overriden[value] then
                    self:overrideGlobals(value)
                end

                return value
            end
        end
    })

    latch:Init()

    self._latches[#self._latches + 1] = latch

    return latch
end

return TestState
