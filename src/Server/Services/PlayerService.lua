local PlayerService = {Client = {}}

local logger

function PlayerService:_listenForDeaths(player)
    local function characterSpawned(character)
        local humanoid = character:WaitForChild("Humanoid")

        if not humanoid then
            logger:Warn("Failed to find a humanoid for player " .. player)
            return
        end

        self._playerEvents:Update(player.Name .. "_died", humanoid.Died:Connect(
                                  function()
            logger:Log(player, " has died.")
            if self.Services.TeamService:GetTeam(player) ~= "Lobby" then
                logger:Log(player, " has died in the round")

                -- we assign the lobby team here rather than in an event connection
                -- in TeamService because other connections to the PlayerLeftRound
                -- event like in RoundService might need to guarentee the person
                -- is on the lobby team.
                self.Services.TeamService:AssignTeam(player, "Lobby")
                self:FireEvent("PlayerLeftRound", player)
                self:FireClient("LeftRound", player)
            end
        end))
    end

    self._playerEvents[player.Name .. "_spawned"] = player.CharacterAdded:Connect(characterSpawned)
end

function PlayerService:_spawnIntoLobby(player)
    local lobbySpawns = workspace.LobbySpawns:GetChildren()
    local randomSpawn = lobbySpawns[math.random(1, #lobbySpawns)]
    player.RespawnLocation = randomSpawn
    player:LoadCharacter()
end

function PlayerService:_onPlayerAdded(player)
    logger:Log("Player ", player, " has joined the game")
    logger:Warn(player, " was marked as avaliable too quickly. We still need a system to get this working.")

    self:Fire("PlayerLoaded", player)
    self._avaliablePlayers[player] = true
    self:_spawnIntoLobby(player)
    self:_listenForDeaths(player)
end

function PlayerService:_onPlayerRemoving(player)
    logger:Log("Player ", player, " has left the game")

    self:Fire("PlayerRemoving", player)
end

function PlayerService:GetPlayers()
    return self.Shared.TableUtil.Map(game.Players:GetChildren(), function(instance)
        if instance:IsA("Player") then
            return instance
        elseif instance:IsA("StringValue") then
            return self.Shared.TestPlayer.fromState(instance)
        else
            logger:Warn("Unknown player instance: ", instance)
        end
    end)
end

function PlayerService:GetAvaliablePlayers()
    return self.Shared.TableUtil.Filter(self:GetPlayers(), function(player)
        return self._avaliablePlayers[player]
    end)
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

function PlayerService:Start()
    local players = game:GetService("Players")

    local onPlayerAdded = function(pl)
        self:_onPlayerAdded(pl)
    end
    players.PlayerAdded:Connect(onPlayerAdded)
    table.foreach(players:GetPlayers(), onPlayerAdded)

    players.PlayerRemoving:Connect(function(player)
        self:_onPlayerRemoving(player)
    end)

    self:ConnectEvent("PlayerLeftRound", function(player)
        PlayerService:_spawnIntoLobby(player)
    end)

    if self.Modules.Settings.UseTestPlayers then
        local rootPlayer = game.Players:WaitForChild("ModuleMaker")

        local function newTp(name)
            return self.Shared.TestPlayer.new(rootPlayer, {Name = name, Character = {type = "Instance"}}, true)
        end
        local tp1 = newTp("TestPlayer1")
        local tp2 = newTp("TestPlayer2")
        local tp3 = newTp("TestPlayer3")

        self.Services.PlayerService:_onPlayerAdded(tp1)
        self.Services.PlayerService:_onPlayerAdded(tp2)
        self.Services.PlayerService:_onPlayerAdded(tp3)
    end
end

function PlayerService:Init()
    logger = self.Shared.Logger.new()
    self._avaliablePlayers = self.Shared.PlayerDict.new()
    self._playerEvents = self.Shared.PlayerDict.new()

    self:RegisterEvent("PlayerLoaded")
    self:RegisterEvent("PlayerRemoving")
    self:RegisterEvent("PlayerLeftRound")
    self:RegisterClientEvent("LeftRound")
end

return PlayerService
