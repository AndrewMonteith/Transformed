local AmmoReloadStation = {}

local logger

local function updateVisuals(reloadStation, active)
    AmmoReloadStation.Modules.Tween.fromService(reloadStation.WindowDoor, TweenInfo.new(.3, Enum.EasingStyle.Linear),
                                                {Transparency = active and 1 or 0}):Play()

    reloadStation.Lightbulb.PointLight.Enabled = active
    reloadStation.Lightbulb.Particles.Gunpowder.Enabled = active

    if active then
        AmmoReloadStation.Shared.Resource:Load("AmmoStationBillboard"):Clone().Parent = reloadStation
    else
        reloadStation.AmmoStationBillboard:Destroy()
    end

    local newColor = active and BrickColor.new("Bright green") or BrickColor.new("Institutional white")
    for i = 1, 6 do
        local greenLight = reloadStation.GreenLights["Light" .. i]
        if greenLight.BrickColor ~= newColor then
            greenLight.BrickColor = newColor
            wait(.15)
        end
    end
end

function AmmoReloadStation:_getClosestReloadStation()
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

function AmmoReloadStation:_removeBullet(reloadStation)
    for i = 6, 1, -1 do
        local ammoLight = reloadStation.GreenLights["Light" .. i]
        if ammoLight.BrickColor == BrickColor.new("Bright green") then
            ammoLight.BrickColor = BrickColor.new("Institutional white")

            if i > 1 then
                return
            end
        end
    end

    coroutine.wrap(updateVisuals)(reloadStation, false)
    self.Shared.TableUtil.FastRemoveFirstValue(self._activeReloadStations, reloadStation)
end

function AmmoReloadStation:DistanceTick(dt)
    local currentClosestStation, distance = self:_getClosestReloadStation()
    if (not currentClosestStation) or distance > self.Shared.Settings.ReloadStationDistance then
        self.timeNearStation = 0
        return
    end

    if self.closestStation ~= currentClosestStation then
        self.closestStation = currentClosestStation
        self.timeNearStation = 0
    end

    self.timeNearStation = self.timeNearStation + dt

    local canGetBullet = self.timeNearStation >= self.Shared.Settings.TimePerBullet and (not self.gettingBullet) and
                         self.Controllers.Gun:GetAmmo() < self.Shared.Settings.MaxAmmo

    if canGetBullet then
        self.gettingBullet = true

        local approvedBullet = self.Services.InRoundService:RequestBulletFromStation(self.closestStation)
        if approvedBullet then
            self.timeNearStation = 0
            self:FireEvent("GotBullet")
            self:_removeBullet(self.closestStation)
        else
            logger:Warn("Server did not grant bullet")
        end

        self.gettingBullet = false
    end
end

function AmmoReloadStation:_removeReloadStation(reloadStation)
    table.remove(self._activeReloadStations, table.find(self._activeReloadStations, reloadStation))
    updateVisuals(reloadStation, false)
end

function AmmoReloadStation:Activate(reloadStations)
    self._activeReloadStations = reloadStations

    for _, reloadStation in pairs(reloadStations) do
        coroutine.wrap(updateVisuals)(reloadStation, true)
    end

    self.heartbeat = game:GetService("RunService").Heartbeat:Connect(
                     function(dt)
        self:DistanceTick(dt)
    end)
end

function AmmoReloadStation:Deactivate()
    if not self._activeReloadStations then
        return
    end

    for _, reloadStation in pairs(self._activeReloadStations) do
        coroutine.wrap(updateVisuals)(reloadStation, false)
    end

    self.heartbeat:Disconnect()
    self.heartbeat = nil
    self._activeReloadStations = nil
end

function AmmoReloadStation:Start()
    local collectionService = game:GetService("CollectionService")
    local heartbeat;

    collectionService:GetInstanceAddedSignal("ActiveReloadStation"):Connect(
    function(reloadStation)
        if self.Controllers.Werewolf:IsWerewolf() then
            return
        end

        logger:Log("Got reload station:", reloadStation)

        self._activeReloadStations[#self._activeReloadStations + 1] = reloadStation
        updateVisuals(reloadStation, true)

        if #self._activeReloadStations > 0 and not heartbeat then
            logger:Log("Activate heartbeat")
            heartbeat = game:GetService("RunService").Heartbeat:Connect(
                        function(dt)
                self:DistanceTick(dt)
            end)
        end
    end)

    collectionService:GetInstanceRemovedSignal("ActiveReloadStation"):Connect(
    function(reloadStation)
        if self.Controllers.Werewolf:IsWerewolf() then
            return
        end

        table.remove(self._activeReloadStations, table.find(self._activeReloadStations, reloadStation))
        updateVisuals(reloadStation, false)

        if #self._activeReloadStations == 0 then
            if heartbeat then
                heartbeat:Disconnect()
                heartbeat = nil
            end
        end
    end)
end

function AmmoReloadStation:Init()
    logger = self.Shared.Logger.new()
    self.timeNearStation = 0
    self._activeReloadStations = {}

    self:RegisterEvent("GotBullet")
end

return AmmoReloadStation
