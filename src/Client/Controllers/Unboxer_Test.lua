local Unboxer_Test = {}

local ExampleClawSkin, ExampleGunSkin

function Unboxer_Test.Setup(state)
    ExampleGunSkin = state.Shared.CrateSkins.GetSkinFromName("Claw", "Ocean Scales")
    ExampleClawSkin = state.Shared.CrateSkins.GetSkinFromName("Gun", "Ocean Scales")

    state.MockCamera = state:MockInstance("Camera")
    state.workspace.CurrentCamera = state.MockCamera

    state.mockPlayerService = state:Mock(state.Services.PlayerService)
end

local function enableOnlyStep(latch, step)
    local stepFuncName = "Step_" .. step
    for name, val in pairs(latch) do
        if name:sub(1, 5) == "Step_" then
            val.Transparent = name == stepFuncName
        end
    end
end

Unboxer_Test["Start animations"] = function(state)
    -- GIVEN:
    local unboxer = state:Latch(state.Controllers.Unboxer)

    enableOnlyStep(unboxer, "Setup")

    state:OverrideGlobal("wait", function(n)
        wait()
        return n
    end)

    -- WHEN:
    state:StartAll()
    unboxer:Unbox(ExampleClawSkin)

    -- EXPECT:
    local distanceFromDestination = (state.MockCamera.CFrame.p -
                                    workspace.CrateOpenArea.CameraGoTo2.CFrame.p).magnitude
    state:Expect(distanceFromDestination):LessThan(0.01)
end

Unboxer_Test["Tells server player is unavailable"] = function(state)
    -- GIVEN:
    local unboxer = state:Latch(state.Controllers.Unboxer)

    enableOnlyStep(unboxer, "Setup")

    state:OverrideGlobal("wait", function(n)
        wait()
        return n
    end)

    -- WHEN:
    state:StartAll()
    unboxer:Unbox(ExampleClawSkin)

    -- EXPECT:
    state:Expect(state.mockPlayerService.PlayerAvailabilityChanged):CalledWith(false)
end

return Unboxer_Test
