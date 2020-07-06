--[[
	We implement the following rules when it comes to crate unboxing:
		- There are 4 tiers of rarity for an item: Common, Uncommon, Rare and Very Rare.
		- Each skin will belong to one of these items.
		- To unbox a crate:
			- Randomly pick a category with probabilities {
				Common = 50%,
				Uncommon = 35%,
				Rare = 15%,
			}
]] local CrateUnboxer = {Client = {}}

local UnboxingProbabilities = {Common = 0.5, Uncommon = 0.35, Rare = 0.15}
CrateUnboxer.UnboxingProbabilities = UnboxingProbabilities

function CrateUnboxer:Start() end

function CrateUnboxer:Init()
    self._logger = self.Shared.Logger.new()
    self._random = Random.new()
end

function CrateUnboxer:UnboxSkin(skinType, player)
    -- Choose which rarity they will be awared
    local rarityProb, unboxedRarity = self._random:NextNumber()
    if rarityProb <= UnboxingProbabilities.Common then
        unboxedRarity = "Common"
    elseif rarityProb <= (UnboxingProbabilities.Common + UnboxingProbabilities.Uncommon) then
        unboxedRarity = "Uncommon"
    else
        unboxedRarity = "Rare"
    end

    local unboxableSkins = self.Shared.CrateSkins:GetAllTierSkins(skinType, unboxedRarity)
    local randomSkinIndex = self._random:NextInteger(1, #unboxableSkins)

    -- Skin is a skinName => skin Dict so we need to go through to do an index
    local i = 1
    for _, skin in pairs(unboxableSkins) do
        if i == randomSkinIndex then
            return skin
        end
        i = i + 1
    end
end

return CrateUnboxer
