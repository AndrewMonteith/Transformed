-- Team Service
-- Username
-- June 1, 2020
local TeamService = {Client = {}}

function TeamService:AssignTeam(player, newTeam)
    self._logger:Log("Setting team of ", player, " to ", newTeam)

    local currentTeam = self._playerTeams[player]
    if currentTeam ~= newTeam and currentTeam then
        self:FireClient("TeamChanged", player, newTeam)
    end

    player.Neutral = false
    player.TeamColor = game:GetService("Teams")[newTeam].TeamColor
    self._playerTeams[player] = newTeam
end

function TeamService:GetTeam(player)
    local team = self._playerTeams[player] or "Lobby"

    if not team then
        self._logger:Warn("Failed to have team for:", player)
    end

    return team
end

function TeamService.Client:GetTeam(player) return TeamService:GetTeam(player) end

function TeamService:AssignTeams(playersInRound)
    self._logger:Log("Assigning teams to players in round")

    self.Shared.TableUtil.Shuffle(playersInRound)

    local isWerewolf = math.random() < 0.5
    for _, player in pairs(playersInRound) do
        self:AssignTeam(player, isWerewolf and "Werewolf" or "Human")
        isWerewolf = not isWerewolf
    end
end

function TeamService:GetTeamMap() return self._playerTeams:RawDictionary() end

function TeamService:Start()
    local function assignLobby(player) self:AssignTeam(player, "Lobby") end

    self.Services.PlayerService:ConnectPlayerLoaded(assignLobby)
    self.Services.PlayerService:ConnectEvent("PlayerLeftRound", assignLobby)
end

function TeamService:Init()
    self._playerTeams = self.Shared.PlayerDict.new()
    self._logger = self.Shared.Logger.new()

    self:RegisterClientEvent("TeamChanged")
end

return TeamService
