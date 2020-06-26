local TestState = {}

function TestState.__tostring(self) return "TestState" end

function TestState.new(Aero)
    return setmetatable(
           {_success = true, _aero = Aero, _mocks = {}, _latches = {}, _overriden = {}, _globals = {}},
           TestState)
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

local Queries = {
    HasLength = function(value, length)
        local same = #value == length
        local errorMsg = (not same) and
                         ("Mismatched lengths. Expected %d got %d"):format(#value, length)

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
    end

}

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
    else
        error("Undefined key " .. key)
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

function TestState:MockService(serviceName)
    local originalService = self._aero.Services[serviceName]
    if not serviceName then
        error("Unknown service " .. serviceName)
    end

    local mockService = {_orig = originalService}
    self._mocks[serviceName] = mockService
    return mockService
end

function TestState:RegisterMockEvent(name, isClient) end

function TestState:MockInstance(className) return {} end

function TestState:Latch(service)
    self:ClearState(service)

    local latch = {}

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
                return function(eventName)
                    self:RegisterMockEvent(eventName, isClientEvent)
                end
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

    return latch
end

return TestState
