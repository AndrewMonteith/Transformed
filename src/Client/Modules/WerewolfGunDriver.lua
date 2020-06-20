local WerewolfGunDriver = {}
WerewolfGunDriver.__index = WerewolfGunDriver

local logger

function WerewolfGunDriver.new(tool)
    local self = setmetatable({
        tool = tool,
        gui = WerewolfGunDriver.Shared.Resource:Load("DecoyGunGui"):Clone(),
        lastFired = tick()
    }, WerewolfGunDriver)

    return self
end

function WerewolfGunDriver:_canFire()
    local now = tick()

    if now - self.lastFired <= 0.4 then
        return false
    end

    self.lastFired = now
    return true
end

function WerewolfGunDriver:Activated()
    if self:_canFire() then
        self.Services.InRoundService.PlayFireSound:Fire()
    end
end

function WerewolfGunDriver:Equipped() self.gui.Parent = game.Players.LocalPlayer.PlayerGui end

function WerewolfGunDriver:Unequipped() self.gui.Parent = nil end

function WerewolfGunDriver:Destroy() self.gui:Destroy() end

function WerewolfGunDriver:Init() logger = self.Shared.Logger.new() end

return WerewolfGunDriver
