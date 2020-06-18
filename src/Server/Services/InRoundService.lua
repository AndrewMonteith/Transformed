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

function InRoundService:_isValidGunDamageRequest(shooter, shot)
    local shooterTeam = self.Services.TeamService:GetTeam(shooter)
    local shotTeam = self.Services.TeamService:GetTeam(shot)

    if shooterTeam == "Lobby" or shotTeam == "Lobby" then
        logger:Warn("Denied shot request as someone was on the lobby team")
        return
    end

    local shooterHead = shooter.Character:FindFirstChild("Head")
    local shotHead = shot.Character:FindFirstChild("Head")

    if not (shooterHead and shooterHead) or (shooterHead.Position - shotHead.Position).magnitude > MaxBulletDistance + 8 then
        logger:Warn("Denied shot request as people were too far away")
        return
    end

    local userAmmo = self._userAmmo[shooter]
    if userAmmo == 0 then
        logger:Warn("Denied shot request as user had no ammo")
        return
    end

    return true
end

function InRoundService:_clientGunDamageRequest(shooter, shotPlayer, hitPartName, distance)
    logger:Log(shooter, " has claimed they shot ", shotPlayer)

    if not self:_isValidGunDamageRequest(shooter, shotPlayer) then
        return
    end

    local shotHumanoid = shotPlayer.Character:FindFirstChildOfClass("Humanoid")
    if shotHumanoid then
        local damageToTake = 25 + 20 * (1 - math.min(distance, MaxBulletDistance) / MaxBulletDistance)

        if hitPartName:find("Head") then
            damageToTake = damageToTake + 5
        end

        shotHumanoid:TakeDamage(damageToTake)
    else
        logger:Warn("Could not find humanoid for ", shotPlayer.Name)
    end
end

function InRoundService.Client:RequestBulletFromStation(player, reloadStation)
    if InRoundService._userAmmo[player] == InRoundService.Shared.Settings.MaxAmmo then
        logger:Warn(player, " requested a bullet but already has max ammo")
        return false
    end

    InRoundService._userAmmo[player] = InRoundService._userAmmo[player] + 1

    logger:Log(player, " requested a bullet from ", reloadStation)
    return true
end

function InRoundService:_isValidClawDamageRequest(werewolf, hitPlayer)
    local werewolfTeam = self.Services.TeamService:GetTeam(werewolf)
    local hitPlayerTeam = self.Services.TeamService:GetTeam(hitPlayer)

    if werewolfTeam ~= "Werewolf" or hitPlayerTeam ~= "Human" then
        logger:Warn(werewolf, " sent an invalid werewolf damage request because of teams")
        return
    end

    return true
end

function InRoundService:_clientClawDamageRequest(werewolf, hitPlayer)
    if not self:_isValidClawDamageRequest(werewolf, hitPlayer) then
        logger:Warn("Invalid werewolf request from ", werewolf)
        return
    end

    local hitHumanoid = hitPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hitHumanoid then
        hitHumanoid:TakeDamage(65)
    else
        logger:Warn("Could not find humanoid in ", hitHumanoid)
    end
end

function InRoundService:_roundStarted()
    logger:Warn("This should be called by DayNightCycle as well")
    self._userAmmo = self.Shared.PlayerDict.new()

    for _, player in pairs(self.Services.PlayerService:GetPlayersInRound()) do
        self._userAmmo[player] = 0

        local team = self.Services.TeamService:GetTeam(player)

        -- we put the tool in PlayerGui so the client scripts can find it
        -- initalise it then put it in the backpack
        self.Shared.Resource:Load(team .. "Gun"):Clone().Parent = player.PlayerGui
    end
end

function InRoundService:_roundEnded()
    self._userAmmo:Destroy()
end

function InRoundService:_sunrise()
    local reloadStations = workspace.TestAmmoStations:GetChildren()
    self.Shared.TableUtil.Shuffle(reloadStations)
    reloadStations = {reloadStations[1], reloadStations[2]}

    for _, player in pairs(self.Services.PlayerService:GetPlayersInRound()) do
        local team = self.Services.TeamService:GetTeam(player)
        if team == "Human" then
            self:FireClient("ActivateReloadStations", player, reloadStations)
        end

        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.HealthDisplayType = "AlwaysOff"
        end
    end
end

function InRoundService:_sunset()
    for _, player in pairs(self.Services.PlayerService:GetPlayersInRound()) do
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.HealthDisplayType = "AlwaysOn"
        end
    end
end

function InRoundService:Start()
    self:ConnectClientEvent("PlayFireSound", playFireEffect)
    self:ConnectClientEvent("HitPlayer", function(...)
        self:_clientGunDamageRequest(...)
    end)
    self:ConnectClientEvent("ClawPlayer", function(...)
        self:_clientClawDamageRequest(...)
    end)

    local rs = self.Services.RoundService
    rs:ConnectEvent("RoundStarted", function()
        self:_roundStarted()
    end)
    rs:ConnectEvent("RoundEnded", function()
        self:_roundEnded()
    end)

    local dnc = self.Services.DayNightCycle
    dnc:ConnectEvent("Sunrise", function()
        self:_sunrise()
    end)
    dnc:ConnectEvent("Sunset", function()
        self:_sunset()
    end)
end

function InRoundService:Init()
    self:RegisterClientEvent("HitPlayer")
    self:RegisterClientEvent("PlayFireSound")
    self:RegisterClientEvent("ClawPlayer")

    self:RegisterClientEvent("ActivateReloadStations")

    logger = self.Shared.Logger.new()
    MaxBulletDistance = self.Shared.Settings.BulletFireDistance
end

return InRoundService
