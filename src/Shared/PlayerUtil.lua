local PlayerUtil = {}

local logger;

function PlayerUtil.GetPlayerFromName(name)
    local player = game.Players:FindFirstChild(name)
    if not player then
        logger:Warn("Couldn't find player:", name)
        return
    end

    if player:IsA("Player") then
        return player
    else
        return PlayerUtil.Shared.TestPlayer.fromState(player)
    end
end

function PlayerUtil.GetPlayerFromPart(part)
    while part.Parent ~= workspace do
        part = part.Parent
    end

    local player = game.Players:GetPlayerFromCharacter(part)
    if player then
        return player
    end

    local runService = game:GetService("RunService")
    if not (runService:IsStudio() and part:FindFirstChild("IsTestPlayer")) then
        return
    end

    return PlayerUtil.Shared.TestPlayer.new(game.Players:GetPlayers()[1], {Name = part.Name})
end

function PlayerUtil:Init() logger = self.Shared.Logger.new() end

return PlayerUtil
