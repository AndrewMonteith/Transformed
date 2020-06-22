local RoundService = {Client = {}}

local logger

function RoundService:IsRoundActive() return self._roundActive end

function RoundService:waitForRequiredPlayers()
    local requiredPlayers = self.Modules.Settings.RequiredPlayersToStart
    local coundownDuration = self.Modules.Settings.CountdownSeconds
    local avaliablePlayers;

    repeat
        logger:Log("Waiting for ", coundownDuration, " seconds")

        local dt = 0;
        while dt < coundownDuration do
            dt = dt + wait(5)
        end

        avaliablePlayers = self.Services.PlayerService:GetAvaliablePlayers()
    until #avaliablePlayers >= requiredPlayers

    return avaliablePlayers
end

function RoundService:putPlayersOntoMap(playersInRound)
    -- ! Change back to MapSpawns when doing in map tests
    local spawns = workspace.LobbySpawns:GetChildren()
    self.Shared.TableUtil.Shuffle(spawns)

    for i = 1, #playersInRound do
        local player = playersInRound[i]

        player.RespawnLocation = spawns[i]
        player.CharacterAppearanceId = 347921667
        player:LoadCharacter()
        player.CharacterAppearanceId = player.UserId
    end
end

function RoundService:listenForDeaths()
    self.Services.PlayerService:ConnectEvent("PlayerLeftRound", function()
        if (not self._roundActive) then
            return
        end

        local humansAlive, werewolvesAlive = 0, 0

        for _, player in pairs(self.Services.PlayerService:GetPlayersInRound()) do
            local team = self.Services.TeamService:GetTeam(player)
            if team == "Werewolf" then
                werewolvesAlive = werewolvesAlive + 1
            elseif team == "Human" then
                humansAlive = humansAlive + 1
            end
        end

        if humansAlive == 0 and werewolvesAlive == 0 then
            self:endRound("Draw")
        elseif humansAlive == 0 then
            self:endRound("Werewolf")
        elseif werewolvesAlive == 0 then
            self:endRound("Human")
        end
    end)
end

function RoundService:endRound(winningTeam)
    if self._roundEnding then
        return
    end
    self._roundEnding = true

    logger:Log("Round won by ", winningTeam)

    for _, player in pairs(self.Services.PlayerService:GetPlayersInRound()) do
        player:LoadCharacter()
        self.Services.PlayerService:LeaveRound(player)
    end

    local playerKills = self.Services.InRoundService:GetPlayerKills()

    self._roundActive = false
    self:Fire("RoundEnded")
    self:FireAllClients("RoundEnded", {Winners = winningTeam, PlayerKills = playerKills})

    self._roundEnding = false
    self:performRound()
end

function RoundService:beginRound()
    logger:Log("Beginning round ", self._roundNumber)

    local playersInRound = self:waitForRequiredPlayers()
    logger:Log("Beginning round with ", #playersInRound, " players")

    -- Since some client side things manipulate humanoid when team is changed
    -- we need to reload the characters before giving them the teams
    self:putPlayersOntoMap(playersInRound)
    self.Services.TeamService:AssignTeams(playersInRound)

    local playerTeamMap = self.Services.TeamService:GetTeamMap()
    self:Fire("RoundStarted")
    self:FireAllClients("RoundStarted", playerTeamMap)

    delay(1, function() self.Services.DayNightCycle:SetActive(true) end)
end

function RoundService:Start()
    self:listenForDeaths()

    local performRound = self.Shared.Event.new()
    performRound:Connect(function()
        if self._roundActive then
            logger:Warn("Cannot start round if already active")
            return
        end
        self._roundActive = true

        self._roundNumber = self._roundNumber + 1
        self:beginRound()
    end)

    function RoundService:performRound() performRound:Fire() end

    self:performRound()
end

function RoundService:Init()
    logger = self.Shared.Logger.new()
    self._roundActive = false
    self._roundNumber = 0

    self:RegisterEvent("RoundStarted")
    self:RegisterEvent("RoundEnded")
    self:RegisterClientEvent("RoundStarted")
    self:RegisterClientEvent("RoundEnded")
end

return RoundService
