local HumanGunDriver = {}
HumanGunDriver.__index = HumanGunDriver

local logger

function HumanGunDriver.new(tool)
    local self = setmetatable({
        tool = tool,
        gui = HumanGunDriver.Shared.Resource:Load("CollectedAmmoGui"):Clone(),

        ammo = 0,
        maxAmmo = HumanGunDriver.Shared.Settings.MaxAmmo,
        lastFired = tick(),

        fireDistance = HumanGunDriver.Shared.Settings.BulletFireDistance
    }, HumanGunDriver)

    self:_updateAmmoLabel()

    return self
end

function HumanGunDriver:_canFire()
    local now = tick()

    if now - self.lastFired <= 0.4 or self.ammo == 0 then
        return false
    end

    self.lastFired = now
    return true
end

function HumanGunDriver:_fireBullet()
    self.Services.InRoundService.PlayFireSound:Fire()

    local ray = self.Controllers.UserInput:Get("Mouse"):GetRay(self.fireDistance)
    local hitPart, hitPosition = workspace:FindPartOnRay(ray, game.Players.LocalPlayer.Character)

    if hitPart then
        local player = self.Shared.PlayerUtil.GetPlayerFromPart(hitPart)
        if player then
            self.Services.InRoundService.HitPlayer:Fire(player, hitPart.Name, (hitPosition - ray.Origin).magnitude)
        end
    end
end

function HumanGunDriver:_updateAmmoLabel()
    self.gui.Background.CollectedAmmo.Text = ("%.2d / 12"):format(self.ammo)
end

function HumanGunDriver:Activated()
    if not self:_canFire() then
        if self.ammo == 0 then
            self.tool.Handle.Empty:Play()
        end

        return
    end

    self:_fireBullet()
    self.ammo = self.ammo - 1
    self:_updateAmmoLabel()
end

function HumanGunDriver:Equipped()
    if self.gui then
        self.gui.Parent = game.Players.LocalPlayer.PlayerGui
    end
end

function HumanGunDriver:Unequipped()
    if self.gui then
        self.gui.Parent = nil
    end
end

function HumanGunDriver:GiveBullet()
    if self.ammo >= self.maxAmmo then
        logger:Warn("Cannot give bullets past the max")
        return
    end

    self.ammo = self.ammo + 1
    self:_updateAmmoLabel()
end

function HumanGunDriver:Destroy()
    self.gui:Destroy()
end

function HumanGunDriver:GetAmmo()
    return self.ammo
end

function HumanGunDriver:Init()
    logger = self.Shared.Logger.new()
end

return HumanGunDriver
