local TestState = require(script.Parent.TestState)
local TestUtil = require(script.Parent.TestUtil)
local logger = TestUtil.NewLogger("TestHarness")

local function LoadInitalGameState()
    local Aero = {
        Services = {},
        Controllers = {},

        Server = {Modules = {}, Tests = {}},

        Client = {Modules = {}, Tests = {}},

        Shared = {Modules = {}, Tests = {}}
    }

    local function loadModuleScripts(real, tests, folder)
        for _, child in pairs(folder:GetChildren()) do
            if child:IsA("Folder") then
                loadModuleScripts(real, tests, child)
            elseif child:IsA("ModuleScript") then
                local t = child.Name:sub(-5, -1) == "_Test" and tests or real
                t[child.Name] = require(child)
            end
        end
    end

    local aeroServer = game.ServerStorage.Aero
    local aeroClient = game.StarterPlayer.StarterPlayerScripts.Aero

    loadModuleScripts(Aero.Services, Aero.Server.Tests, aeroServer.Services)
    loadModuleScripts(Aero.Controllers, Aero.Client.Tests, aeroClient.Controllers)
    loadModuleScripts(Aero.Server.Modules, Aero.Server.Tests, aeroServer.Modules)
    loadModuleScripts(Aero.Client.Modules, Aero.Client.Tests, aeroClient.Modules)
    loadModuleScripts(Aero.Shared.Modules, Aero.Shared.Tests, game.ReplicatedStorage.Aero.Shared)

    table.foreach(Aero.Services, function(name, service)
        service.IsService = true
        service.__Name = name
    end)

    table.foreach(Aero.Controllers, function(name, controller)
        controller.IsController = true
        controller.__Name = name
    end)

    return Aero
end

local Aero = LoadInitalGameState()

local function RunServerTests(Aero)
    logger:Log("Running server tests...")

    for name, testSuite in pairs(Aero.Server.Tests) do
        logger:Log("  - Running test suite ", name)

        for testName, test in pairs(testSuite) do
            logger:Log("    - Test ", testName)

            local testState = TestState.new(Aero)

            test(testState)

            if testState:Success() then
                logger:Log("       Passed")
            else
                logger:Log("       Failed:" .. testState:ErrorMsg())
            end
        end
    end
end

local function RunModuleTests(Aero)
    logger:Log("Running shared module tests...")

    for name, testSuite in pairs(Aero.Shared.Tests) do
        logger:Log("  - Running test suite ", name)

        for testName, test in pairs(testSuite) do
            logger:Log("    - Test ", testName)

            local testState = TestState.new(Aero)

            test(testState)

            if testState:Success() then
                logger:Log("       Passed")
            else
                logger:Log("       Failed:" .. testState:ErrorMsg())
            end
        end
    end
end

RunServerTests(Aero)
-- RunClientTests(Aero)
RunModuleTests(Aero)
