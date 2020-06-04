-- In Round Service
-- Username
-- June 3, 2020

local InRoundService = {Client = {}}

local logger

local function playFireEffect(shotPlayer)
	local fireSoundEffect = InRoundService.Shared.Resource:Load("GunFire"):Clone()
	local playerHead = shotPlayer.Character:FindFirstChild("Head")

	if playerHead then
		fireSoundEffect.Parent = playerHead
		fireSoundEffect.PlayOnRemove = true
		fireSoundEffect:Destroy()
	end
end

local function clientDamageRequest(shooter, shotName)
	local shotPlayer = InRoundService.Shared.PlayerUtil.GetPlayerFromName(shotName)
	
	logger:Log(shooter, " has claimed they shot ", shotPlayer)
	logger:Log("Shot someone on the team:", InRoundService.Services.TeamService:GetTeam(shotPlayer))
end

function InRoundService:Start()
	self:ConnectClientEvent("HitPlayer", clientDamageRequest)
	self:ConnectClientEvent("PlayFireSound", playFireEffect)
end

function InRoundService:Init()
	self:RegisterClientEvent("HitPlayer")	
	self:RegisterClientEvent("PlayFireSound")
	logger = self.Shared.Logger.new()
end


return InRoundService