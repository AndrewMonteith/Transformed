local AmmoReloadStation = {}

local logger

local function updateVisuals(reloadStation, active)
	AmmoReloadStation.Modules.Tween.fromService(
		reloadStation.WindowDoor, TweenInfo.new(.3, Enum.EasingStyle.Linear), {Transparency = active and 1 or 0}):Play()

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

	for _, reloadStation in pairs(self.reloadStations) do
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
	self.Shared.TableUtil.FastRemoveFirstValue(self.reloadStations, reloadStation)
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

	local canGetBullet = self.timeNearStation >= self.Shared.Settings.TimePerBullet and 
						 (not self.gettingBullet) and 
						 self.Modules.HumanGunDriver:GetAmmo() < self.Shared.Settings.MaxAmmo

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

function AmmoReloadStation:SetActive(reloadStations, active)
	self.reloadStations = reloadStations
	
	for _, reloadStation in pairs(reloadStations) do
		coroutine.wrap(updateVisuals)(reloadStation, active)
	end

	if active then
		self.heartbeat = game:GetService("RunService").Heartbeat:Connect(function(dt)
			self:DistanceTick(dt)
		end)
	elseif self.heartbeat then
		self.heartbeat:Disconnect()
		self.heartbeat = nil
		self.reloadStations = nil
	end
end

function AmmoReloadStation:Start()
end

function AmmoReloadStation:Init()
	logger = self.Shared.Logger.new()
	self.timeNearStation = 0

	self:RegisterEvent("GotBullet")
end


return AmmoReloadStation