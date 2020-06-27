local TestUtilities = {}

TestUtilities.NewLogger = function(id)
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

return TestUtilities
