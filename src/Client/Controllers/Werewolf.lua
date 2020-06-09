local Werewolf = {}

local logger

function Werewolf:_showCostumes(werewolves)
    self.werewolfCostumes = {}

    for _, playerName in pairs(werewolves) do
        local werewolf = self.Shared.PlayerUtil.GetPlayerFromName(playerName)
        self.werewolfCostumes[playerName] = self.Modules.WerewolfCostume.new(werewolf.Character)
    end

    local showCostumes = self.Modules.Tween.new(TweenInfo.new(.7, Enum.EasingStyle.Linear), function(n)
        local transparency = 1-n
        for _, costume in pairs(self.werewolfCostumes) do
            costume:SetTransparency(transparency)
        end
    end)

    showCostumes:Play()
end

function Werewolf:_tryDamage(part)
    local player = self.Shared.PlayerUtil.GetPlayerFromPart(part)
    if (not player) or self.damagedPlayers[player] then
        return
    end

    self.damagedPlayers[player] = true
    self.Services.InRoundService.ClawPlayer:Fire(player.Name)
end

function Werewolf:_activateWerewolf()
    self.events = self.Shared.Maid.new()

    local swingAnimationTrack = self.Shared.Resource:Load("WerewolfSwing")
    self.swingAnimation = self.Player.Character.Humanoid:LoadAnimation(swingAnimationTrack)

    self.events:GiveTask(self.Controllers.UserInput:Get("Mouse").LeftDown:Connect(function()
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

function Werewolf:Activate(werewolves)
    self:_showCostumes(werewolves)

    local isWerewolf = table.find(werewolves, self.Player.Name)~=nil
    if isWerewolf then
        self.werewolfCostumes[self.Player.Name]:AddClaws()
        self:_activateWerewolf()
    end
end

function Werewolf:Start()
	
end


function Werewolf:Init()
    logger = self.Shared.Logger.new()
    self.touchedParts = {}
end


return Werewolf