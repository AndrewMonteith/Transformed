-- Werewolf Gun Driver
-- Username
-- June 2, 2020
local WerewolfGunDriver = {}
WerewolfGunDriver.__index = WerewolfGunDriver

function WerewolfGunDriver.new()

    local self = setmetatable({}, WerewolfGunDriver)

    return self

end

return WerewolfGunDriver
