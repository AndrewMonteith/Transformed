local WerewolfCostume = {}
WerewolfCostume.__index = WerewolfCostume

function WerewolfCostume.new(character)
    local costumeParts = WerewolfCostume.Shared.Resource:Load("WerewolfCostume"):Clone() 
    local costumePartDict = {}

    for _, part in pairs(costumeParts:GetChildren()) do
        costumePartDict[part] = true
    end

	local self = setmetatable({
		character = character;
		logger = WerewolfCostume.Shared.Logger.new();
		costumeParts = costumePartDict
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

	for costumePart in pairs(self.costumeParts) do
		local characterPart = self.character[costumePart.Name]
		costumePart.Name = costumePart.Name .. "Clone"
		costumePart.CFrame = characterPart.CFrame
        costumePart.Parent = self.character

		local w = Instance.new("WeldConstraint", costumePart)
		w.Part0, w.Part1 = characterPart, costumePart
	end

	anchorModel(self.character, false)
end

function WerewolfCostume:SetTransparency(transparency)
	for part in pairs(self.costumeParts) do
		part.Transparency = transparency
    end
end

function WerewolfCostume:Destroy()
	for part in pairs(self.costumeParts) do
		part:Destroy()
	end
end

function WerewolfCostume:_giveClaw(hand, offset)
    local claw = self.Shared.Resource:Load("WerewolfClaw"):Clone()
    claw.Parent = self.character
    claw.CFrame = hand.CFrame * offset

    local w = Instance.new("WeldConstraint", claw)
    w.Part0, w.Part1 = hand, claw

    claw.Anchored = false
end

function WerewolfCostume:AddClaws()
    local claw = self.Shared.Resource:Load("WerewolfClaw")

    local leftHand, rightHand = self.character:FindFirstChild("LeftHand"), self.character:FindFirstChild("RightHand")

    if leftHand and rightHand then
        local leftHandClawCFrame = CFrame.new(-0.286212921, -0.757482529, -0.0723862648, 
                                              -0.984806001, 0.0241641719, -0.171962395, 
                                              0.173652992, 0.137095124, -0.975223184, 
                                              1.1924104e-05, -0.990268171, -0.139208332)

        local rightHandClawCFrame = CFrame.new(0.327533722, -0.763594985, -0.117964745,
                                               0.984799027, -0.0301527902, 0.171041176, 
                                               0.163214117, -0.17605409, -0.970757604, 
                                               0.0593772754, 0.983922184, -0.168455914)

        self:_giveClaw(leftHand, leftHandClawCFrame)
        self:_giveClaw(rightHand, rightHandClawCFrame)
    end
end

return WerewolfCostume