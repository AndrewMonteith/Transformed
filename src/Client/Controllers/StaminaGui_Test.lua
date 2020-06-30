local StaminaGui_Test = {}

StaminaGui_Test["Activates when joining a round"] =
function(state)
    -- GIVEN:
    local teamService = state:MockService(state.Services.TeamService)
    local staminaGui = state:Latch(state.Controllers.StaminaGui)

    staminaGui.activate.Transparent = true
    state.IsClient = true

    -- WHEN:
    state:StartAll()
    teamService.TeamChanged:Fire("Werewolf")

    -- EXPECT:
    state:Expect(staminaGui.activate):CalledOnce()
end

StaminaGui_Test["Deactivates when leaving a round"] = function(state)
    -- GIVEN:
    local teamService = state:MockService(state.Services.TeamService)
    local staminaGui = state:Latch(state.Controllers.StaminaGui)

    staminaGui.destroy.Transparent = true
    state.IsClient = true

    -- WHEN:
    state:StartAll()

    staminaGui._active = true
    teamService.TeamChanged:Fire("Lobby")

    -- EXPECT:
    state:Expect(staminaGui.destroy):CalledOnce()

end

return StaminaGui_Test
