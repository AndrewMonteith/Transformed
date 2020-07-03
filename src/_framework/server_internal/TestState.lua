local TestState = {}
local TestUtil = require(script.Parent.TestUtil)
local Mock = require(script.Parent.Mocker)

function TestState.__tostring(self) return "TestState" end

function TestState.new(Aero, test)
    local state = setmetatable({
        _success = true,
        _aero = Aero,
        _testSuite = test,
        _mocks = {}, -- mocked players and instances
        _latches = {}, -- all services we've latched onto
        _globals = {} -- all globals the test has overriden
    }, TestState)

    state:OverrideGlobal("game", state:gameLoader())
    state:OverrideGlobal("RUNNING_TESTS", true)

    state.AllowLogging = false

    return state
end

local function getEventName(eventName, isClient) return (isClient and "Client_" or "") .. eventName end
local function getEvent(obj, eventName, isClient)
    local event = obj._events[getEventName(eventName, isClient)]

    return event or error("Event " .. eventName .. " does not exist", 3)
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

function TestState:moduleLoader(moduleType, requester)
    local function getLiveModule(moduleName)
        if moduleType == "Server" then
            return self._aero.Server.Modules[moduleName]
        elseif moduleType == "Client" then
            return self._aero.Client.Modules[moduleName]
        elseif moduleType == "Shared" then
            return self._aero.Shared.Modules[moduleName]
        else
            error("Unknown module type " .. moduleType)
        end
    end

    return setmetatable({}, {
        __index = function(_, moduleName)
            local module = self._mocks[moduleName] or self:Latch(getLiveModule(moduleName))
            module.__Requester = requester.__Name
            return module
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
    if self._mocks[rbxService] then
        return self._mocks[rbxService]
    end

    local service = game:GetService(rbxService)
    local overridenMethods = OverridenRbxServiceMethods[rbxService] or {}

    self._mocks[rbxService] = setmetatable({_events = {}}, {
        __index = function(ms, propName)
            local override = overridenMethods[propName]
            if override then
                return function(_, ...) return override(self, ...) end
            end

            local property = service[propName]

            if typeof(property) == "RBXScriptSignal" then
                local event = ms._events[propName]

                if not event then
                    event = TestUtil.FakeEvent()
                    ms._events[propName] = event
                end

                return event
            elseif typeof(property) == "function" then
                return function(_, ...) return service[propName](service, ...) end
            else
                return property
            end
        end
    })

    return self._mocks[rbxService]
end

function TestState:gameLoader()
    return setmetatable({}, {
        __index = function(_, index)
            if index == "GetService" then
                return function(_, service) return self:rbxServiceLoader(service) end
            elseif game:FindService(index) then
                return self:rbxServiceLoader(index)
            else
                local val = game[index]
                if typeof(val) == "function" then
                    return function(...) return val(game, ...) end
                else
                    return val
                end
            end
        end
    })
end

function TestState:Expect(value) return require(script.Parent.Expecter)(self, value) end

function TestState.__index(state, key)
    local inbuilt = rawget(TestState, key)

    if inbuilt then
        return inbuilt
    elseif key == "Services" then
        return state._aero.Services
    elseif key == "Shared" then
        return state._aero.Shared.Modules
    elseif key == "Controllers" then
        return state._aero.Controllers
    elseif key == "game" then
        return state:gameLoader(false)
    end
end

function TestState:OverrideGlobal(name, newVal) self._globals[name] = newVal end

function TestState:createStateEnv()
    return setmetatable({}, {__index = function(_, ind)
        return self._globals[ind] or getfenv()[ind]
    end})
end

function TestState:Success() return self._success end

function TestState:ErrorMsg() return self._errorMsg end

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

function TestState:initaliseMockServiceState(serviceToBeMocked, mockService)
    -- When we mock a service we replace every function with a Mock function
    -- and run the Init method in sandboxed environment to create a mock
    -- of each event it initalises, but we discard any other state.

    local dummyValue = setmetatable({}, {
        __index = function(tab) return tab end,
        __call = function(tab) return tab end
    })

    local env = setmetatable({}, {
        __index = function(_, ind)
            if ind == "RegisterEvent" or ind == "RegisterClientEvent" then
                local isClient = ind == "RegisterClientEvent"
                return function(_, name)
                    mockService._events[getEventName(name, isClient)] = Mock.Event()
                end
            elseif ind == "Init" then
                return serviceToBeMocked.Init
            else
                return dummyValue
            end
        end,
        __newindex = function(_, ind, val)
            -- Very specific edge case for loading key events in Keyboard
            if ind == "KeyUp" or ind == "KeyDown" then
                mockService._events[ind] = Mock.Event()
            end
        end
    })

    env:Init()

    for name in pairs(serviceToBeMocked) do
        if name:sub(1, 2) ~= "__" then
            mockService[name] = Mock.Method()
        end
    end
end

function TestState:MockCode(code)
    local indexInClientEvents = code.__Type == "Service"

    local mock = setmetatable({_events = {}, ClassName = "Mock" .. code.__Type}, {
        __index = function(ms, ind)
            local value = rawget(ms, ind)
            if value then
                return value
            end

            local event = getEvent(ms, ind, indexInClientEvents)

            if event then
                -- A connection should only be made by a latch. If a latch connects to an event we
                -- realise the event so that we can interact with it in the test. Any event indexed
                -- via this way must be a client event since it wil be <service>.<event> rather than
                -- service:ConnectEvent(<event>)
                return {
                    Connect = function(connector, callback)
                        if tostring(event) == "MockEvent" then
                            event = TestUtil.FakeEventFromMock(event)
                            ms._events[getEventName(ind, indexInClientEvents)] = event
                            connector._event = event
                        end

                        return event:Connect(callback)
                    end,

                    Fire = function(_, ...) event:Fire(...) end,

                    _event = event
                }
            end
        end,

        __newindex = function(ms, ind, val)
            if typeof(val) == "function" then
                rawset(ms, ind, TestUtil.MethodProxy(val, self:createStateEnv()))
            else
                rawset(ms, ind, val)
            end
        end
    })

    self:initaliseMockServiceState(code, mock)

    mock.ConnectEvent = function(_, eventName, callback)
        getEvent(mock, eventName):Connect(callback)
    end

    self._mocks[code.__Name] = mock

    return mock
end

function TestState:StartAll()
    for _, latch in pairs(self._latches) do
        if latch.Start then
            latch:Start()
        end
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
    if self._latches[service.__Name] then
        return self._latches[service.__Name]
    end

    -- To ensure all the tests are run in the same environment
    -- Anytime a module sets a self.<variable> = <value>
    -- It will be stored in this table which is new for each test
    -- We also store method-interceptors in this state so we can record what methods have been called with.
    local state = {}

    if _G.IsClientCode[service.__Name] and (not self.Player) then
        self.Player = self:MockPlayer("Player1")
    end

    local latch = setmetatable({_events = {}}, {
        __index = function(latch, index)
            if index == "Modules" then
                return self:moduleLoader("Server", service)
            elseif index == "Shared" then
                return self:moduleLoader("Shared", service)
            elseif index == "Services" then
                return self:serviceLoader()
            elseif index == "RegisterEvent" or index == "RegisterClientEvent" then
                local isClientEvent = index == "RegisterClientEvent"
                return function(_, eventName)
                    latch._events[getEventName(eventName, isClientEvent)] = Mock.Event()
                end
            elseif index == "ConnectEvent" then
                return function(_, eventName, callback)
                    local event = getEvent(latch, eventName)

                    if tostring(event) == "MockEvent" then
                        event = TestUtil.FakeEventFromMock(event)
                        latch._events[eventName] = event
                    end

                    event:Connect(callback)
                end
            elseif index == "Fire" then
                return function(_, eventName, ...)
                    getEvent(latch, eventName):Fire(...)
                end
            elseif index == "_logger" then
                return self:logger(service.__Name)
            else
                local value = rawget(state, index) -- any self:<index> or self.<index> should be stored in state 
                if value == nil then
                    value = self[index] -- any code used inside the Test that uses state.<index> inside a test
                end

                return value
            end
        end,

        __newindex = function(_, ind, val)
            if ind == "_logger" then
                return
            end

            if typeof(val) == "function" then
                state[ind] = TestUtil.MethodProxy(val, self:createStateEnv())
            else
                state[ind] = val
            end
        end
    })

    for k, v in pairs(service) do
        latch[k] = v
    end

    if service.Init then
        latch:Init()
    end

    self._latches[service.__Name] = latch

    return latch
end

return TestState
