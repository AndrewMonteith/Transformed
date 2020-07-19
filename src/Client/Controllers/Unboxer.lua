local Unboxer = {SkinImages = {Claw = "rbxassetid://739858890", Gun = "rbxassetid://739858777"}}

function Unboxer:Unbox(skin, skinType)
    self.Services.PlayerService.PlayerAvailabilityChanged:Fire(false)

    local crateModel = self:Step_VisualSetup(skin, skinType)
    self:Step_ListenForClicks(crateModel)
end

function Unboxer:Step_VisualSetup(skin, skinType)
    local crateModel = self.Shared.Resource:Load("Crates")[skin.Rarity]:Clone()
    crateModel.PrimaryPart = crateModel.Primary
    crateModel.Icon.Decal.Texture = Unboxer.SkinImages[skinType]

    crateModel.Parent = workspace
    crateModel:SetPrimaryPartCFrame(CFrame.new(workspace.CrateOpenArea.CrateGoTo.CFrame.p,
                                               workspace.CrateOpenArea.CameraGoTo2.CFrame.p))

    self:tweenInCamera()

    return crateModel
end

function Unboxer:Step_ShakeCrate(crate, clickNumber)
    local numberOfOscillations, dampening = 8, 0.8
    local maxAmplitude = 1 + (clickNumber - 1) * 1.5

    local function eqn(ratio)
        local x = math.pi * 2 * ratio
        return math.exp(-dampening * x) * math.sin(numberOfOscillations * x)
    end

    local origCf = crate:GetPrimaryPartCFrame()
    local rightVector = Vector3.FromNormalId(Enum.NormalId.Right)
    local amplitudeVector = origCf:vectorToObjectSpace(rightVector) * maxAmplitude

    local tween = self.Modules.Tween.new(TweenInfo.new(.7, Enum.EasingStyle.Linear), function(ratio)
        local r = eqn(ratio)
        crate:SetPrimaryPartCFrame(origCf + amplitudeVector * r)
    end)

    tween:Play()
    tween.Completed:Wait()
end

function Unboxer:Step_ListenForClicks(crateModel)
    local function getCrateFromClick(part)
        while not part:FindFirstChild("Primary") do
            part = part.Parent
        end
        return part
    end

    local mouse = self.Controllers.UserInput:Get("Mouse")
    local clickNumber, shaking = 1, false
    self._events:GiveTask(mouse:ConnectEvent("LeftDown", function()
        local crate = getCrateFromClick(mouse:GetTarget())

        if crate == crateModel and (not shaking) then
            shaking = true
            self:Step_ShakeCrate(crateModel, clickNumber)
            clickNumber = clickNumber + 1
            shaking = false
        end
    end))
end

function Unboxer:tweenInCamera()
    local camera, crateArea = workspace.CurrentCamera, workspace.CrateOpenArea
    local goto1Cf, goto2Cf = crateArea.CameraGoTo1.CFrame, crateArea.CameraGoTo2.CFrame

    local direction = goto2Cf.p - goto1Cf.p
    local startCf = CFrame.new(goto1Cf.p, goto1Cf.p + direction)
    local endCf = CFrame.new(goto2Cf.p, goto2Cf.p + direction)

    local tween = self.Modules.Tween.new(TweenInfo.new(1, Enum.EasingStyle.Sine),
                                         function(n) camera.CFrame = startCf:Lerp(endCf, n) end)

    camera.CameraType = Enum.CameraType.Scriptable
    tween:Play()
    tween.Completed:Wait()
end

function Unboxer:Start() end

function Unboxer:Init()
    self._logger = self.Shared.Logger.new()
    self._events = self.Shared.Maid.new()
end

return Unboxer
