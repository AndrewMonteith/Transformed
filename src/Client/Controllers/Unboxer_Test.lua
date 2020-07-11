local Unboxer_Test = {}

local ExampleClawSkin, ExampleGunSkin

function Unboxer_Test.SetupForATest(state)
    ExampleGunSkin = state.Shared.CrateSkins.GetSkinFromName("Claw", "Ocean Scales")
    ExampleClawSkin = state.Shared.CrateSkins.GetSkinFromName("Gun", "Ocean Scales")

    state.MockCamera = state:MockInstance("Camera")
    state.workspace.CurrentCamera = state.MockCamera

    state.MockPlayerService = state:Mock(state.Services.PlayerService)
end

local function enableOnlyStep(latch, step)
    local stepFuncName = "Step_" .. step
    for name, val in pairs(latch.State) do
        if name:sub(1, 5) == "Step_" then
            val.Transparent = name ~= stepFuncName
        end
    end
end

Unboxer_Test["Start animations"] = function(state)
    -- GIVEN:
    local unboxer = state:Latch(state.Controllers.Unboxer)
    enableOnlyStep(unboxer, "VisualSetup")

    -- WHEN:
    state:StartAll()
    unboxer:Unbox(ExampleClawSkin)

    -- EXPECT:
    local distanceFromDestination = (state.MockCamera.CFrame.p -
                                    workspace.CrateOpenArea.CameraGoTo2.CFrame.p).magnitude
    state:Expect(distanceFromDestination):LessThan(0.01)
end

Unboxer_Test["Tells server player is unavailable"] =
function(state)
    -- GIVEN:
    local unboxer = state:Latch(state.Controllers.Unboxer)
    enableOnlyStep(unboxer, "") -- disable all steps

    -- WHEN:
    state:StartAll()
    unboxer:Unbox(ExampleClawSkin)

    -- EXPECT:
    state:Expect(state.MockPlayerService.PlayerAvailabilityChanged):CalledWith(false)
end

Unboxer_Test["Crate shakes when clicked"] = function(state)
    -- GIVEN:
    local unboxer = state:Latch(state.Controllers.Unboxer)
    enableOnlyStep(unboxer, "ListenForClicks")

    local mockMouse = state:Mock(state.Controllers.Mouse)
    function state.Controllers.UserInput:Get(inputType)
        if inputType == "Mouse" then
            return mockMouse
        end
    end

    function mockMouse:Target()
        return state.mockCrate
    end

    -- WHEN:
    state:StartAll()
    unboxer:Step_ListenForClicks(state.mockCrate)
    mockMouse:Fire("LeftDown")


    -- EXPECT:
    state:Expect(unboxer.Step_ShakeCrate):CalledOnce()
end

return Unboxer_Test
