local Queries;
Queries = {
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
            testFailed(("Expected %s got %s"):format(tostring(expected), tostring(value)))
        elseif tv == "table" then
            if #value ~= #expected then
                testFailed(("Mismatched length, wanted %d but got %d"):format(#expected, #value))
            end

            for k in pairs(value) do
                if value[k] ~= expected[k] then
                    testFailed(("The key %s did not match. Expected %s but got %s"):format(k,
                                                                                           tostring(
                                                                                           expected[k]),
                                                                                           tostring(
                                                                                           value[k])))
                end
            end
        elseif value ~= expected then
            testFailed(("Expected %s but got %s"):format(tostring(expected), tostring(value)))
        end

        return success, errorMsg
    end,

    IsTruthy = function(value)
        return value, value or ("Expected truthy value got %s"):format(tostring(value))
    end,

    IsFalsy = function(value)
        return (not value), (not value) or ("Expected falsy value got %s"):format(tostring(value))
    end,

    IsTrue = function(value)
        return (value == true), (value == true) or ("Expected true got %s"):format(tostring(value))
    end,

    IsFalse = function(value)
        return (value == false),
               (value == false) or ("Expected false got %s"):format(tostring(value))
    end,

    NotNil = function(value)
        return value ~= nil, (value ~= nil) or ("Expected value to not be nil")
    end,

    IsNil = function(value) return value == nil, (value == nil) or ("Exected value to be nil") end,

    CalledOnce = function(value)
        local success = #value._calls == 1
        return success, success or
               ("Expected method to be called once but was called %d times"):format(#value._calls)
    end,

    GreaterThan = function(value, expected)
        local success = value > expected
        return success, success or ("Expected %d to be greater than %d"):format(value, expected)
    end,

    LessThan = function(value, expected)
        local success = value < expected
        return success, success or ("Expected %d to be less than %d"):format(value, expected)
    end,

    InInterval = function(value, lowerBound, upperBound)
        local success = lowerBound <= value and value <= upperBound

        return success,
               success or ("Expected %d to be in interval [%d, %d]"):format(lowerBound, upperBound)
    end,

    CalledNTimes = function(value, n)
        local success = #value._calls == n
        return success, success or
               ("Expected method to be called %d times but was called %d times"):format(n,
                                                                                        #value._calls)
    end,

    EventCalledWith = function(value, ...)
        local shouldBeFiredWith = {...}

        local called = typeof(value) == "table" and (value._calls and value or value._event)
        if not called then
            return false, "CalledWith must be called with an invocable object"
        end

        for _, firedWith in pairs(called._calls) do
            local valuesEqual = Queries.Equals(firedWith, shouldBeFiredWith)

            if valuesEqual then
                return true
            end
        end

        local errorMessage =
        ("Not called with given arguments. It was called %d times though"):format(#value._calls)
        return false, errorMessage
    end,

    MethodCalledWith = function(value, ...)
        local shouldBeFiredWith = {...}

        local called = typeof(value) == "table" and (value._calls and value or value._event)
        if not called then
            return false, "CalledWith must be called with an invocable object"
        end

        for _, firedWith in pairs(called._calls) do
            local withoutFirst = {select(2, table.unpack(firedWith))}
            local valuesEqual = Queries.Equals(withoutFirst, shouldBeFiredWith)

            if valuesEqual then
                return true
            end
        end

        local errorMessage =
        ("Not called with given arguments. It was called %d times though"):format(#value._calls)
        return false, errorMessage
    end,

    RbxEventCalled = function(value, timeout)
        timeout = timeout or 1

        local called = false
        value:Connect(function() called = true end)

        local dt = 0;
        while dt < timeout and not called do
            dt = dt + (wait())
        end

        return called, called or "Rbx event was not called within the timeout period"
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

                state._expectation = state._expectation + 1

                state._success = success
                if not success then
                    state._errorMsg = ("Expectation %d - %s"):format(state._expectation, errorMsg)
                end
                return querier
            end
        end
    })
end
