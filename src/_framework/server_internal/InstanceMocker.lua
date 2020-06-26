--[[
	There are 
]] local InstanceMocker = {}

local function hasEvent(inst, event)
    return pcall(function() return typeof(inst[event]) == "RBXScriptSignal" end)
end

local function hasProperty(inst, prop)
    return pcall(function()
        local t = typeof(inst[prop])

        return not (t == "function" or t == "RBXScriptSignal")
    end)
end

local function hasMethod(inst, method)
    return pcall(function() return typeof(inst[method]) == "function" end)
end

function InstanceMocker.Mock(className)
    local inst = Instance.new(className)

    return setmetatable({ClassName = className},
                        {__index = function(self, ind) return rawget(self, ind) or inst[ind] end})
end

--[[
	Special attention is required to the functionality and how we mock the person since
	we'll have no actual Instance to play around with. We'll add properties as we need them
]]

local DefaultPlayerProperties = {}

function InstanceMocker.MockPlayer(state, playerName)
    local mockPlayer = {Name = playerName, ClassName = playerName}

    function mockPlayer:JoinGame() state.game.Players.PlayerAdded:Fire(mockPlayer) end
    function mockPlayer:LoadCharacter() end

    mockPlayer.CharacterAdded = {Connect = function() end}

    return setmetatable(mockPlayer, {
        __index = function(tab, ind)
            local val = rawget(tab, ind) or DefaultPlayerProperties[ind]

            if val then
                return val
            end

            error("Indexed an unsupported thing " .. ind, 2)
        end
    })
end

return InstanceMocker
