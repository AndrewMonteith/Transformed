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

        local team = self.Services.TeamService:GetTeam(player)
        local gun = self.Shared.Resource:Load(team .. "Gun"):Clone()
        gun.Name = "Gun"
        gun.Parent = player.Backpack
    end
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

    delay(3, function()
        self.Services.DayNightCycle:SetActive(true)
    end)
end

function RoundService:Start()
    local roundNumber = 0
    self._performRound:Connect(function()
        roundNumber = roundNumber + 1
        -- self:_beginRound(roundNumber)
    end)

    self._performRound:Fire()
end

function RoundService:Init()
    logger = self.Shared.Logger.new()
    self._performRound = self.Shared.Event.new()

    self:RegisterEvent("RoundStarted")
    self:RegisterEvent("RoundEnded")
    self:RegisterClientEvent("RoundStarted")
    self:RegisterClientEvent("RoundEnded")
end

return RoundService
