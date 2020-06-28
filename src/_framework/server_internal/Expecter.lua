local Queries = {
    HasLength = function(value, length)
        local same = #value == length
        local errorMsg = same or ("Mismatched lengths. Expected %d got %d"):format(length, #value)

        return same, errorMsg
    end,

    Equals = function(value, expected)
        local tv, to = typeof(value), typeof(expected)
        local success, errorMsg = true, "Values are different."

        local function testFailed(msg) success, errorMsg = false, msg end

        if tv ~= to then
            testFailed(("Expected %d got %d"):format(tostring(expected), tostring(value)))
        elseif tv == "table" then
            if #value ~= #expected then
                testFailed(("Mismatched length, wanted %d but got %d"):format(#expected, #value))
            end

            for k in pairs(value) do
                if value[k] ~= expected[k] then
                    testFailed(("The key %s did not match. Expected %s but got %s"):format(k,
                                                                                           expected[k],
                                                                                           value[k]))
                end
            end
        elseif value ~= expected then
            testFailed(("Expected %s but got %s"):format(expected, value))
        end

        return success, errorMsg
    end,

    IsTruthy = function(value)
        return value, value or ("Expected truthy value got %s"):format(tostring(value))
    end,

    Called = function(value)
        if tostring(value) ~= "MockMethod" then
            return false, "Expected mock method got " .. tostring(value)
        end

        return {
            Once = function()
                local success = #value._calls == 1
                return success, success or
                       ("Expected method to be called once but was called %d times"):format(
                       #value._calls)
            end
        }
    end
}

return function(state, value)
    return setmetatable({}, {
        __index = function(querier, ind)
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
