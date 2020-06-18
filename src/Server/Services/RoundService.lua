local RoundService = {Client = {}}

local logger

function RoundService:IsRoundActive()
    return self._roundActive
end

function RoundService:_waitForRequiredPlayers()
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

function RoundService:_putPlayersOntoMap(playersInRound)
    local spawns = workspace.MapSpawns:GetChildren()
    self.Shared.TableUtil.Shuffle(spawns)

    for i = 1, #playersInRound do
        local player = playersInRound[i]

        player.RespawnLocation = spawns[i]
        player.CharacterAppearanceId = 347921667
        player:LoadCharacter()
        player.CharacterAppearanceId = player.UserId
    end
end

function RoundService:_listenForDeaths()
    self.Services.PlayerService:ConnectEvent("PlayerLeftRound", function()
        if (not self._roundActive) or self._roundEnding then
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
            self:_endRound("Draw")
        elseif humansAlive == 0 then
            self:_endRound("Werewolf")
        elseif werewolvesAlive == 0 then
            self:_endRound("Human")
        end
    end)
end

function RoundService:_endRound(winningTeam)
    self._roundEnding = true

    logger:Log("Round won by ", winningTeam)

    for _, player in pairs(self.Services.PlayerService:GetPlayersInRound()) do
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Health = 0
        end
    end

    self:Fire("RoundEnded")
    self:FireAllClients("RoundEnded", winningTeam)
end

function RoundService:_beginRound(roundNumber)

    logger:Log("Beginning round ", roundNumber)

    local playersInRound = self:_waitForRequiredPlayers()
    logger:Log("Beginning round with ", #playersInRound, " players")

    self.Services.TeamService:AssignTeams(playersInRound)
    self:_putPlayersOntoMap(playersInRound)

    self:Fire("RoundStarted")

    local playerTeamMap = self.Services.TeamService:GetTeamMap()
    for _, player in pairs(playersInRound) do
        self:FireClient("RoundStarted", player, playerTeamMap)
    end

    delay(1, function()
        self.Services.DayNightCycle:SetActive(true)
    end)
end

function RoundService:Start()
    local roundNumber = 0
    self._performRound:Connect(function()
        if self._roundActive then
            logger:Warn("Cannot start round if already active")
            return
        end

        self._roundActive = true
        roundNumber = roundNumber + 1
        self:_beginRound(roundNumber)
    end)

    self._performRound:Fire()

    self:_listenForDeaths()
end

function RoundService:Init()
    logger = self.Shared.Logger.new()
    self._performRound = self.Shared.Event.new()
    self._roundActive = false

    self:RegisterEvent("RoundStarted")
    self:RegisterEvent("RoundEnded")
    self:RegisterClientEvent("RoundStarted")
    self:RegisterClientEvent("RoundEnded")
end

return RoundService
