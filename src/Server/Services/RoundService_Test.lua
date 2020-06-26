local RoundServiceTests = {}

function RoundServiceTests.roundBeginsWithEnoughActivePlayers(state)
    -- GIVEN:
    local roundService = state:Latch(state.Services.RoundService)
    local playerService = state:MockService("PlayerService")

    local mockPlayers = {
        state:MockPlayer("Player"), state:MockPlayer("Player"), state:MockPlayer("Player")
    }

    function playerService:GetAvaliablePlayers() return mockPlayers end

    roundService:OverrideGlobal("wait", function(n) wait() return n end)

    -- WHEN:
    local avaliablePlayers = roundService:waitForRequiredPlayers()

    -- EXPECT:
    state:Expect(avaliablePlayers):HasLength(3):Equals(mockPlayers)
end

return RoundServiceTests
