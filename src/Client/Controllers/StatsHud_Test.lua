local StatsHud_Test = {}

local DefaultValues = {Xp = 100, Money = 500}

function StatsHud_Test.SetupForATest(state)
    state.mockStatsService = state:Mock(state.Services.StatsService)
    function state.mockStatsService:Get(key) return DefaultValues[key] end
end

StatsHud_Test["Gui is made visible"] = function(state)
    -- GIVEN:
    local statsHud = state:Latch(state.Controllers.StatsHud)

    -- WHEN:
    state:StartAll()

    -- EXPECT:
    statsHud:Expect(statsHud._gui.Parent):Equals(state.Player.PlayerGui)
end

StatsHud_Test["Gui loads stats on start"] = function(state)
    -- GIVEN:
    local statsHud = state:Latch(state.Controllers.StatsHud)

    -- WHEN:
    state:StartAll()

    -- EXPECT:
    state:Expect(statsHud._gui.HudBackground.Money.Text:find(DefaultValues.Money)):NotNil()
    state:Expect(statsHud._gui.HudBackground.LevelBarContainer.CurrentLevel.Text:find("-1")):IsNil()
end

StatsHud_Test["Stats hud reflects changes in money"] =
function(state)
    -- GIVEN:
    local statsHud = state:Latch(state.Controllers.StatsHud)

    -- WHEN:
    state:StartAll()
    state.mockStatsService:FireClient("MoneyChanged", state.Player, 400)

    -- EXPECT:
    state:Expect(statsHud._gui.HudBackground.Money.Text:find(400)):NotNil()
end

StatsHud_Test["Stats hud reflects change in Xp"] =
function(state)
    -- GIVEN:
    local statsHud = state:Latch(state.Controllers.StatsHud)

    -- WHEN:
    state:StartAll()
    state.mockStatsService.XpChanged:Fire(10000)

    -- EXPECT:
    state:Expect(tonumber(statsHud._gui.HudBackground.Money.Text:match("%d+"))):GreaterThan(4)
end

StatsHud_Test["Server told when status toggled to unavaliable"] =
function(state)
    -- GIVEN:
    local statsHud = state:Latch(state.Controllers.StatsHud)
    local playerService = state:Mock(state.Services.PlayerService)

    -- WHEN:
    state:StartAll()
    statsHud:SetAvailability(false)

    -- EXPECT:
    state:Expect(playerService.PlayerAvailabilityChanged):EventCalledWith(false)
end

StatsHud_Test["Server recognises when status changed"] =
function(state)
    -- GIVEN:
    local statsHud = state:Latch(state.Controllers.StatsHud)
    local playerService = state:LatchService(state.Services.PlayerService)

    -- WHEN:
    state:StartAll()
    statsHud:SetAvailability(false)

    -- EXPECT:
    state:Expect(playerService:IsAvailable(state.Player)):IsFalse()
end

return StatsHud_Test
