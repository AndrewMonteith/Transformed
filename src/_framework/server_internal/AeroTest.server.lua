if not game.ReplicatedStorage.RunTests.Value then
    return
end

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

    local DontLoad = {MockDataStoreService = true}

    local function loadModuleScripts(real, tests, folder)
        local function loadModule(module)
            if not DontLoad[module.Name] then
                local t = module.Name:sub(-5, -1) == "_Test" and tests or real
                t[module.Name] = require(module)
            end
        end

        for _, child in pairs(folder:GetChildren()) do
            if child:IsA("Folder") then
                loadModuleScripts(real, tests, child)
            elseif child:IsA("ModuleScript") then
                loadModule(child)

                -- Some module scripts have other module scripts as descendants which
                -- are loaded into their global environment. We overload their global environment
                -- which make them disappear therefore we load them here and leave it to us
                -- to overload the specific methods to handle then properly. So far this only affects UserInput
                if #child:GetChildren() > 0 then
                    for _, desc in pairs(child:GetChildren()) do
                        loadModule(desc)
                    end
                end
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

    local function addMetadata(codeType)
        return function(name, code)
            code.__Name = name
            code.__Type = codeType
        end
    end

    table.foreach(Aero.Services, addMetadata("Service"))
    table.foreach(Aero.Controllers, addMetadata("Controller"))
    table.foreach(Aero.Shared.Modules, addMetadata("Module"))
    table.foreach(Aero.Server.Modules, addMetadata("Module"))
    table.foreach(Aero.Client.Modules, addMetadata("Module"))

    return Aero
end

local Aero = LoadInitalGameState()

local function RunTestSuites(message, testSuites)
    logger:Log("Running ", message)
    for name, testSuite in pairs(testSuites) do
        logger:Log("  - Running test suite ", name)

        for testName, test in pairs(testSuite) do
            logger:Log("    - Test ", testName)

            local testState = TestState.new(Aero, testSuite)

            if typeof(testSuite.Setup) == "function" then
                testSuite.Setup(testState)
            end

            test(testState)

            if testState:Success() then
                logger:Log("       Passed")
            else
                logger:Warn("       Failed:" .. testState:ErrorMsg())
            end
        end

        print()
    end
end

RunTestSuites("Server tests", Aero.Server.Tests)
RunTestSuites("Client tests", Aero.Client.Tests)
RunTestSuites("Shared tests", Aero.Shared.Tests)
