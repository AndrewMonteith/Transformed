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
