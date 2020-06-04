local Round = {}
Round.__index = Round

local roundNumber = 0

function Round.new()
	local Event = Round.Shared.Event

	local self = setmetatable({
		_logger = Round.Shared.Logger.new()
	}, Round)

	return self
end

function Round:_waitForRequiredPlayers()
end

function Round:_putPlayersOntoMap(playersInRound)
end

function Round:Begin()
end

function Round:End()
end

return Round