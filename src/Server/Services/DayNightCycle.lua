-- Day Night Cycle
-- Username
-- June 12, 2020
local DayNightCycle = {Client = {}}

local SunriseHour, SunsetHour = 6, 18
local logger

DayNightCycle.Times = {
    Sunrise = ("0%d:15:00"):format(SunriseHour),
    Sunset = ("0%d:15:00"):format(SunsetHour),
    LobbyTime = "-11:02:31"
}

function DayNightCycle:Start()
end

function DayNightCycle:IsDaytime()
    return self.isDaytime
end

function DayNightCycle:SetTime(time)
    game:GetService("Lighting").TimeOfDay = time
end

function DayNightCycle:DoTimeCycle(time)
    if self.timePassing then
        return
    end

    self.timePassing = true
    self.isDaytime = true

    local startHour, targetHour = SunriseHour, SunsetHour
    local timeElapsed = time

    local roundTwilight = self.Modules.Settings.RoundTwilightTime
    local actualTwilight = math.abs((targetHour - startHour) * 3600)
    local Lighting = game:GetService("Lighting")

    self:SetTime(self.Times.Sunrise)

    while self.timePassing do
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
            for _, player in pairs(self.Services.PlayerService:GetPlayersInRound()) do
                self:FireClient(event, player)
            end

            self.isDaytime = not self.isDaytime
            timeElapsed = timeElapsed % roundTwilight
            targetHour, startHour = startHour, targetHour
        end
    end

    self:SetTime(self.Times.LobbyTime)
end

function DayNightCycle:SetActive(active)
    if active then
        spawn(function(time)
            self:DoTimeCycle(time)
        end)
    else
        self.timePassing = active
    end
end

function DayNightCycle:Init()
    self.timePassing = false
    logger = self.Shared.Logger.new()

    self:RegisterClientEvent("Sunrise")
    self:RegisterClientEvent("Sunset")
    self:RegisterEvent("Sunrise")
    self:RegisterEvent("Sunset")
end

return DayNightCycle
