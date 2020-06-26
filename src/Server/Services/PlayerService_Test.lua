local PlayerServiceTest = {}

function PlayerServiceTest.newJoinsSpawnedIntoLobby(state)
    -- GIVEN:
    local player = state:MockPlayer("Player1")
    state:Latch(state.Services.PlayerService)

    -- WHEN:
    state:StartServices()
    player:JoinGame()

    -- EXPECT:
    state:Expect(workspace.LobbySpawns:FindFirstChild(player.RespawnLocation.Name)):IsTruthy()
end

return PlayerServiceTest
