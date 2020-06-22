local AmmoReloadStation = {}

local logger

local BulletPresentColor = BrickColor.new("Bright green")
local NoBulletColor = BrickColor.new("Institutional white")

function AmmoReloadStation:updateVisuals(reloadStation, active)
    reloadStation.Lightbulb.PointLight.Enabled = active
    reloadStation.Lightbulb.Particles.Gunpowder.Enabled = active

    if active then
        self.Shared.Resource:Load("AmmoStationBillboard"):Clone().Parent = reloadStation
    else
        reloadStation.AmmoStationBillboard:Destroy()
    end

    self.Modules.Tween.fromService(reloadStation.WindowDoor,
                                   TweenInfo.new(.3, Enum.EasingStyle.Linear),
                                   {Transparency = active and 1 or 0}):Play()

    local newColor = active and BulletPresentColor or NoBulletColor

    for i = 1, 6 do
        local greenLight = reloadStation.GreenLights["Light" .. i]
        if greenLight.BrickColor ~= newColor then
            greenLight.BrickColor = newColor
            wait(.15)
        end
    end
end

function AmmoReloadStation:getClosestReloadStation()
    local characterPosition = self.Player.Character:GetPrimaryPartCFrame().p
    local closestStation, minDistance = nil, math.huge

    for _, reloadStation in pairs(self._activeReloadStations) do
        local dist = (characterPosition - reloadStation.WindowDoor.Position).magnitude

        if dist < minDistance then
            closestStation, minDistance = reloadStation, dist
        end
    end

    return closestStation, minDistance
end

function AmmoReloadStation:removeBullet(reloadStation)
    for i = 6, 1, -1 do
        local ammoLight = reloadStation.GreenLights["Light" .. i]
        if ammoLight.BrickColor == BulletPresentColor then
            ammoLight.BrickColor = NoBulletColor

            if i > 1 then
                return
            end
        end
    end

    self:updateVisuals(reloadStation, false)
    self.Shared.TableUtil.FastRemoveFirstValue(self._activeReloadStations, reloadStation)
end

function AmmoReloadStation:distanceTick(dt)
    local currentClosestStation, distance = self:getClosestReloadStation()
    if (not currentClosestStation) or distance > self.Shared.Settings.ReloadStationDistance then
        self._timeNearStation = 0
        return
    end

    if self.closestStation ~= currentClosestStation then
        self.closestStation = currentClosestStation
        self._timeNearStation = 0
    end

    self._timeNearStation = self._timeNearStation + dt

    local canGetBullet = self._timeNearStation >= self.Shared.Settings.TimePerBullet and
                         (not self.gettingBullet) and self.Controllers.Gun:GetAmmo() <
                         self.Shared.Settings.MaxAmmo

    if canGetBullet then
        self.gettingBullet = true

        local approvedBullet = self.Services.InRoundService:RequestBulletFromStation(
                               self.closestStation)
        if approvedBullet then
            self._timeNearStation = 0
            self:FireEvent("GotBullet")
            self:removeBullet(self.closestStation)
        else
            logger:Warn("Server did not grant bullet")
        end

        self.gettingBullet = false
    end
end

function AmmoReloadStation:Start()
    local heartbeat;

    local function reloadStationActive(reloadStation)
        self._activeReloadStations[#self._activeReloadStations + 1] = reloadStation
        self:updateVisuals(reloadStation, true)

        if #self._activeReloadStations > 0 and not heartbeat then
            logger:Log("Activate heartbeat")
            heartbeat = game:GetService("RunService").Heartbeat:Connect(
                        function(dt) self:distanceTick(dt) end)
        end
    end

    local function reloadStationStopped(reloadStation)
        table.remove(self._activeReloadStations,
                     table.find(self._activeReloadStations, reloadStation))
        self:updateVisuals(reloadStation, false)

        if #self._activeReloadStations == 0 then
            if heartbeat then
                heartbeat:Disconnect()
                heartbeat = nil
            end
        end
    end

    local roundEvents = self.Shared.Maid.new()
    self.Services.TeamService.TeamChanged:Connect(function(newTeam)
        if newTeam == "Human" then
            local cs = game:GetService("CollectionService")
            roundEvents:GiveTask(cs:GetInstanceAddedSignal("ActiveReloadStation"):Connect(
                                 reloadStationActive))
            roundEvents:GiveTask(cs:GetInstanceRemovedSignal("ActiveReloadStation"):Connect(
                                 reloadStationStopped))
        else
            roundEvents:DoCleaning()
        end
    end)
end

function AmmoReloadStation:Init()
    logger = self.Shared.Logger.new()
    self._timeNearStation = 0
    self._activeReloadStations = {}

    self:RegisterEvent("GotBullet")
end

return AmmoReloadStation
