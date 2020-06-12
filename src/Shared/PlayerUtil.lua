local PlayerUtil = {}

local logger;

function PlayerUtil.Kill(player)
    if not player.Character then
        return
    end

    local humanoid = player.Character:WaitForChild("Humanoid", 0.2)

    if humanoid then
        humanoid.Health = 0
    end
end

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

    -- logger:Log("Studio Mode Detected - Producing a test instance.")
    return PlayerUtil.Shared.TestPlayer.new(game.Players:GetPlayers()[1], {Name = part.Name})
end

function PlayerUtil:Init()
    logger = self.Shared.Logger.new()
end

return PlayerUtil
