local WerewolfCostume = {}
WerewolfCostume.__index = WerewolfCostume

function WerewolfCostume.new(character)
    local costumePartsFolder = WerewolfCostume.Shared.Resource:Load("WerewolfCostume"):Clone()
    local costumeParts = {}

    for _, costumePart in pairs(costumePartsFolder:GetChildren()) do
        local characterPart = character[costumePart.Name]

        costumeParts[characterPart] = false
        costumeParts[costumePart] = true
    end

    local self = setmetatable({
        character = character,
        logger = WerewolfCostume.Shared.Logger.new(),
        costumeParts = costumeParts
    }, WerewolfCostume)

    self:_weldToCharacter()

    return self
end

local function anchorModel(model, anchored)
    for _, inst in pairs(model:GetChildren()) do
        if inst:IsA("BasePart") then
            inst.Anchored = anchored
        end
    end
end

function WerewolfCostume:_weldToCharacter()
    anchorModel(self.character, true)

    for part, isCostumePart in pairs(self.costumeParts) do
        if isCostumePart then
            local characterPart = self.character[part.Name]
            part.Name = part.Name .. "Clone"
            part.CFrame = characterPart.CFrame
            part.Parent = self.character

            local w = Instance.new("WeldConstraint", part)
            w.Part0, w.Part1 = characterPart, part
        end
    end

    anchorModel(self.character, false)
end

function WerewolfCostume:SetTransparency(transparency)
    for part, isCostumePart in pairs(self.costumeParts) do
        if isCostumePart then
            part.Transparency = transparency
            if part.Name == "HeadClone" then
                part.Face.Transparency = transparency
            end
        else
            part.Transparency = 1 - transparency

            -- when transparency is 0 we fully hide the original character model
            -- however we need to make the head not truely invisible else
            -- the health bar will be hidden during the night
            if transparency == 0 and part.Name == "Head" then
                part.Transparency = 0.99
            end
        end
    end

end

function WerewolfCostume:Destroy()
    for part in pairs(self.costumeParts) do
        part:Destroy()
    end

    if self.leftClaw and self.rightClaw then
        self.leftClaw:Destroy()
        self.rightClaw:Destroy()
    end
end

function WerewolfCostume:_giveClaw(hand, offset)
    local claw = self.Shared.Resource:Load("WerewolfClaw"):Clone()
    claw.Parent = self.character
    claw.CFrame = hand.CFrame * offset
    claw.Name = hand.Name .. "Claw"

    local w = Instance.new("WeldConstraint", claw)
    w.Part0, w.Part1 = hand, claw

    claw.Anchored = false

    return claw
end

function WerewolfCostume:AddClaws()
    local leftHand, rightHand = self.character:FindFirstChild("LeftHand"), self.character:FindFirstChild("RightHand")

    if leftHand and rightHand then
        local leftHandClawCFrame = CFrame.new(-0.286212921, -0.757482529, -0.0723862648, -0.984806001, 0.0241641719,
                                              -0.171962395, 0.173652992, 0.137095124, -0.975223184, 1.1924104e-05,
                                              -0.990268171, -0.139208332)

        local rightHandClawCFrame = CFrame.new(0.327533722, -0.763594985, -0.117964745, 0.984799027, -0.0301527902,
                                               0.171041176, 0.163214117, -0.17605409, -0.970757604, 0.0593772754,
                                               0.983922184, -0.168455914)

        self.leftClaw = self:_giveClaw(leftHand, leftHandClawCFrame)
        self.rightClaw = self:_giveClaw(rightHand, rightHandClawCFrame)
    end
end

function WerewolfCostume:RemoveClaws()
    self.leftClaw:Destroy()
    self.rightClaw:Destroy()
end

return WerewolfCostume
