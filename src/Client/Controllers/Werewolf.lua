local Werewolf = {}

local logger

function Werewolf:_tweenCostumesVisibility(visible)
    local tween = self.Modules.Tween.new(TweenInfo.new(.7, Enum.EasingStyle.Linear), function(n)
        local transparency = visible and 1 - n or n
        for _, costume in pairs(self.werewolfCostumes) do
            costume:SetTransparency(transparency)
        end
    end)

    tween:Play()
end

function Werewolf:_tryDamage(part)
    local player = self.Shared.PlayerUtil.GetPlayerFromPart(part)
    if (not player) or self.damagedPlayers[player] then
        return
    end

    self.damagedPlayers[player] = true
    self.Services.InRoundService.ClawPlayer:Fire(player)
end

function Werewolf:_connectEvents()
    local swingAnimationTrack = self.Shared.Resource:Load("WerewolfSwing")
    self.swingAnimation = self.Player.Character.Humanoid:LoadAnimation(swingAnimationTrack)

    self.events:GiveTask(self.Controllers.UserInput:Get("Mouse").LeftDown:Connect(
                         function()
        if not self.swingAnimation.IsPlaying then
            self.swingAnimation:Play()
        end
    end))

    local leftClaw = self.Player.Character:FindFirstChild("LeftHandClaw")
    local rightClaw = self.Player.Character:FindFirstChild("RightHandClaw")

    local function touched(touchedPart)
        if touchedPart.Parent == self.Player.Character then
            return
        end

        self.touchedParts[touchedPart] = true

        if self.allowDamage then
            self:_tryDamage(touchedPart)
        end
    end

    local function touchEnded(touchedPart)
        if touchedPart.Parent == self.Player.Character then
            return
        end

        self.touchedParts[touchedPart] = nil
    end

    self.events:GiveTask(leftClaw.Touched:Connect(touched))
    self.events:GiveTask(rightClaw.Touched:Connect(touched))
    self.events:GiveTask(leftClaw.TouchEnded:Connect(touchEnded))
    self.events:GiveTask(rightClaw.TouchEnded:Connect(touchEnded))

    self.swingAnimation.KeyframeReached:Connect(function(keyframe)
        if keyframe == "DamageStart" then
            self.allowDamage = true
            self.damagedPlayers = self.Shared.PlayerDict.new()

            for part in pairs(self.touchedParts) do
                self:_tryDamage(part)
            end
        elseif keyframe == "DamageEnd" then
            self.allowDamage = false
        end
    end)
end

function Werewolf:Initalise(playersAndTeam)
    self.werewolfCostumes = {}
    self.events = self.Shared.Maid.new()
    self.isWerewolf = playersAndTeam[self.Player.Name] == "Werewolf"

    for playerName, team in pairs(playersAndTeam) do
        if team == "Werewolf" then
            self.werewolfCostumes[playerName] = self.Modules.WerewolfCostume.new(workspace[playerName])
        end
    end
end

function Werewolf:Destory()
    for _, costume in pairs(self.werewolfCostumes) do
        costume:Destroy()
    end

    self.werewolfCostumes = nil
    self.events:DoCleaning()
    self.touchedParts = {}
    self.isWerewolf = nil
end

function Werewolf:SetActive(active)
    self:_tweenCostumesVisibility(active)

    if self.isWerewolf then
        if active then
            self.werewolfCostumes[self.Player.Name]:AddClaws()
            self:_connectEvents()
        else
            self.werewolfCostumes[self.Player.Name]:RemoveClaws()
            self.events:DoCleaning()
        end
    end
end

function Werewolf:Start()
    self.Services.RoundService.RoundStarted:Connect(function(playersAndTeam)
        self:Initalise(playersAndTeam)
    end)

    self.Services.RoundService.RoundEnded:Connect(function()
        self:Destory()
    end)

    local function setActive(active)
        return function()
            self:SetActive(active)
        end
    end
    self.Services.DayNightCycle.Sunrise:Connect(setActive(false))
    self.Services.DayNightCycle.Sunset:Connect(setActive(true))
end

function Werewolf:Init()
    logger = self.Shared.Logger.new()
    self.touchedParts = {}
end

return Werewolf
