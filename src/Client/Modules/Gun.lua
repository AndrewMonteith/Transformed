local Gun = {}
Gun.__index = Gun

function Gun.new(team, tool)
	local gunDriver = Gun.Modules[team .. "GunDriver"].new(tool)

	local self = setmetatable({
		logger = Gun.Shared.Logger.new(),
		driver = gunDriver,
		events = Gun.Shared.Maid.new()
	}, Gun)

	self.events:GiveTask(tool.Equipped:Connect(function() self.driver:Equipped() end))
	self.events:GiveTask(tool.Activated:Connect(function() self.driver:Activated() end))
	self.events:GiveTask(tool.Unequipped:Connect(function() self.driver:Unequipped() end))
	
	self.events:GiveTask(Gun.Controllers.AmmoReloadStation:ConnectEvent("GotBullet", function()
		self.driver:GiveBullet()
	end))

	return self
end

function Gun:Destroy()
	self.driver:Destroy()
	self.events:Destroy()
end


return Gun