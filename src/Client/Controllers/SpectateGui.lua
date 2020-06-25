local SpectateGui = {}

local logger

function SpectateGui:setInLobby(inLobby)
    self._inLobby = inLobby
    self._spectateButton.Visible = inLobby and self._roundActive
end

function SpectateGui:spectatePlayer(playerName)
    -- There is some really annoying bug where when you move away
    -- from a hidden werewolf at daytime it causes there head to become
    -- visible. Why does this happen? Honestly no idea. I suspect something to
    -- do with the CameraScripts. After 3 hours and a pack a harbio I decided to
    -- do a hacky fix which you see below.
    local currentSpecCharacter = workspace[self._playerIter:Current()]
    local headClone = currentSpecCharacter:FindFirstChild("HeadClone")
    local shouldHeadBeVisible = headClone and currentSpecCharacter.LowerTorsoClone.Transparency == 0

    workspace.CurrentCamera.CameraSubject = workspace[playerName]:FindFirstChildOfClass("Humanoid")
    self._gui.Background.Spectating.Text = playerName

    if headClone then
        headClone.Face.Transparency = shouldHeadBeVisible and 0 or 1
    end
end

function SpectateGui:setSpectating(active)
    if self._spectating == active then
        return
    end
    self._spectating = active

    if active then
        self:spectatePlayer(self._playerIter:Current())
        self._gui.Parent = self.Player.PlayerGui
    else
        workspace.CurrentCamera.CameraSubject = self.Player.Character:FindFirstChildOfClass(
                                                "Humanoid")
        self._gui.Parent = nil
    end
end

function SpectateGui:initalise(playersAndTeams)
    self._playersInRound = self.Shared.CircularLinkedList.new()
    self._playerIter = self._playersInRound:Iter()
    for playerName in pairs(playersAndTeams) do
        if playerName ~= self.Player.Name then
            self._playersInRound:Insert(playerName)
        end
    end

    self:setInLobby(playersAndTeams[self.Player.Name] == "Lobby")

    self._roundEvents:GiveTask(self.Services.PlayerService.PlayerLeftRound:Connect(
                               function(player)
        self._playersInRound:Remove(player.Name)

        if self._spectating then
            self:spectatePlayer(self._playerIter:Current())
        end
    end))

    self._roundEvents:GiveTask(self._gui.Background.Left.MouseButton1Click:Connect(
                               function() self:spectatePlayer(self._playerIter:Next()) end))
    self._roundEvents:GiveTask(self._gui.Background.Right.MouseButton1Click:Connect(
                               function() self:spectatePlayer(self._playerIter:Prev()) end))

    self._roundEvents:GiveTask(self._spectateButton.MouseButton1Click:Connect(
                               function() self:setSpectating(not self._spectating) end))
end

function SpectateGui:setEnabled(enabled)
    if enabled then
        self._spectateButton.Visible = true
    else
        self._spectateButton.Visible = false
        self:setSpectating(false)
        self._roundEvents:DoCleaning()
        self._playersInRound = nil
        self._playerIter = nil
    end
end

function SpectateGui:Start()
    self._gui = self.Shared.Resource:Load("SpectateGui")
    self._spectateButton = self.Player.PlayerGui:WaitForChild("LobbyGui"):WaitForChild("Buttons")
                           :WaitForChild("Spectate")
    self:setInLobby(true)

    self.Services.RoundService.RoundEnded:Connect(function()
        self._roundActive = false
        self:setEnabled(false)
    end)

    self.Services.RoundService.RoundStarted:Connect(
    function(playersAndTeams)
        self._roundActive = true
        self:initalise(playersAndTeams)

        if self._inLobby then
            self:setEnabled(true)
        end
    end)

    self.Services.TeamService.TeamChanged:Connect(function(newTeam)
        if newTeam == "Lobby" then
            self:setInLobby(true)
        end
    end)

end

function SpectateGui:Init()
    logger = self.Shared.Logger.new()
    self._roundActive = false
    self._roundEvents = self.Shared.Maid.new()
    self._spectating = false
end

return SpectateGui
