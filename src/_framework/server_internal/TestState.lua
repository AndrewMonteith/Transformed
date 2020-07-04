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

function TestState:moduleLoader(moduleType, clientCode)
    clientCode = clientCode or moduleType == "Client"

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
            local module = self._mocks[moduleName] or
                           self:LatchModule(getLiveModule(moduleName), clientCode)
            module.__RunningOnClient = clientCode
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

local function createCodeObjectState(isService, isLatch)
    return {_events = {}, _clientEvents = isService and {} or nil, _state = isLatch and {} or nil}
end

function TestState:initaliseMockInterface(mock, args)
    -- Copy the interface of args.Code by running the Init in a
    -- sandboxed environment to only register events. Once all
    -- events are registered we then copy the API with mock methods

    local noValue = setmetatable({}, {
        __index = function(tab) return tab end,
        __call = function(tab) return tab end
    })

    local sandboxEnv = setmetatable({}, {
        __index = function(_, ind)
            if ind == "Init" then
                return args.Code.Init
            elseif mock[ind] then
                return mock[ind]
            else
                return noValue
            end
        end
    })

    sandboxEnv:Init()

    for k, v in pairs(args.Code) do
        if typeof(v) == "function" then
            mock[k] = Mock.Method()
        end
    end
end

function TestState:realisingEventConnection(events, eventName)
    local event = events[eventName]
    return setmetatable({
        Connect = function(_, callback)
            if tostring(event) == "MockEvent" then
                event = TestUtil.FakeEventFromMock(event)
                events[eventName] = event
            end

            return event:Connect(callback)
        end
    }, {__index = event})
end

function TestState:createMock(args)
    if self._mocks[args.Name] then
        return self._mocks[args.Name]
    end

    local mock = createCodeObjectState(not args.ClientOnly, false)

    setmetatable(mock, {
        __index = function(mock, ind)
            local value = args.Indexer(mock, ind)
            if value then
                return value
            elseif ind == "RegisterEvent" then
                return function(_, eventName) mock._events[eventName] = Mock.Event() end
            elseif mock._events[ind] then
                return self:realisingEventConnection(mock._events, ind)
            elseif ind == "ConnectEvent" then
                return function(_, eventName, callback)
                    local connection = self:realisingEventConnection(mock._events, eventName)
                    return connection:Connect(callback)
                end
            end
        end
    })

    self:initaliseMockInterface(mock, args)

    self._mocks[args.Name] = mock
    return mock
end

function TestState:mockService(service)
    return self:createMock{
        Name = service.__Name,
        ClientOnly = false,
        Code = service,
        Indexer = function(mock, ind)
            if ind == "RegisterClientEvent" then
                return function(_, eventName)
                    mock._clientEvents[eventName] = Mock.Event()
                end
            elseif ind == "ConnectClientEvent" then
                return function(_, eventName, callback)
                    local connection = self:realisingEventConnection(mock._clientEvents, eventName)
                    return connection:Connect(callback)
                end
            elseif ind == "FireClient" then
                return function(_, eventName, player, ...)
                    mock._clientEvents[eventName]:Fire(...)
                end
            elseif mock._clientEvents[ind] then
                return self:realisingEventConnection(mock._clientEvents, ind)
            end
        end
    }
end

function TestState:mockController(controller)
    return self:createMock{
        Name = controller.__Name,
        ClientOnly = true,
        Code = controller,
        Indexer = function(mock, ind) end
    }
end

function TestState:MockModule(module, isClientOnly)
    return self:createMock{
        Name = module.__Name,
        ClientOnly = isClientOnly,
        Code = module,
        Indexer = function(mock, ind) end
    }
end

function TestState:Mock(code)
    if code.__Type == "Controller" then
        return self:mockController(code)
    elseif code.__Type == "Service" then
        return self:mockService(code)
    else
        error("Implicit mock not supported for modules")
    end
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

function TestState:createLatch(args)
    if self._latches[args.Name] then
        return self._latches[args.Name]
    end

    if args.ClientOnly then
        self.Player = self:MockPlayer("Player")
    end

    local latch = createCodeObjectState(not args.ClientOnly, true)

    setmetatable(latch, {
        __index = function(latch, index)
            if index == "Modules" then
                return self:moduleLoader(latch.ClientOnly and "Client" or "Server")
            elseif index == "Shared" then
                return self:moduleLoader("Shared", args.ClientOnly)
            elseif index == "Services" then
                return self:serviceLoader()
            elseif index == "RegisterEvent" then
                return function(_, eventName)
                    latch._events[eventName] = TestUtil.FakeEvent()
                end
            elseif index == "ConnectEvent" then
                return function(_, eventName, func)
                    return latch._events[eventName]:Connect(func)
                end
            elseif index == "Fire" then
                return function(_, eventName, ...) latch._events[eventName]:Fire(...) end
            elseif index == "_logger" then
                return self:logger(latch.Name)
            else
                local value = args.Indexer(latch, index) -- controller/service specific method?
                or latch._state[index] -- self:<index> or self.index ?
                or self[index] -- state.<index> ?

                return value
            end
        end,

        __newindex = function(_, ind, val)
            if ind == "_logger" then
                return
            elseif typeof(val) == "function" then
                latch._state[ind] = TestUtil.MethodProxy(val, self:createStateEnv())
            else
                latch._state[ind] = val
            end
        end
    })

    table.foreach(args.Code, function(k, v) latch[k] = v end)

    if args.Code.Init then
        latch:Init()
    end

    self._latches[args.Name] = latch

    return latch
end

function TestState:LatchController(controller)
    return self:createLatch{
        Name = controller.__Name,
        ClientOnly = true,
        Code = controller,
        Indexer = function(latch, index) end
    }
end

function TestState:LatchService(service)
    return self:createLatch{
        Name = service.__Name,
        ClientOnly = false,
        Code = service,
        Indexer = function(latch, index)
            if index == "RegisterClientEvent" then
                return function(_, eventName)
                    latch._clientEvents[eventName] = TestUtil.FakeEvent()
                end
            elseif index == "FireClient" then
                return function(_, eventName, player, ...)
                    latch._clientEvents[eventName]:Fire(...)
                end
            elseif index == "ConnectClientEvent" then
                return function(_, eventName, func)
                    return latch._clientEvents[eventName]:Connect(func)
                end
            elseif latch._clientEvents[index] then
                return {Fire = function(_, ...)
                    latch._clientEvents[index]:Fire(self.Player, ...)
                end}
            end
        end
    }
end

function TestState:Latch(code)
    if code.__Type == "Service" then
        return self:LatchService(code)
    elseif code.__Type == "Controller" then
        return self:LatchController(code)
    else
        error("Modules not supported in implicit latch")
    end
end

function TestState:LatchModule(module, isClientCode)
    return self:createLatch{
        Name = module.__Name,
        ClientOnly = isClientCode,
        Code = module,
        Indexer = function(latch, index) end
    }
end

return TestState
