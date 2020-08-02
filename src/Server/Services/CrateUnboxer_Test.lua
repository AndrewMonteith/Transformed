local CrateUnboxer_Test = {}

function CrateUnboxer_Test.SetupForATest(state) state.Player = state:MockPlayer("Player1") end

local function fuzzyEquals(x, y) return math.abs(x - y) <= 0.025 end

CrateUnboxer_Test["Unboxes with correct probabilites"] =
function(state)
    -- GIVEN:
    local crateUnboxer = state:Latch(state.Services.CrateUnboxer)

    -- WHEN:
    local totalUnboxings = 10000
    local unboxingDistributions = crateUnboxer.UnboxingDistributions
    for rarity, unboxingDistribution in pairs(unboxingDistributions) do
        local raritiesUnboxed = {Common = 0, Uncommon = 0, Rare = 0}

        for _ = 1, totalUnboxings do
            local unboxedItem = crateUnboxer:UnboxSkin("Claw", rarity, state.Player)
            raritiesUnboxed[unboxedItem.Rarity] = raritiesUnboxed[unboxedItem.Rarity] + 1
        end

        local actualDistribution = {
            Common = raritiesUnboxed.Common / totalUnboxings,
            Uncommon = raritiesUnboxed.Uncommon / totalUnboxings,
            Rare = raritiesUnboxed.Rare / totalUnboxings
        }

        local distributionMatches = fuzzyEquals(unboxingDistribution.Common,
                                                actualDistribution.Common) and
                                    fuzzyEquals(unboxingDistribution.Uncommon,
                                                actualDistribution.Uncommon) and
                                    fuzzyEquals(unboxingDistribution.Rare, actualDistribution.Rare)

        if not distributionMatches then
            state:Error("Distribution mismatch for " .. rarity)
        end
    end
end

CrateUnboxer_Test["Can unbox gun items"] = function(state)
    -- GIVEN:
    local crateUnboxer = state:Latch(state.Services.CrateUnboxer)

    -- WHEN:
    local unboxedItem = crateUnboxer:UnboxSkin("Gun", "Common", state.Player)

    -- EXPECT:
    state:Expect(unboxedItem.Supports.Gun):IsTrue()
end

CrateUnboxer_Test["Can unbox claw items"] = function(state)
    -- GIVEN:
    local crateUnboxer = state:Latch(state.Services.CrateUnboxer)

    -- WHEN:
    local unboxedItem = crateUnboxer:UnboxSkin("Claw", "Common", state.Player)

    -- EXPECT:
    state:Expect(unboxedItem.Supports.Claw):IsTrue()
end

return CrateUnboxer_Test
