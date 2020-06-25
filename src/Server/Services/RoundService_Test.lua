local RoundServiceTests = {}

function RoundServiceTests.roundBeginsWithEnoughActivePlayers(state)
    -- GIVEN:
    local playerService = state:Mock(state.Services.PlayerService)
    local roundService = state:Latch(state.Services.RoundService)

    local mockPlayers = {
        state:MockPlayer("Player"), state:MockPlayer("Player"), state:MockPlayer("Player")
    }

    function playerService:GetAvaliablePlayers() return mockPlayers end

    roundService:OverrideGlobal("wait", function(n)
        wait()
        return n
    end)

    -- WHEN:
    state:StartAll()
    local avaliablePlayers = roundService:waitForRequiredPlayers()

    -- EXPECT:
    state:Expect(avaliablePlayers):HasLength(3):Equals(mockPlayers)
end

return RoundServiceTests
