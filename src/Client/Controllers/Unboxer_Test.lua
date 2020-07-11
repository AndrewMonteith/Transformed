local Unboxer_Test = {}

local ExampleClawSkin, ExampleGunSkin

function Unboxer_Test.SetupForATest(state)
    ExampleGunSkin = state.Shared.CrateSkins.GetSkinFromName("Claw", "Ocean Scales")
    ExampleClawSkin = state.Shared.CrateSkins.GetSkinFromName("Gun", "Ocean Scales")

    state.MockCamera = state:MockInstance("Camera")
    state.workspace.CurrentCamera = state.MockCamera

    state.MockPlayerService = state:Mock(state.Services.PlayerService)

    state.Crate = game.ReplicatedStorage:FindFirstChild("Crates", true).Epic
    state.Crate.PrimaryPart = state.Crate.Primary
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

Unboxer_Test["Crate will shake when clicked"] = function(state)
    -- GIVEN:
    local unboxer = state:Latch(state.Controllers.Unboxer)
    enableOnlyStep(unboxer, "ListenForClicks")

    local mockMouse = state:Mock(state.Controllers.Mouse)
    function state.Controllers.UserInput:Get(inputType)
        if inputType == "Mouse" then
            return mockMouse
        end
    end

    function mockMouse:Target() return state.mockCrate end

    -- WHEN:
    state:StartAll()
    unboxer:Step_ListenForClicks(state.mockCrate)
    mockMouse:Fire("LeftDown")

    -- EXPECT:
    state:Expect(unboxer.Step_ShakeCrate):CalledOnce()
end

local function recordShake(unboxer, crateModel, clickNumber)
    local minDisp, maxDisp = math.huge, -math.huge

    local origPos = crateModel:GetPrimaryPartCFrame().p

    crateModel.PrimaryPart.Changed:Connect(function()
        local dispVec = crateModel:GetPrimaryPartCFrame().p - origPos
        local disp = math.sign(dispVec.x) * dispVec.magnitude

        minDisp = math.min(minDisp, disp)
        maxDisp = math.max(maxDisp, disp)
    end)

    unboxer:Step_ShakeCrate(crateModel, clickNumber)

    return minDisp, maxDisp
end

Unboxer_Test["Shaking works properly"] = function(state)
    -- GIVEN:
    local unboxer = state:Latch(state.Controllers.Unboxer)
    enableOnlyStep(unboxer, "ShakeCrate")

    -- WHEN:
    local click1MinDisp, click1MaxDisp = recordShake(unboxer, state.Crate, 1)
    local click2MinDisp, click2MaxDisp = recordShake(unboxer, state.Crate, 2)
    local click3MinDisp, click3MaxDisp = recordShake(unboxer, state.Crate, 3)

    -- EXPECT:
    state:Expect(click1MinDisp):LessThan(0)
    state:Expect(click1MaxDisp):GreaterThan(0)
    state:Expect(click2MinDisp):LessThan(0)
    state:Expect(click2MaxDisp):GreaterThan(0)
    state:Expect(click3MinDisp):LessThan(0)
    state:Expect(click3MaxDisp):GreaterThan(0)

    state:Expect(click2MinDisp):LessThan(click1MinDisp)
    state:Expect(click2MaxDisp):GreaterThan(click1MaxDisp)
    state:Expect(click3MinDisp):LessThan(click2MinDisp)
    state:Expect(click3MaxDisp):GreaterThan(click2MaxDisp)
end

return Unboxer_Test
