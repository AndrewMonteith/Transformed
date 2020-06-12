-- Day Night Cycle
-- Username
-- June 12, 2020
local DayNightCycle = {Client = {}}

function DayNightCycle:Start()
    
    self.Services.RoundService:ConnectEvent("")
end

function DayNightCycle:Init()
    self.timePassing = false
end

return DayNightCycle
