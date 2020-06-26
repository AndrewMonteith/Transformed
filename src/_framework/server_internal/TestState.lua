local TestState = {}

function TestState.__tostring(self) return "TestState" end

function TestState.new(Aero)
    local state = setmetatable({
        _success = true,
        _aero = Aero,
        _mocks = {}, -- all non-events we've mocked
        _events = {}, -- all events the test is connected to
        _overriden = {}, -- what functions we've overriden. TODO: Is this table necessary
        _globals = {} -- all globals the test has overriden
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

function TestState:mockEvent(details)
    -- Possible point: In future might encounter a test using events of the same name
    --                 May be required to use instance to make this unique
    local eventName = (details.IsClientEvent and "Client_" or "") .. details.EventName
    local event = self._events[eventName]
    if event then
        return event
    end

    local mockEvent = {}
    local connections = {}
    local runningConnections, id = {}, 0

    function mockEvent:Connect(func)
        local myId = id + 1
        id = id + 1

        local function connection(...)
            runningConnections[myId] = true
            coroutine.wrap(func)(...)
            runningConnections[myId] = false
        end

        connections[#connections + 1] = connection
        return {Disconnect = function() table.remove(connections, connection) end}
    end

    function mockEvent:IsFinished()
        for _, running in pairs(runningConnections) do
            if running then
                return false
            end
        end

        return true
    end

    function mockEvent:Fire(...)
        for _, connection in pairs(connections) do
            connection(...)
        end
    end

    self._events[eventName] = mockEvent

    return mockEvent
end

function TestState:isFinished()
    for _, event in pairs(self._events) do
        if not event:IsFinished() then
            return false
        end
    end

    return true
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

local Queries = {
    HasLength = function(value, length)
        local same = #value == length
        local errorMsg = same or ("Mismatched lengths. Expected %d got %d"):format(#value, length)

        return same, errorMsg
    end,

    Equals = function(value, other)
        local tv, to = typeof(value), typeof(other)
        local success, errorMsg = true, "Values are different."

        local function testFailed(msg) success, errorMsg = false, msg end

        if tv ~= to then
            testFailed(("Expected %d got %d"):format(tostring(value), tostring(other)))
        elseif tv == "table" then
            if #value ~= #other then
                testFailed(("Mismatched length, wanted %d but got %d"):format(#value, #other))
            end

            for k in pairs(value) do
                if value[k] ~= other[k] then
                    testFailed("The key %s did not match. Expected %s but got %s"):format(k,
                                                                                          value[k],
                                                                                          other[k])
                end
            end
        elseif value ~= other then
            testFailed(("Expected %s but got %s"):format(value, other))
        end

        return success, errorMsg
    end,

    IsTruthy = function(value)
        return value, value or ("Expected truthy value got %s"):format(tostring(value))
    end
}

function TestState:waitUntilFinished()
    print("waiting till finished...")
    while not self:isFinished() do
        wait()
    end
end

function TestState:Expect(value)
    local state = self

    local querier = {}
    return setmetatable(querier, {
        __index = function(_, ind)
            if not state._success then
                return function() return querier end
            end

            local query = Queries[ind]
            if not query then
                error("Unknown Query " .. ind, 2)
            end

            -- the _ parameter would represent the self we are passed by calling
            -- the expectation builder with : notation
            return function(_, ...)
                local success, errorMsg = query(value, ...)
                state._success = query(value, ...)
                if not success then
                    state._errorMsg = errorMsg
                end
                return querier
            end
        end
    })
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

function TestState:MockInstance(className)
    local mock = require(script.Parent.InstanceMocker).MockInstance(className)
    self._mocks[#self._mocks + 1] = mock
    return mock
end

function TestState:MockPlayer(playerName)
    local mock = require(script.Parent.InstanceMocker).MockPlayer(self, playerName)
    self._mocks[#self._mocks + 1] = mock
    return mock
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

function TestState:Latch(service)
    self:ClearState(service)

    local latch = {}

    local function getEvent(name)
        local event = self._events[name]
        if not event then
            error("Event " .. name .. " does not exist", 3)
        end
        return event
    end

    local latch = setmetatable(latch, {
        __index = function(_, index)
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
    latch:Start()

    return latch
end

return TestState
