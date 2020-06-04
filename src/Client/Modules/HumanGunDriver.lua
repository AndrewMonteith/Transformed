local HumanGunDriver = {}
HumanGunDriver.__index = HumanGunDriver


function HumanGunDriver.new(tool)
	local self = setmetatable({
		logger = HumanGunDriver.Shared.Logger.new(),
		tool = tool,
		gui = HumanGunDriver.Shared.Resource:Load("GunReloadGui"):Clone(),

		ammo = 6,
		clipSize = 6,
		lastFired = tick(),

		fireDistance = HumanGunDriver.Shared.Settings.BulletFireDistance
	}, HumanGunDriver)

	return self
end

function HumanGunDriver:_canFire() 
	local now = tick()

	if now - self.lastFired <= 0.4 then
		return false
	end

	if self.ammo == 0 or self.reloading then
		return false
	end

	self.lastFired = now
	return true
end

function HumanGunDriver:_fireBullet()
	self.Services.InRoundService.PlayFireSound:Fire()

	local ray = self.Controllers.UserInput:Get("Mouse"):GetRay(self.fireDistance)
	local hitPart, hitPosition = workspace:FindPartOnRay(ray, game.Players.LocalPlayer.Character)

	if hitPart then
		local player = self.Shared.PlayerUtil.GetPlayerFromPart(hitPart)
		if player then
			self.Services.InRoundService.HitPlayer:Fire(player.Name)
		end
	end
end

function HumanGunDriver:_removeImageFromGui()
	local container = self.gui.Container
	local bulletImage = container.GunBarrel["Bullet" .. tostring(self.ammo)] 
	local numberUtil = self.Shared.NumberUtil
	local startRotation, endRotation = container.Rotation, container.Rotation+60

	local t = self.Modules.Tween.new(TweenInfo.new(.2, Enum.EasingStyle.Sine), function(ratio)
		bulletImage.ImageTransparency = ratio
		container.Rotation = numberUtil.Lerp(startRotation, endRotation, ratio)
	end)

	t:Play()
end

function HumanGunDriver:Activated()
	if not self:_canFire() then
		if self.ammo == 0 then
			self.tool.Handle.Empty:Play()
		end

		return
	end
	
	self:_removeImageFromGui()
	self:_fireBullet()

	self.ammo = self.ammo - 1
end

function HumanGunDriver:Equipped()
	self.logger:Log("Equipped")
	if self.gui then
		self.gui.Parent = game.Players.LocalPlayer.PlayerGui
	end
end

function HumanGunDriver:Unequipped()
	self.logger:Log("Unequipped")
	if self.gui then
		self.gui.Parent = nil
	end
end

function HumanGunDriver:Reload()
	self.logger:Log("Reload")
	
	local startSize, endSize = UDim2.new(0, 0, 0, 0), UDim2.new(0, 39, 0, 39)
	local tweenInfo = TweenInfo.new((6-self.ammo)*0.175, Enum.EasingStyle.Sine)
	for i = 6, 1, -1 do
		local bulletImage = self.gui:FindFirstChild("Bullet" .. tostring(i), true)
		
		if bulletImage.ImageTransparency == 1 then
			local startPos, endPos = bulletImage.Position + UDim2.new(0, 39/2, 0, 39/2), bulletImage.Position
			bulletImage.Position, bulletImage.Size = startPos, startSize
			
			local t = self.Modules.Tween.fromService(bulletImage, tweenInfo, 
													{Position = endPos; Size = endSize; ImageTransparency = 0})
			
			t:Play()
		end
	end
	
	self.Modules.Tween.fromService(self.gui.Container, tweenInfo, {Rotation = 0}):Play()

	self.ammo = 6
end


function HumanGunDriver:Destroy()
	self.tool:Destroy()
	self.gui:Destroy()
end


return HumanGunDriver