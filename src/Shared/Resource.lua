local Resource = {}

function Resource:isClient()
    if RUNNING_TESTS then
        print(RUNNING_TESTS, IS_CLIENT)
        return IS_CLIENT
    else
        return game:GetService("RunService"):IsClient()
    end
end

function Resource:Load(name)
    if self:isClient() then
        return self:LoadShared(name)
    end

    return game.ServerStorage.Resources:FindFirstChild(name, true)
end

function Resource:LoadShared(name)
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end

    return game:GetService("ReplicatedStorage").Resources:FindFirstChild(name, true)
end

return Resource
