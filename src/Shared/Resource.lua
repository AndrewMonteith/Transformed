local Resource = {}

function Resource:isClient()
    if RUNNING_TESTS then
        return self.__RunningOnClient
    else
        return game:GetService("RunService"):IsClient()
    end
end

function Resource:getResource(resources, name) return resources:FindFirstChild(name, true):Clone() end

function Resource:Load(name)
    if self:isClient() then
        return self:LoadShared(name)
    end

    return self:getResource(game.ServiceStorage.Resources, name)
end

function Resource:LoadShared(name)
    if not game:IsLoaded() and not RUNNING_TESTS then
        game.Loaded:Wait()
    end

    return self:getResource(game:GetService("ReplicatedStorage"):WaitForChild("Resources"), name)
end

return Resource
