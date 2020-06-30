-- Day Night Cycle
-- Username
-- June 12, 2020
local DayNightCycle = {Client = {}}

local SunriseHour, SunsetHour = 6, 18

local Times = {
    Sunrise = ("0%d:15:00"):format(SunriseHour),
    Sunset = ("0%d:15:00"):format(SunsetHour),
    LobbyTime = "-11:02:31"
}

function DayNightCycle:setTime(time) game:GetService("Lighting").TimeOfDay = time end

function DayNightCycle:doTimeCycle(time)
    if self._timePassing then
        return
    end

    self._timePassing = true
    self._isDaytime = true

    self:Fire("Sunrise")
    self:FireAllClients("Sunrise")

    local startHour, targetHour = SunriseHour, SunsetHour
    local timeElapsed = time

    local roundTwilight = self.Modules.ServerSettings.RoundTwilightTime
    local actualTwilight = math.abs((targetHour - startHour) * 3600)
    local Lighting = game:GetService("Lighting")

    self:setTime(Times.Sunrise)

    while self._timePassing do
        local passTime = wait(.1)

        timeElapsed = timeElapsed + passTime

        local totalAddedSeconds = timeElapsed / roundTwilight * actualTwilight

        local seconds = math.floor(totalAddedSeconds % 60)
        local addedMinutes = math.floor((totalAddedSeconds / 60) % 60)
        local addedHours = math.floor(totalAddedSeconds / 3600)

        Lighting.TimeOfDay = ("%d:%d:%d"):format(startHour + addedHours, 15 + addedMinutes, seconds)

        if timeElapsed >= roundTwilight then
            local event = targetHour == SunsetHour and "Sunset" or "Sunrise"

            self:Fire(event)
            self:FireAllClients(event)

            self._isDaytime = not self._isDaytime
            timeElapsed = timeElapsed % roundTwilight
            targetHour, startHour = startHour, targetHour
        end
    end

    self._logger:Log("Reset to lobby time")
    self:setTime(Times.LobbyTime)
end

function DayNightCycle:SetActive(active)
    if self._timePassing == active then
        return
    end

    if active then
        spawn(function(time) self:doTimeCycle(time) end)
    else
        self._timePassing = active
    end
end

function DayNightCycle:Init()
    self._logger = self.Shared.Logger.new()
    self._timePassing = false

    self:RegisterClientEvent("Sunrise")
    self:RegisterClientEvent("Sunset")
    self:RegisterEvent("Sunrise")
    self:RegisterEvent("Sunset")
end

function DayNightCycle:Start()
    self.Services.RoundService:ConnectEvent("RoundEnded", function() self:SetActive(false) end)
end

return DayNightCycle
