-- Mouse
-- Stephen Leitnick
-- December 28, 2017

--[[
	
	Vector2   Mouse:GetPosition()
	Vector2   Mouse:GetDelta()
	Void      Mouse:Lock()
	Void      Mouse:LockCenter()
	Void      Mouse:Unlock()
	Ray       Mouse:GetRay(distance)
	Ray       Mouse:GetRayFromXY(x, y)
	Void      Mouse:SetMouseIcon(iconId)
	Void      Mouse:SetMouseIconEnabled(isEnabled)
	Boolean   Mouse:IsMouseIconEnabled()
	Booleam   Mouse:IsButtonPressed(mouseButton)
	Many      Mouse:Cast(ignoreDescendantsInstance, terrainCellsAreCubes, ignoreWater)
	Many      Mouse:CastWithIgnoreList(ignoreDescendantsTable, terrainCellsAreCubes, ignoreWater)
	Many      Mouse:CastWithWhitelist(whitelistDescendantsTable, ignoreWater)
	
	Mouse.LeftDown()
	Mouse.LeftUp()
	Mouse.RightDown()
	Mouse.RightUp()
	Mouse.MiddleDown()
	Mouse.MiddleUp()
	Mouse.Moved()
	Mouse.Scrolled(amount)
	
--]]

local Mouse = {}


function Mouse:GetPosition()
	return self._userInput:GetMouseLocation()
end


function Mouse:GetDelta()
	return self._userInput:GetMouseDelta()
end


function Mouse:Lock()
	self._userInput.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
end


function Mouse:LockCenter()
	self._userInput.MouseBehavior = Enum.MouseBehavior.LockCenter
end


function Mouse:Unlock()
	self._userInput.MouseBehavior = Enum.MouseBehavior.Default
end


function Mouse:SetMouseIcon(iconId)
	self._playerMouse.Icon = (iconId and ("rbxassetid://" .. iconId) or "")
end


function Mouse:SetMouseIconEnabled(enabled)
	self._userInput.MouseIconEnabled = enabled
end


function Mouse:IsMouseIconEnabled()
	return self._userInput.MouseIconEnabled
end


function Mouse:IsButtonPressed(mouseButton)
	return self._userInput:IsMouseButtonPressed(mouseButton)
end


function Mouse:GetRay(distance)
	local mousePos = self._userInput:GetMouseLocation()
	local viewportMouseRay = self._cam:ViewportPointToRay(mousePos.X, mousePos.Y)
	return Ray.new(viewportMouseRay.Origin, viewportMouseRay.Direction * distance)
end


function Mouse:GetRayFromXY(x, y)
	local viewportMouseRay = self._cam:ViewportPointToRay(x, y)
	return Ray.new(viewportMouseRay.Origin, viewportMouseRay.Direction)
end


function Mouse:Cast(ignoreDescendantsInstance, terrainCellsAreCubes, ignoreWater)
	return workspace:FindPartOnRay(self:GetRay(self._RAY_DISTANCE), ignoreDescendantsInstance, terrainCellsAreCubes, ignoreWater)
end


function Mouse:CastWithIgnoreList(ignoreDescendantsTable, terrainCellsAreCubes, ignoreWater)
	return workspace:FindPartOnRayWithIgnoreList(self:GetRay(self._RAY_DISTANCE), ignoreDescendantsTable, terrainCellsAreCubes, ignoreWater)
end


function Mouse:CastWithWhitelist(whitelistDescendantsTable, ignoreWater)
	return workspace:FindPartOnRayWithWhitelist(self:GetRay(self._RAY_DISTANCE), whitelistDescendantsTable, ignoreWater)
end


function Mouse:Start()
	
end


function Mouse:Init()
	self._playerMouse = game:GetService("Players").LocalPlayer:GetMouse()
	self._userInput = game:GetService("UserInputService")
	self._cam = workspace.CurrentCamera

	self._RAY_DISTANCE = 999

	self.LeftDown   = self.Shared.Event.new()
	self.LeftUp     = self.Shared.Event.new()
	self.RightDown  = self.Shared.Event.new()
	self.RightUp    = self.Shared.Event.new()
	self.MiddleDown = self.Shared.Event.new()
	self.MiddleUp   = self.Shared.Event.new()
	self.Moved      = self.Shared.Event.new()
	self.Scrolled   = self.Shared.Event.new()
	
	self._userInput.InputBegan:Connect(function(input, processed)
		if (processed) then return end
		if (input.UserInputType == Enum.UserInputType.MouseButton1) then
			self.LeftDown:Fire()
		elseif (input.UserInputType == Enum.UserInputType.MouseButton2) then
			self.RightDown:Fire()
		elseif (input.UserInputType == Enum.UserInputType.MouseButton3) then
			self.MiddleDown:Fire()
		end
	end)
	
	self._userInput.InputEnded:Connect(function(input, _processed)
		if (input.UserInputType == Enum.UserInputType.MouseButton1) then
			self.LeftUp:Fire()
		elseif (input.UserInputType == Enum.UserInputType.MouseButton2) then
			self.RightUp:Fire()
		elseif (input.UserInputType == Enum.UserInputType.MouseButton3) then
			self.MiddleUp:Fire()
		end
	end)
	
	self._userInput.InputChanged:Connect(function(input, processed)
		if (input.UserInputType == Enum.UserInputType.MouseMovement) then
			self.Moved:Fire()
		elseif (input.UserInputType == Enum.UserInputType.MouseWheel) then
			if (not processed) then
				self.Scrolled:Fire(input.Position.Z)
			end
		end
	end)
	
end


return Mouse
