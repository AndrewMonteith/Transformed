local Gun = {}

function Gun:_connectUserInputEvents()
    self.events:GiveTask(self.tool.Equipped:Connect(function()
        self.gun:Equipped()
    end))

    self.events:GiveTask(self.tool.Activated:Connect(function()
        self.gun:Activated()
    end))

    self.events:GiveTask(self.tool.Unequipped:Connect(function()
        self.gun:Unequipped()
    end))

    self.events:GiveTask(self.Controllers.AmmoReloadStation:ConnectEvent("GotBullet", function()
        self.gun:GiveBullet()
    end))
end

function Gun:Start()
    self.Services.RoundService.RoundStarted:Connect(function(playersAndTeam)
        self.team = playersAndTeam[self.Player.Name]
        self.tool = self.Player.PlayerGui:WaitForChild(self.team .. "Gun")
        self.gun = Gun.Modules[self.team .. "GunDriver"].new(self.tool)

        self.tool.Name = "Gun"
        self.tool.Parent = self.Player.Backpack

        if self.team == "Human" then
            self:_connectUserInputEvents()
        end
    end)

    local function destroy()
        if not self.gun then
            return
        end

        self.gun:Destroy()
        self.tool:Destroy()
        self.gun, self.team, self.tool = nil, nil, nil
    end
    self.Services.RoundService.RoundEnded:Connect(destroy)
    self.Services.PlayerService.LeftRound:Connect(destroy)

    self.Services.DayNightCycle.Sunrise:Connect(function()
        if self.team == "Werewolf" then
            self.tool.Parent = self.Player.Backpack
            self:_connectUserInputEvents()
        end
    end)

    self.Services.DayNightCycle.Sunset:Connect(function()
        if self.team == "Werewolf" then
            self.tool.Parent = nil
            self.events:DoCleaning()
        end
    end)
end

function Gun:GetAmmo()
    return self.gun:GetAmmo()
end

function Gun:Init()
    self.events = self.Shared.Maid.new()
end

return Gun
