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
        return {Disconnect = function() table.remove(connections, connection) end}
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

    return event
end

return TestUtilities
