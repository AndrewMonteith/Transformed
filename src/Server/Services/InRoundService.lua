-- In Round Service
-- Username
-- June 3, 2020
local InRoundService = {Client = {}}

function InRoundService:playFireEffect(shotPlayer)
    local fireSoundEffect = self.Shared.Resource:Load("GunFire"):Clone()
    local playerHead = shotPlayer.Character:FindFirstChild("Head")

    if playerHead then
        fireSoundEffect.Parent = playerHead
        fireSoundEffect.PlayOnRemove = true
        fireSoundEffect:Destroy()
    end
end

function InRoundService:damageHumanoid(humanoid, damager, damage)
    self._damageLog[humanoid.Parent.Name] = {By = damager.Name, When = tick()}
    humanoid:TakeDamage(damage)
end

function InRoundService:isValidGunDamageRequest(shooter, shot)
    local shooterTeam = self.Services.TeamService:GetTeam(shooter)
    local shotTeam = self.Services.TeamService:GetTeam(shot)

    if shooterTeam == "Lobby" or shotTeam == "Lobby" then
        self._logger:Warn("Denied shot request as someone was on the lobby team")
        return
    end

    local shooterHead = shooter.Character:FindFirstChild("Head")
    local shotHead = shot.Character:FindFirstChild("Head")
    local maxBulletDistance = self.Shared.SharedSettings.BulletFireDistance
    local playersClose = (shooterHead.Position - shotHead.Position).magnitude < maxBulletDistance
    if not (shooterHead and shooterHead and playersClose) then
        self._logger:Warn("Denied shot request as people were too far away")
        return
    end

    local userAmmo = self._userAmmo[shooter]
    if userAmmo == 0 then
        self._logger:Warn("Denied shot request as user had no ammo")
        return
    end

    return true
end

function InRoundService:clientGunDamageRequest(shooter, shotPlayer, hitPartName, distance)
    self._logger:Log(shooter, " has claimed they shot ", shotPlayer)

    if not self:isValidGunDamageRequest(shooter, shotPlayer) then
        return
    end

    local shotHumanoid = shotPlayer.Character:FindFirstChildOfClass("Humanoid")
    if shotHumanoid then
        local maxBulletDistance = self.Shared.SharedSettings.BulletFireDistance
        local damageToTake = 25 + 20 *
                             (1 - math.min(distance, maxBulletDistance) / maxBulletDistance)

        if hitPartName:find("Head") then
            damageToTake = damageToTake + 5
        end

        self:damageHumanoid(shotHumanoid, shooter, damageToTake)
    else
        self._logger:Warn("Could not find humanoid for ", shotPlayer.Name)
    end
end

function InRoundService.Client:RequestBulletFromStation(player, reloadStation)
    if InRoundService._userAmmo[player] == InRoundService.Shared.SharedSettings.MaxAmmo then
        self._logger:Warn(player, " requested a bullet but already has max ammo")
        return false
    end

    self._userAmmo[player] = InRoundService._userAmmo[player] + 1

    self._logger:Log(player, " requested a bullet from ", reloadStation)
    return true
end

function InRoundService:_isValidClawDamageRequest(werewolf, hitPlayer)
    local werewolfTeam = self.Services.TeamService:GetTeam(werewolf)
    local hitPlayerTeam = self.Services.TeamService:GetTeam(hitPlayer)

    if werewolfTeam ~= "Werewolf" or hitPlayerTeam ~= "Human" then
        self._logger:Warn(werewolf, " sent an invalid werewolf damage request because of teams")
        return
    end

    return true
end

function InRoundService:clientClawDamageRequest(werewolf, hitPlayer)
    if not self:_isValidClawDamageRequest(werewolf, hitPlayer) then
        self._logger:Warn("Invalid werewolf request from ", werewolf)
        return
    end

    local hitHumanoid = hitPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hitHumanoid then
        self:damageHumanoid(hitHumanoid, werewolf, 65)
    else
        self._logger:Warn("Could not find humanoid in ", hitHumanoid)
    end
end

function InRoundService:GetPlayerKills() return self._playerKills:RawDictionary() end

function InRoundService:roundStarted()
    self._logger:Warn("This should be called by DayNightCycle as well")
    self._userAmmo = self.Shared.PlayerDict.new()
    self._damageLog = self.Shared.PlayerDict.new()
    self._playerKills = self.Shared.PlayerDict.new {listenForPlayerRemoving = false}

    for _, player in pairs(self.Services.PlayerService:GetPlayersInRound()) do
        self._userAmmo[player] = 0
        self._playerKills[player] = 0

        local team = self.Services.TeamService:GetTeam(player)

        -- we put the tool in PlayerGui so the client scripts can find it
        -- initalise it then put it in the backpack
        self.Shared.Resource:Load(team .. "Gun"):Clone().Parent = player.PlayerGui
    end

    self._deathConnection = self.Services.PlayerService:ConnectEvent("PlayerLeftRound",
                                                                     function(player)
        local damageLogEntry = self._damageLog[player]
        if (not damageLogEntry) or tick() - damageLogEntry.When >= 1.5 then
            self._logger:Log(player, " left round of natural causes")
            return
        end

        self._playerKills[damageLogEntry.By] = self._playerKills[damageLogEntry.By] + 1
    end)
end

local function clearActiveReloadStations()
    local collectionService = game:GetService("CollectionService")
    for _, activeReloadStation in pairs(collectionService:GetTagged("ActiveReloadStation")) do
        collectionService:RemoveTag(activeReloadStation, "ActiveReloadStation")
    end
end

function InRoundService:roundEnded()
    self._userAmmo:Destroy()
    self._playerKills:Destroy()
    self._damageLog:Destroy()
    self._deathConnection:Disconnect()
    clearActiveReloadStations()
end

function InRoundService:sunrise()
    local collectionService = game:GetService("CollectionService")
    local reloadStations = workspace.TestAmmoStations:GetChildren()
    self.Shared.TableUtil.Shuffle(reloadStations)
    collectionService:AddTag(reloadStations[1], "ActiveReloadStation")
    collectionService:AddTag(reloadStations[2], "ActiveReloadStation")

    for _, player in pairs(self.Services.PlayerService:GetPlayersInRound()) do
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.HealthDisplayType = "AlwaysOff"
        end
    end
end

function InRoundService:sunset()
    clearActiveReloadStations()

    for _, player in pairs(self.Services.PlayerService:GetPlayersInRound()) do
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.HealthDisplayType = "AlwaysOn"
        end
    end
end

function InRoundService:Start()
    self:ConnectClientEvent("PlayFireSound", function(...) self:playFireEffect(...) end)
    self:ConnectClientEvent("HitPlayer", function(...) self:clientGunDamageRequest(...) end)
    self:ConnectClientEvent("ClawPlayer", function(...) self:clientClawDamageRequest(...) end)

    local rs = self.Services.RoundService
    rs:ConnectEvent("RoundStarted", function() self:roundStarted() end)
    rs:ConnectEvent("RoundEnded", function() self:roundEnded() end)

    local dnc = self.Services.DayNightCycle
    dnc:ConnectEvent("Sunrise", function() self:sunrise() end)
    dnc:ConnectEvent("Sunset", function() self:sunset() end)
end

function InRoundService:Init()
    self:RegisterClientEvent("HitPlayer")
    self:RegisterClientEvent("PlayFireSound")
    self:RegisterClientEvent("ClawPlayer")

    self._logger = self.Shared.Logger.new()
end

return InRoundService
