local RoundServiceTests = {}

function RoundServiceTests.roundBeginsWithEnoughActivePlayers(state)
    -- GIVEN:
    local roundService = state:Latch(state.Services.RoundService)
    local playerService = state:MockService("PlayerService")

    local mockPlayers = {
        state:MockInstance("Player"), state:MockInstance("Player"), state:MockInstance("Player")
    }

    function playerService:GetAvaliablePlayers() return mockPlayers end

    roundService:OverrideGlobal("wait", function(n) return n end)

    -- WHEN:
    local avaliablePlayers = roundService:waitForRequiredPlayers()

    -- EXPECT:
    state:Expect(avaliablePlayers):HasLength(3):Equals(mockPlayers)
end

return RoundServiceTests
