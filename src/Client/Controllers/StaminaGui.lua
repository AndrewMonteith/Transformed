local StaminaGui = {}

local JumpStamina = 37.5
local StaminaRechargeRate = 8

function StaminaGui:SetStamina(stamina)
    self._stamina = math.clamp(stamina, 0, self._maxStamina)

    local xScale = self._stamina / self._maxStamina
    self._gui.Background.GreenBar.ClipContainer.Size = UDim2.new(xScale, 0, 1, 0)
end

function StaminaGui:changeStamina(dStamina) self:SetStamina(self._stamina + dStamina) end

function StaminaGui:staminaLoopTick(dt)
    local dStamina = dt * StaminaRechargeRate
    local incOrDecreasing = self._sprinting and -1 or 1

    self:changeStamina(dStamina * incOrDecreasing)

    if self._stamina <= 5 and self._sprinting then
        self:stopSprinting()
    end
end

function StaminaGui:jump()
    local hasStamina = self._stamina >= JumpStamina
    local onGround = self._humanoid.FloorMaterial ~= Enum.Material.Air

    if not (hasStamina and onGround and not self._jumping) then
        return
    end

    self:changeStamina(-JumpStamina)
    self._jumping = true
    self._humanoid.JumpPower = 50 + self._extraJp
    self._humanoid.Jump = true
end

function StaminaGui:startSprinting()
    local isMoving = self._humanoid.MoveDirection.magnitude > 0
    if self._stamina < 10 or (not isMoving) then
        return
    end

    self._sprinting = true
    self._humanoid.WalkSpeed = self._humanoid.WalkSpeed * 1.4 ^ 0.5
end

function StaminaGui:stopSprinting()
    self._sprinting = false
    self._humanoid.WalkSpeed = self._humanoid.WalkSpeed * 1.4 ^ -0.5
end

function StaminaGui:activate()
    self._active = true
    self._stamina = 100
    self._gui = self.Shared.Resource:Load("StaminaGui"):Clone()
    self._gui.Parent = self.Player.PlayerGui

    local keyboard = self.Controllers.UserInput:Get("Keyboard")
    self._events:GiveTask(keyboard:ConnectEvent("KeyDown", function(key)
        if key == Enum.KeyCode.Space then
            self:jump()
        elseif key == Enum.KeyCode.LeftShift and (not self._sprinting) then
            self:startSprinting()
        end
    end))

    self._events:GiveTask(keyboard:ConnectEvent("KeyUp", function(key)
        if key == Enum.KeyCode.LeftShift and self._sprinting then
            self:stopSprinting()
        end
    end))

    self._events:GiveTask(game:GetService("RunService").Heartbeat:Connect(
                          function(dt) self:staminaLoopTick(dt) end))

    self._humanoid = self.Shared.PlayerUtil.GetHumanoid()
    self._humanoid.JumpPower = 0

    self._events:GiveTask(self._humanoid.FreeFalling:Connect(
                          function()
        self._jumping = false
        self._humanoid.JumpPower = 0
    end))

    self._maxStamina = self._team == "Werewolf" and 115 or 100

    if self._team == "Werewolf" then
        self._events:GiveTask(self.Services.DayNightCycle.Sunrise:Connect(
                              function()
            if self._humanoid.WalkSpeed > 16 then
                self._humanoid.WalkSpeed = self._humanoid.WalkSpeed * (1.75 ^ -0.5)
            end
            self._extraJp = 0
        end))

        self._events:GiveTask(self.Services.DayNightCycle.Sunset:Connect(
                              function()
            self._humanoid.WalkSpeed = self._humanoid.WalkSpeed * (1.75 ^ 0.5)
            self._extraJp = 10
        end))
    end
end

function StaminaGui:destroy()
    self._active = false
    self._events:DoCleaning()
    self._humanoid.JumpPower = 50
    self._extraJp = 0
    self._humanoid = nil
    self._gui:Destroy()
end

function StaminaGui:Start()
    self.Services.TeamService.TeamChanged:Connect(function(newTeam)
        self._team = newTeam

        if newTeam == "Lobby" and self._active then
            self:destroy()
        elseif newTeam ~= "Lobby" and (not self._active) then
            self:activate()
        end
    end)
end

function StaminaGui:Init()
    self._active = false
    self._events = self.Shared.Maid.new()
    self._maxStamina = 100
    self._extraJp = 0
    self._logger = self.Shared.Logger.new()
end

return StaminaGui
