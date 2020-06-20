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
    self.Services.RoundService.RoundStarted:Connect(
    function(playersAndTeam)
        self.team = playersAndTeam[self.Player.Name]
        self._tool = self.Player.PlayerGui:WaitForChild(self.team .. "Gun")
        self._gun = Gun.Modules[self.team .. "GunDriver"].new(self._tool)

        self._tool.Name = "Gun"
        self._tool.Parent = self.Player.Backpack

        if self.team == "Human" then
            self:connectUserInputEvents()
        end
    end)

    local function destroy()
        if not self._gun then
            return
        end

        self._gun:Destroy()
        self._tool:Destroy()
        self._gun, self.team, self._tool = nil, nil, nil
    end
    self.Services.RoundService.RoundEnded:Connect(destroy)
    self.Services.PlayerService.LeftRound:Connect(destroy)

    self.Services.DayNightCycle.Sunrise:Connect(function()
        if self.team == "Werewolf" then
            self._tool.Parent = self.Player.Backpack
            self:connectUserInputEvents()
        end
    end)

    self.Services.DayNightCycle.Sunset:Connect(function()
        if self.team == "Werewolf" then
            self._tool.Parent = nil
            self._events:DoCleaning()
        end
    end)
end

function Gun:GetAmmo() return self._gun:GetAmmo() end

function Gun:Init() self._events = self.Shared.Maid.new() end

return Gun
