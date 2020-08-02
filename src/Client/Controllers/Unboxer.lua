local Unboxer = {SkinImages = {Claw = "rbxassetid://739858890", Gun = "rbxassetid://739858777"}}

function Unboxer:Unbox(skin, skinType)
    self.Services.PlayerService.PlayerMandatoryUnavailable:Fire(true)

    local crateModel = self:Step_VisualSetup(skin, skinType)
    self:Step_ListenForClicks(crateModel, skin, skinType)
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

function Unboxer:Step_ListenForClicks(crateModel, skin, skinType)
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

        if crate ~= crateModel then
            return
        end

        if (clickNumber < 3) then
            if shaking then
                return
            end
            shaking = true

            self:Step_ShakeCrate(crateModel, clickNumber)
            clickNumber = clickNumber + 1

            shaking = false
        else
            self._events:DoCleaning()
            self:Step_OpenCrate(crateModel, skin, skinType)
        end
    end))
end

function Unboxer:initRisePart(crateModel, skin, skinType)
    local risePart = self.Shared.Resource:Load(skinType .. "Clone")

    if skin.Texture:find(",") then
        risePart.BrickColor =
        BrickColor.new(Color3.fromRGB(skin.Texture:match("(%d+),(%d+),(%d+)")))
    else
        risePart.Mesh.TextureId = skin.Texture
    end

    if skin.Tint then
        risePart.BrickColor = BrickColor.new(skin.Tint)
    end

    risePart.CFrame = CFrame.new(workspace.CrateOpenArea.CrateGoTo.CFrame.p) *
                      CFrame.Angles(-math.pi / 2, 0, -math.pi)
    risePart.Parent = crateModel

    return risePart
end

function Unboxer:riseFromCrate(risePart)
    local camera = workspace.CurrentCamera

    local upVect = camera.CFrame:vectorToObjectSpace(Vector3.FromNormalId(Enum.NormalId.Top)) * 8
    local backVect = camera.CFrame:vectorToObjectSpace(Vector3.FromNormalId(Enum.NormalId.Back)) * 5

    local startCamCf, endCamCf = camera.CFrame, camera.CFrame + upVect + backVect
    local startPartCf, endPartCf = risePart.CFrame, risePart.CFrame + upVect

    local riseTween = self.Modules.Tween.new(TweenInfo.new(2.2, Enum.EasingStyle.Sine,
                                                           Enum.EasingDirection.InOut),
                                             function(ratio)
        camera.CFrame = startCamCf:Lerp(endCamCf, ratio)
        risePart.CFrame = startPartCf:Lerp(endPartCf, ratio)
    end)

    riseTween:Play()
    riseTween.Completed:Wait();
end

function Unboxer:spinPart(risePart)
    local spin = self.Modules.Tween.fromService(risePart, TweenInfo.new(3, Enum.EasingStyle.Linear,
                                                                        Enum.EasingDirection.Out,
                                                                        math.huge), {
        Rotation = risePart.Rotation + Vector3.new(0, 0, 360)
    })

    spin:Play()

    return function()
        spin:Cancel()
        risePart:Destroy()
    end
end

function Unboxer:updateGuiPositions(gui, risePart)
    local halfY = Vector3.new(0, risePart.Size.y / 2, 0)
    local topPos = workspace.CurrentCamera:WorldToScreenPoint(risePart.Position + halfY)
    local bottomPos = workspace.CurrentCamera:WorldToScreenPoint(risePart.Position - halfY)

    local names, rarity = gui.Names, gui.Rarity
    local pixelOffset = 8

    names.Position = UDim2.new(0, 0, 0, topPos.y) -
                     UDim2.new(0, 0, 0, names.AbsoluteSize.y - pixelOffset)
    rarity.Position = UDim2.new(0, 0, 0, bottomPos.y) - UDim2.new(0, 0, 0, pixelOffset)
end

function Unboxer:tweenIn(gui)
    local function newTween(label, additionalProperties)
        additionalProperties = additionalProperties or {}
        additionalProperties.TextTransparency = 0

        return self.Modules.Tween.FromService(label, TweenInfo.new(1), additionalProperties)
    end

    local tweens = {
        newTween(gui.Names.ItemName), newTween(gui.Names.YouUnboxed, {TextStrokeTransparency = 0.7}),
        newTween(gui.Rarity.RarityLabel), newTween(gui.Rarity.SkinRarity)
    }

    table.foreach(tweens, function(_, tween) tween:Play() end)
    tweens[1].Completed:Wait()

    local showContinue = newTween(gui.Rarity.Continue,
                                  {BackgroundTransparency = 0.8, TextStrokeTransparency = 0.7})
    showContinue:Play()
end

function Unboxer:showGui(risePart, skin, skinType)
    local gui = self.Shared.Resource:Load("UnboxingGui")

    gui.Names.ItemName.Text = skin.Name

    local RarityColors = {
        Rare = Color3.new(252, 159, 0),
        Uncommon = Color3.new(0, 252, 252),
        Common = Color3.new(255, 255, 255)
    }

    gui.Rarity.SkinRarity.Text = (skin.IsVip and "VIP - " or "") .. skin.Rarity
    gui.Rarity.SkinRarity.TextColor3 = skin.IsVip and Color3.new(143, 0, 252) or
                                       RarityColors[skin.Rarity]

    self._events:GiveTask(gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(
                          function() self:updateGuiPositions(gui, risePart) end))

    gui.Parent = game.Players.LocalPlayer.PlayerGui

    self:tweenIn(gui)

    return gui
end

function Unboxer:Step_Cleanup(gui, cleanupRisePart)
    self._events:DoCleaning()
    gui:Destroy()
    cleanupRisePart()
    workspace.CurrentCamera.CameraSubject = game.Players.LocalPlayer.Character
    workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    self.Services.PlayerService.PlayerMandatoryUnavailable:Fire(false)
end

function Unboxer:Step_OpenCrate(crateModel, skin, skinType)
    local risePart = self:initRisePart(crateModel, skin, skinType)

    crateModel.ClickPart.Smoke.Enabled = true
    self:riseFromCrate(risePart)

    local cleanupRisePart = self:spinPart(risePart)
    local gui = self:showGui(risePart, skin, skinType)

    self._events:GiveTask(gui.Rarity.Continue.MouseButton1Click:Connect(
                          function() self:Step_Cleanup(gui, cleanupRisePart) end))
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

    self:RegisterEvent("AcceptedItem")
end

return Unboxer
