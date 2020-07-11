local Unboxer = {}

function Unboxer:Unbox(skin)
    self.Services.PlayerService.PlayerAvailabilityChanged:Fire(false)

    local crateModel = self:Step_VisualSetup()
    self:Step_ListenForClicks(crateModel)
end

function Unboxer:Step_VisualSetup()
    self:tweenInCamera()
end

function Unboxer:Step_ShakeCrate()

end

function Unboxer:Step_ListenForClicks(crateModel)
    local mouse = self.Controllers.UserInput:Get("Mouse")

    self._events:GiveTask(mouse:ConnectEvent("LeftDown", function()
        if mouse:GetTarget() == crateModel then
            self:Step_ShakeCrate(crateModel)
        end
    end))
end

function Unboxer:tweenInCamera()
    local camera, crateArea = workspace.CurrentCamera, workspace.CrateOpenArea
    local startCf, endCf = crateArea.CameraGoTo1.CFrame, crateArea.CameraGoTo2.CFrame

    local tween = self.Modules.Tween.new(TweenInfo.new(1, Enum.EasingStyle.Sine), function(n)
        camera.CFrame = startCf:Lerp(endCf, n)
    end)

    tween:Play()
    tween.Completed:Wait()
end

function Unboxer:Start() end

function Unboxer:Init()
    self._logger = self.Shared.Logger.new()
    self._events = self.Shared.Maid.new()
end

return Unboxer
