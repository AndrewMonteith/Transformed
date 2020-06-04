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

local function isValidDamageRequest(shooter, shot)
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

	return true
end

local function clientDamageRequest(shooter, shotPlayerName, hit, distance)
	local shotPlayer = InRoundService.Shared.PlayerUtil.GetPlayerFromName(shotPlayerName)
	logger:Log(shooter, " has claimed they shot ", shotPlayer)

	if not isValidDamageRequest(shooter, shotPlayer) then
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

function InRoundService:Start()
	self:ConnectClientEvent("HitPlayer", clientDamageRequest)
	self:ConnectClientEvent("PlayFireSound", playFireEffect)
end

function InRoundService:Init()
	self:RegisterClientEvent("HitPlayer")	
	self:RegisterClientEvent("PlayFireSound")
	logger = self.Shared.Logger.new()
	MaxBulletDistance = self.Shared.Settings.BulletFireDistance
end


return InRoundService