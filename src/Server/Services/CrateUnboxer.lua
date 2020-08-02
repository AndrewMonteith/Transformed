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

local UnboxingDistributions = {
    Common = {Common = 1, Uncommon = 0, Rare = 0},
    Uncommon = {Common = 0.75, Uncommon = 0.25, Rare = 0},
    Rare = {Common = 0.5, Uncommon = 0.35, Rare = 0.15}
}
CrateUnboxer.UnboxingDistributions = UnboxingDistributions

function CrateUnboxer:Start() end

function CrateUnboxer:Init()
    self._logger = self.Shared.Logger.new()
    self._random = Random.new()
end

function CrateUnboxer:UnboxSkin(skinType, rarity, player)
    local unboxingDistribution = UnboxingDistributions[rarity]

    -- Choose which rarity they will be awared
    local rarityProb, unboxedRarity = self._random:NextNumber()
    if rarityProb <= unboxingDistribution.Common then
        unboxedRarity = "Common"
    elseif rarityProb <= (unboxingDistribution.Common + unboxingDistribution.Uncommon) then
        unboxedRarity = "Uncommon"
    else
        unboxedRarity = "Rare"
    end

    local isVip = true -- TODO: Check whether player is VIP
    local unboxableSkins = self.Shared.CrateSkins:GetAllTierSkins(skinType, isVip, unboxedRarity)
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
