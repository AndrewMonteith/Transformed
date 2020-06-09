-- In Round Service
-- Username
-- June 3, 2020

local InRoundService = {Client = {}}

local logger, MaxBulletDistance

local function playFireEffect(shotPlayer)
	local fireSoundEffect = InRoundService.Shared.Resource:Load("GunFire"):Clone()
	local playerHead = shotPlayer.Character:FindFirstChild("Head")

	if playerHead then
		fireSoundEffect.Parent = playerHead
		fireSoundEffect.PlayOnRemove = true
		fireSoundEffect:Destroy()
	end
end

local function isValidGunDamageRequest(shooter, shot)
	local shooterTeam = InRoundService.Services.TeamService:GetTeam(shooter)
	local shotTeam = InRoundService.Services.TeamService:GetTeam(shot)

	if shooterTeam == "Lobby" or shotTeam == "Lobby" then
		logger:Warn("Denied shot request as someone was on the lobby team")
		return
	end

	local shooterHead = shooter.Character:FindFirstChild("Head")
	local shotHead = shot.Character:FindFirstChild("Head")

	if not (shooterHead and shooterHead) or (shooterHead.Position-shotHead.Position).magnitude > MaxBulletDistance+8 then
		logger:Warn("Denied shot request as people were too far away")
		return
	end

	local userAmmo = InRoundService.userAmmo[shooter]
	if userAmmo == 0 then 
		logger:Warn("Denied shot request as user had no ammo")
		return
	end

	return true
end

function InRoundService:_clientGunDamageRequest(shooter, shotPlayerName, hit, distance)
	local shotPlayer = self.Shared.PlayerUtil.GetPlayerFromName(shotPlayerName)
	logger:Log(shooter, " has claimed they shot ", shotPlayer)

	if not isValidGunDamageRequest(shooter, shotPlayer) then
		return
	end

	local shotHumanoid = shotPlayer.Character:FindFirstChildOfClass("Humanoid")
	if shotHumanoid then
		local damageToTake = 25 + 20*(1 - math.min(distance, MaxBulletDistance)/MaxBulletDistance)

		if hit:FindFirstChild("face") then
			damageToTake = damageToTake + 5
		end

		shotHumanoid:TakeDamage(damageToTake)
	else
		logger:Warn("Could not find humanoid for ", shotPlayerName)
	end
end

function InRoundService.Client:RequestBulletFromStation(player, reloadStation)
	if InRoundService.userAmmo[player] == InRoundService.Shared.Settings.MaxAmmo then
		logger:Warn(player, " requested a bullet but already has max ammo")
		return false
	end

	InRoundService.userAmmo[player] = InRoundService.userAmmo[player] + 1

	logger:Log(player, " requested a bullet from ", reloadStation)
	return true
end

function InRoundService:_clientClawDamageRequest(werewolf, hitPlayerName)
    local player = self.Shared.PlayerUtil.GetPlayerFromName(hitPlayerName)
    if not player then
        logger:Warn("Invalid werewolf request from ", werewolf)
        return
    end

    local hitPlayerTeam = self.Services.TeamService:GetTeam(player)
    if hitPlayerTeam == "Werewolf" then
        logger:Warn(werewolf, " hit another werewolf " , hitPlayerName)
        return
    end

    logger:Log(werewolf, " will damage ", hitPlayerName)
end

function InRoundService:_roundStarted()
	logger:Warn("This should be called by DayNightCycle as well")
	self.userAmmo = self.Shared.PlayerDict.new()

	for _, player in pairs(self.Services.PlayerService:GetPlayersInRound()) do
		self.userAmmo[player] = 0
	end
end

function InRoundService:_roundEnded()
	self.userAmmo:Destroy()
end

function InRoundService:Start()
	self:ConnectClientEvent("HitPlayer", function(...) self:_clientGunDamageRequest(...) end)
    self:ConnectClientEvent("PlayFireSound", playFireEffect)
    self:ConnectClientEvent("ClawPlayer", function(...) self:_clientClawDamageRequest(...) end)

	self.Services.RoundService:ConnectEvent("RoundStarted", function() self:_roundStarted() end)
	self.Services.RoundService:ConnectEvent("RoundEnded", function() self:_roundEnded() end)
end

function InRoundService:Init()
	self:RegisterClientEvent("HitPlayer")	
    self:RegisterClientEvent("PlayFireSound")
    self:RegisterClientEvent("ClawPlayer")

	logger = self.Shared.Logger.new()
	MaxBulletDistance = self.Shared.Settings.BulletFireDistance
end


return InRoundService