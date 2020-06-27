local PlayerServiceTest = {}

PlayerServiceTest["Newly joined player are spawned into lobby"] =
function(state)
    -- GIVEN:
    local player = state:MockPlayer("Player1")
    state:Latch(state.Services.PlayerService)

    -- WHEN:
    state:Start()
    player:JoinGame()

    -- EXPECT:
    state:Expect(workspace.LobbySpawns:FindFirstChild(player.RespawnLocation.Name)):IsTruthy()
end

PlayerServiceTest["Can find all players in round"] =
function(state)
    -- GIVEN:
    local testPlayers = {
        state:MockPlayer("Player1"), state:MockPlayer("Player2"), state:MockPlayer("Player3")
    }
    local mockTeamService = state:MockService(state.Services.TeamService)
    local playerService = state:Latch(state.Services.PlayerService)

    function mockTeamService:GetTeam(player)
        local teams = {Player1 = "Werewolf", Player2 = "Human", Player3 = "Lobby"}
        return teams[player.Name]
    end

    function playerService:GetPlayers() return testPlayers end

    -- WHEN:
    state:Start()
    local playersInRound = playerService:GetPlayersInRound()

    -- EXPECT:
    state:Expect(playersInRound):HasLength(2)
    state:Expect(playersInRound):Equals({testPlayers[1], testPlayers[2]})
end

return PlayerServiceTest
