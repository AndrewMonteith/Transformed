local StatsService = {Client = {}}

function StatsService:loadDataObjects()
    self.Modules.Data.SaveInStudio = true

    local function onPlayerAdded(player)
        local ds = self.Modules.Data.ForPlayer(player)

        local _, visitedBefore = ds:Get("VisitedBefore"):Await()

        if not visitedBefore then
            local defaultProfile = {Xp = 0, Money = 100, VisitedBefore = true}
            local setPromises = {}

            for key, value in pairs(defaultProfile) do
                setPromises[#setPromises + 1] = ds:Set(key, value)
            end

            self.Shared.Promise.All(setPromises):Await()
        end

        self._dataStores[player] = ds
    end
    game.Players.PlayerAdded:Connect(onPlayerAdded)

    for _, player in pairs(game.Players:GetPlayers()) do
        onPlayerAdded(player)
    end
end

local function getKey(ds, key, default)
    local success, data = ds:Get(key):Await()

    if not success then
        wait(1)
        success, data = ds:Get(key):Await()
    end

    if success then
        return data
    else
        self._logger:Warn("Failed to get key for ", key)
        return default
    end
end

function StatsService.Client:Get(player, key)
    while (not self.Server._dataStores[player]) do
        wait(1)
    end

    return getKey(self.Server._dataStores[player], key, 0)
end

function StatsService:GiveXp(player, bonus)
    local ds = self._dataStores[player]

    -- we assume this operation to succeed because there will be a value
    -- present in the internal cache set by loading their profile
    local xp = getKey(ds, "Xp", 0)
    local newXp = xp + bonus
    ds:Set("Xp", newXp)

    self:FireClient("XpChanged", player, newXp)

    self._logger:Log(player, " was awared ", bonus, " xp. Now on ", newXp)
end

function StatsService:GiveMoney(player, bonus)
    local ds = self._dataStores[player]

    local money = getKey(ds, "Money", 0)
    local newMoney = money + bonus
    ds:Set("Money", newMoney)

    self:FireClient("MoneyChanged", player, newMoney)

    self._logger:Log(player, " was awarded ", bonus, " money. Now on", newMoney)
end

function StatsService:Start() self:loadDataObjects() end

function StatsService:Init()
    self._logger = self.Shared.Logger.new()
    self._dataStores = self.Shared.PlayerDict.new()

    self:RegisterClientEvent("XpChanged")
    self:RegisterClientEvent("MoneyChanged")
end

return StatsService
