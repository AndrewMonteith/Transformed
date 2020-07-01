local StaminaGui_Test = {}

StaminaGui_Test["Activates when joining a round"] =
function(state)
    -- GIVEN:
    local teamService = state:MockCode(state.Services.TeamService)
    local staminaGui = state:Latch(state.Controllers.StaminaGui)

    staminaGui.activate.Transparent = true
    state.IsClient = true

    -- WHEN:
    state:StartAll()
    teamService.TeamChanged:Fire("Werewolf")

    -- EXPECT:
    state:Expect(staminaGui.activate):CalledOnce()
end

StaminaGui_Test["Deactivates when leaving a round"] =
function(state)
    -- GIVEN:
    local teamService = state:MockCode(state.Services.TeamService)
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

StaminaGui_Test["Pressing left shift activates sprinting if they're moving and have stamina"] =
function(state)
    -- GIVEN:
    local mockKeyboard = state:Mock(state.Controllers.Keyboard)
    function state.Controllers.UserInput:Get(inputType)
        if inputType == "Keyboard" then
            return mockKeyboard
        end
    end

    state.IsClient = true
    local mockHumanoid = state:MockInstance("Humanoid")
    mockHumanoid.MoveDirection = Vector3.new(0, 0, 3)
    function state.Shared.PlayerUtil.GetHumanoid() return mockHumanoid end

    state:Mock(state.Services.TeamService)
    local stamianGui = state:Latch(state.Controllers.StaminaGui)

    -- WHEN:
    state:StartAll()
    stamianGui:activate()
    mockKeyboard.KeyDown:Fire(Enum.KeyCode.LeftShift)

    -- EXPECT:
    state:Expect(mockHumanoid.WalkSpeed):GreaterThan(16)
end

return StaminaGui_Test
