local Resource = {}

function Resource:Load(name)
    if game:GetService("RunService"):IsClient() then
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
