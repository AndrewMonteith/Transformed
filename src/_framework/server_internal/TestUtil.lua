local TestUtilities = {}

function TestUtilities.NewLogger(id)
    local function formatOutput(_, ...)
        local args = {"[", id, "]"}
        for i, arg in pairs({...}) do
            args[#args + 1] = tostring(arg)
        end

        return table.concat(args, " ")
    end

    return {
        Log = function(...) print(formatOutput(...)) end,
        Warn = function(...) warn(formatOutput(...)) end
    }
end

function TestUtilities.FakeEvent()
    local event = {}

    local connections = {}
    local isRunning, id = {}, 0

    function event:Connect(func)
        local myId = id + 1
        id = id + 1

        local function connection(...)
            isRunning[myId] = true
            coroutine.wrap(func)(...)
            isRunning[myId] = false
        end

        connections[#connections + 1] = connection

        return
        {Disconnect = function() table.remove(connections, connection) end, Destroy = function() end}
    end

    function event:IsFinished()
        for _, running in pairs(isRunning) do
            if running then
                return false
            end
        end

        return true
    end

    function event:Fire(...)
        for _, connection in pairs(connections) do
            connection(...)
        end
    end

    setmetatable(event, {__tostring = function() return "FakeEvent" end})

    return event
end

function TestUtilities.FakeEventFromMock(mockEvent)
    local fakeEvent = TestUtilities.FakeEvent()

    for _, func in pairs(mockEvent._connections) do
        fakeEvent:Connect(func)
    end

    return fakeEvent
end

function TestUtilities.MethodProxy(method, env)
    return setmetatable({_calls = {}, Transparent = false}, {
        __call = function(self, ...)
            self._calls[#self._calls + 1] = {...}

            if self.Transparent then
                return
            end

            if env then
                setfenv(method, env)
            end

            return method(...)
        end,

        __tostring = function(self) return "MethodProxy" end
    })

end

return TestUtilities
