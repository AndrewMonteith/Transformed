local StaminaGui_Test = {}

function StaminaGui_Test.SetupForATest(state)
    state.teamService = state:Mock(state.Services.TeamService)

    state.mockKeyboard = state:Mock(state.Controllers.Keyboard)
    function state.Controllers.UserInput:Get(inputType)
        if inputType == "Keyboard" then
            return state.mockKeyboard
        end
    end

    state.mockHumanoid = state:MockInstance("Humanoid")
    state.mockHumanoid.MoveDirection = Vector3.new(0, 0, 3)
    function state.Shared.PlayerUtil.GetHumanoid() return state.mockHumanoid end
end

StaminaGui_Test["Activates when joining a round"] =
function(state)
    -- GIVEN:
    local staminaGui = state:Latch(state.Controllers.StaminaGui)
    staminaGui.activate.Transparent = true

    -- WHEN:
    state:StartAll()
    state.teamService:FireClient("TeamChanged", state.Player, "Werewolf")

    -- EXPECT:
    state:Expect(staminaGui.activate):CalledOnce()
end

StaminaGui_Test["Deactivates when leaving a round"] =
function(state)
    -- GIVEN:
    local staminaGui = state:Latch(state.Controllers.StaminaGui)
    staminaGui.destroy.Transparent = true

    -- WHEN:
    state:StartAll()

    staminaGui._active = true
    state.teamService:FireClient("TeamChanged", state.Player, "Lobby")

    -- EXPECT:
    state:Expect(staminaGui.destroy):CalledOnce()
end

StaminaGui_Test["Pressing left shift activates sprinting if they're moving and have stamina"] =
function(state)
    -- GIVEN:
    local stamianGui = state:Latch(state.Controllers.StaminaGui)

    -- WHEN:
    state:StartAll()
    state.teamService:FireClient("TeamChanged", state.Player, "Human")
    state.mockKeyboard.KeyDown:Fire(Enum.KeyCode.LeftShift)

    -- EXPECT:
    state:Expect(state.mockHumanoid.WalkSpeed):GreaterThan(16)
end

StaminaGui_Test["Pressing left shift does not activate sprinting if there's no stamina"] =
function(state)
    -- GIVEN:
    local staminaGui = state:Latch(state.Controllers.StaminaGui)

    -- WHEN:
    state:StartAll()

    state.teamService:FireClient("TeamChanged", state.Player, "Human")
    staminaGui:SetStamina(0)
    state.mockKeyboard.KeyDown:Fire(Enum.KeyCode.LeftShift)

    -- EXPECT:
    state:Expect(state.mockHumanoid.WalkSpeed):Equals(16)
end

StaminaGui_Test["Can jump if theres enough stamina and on ground"] =
function(state)
    -- GIVEN:
    local staminaGui = state:Latch(state.Controllers.StaminaGui)

    -- WHEN:
    state:StartAll()

    state.teamService:FireClient("TeamChanged", state.Player, "Human")
    staminaGui:SetStamina(40)
    state.mockHumanoid.FloorMaterial = Enum.Material.Wood
    state.mockKeyboard.KeyDown:Fire(Enum.KeyCode.Space)

    -- EXPECT:
    state:Expect(state.mockHumanoid.Jump):IsTruthy()
end

StaminaGui_Test["Can't jump if in air"] = function(state)
    -- GIVEN:
    local staminaGui = state:Latch(state.Controllers.StaminaGui)

    -- WHEN:
    state:StartAll()

    state.teamService:FireClient("TeamChanged", state.Player, "Human")
    state.mockHumanoid.FloorMaterial = Enum.Material.Air
    state.mockKeyboard.KeyDown:Fire(Enum.KeyCode.Space)

    -- EXPECT:
    state:Expect(state.mockHumanoid.Jump):IsFalsy()
end

StaminaGui_Test["Can't jump if there's not enough stamina"] =
function(state)
    -- GIVEN:
    local staminaGui = state:Latch(state.Controllers.StaminaGui)

    -- WHEN:
    state:StartAll()

    state.teamService:FireClient("TeamChanged", state.Player, "Human")
    staminaGui:SetStamina(0)
    state.mockHumanoid.FloorMaterial = Enum.Material.Wood
    state.mockKeyboard.KeyDown:Fire(Enum.KeyCode.Space)

    -- EXPECT:
    state:Expect(state.mockHumanoid.Jump):IsFalsy()
end

return StaminaGui_Test
