local PlayerService = {Client = {}}

function PlayerService:listenForDeaths(player)
    local function characterSpawned(character)
        local humanoid = character:WaitForChild("Humanoid")

        if not humanoid then
            self._logger:Warn("Failed to find a humanoid for player " .. player)
            return
        end

        self._playerEvents:Update(player.Name .. "_died", humanoid.Died:Connect(
                                  function()
            self._logger:Log(player, " has died.")
            if self.Shared.TestPlayer.isOne(player) then
                player:LoadCharacter()
            end

            if self.Services.TeamService:GetTeam(player) ~= "Lobby" then
                self._logger:Log(player, " has died in the round")
                self:LeaveRound(player)
            end
        end))
    end

    self._playerEvents[player.Name .. "_spawned"] = player.CharacterAdded:Connect(characterSpawned)
end

function PlayerService:spawnIntoLobby(player)
    local lobbySpawns = workspace.LobbySpawns:GetChildren()
    local randomSpawn = lobbySpawns[math.random(1, #lobbySpawns)]
    player.RespawnLocation = randomSpawn
    player:LoadCharacter()
end

function PlayerService:onPlayerAdded(player)
    self._logger:Log("Player ", player, " has joined the game")
    self._logger:Warn(player,
                      " was marked as avaliable too quickly. We still need a system to get this working.")

    self:Fire("PlayerLoaded", player)
    self._loadedPlayers[player] = true
    self:listenForDeaths(player)
    self:spawnIntoLobby(player)
end

function PlayerService:onPlayerRemoving(player)
    self._logger:Log("Player ", player, " has left the game")

    self:Fire("PlayerRemoving", player)
end

function PlayerService:GetPlayers()
    return self.Shared.TableUtil.Map(game.Players:GetChildren(), function(instance)
        if instance:IsA("Player") then
            return instance
        elseif instance:IsA("StringValue") then
            return self.Shared.TestPlayer.fromState(instance)
        else
            self._logger:Warn("Unknown player instance: ", instance)
        end
    end)
end

function PlayerService:GetAvaliablePlayers()
    return self.Shared.TableUtil.Filter(self:GetPlayers(),
                                        function(player) return self:IsAvailable(player) end)
end

function PlayerService:GetPlayersInRound()
    local players = {}

    for _, player in pairs(self:GetPlayers()) do
        local team = self.Services.TeamService:GetTeam(player)
        if team ~= "Lobby" then
            players[#players + 1] = player
        end
    end

    return players
end

function PlayerService:ConnectPlayerLoaded(callback)
    self:ConnectEvent("PlayerLoaded", callback)
    for _, player in pairs(game.Players:GetPlayers()) do
        callback(player)
    end
end

function PlayerService:LeaveRound(player)
    -- we assign the lobby team here rather than in an event connection
    -- in TeamService because other connections to the PlayerLeftRound
    -- event like in RoundService might need to guarentee the person
    -- is on the lobby team.
    self.Services.TeamService:AssignTeam(player, "Lobby")
    self:Fire("PlayerLeftRound", player)
    self:FireAllClients("PlayerLeftRound", player)
end

function PlayerService:Start()
    local players = game:GetService("Players")

    local onPlayerAdded = function(pl) self:onPlayerAdded(pl) end
    players.PlayerAdded:Connect(onPlayerAdded)
    table.foreach(players:GetPlayers(), function(_, player) onPlayerAdded(player) end)

    players.PlayerRemoving:Connect(function(player) self:onPlayerRemoving(player) end)
    self:ConnectEvent("PlayerLeftRound", function(player) self:spawnIntoLobby(player) end)
    self:ConnectClientEvent("PlayerAvailabilityChanged", function(player, available)
        self._availablePlayers[player] = available
    end)
    self:ConnectClientEvent("PlayerMandatoryUnavailable", function(player, unavailable)
        self._mandatoryUnavailable[player] = unavailable
    end)

    if self.Modules.ServerSettings.UseTestPlayers then
        local rootPlayer = game.Players:WaitForChild("ModuleMaker")

        local function newTp(name)
            return self.Shared.TestPlayer.new(rootPlayer,
                                              {Name = name, Character = {type = "Instance"}}, true)
        end
        local tp1 = newTp("TestPlayer1")
        local tp2 = newTp("TestPlayer2")
        local tp3 = newTp("TestPlayer3")

        self.Services.PlayerService:onPlayerAdded(tp1)
        self.Services.PlayerService:onPlayerAdded(tp2)
        self.Services.PlayerService:onPlayerAdded(tp3)
    end
end

function PlayerService:IsAvailable(player)
    return self._loadedPlayers[player] and self._availablePlayers[player] and
           not self._mandatoryUnavailable[player]
end

function PlayerService:Init()
    self._logger = self.Shared.Logger.new()
    self._loadedPlayers = self.Shared.PlayerDict.new()
    self._availablePlayers = self.Shared.PlayerDict.new() -- if they say they're ready
    self._mandatoryUnavailable = self.Shared.PlayerDict.new() -- if the system says they're ready
    self._playerEvents = self.Shared.PlayerDict.new()

    self:RegisterEvent("PlayerLoaded")
    self:RegisterEvent("PlayerRemoving")
    self:RegisterEvent("PlayerLeftRound")
    self:RegisterClientEvent("PlayerLeftRound")
    self:RegisterClientEvent("PlayerAvailabilityChanged")
    self:RegisterClientEvent("PlayerMandatoryUnavailable")
end

return PlayerService
