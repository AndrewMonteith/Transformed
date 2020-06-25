local EndOfRoundGui = {}

local KillLeaderboardItemHeight = 21

function EndOfRoundGui:loadGui(roundDetails)
    local gui = self.Shared.Resource:Load("EndOfRoundGui"):Clone()
    local killListLabel = self.Shared.Resource:Load("KillListLabel")

    gui.Background.WinnerLabels[roundDetails.Winners].Visible = true

    local playerList = gui.Background.PlayerLeaderboard.PlayerList
    for player, kills in pairs(roundDetails.PlayerKills) do
        local label = killListLabel:Clone()
        label.Player.Text = player
        label.Kills.Text = kills
        label.Position = UDim2.new(0, 0, 0, #playerList:GetChildren() * KillLeaderboardItemHeight)
        label.Parent = playerList
    end

    gui.Parent = self.Player.PlayerGui

    return gui
end

function EndOfRoundGui:scrollKillLeaderboard(gui)
    local playerList = gui.Background.PlayerLeaderboard.PlayerList
    local itemsInList = #playerList:GetChildren() - 1 -- gui constraint is also a child
    local hiddenItems = math.max(0, itemsInList - 9) -- 9 items can fit in the frame

    if hiddenItems == 0 then
        return
    end

    wait(2)

    local hiddenPixels = hiddenItems * KillLeaderboardItemHeight
    playerList.CanvasSize = UDim2.new(0, 0, 1, hiddenPixels)
    local scrollTween = self.Modules.Tween.fromService(playerList, TweenInfo.new(hiddenItems * 0.5),
                                                       {CanvasPosition = Vector2.new(0, hiddenPixels)})

    scrollTween:Play()
    scrollTween.Completed:Wait()
end

function EndOfRoundGui:Start()
    self.Services.RoundService.RoundEnded:Connect(function(roundDetails)
        local gui = self:loadGui(roundDetails)

        local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Sine)
        local showGui = self.Modules.Tween.fromService(gui.Background, tweenInfo,
                                                       {Position = UDim2.new(0.5, -220, 0.5, -177)})

        showGui:Play()
        showGui.Completed:Wait()

        self:scrollKillLeaderboard(gui)

        wait(4)

        local hideTween = self.Modules.Tween.fromService(gui.Background, tweenInfo,
                                                         {Position = UDim2.new(0.5, -220, 1, 0)})
        hideTween:Play()
        hideTween.Completed:Wait()
        gui:Destroy()
    end)
end

function EndOfRoundGui:Init() self._logger = self.Shared.Logger.new() end

return EndOfRoundGui
