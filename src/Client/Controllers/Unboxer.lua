local Unboxer = {}

function Unboxer:Unbox(skin)
    self.Services.PlayerService.PlayerAvailabilityChanged:Fire(false)

    self:step_Setup()
end

function Unboxer:step_Setup()
	self:tweenInCamera()
end

function Unboxer:tweenInCamera()
    local camera, crateArea = workspace.CurrentCamera, workspace.CrateOpenArea
    local startCf, endCf = crateArea.CameraGoTo1.CFrame, crateArea.CameraGoTo2.CFrame

    local tween = self.Modules.Tween.new(TweenInfo.new(1, Enum.EasingStyle.Sine),
                                         function(n) camera.CFrame = startCf:Lerp(endCf, n) end)

    tween:Play()
	tween.Completed:Wait()
end

function Unboxer:Start() end

function Unboxer:Init() self._logger = self.Shared.Logger.new() end

return Unboxer
