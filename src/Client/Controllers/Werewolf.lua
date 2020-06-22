local Werewolf = {}

local logger

function Werewolf:tweenCostumesVisibility(visible)
    local tween = self.Modules.Tween.new(TweenInfo.new(.7, Enum.EasingStyle.Linear), function(n)
        local transparency = visible and 1 - n or n
        for _, costume in pairs(self._werewolfCostumes) do
            costume:SetTransparency(transparency)
        end
    end)

    tween:Play()
end

function Werewolf:tryDamage(part)
    local player = self.Shared.PlayerUtil.GetPlayerFromPart(part)
    if (not player) or self.damagedPlayers[player] then
        return
    end

    self.damagedPlayers[player] = true
    self.Services.InRoundService.ClawPlayer:Fire(player)
end

function Werewolf:connectEvents()
    local swingAnimationTrack = self.Shared.Resource:Load("WerewolfSwing")
    self.swingAnimation = self.Player.Character.Humanoid:LoadAnimation(swingAnimationTrack)

    self._events:GiveTask(self.Controllers.UserInput:Get("Mouse").LeftDown:Connect(
                          function()
        if not self.swingAnimation.IsPlaying then
            self.swingAnimation:Play()
        end
    end))

    local leftClaw = self.Player.Character:FindFirstChild("LeftHandClaw")
    local rightClaw = self.Player.Character:FindFirstChild("RightHandClaw")

    local function touchEnded(touchedPart)
        if touchedPart.Parent == self.Player.Character then
            return
        end

        self._touchedParts[touchedPart] = nil
    end
    self._events:GiveTask(leftClaw.TouchEnded:Connect(touchEnded))
    self._events:GiveTask(rightClaw.TouchEnded:Connect(touchEnded))

    local allowDamage = false

    local function touched(touchedPart)
        if touchedPart.Parent == self.Player.Character then
            return
        end

        self._touchedParts[touchedPart] = true

        if allowDamage then
            self:tryDamage(touchedPart)
        end
    end
    self._events:GiveTask(leftClaw.Touched:Connect(touched))
    self._events:GiveTask(rightClaw.Touched:Connect(touched))

    self.swingAnimation.KeyframeReached:Connect(function(keyframe)
        if keyframe == "DamageStart" then
            allowDamage = true
            self.damagedPlayers = self.Shared.PlayerDict.new()

            for part in pairs(self._touchedParts) do
                self:tryDamage(part)
            end
        elseif keyframe == "DamageEnd" then
            allowDamage = false
        end
    end)
end

function Werewolf:initalise(playersAndTeam)
    self._werewolfCostumes = {}
    self._events = self.Shared.Maid.new()
    self._isWerewolf = playersAndTeam[self.Player.Name] == "Werewolf"

    for playerName, team in pairs(playersAndTeam) do
        if team == "Werewolf" then
            self._werewolfCostumes[playerName] = self.Modules.WerewolfCostume.new(
                                                 workspace[playerName])
        end
    end
end

function Werewolf:destroyPlayerCostume(player)
    if self._werewolfCostumes[player.Name] then
        self._werewolfCostumes[player.Name]:Destroy()
        self._werewolfCostumes[player.Name] = nil
    end

    if player.Name == self.Player.Name then
        self._events:DoCleaning()
        self._touchedParts = {}
    end
end

function Werewolf:setActive(active)
    if self._isActive == active then
        return
    end
    self._isActive = active;

    self:tweenCostumesVisibility(active)

    if self._isWerewolf then
        if active then
            self._werewolfCostumes[self.Player.Name]:AddClaws()
            self:connectEvents()
        else
            self._werewolfCostumes[self.Player.Name]:RemoveClaws()
            self._events:DoCleaning()
        end
    end
end

function Werewolf:Start()
    local function init(playersAndTeam) self:initalise(playersAndTeam) end
    self.Services.RoundService.RoundStarted:Connect(init)
    self.Services.RoundService.RoundEnded:Connect(function() self._isActive = false end)

    self.Services.PlayerService.PlayerLeftRound:Connect(
    function(player)
        if player.Name == self.Player.Name then
            self._isWerewolf = false
        end

        self:destroyPlayerCostume(player)
    end)

    local function setActive(active) return function() self:setActive(active) end end
    self.Services.DayNightCycle.Sunrise:Connect(setActive(false))
    self.Services.DayNightCycle.Sunset:Connect(setActive(true))
end

function Werewolf:Init()
    logger = self.Shared.Logger.new()
    self._isActive = false
    self._touchedParts = {}
    self._isWerewolf = false
end

return Werewolf
