local Gun = {}

function Gun:connectUserInputEvents()
    self._events:GiveTask(self._tool.Equipped:Connect(function() self._gun:Equipped() end))
    self._events:GiveTask(self._tool.Activated:Connect(function() self._gun:Activated() end))
    self._events:GiveTask(self._tool.Unequipped:Connect(function() self._gun:Unequipped() end))

    self._events:GiveTask(self.Controllers.AmmoReloadStation:ConnectEvent("GotBullet", function()
        self._gun:GiveBullet()
    end))
end

function Gun:Start()
    self.Services.TeamService.TeamChanged:Connect(function(newTeam)
        self._team = newTeam

        if newTeam == "Lobby" and self._gun then
            self._gun:Destroy()
            self._tool:Destroy()
            self._gun, self._team, self._tool = nil, nil, nil
        elseif newTeam ~= "Lobby" and (not self._gun) then
            self._tool = self.Player.PlayerGui:WaitForChild(self._team .. "Gun")
            self._tool.Name = "Gun"
            self._tool.Parent = self.Player.Backpack

            self._gun = Gun.Modules[self._team .. "GunDriver"].new(self._tool)

            if newTeam == "Human" then
                self:connectUserInputEvents()
            end
        end
    end)

    self.Services.DayNightCycle.Sunrise:Connect(function()
        if self._team == "Werewolf" then
            self._tool.Parent = self.Player.Backpack
            self:connectUserInputEvents()
        end
    end)

    self.Services.DayNightCycle.Sunset:Connect(function()
        if self._team == "Werewolf" then
            self._tool.Parent = nil
            self._events:DoCleaning()
        end
    end)
end

function Gun:GetAmmo() return self._gun:GetAmmo() end

function Gun:Init() self._events = self.Shared.Maid.new() end

return Gun
