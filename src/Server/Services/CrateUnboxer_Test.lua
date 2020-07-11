local CrateUnboxer_Test = {}

function CrateUnboxer_Test.SetupForATest(state) state.Player = state:MockPlayer("Player1") end

CrateUnboxer_Test["Unboxes with correct probabilites"] =
function(state)
    -- GIVEN:
    local crateUnboxer = state:Latch(state.Services.CrateUnboxer)

    -- WHEN:
    local totalUnboxings = 10000
    for rarity, probOfUnboxingOne in pairs(crateUnboxer.UnboxingProbabilities) do
        local matchingItems = 0
        for _ = 1, totalUnboxings do
            local unboxedItem = crateUnboxer:UnboxSkin("Claw", state.Player)

            if unboxedItem.Rarity == rarity then
                matchingItems = matchingItems + 1
            end
        end

        local observedProbability = matchingItems / totalUnboxings
        if math.abs(observedProbability - probOfUnboxingOne) > 0.05 then
            state:Error(("Expected unboxing probability of %.2f but got %.2f for %s"):format(
                        probOfUnboxingOne, observedProbability, rarity))
        end
    end
end

CrateUnboxer_Test["Can unbox gun items"] = function(state)
    -- GIVEN:
    local crateUnboxer = state:Latch(state.Services.CrateUnboxer)

    -- WHEN:
    local unboxedItem = crateUnboxer:UnboxSkin("Gun", state.Player)

    -- EXPECT:
    state:Expect(unboxedItem.Supports.Gun):IsTrue()
end

CrateUnboxer_Test["Can unbox claw items"] = function(state)
    -- GIVEN:
    local crateUnboxer = state:Latch(state.Services.CrateUnboxer)

    -- WHEN:
    local unboxedItem = crateUnboxer:UnboxSkin("Claw", state.Player)

    -- EXPECT:
    state:Expect(unboxedItem.Supports.Claw):IsTrue()
end

return CrateUnboxer_Test
