local StatsHud = {}

function StatsHud:startXpStat()
    local levelBar = self._gui.HudBackground.LevelBarContainer

    local function setXp(experience)
        local level = self.Shared.ExperienceCalculator.GetLevelFromExperience(experience)
        local _, _, percent = self.Shared.ExperienceCalculator.GetSubExperience(experience)

        levelBar.ClipContainer.Size = UDim2.new(percent, 0, 1, 0)
        levelBar.CurrentLevel.Text = ("   Level %d"):format(level)
    end

    setXp(self.Services.StatsService:Get("Xp") or 0)
    self.Services.StatsService.XpChanged:Connect(setXp)
end

function StatsHud:startMoneyStat()
    local moneyLabel = self._gui.HudBackground.Money

    local function setMoney(money) moneyLabel.Text = money end

    setMoney(self.Services.StatsService:Get("Money") or 0)
    self.Services.StatsService.MoneyChanged:Connect(setMoney)
end

function StatsHud:Start()
    self._gui = self.Shared.Resource:Load("StatsHud"):Clone()

    self:startXpStat()
    self:startMoneyStat()

    self._gui.Parent = self.Player.PlayerGui
end

function StatsHud:Init() self._logger = self.Shared.Logger.new() end

return StatsHud
