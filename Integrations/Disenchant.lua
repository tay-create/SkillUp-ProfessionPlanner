---@type string, SkillUpNamespace
local _, ns = ...

if ns.broken then
	return
end

-- Forever client item-level bands, with Classic green-armor odds as an estimate.
-- https://legacyofwarcraft.com/db/forever/professions/disenchanting.html
-- The Forever guide uses required character levels, which are different from item levels.
-- Each attempt produces random materials, and Forever's actual odds can differ.
-- [min item level, max item level, {dust item, min, max, optional chance}, {essence ...}, {shard ...}]
local ARMOR = {
	{ 5, 15, { 10940, 1, 2, 0.80 }, { 10938, 1, 2 } },
	{ 16, 20, { 10940, 2, 3 }, { 10939, 1, 2 }, { 10978, 1, 1 } },
	{ 21, 25, { 10940, 4, 6 }, { 10998, 1, 2, 0.15 }, { 10978, 1, 1, 0.10 } },
	{ 26, 30, { 11083, 1, 2 }, { 11082, 1, 2 }, { 11084, 1, 1 } },
	{ 31, 35, { 11083, 2, 5 }, { 11134, 1, 2 }, { 11138, 1, 1 } },
	{ 36, 40, { 11137, 1, 2 }, { 11135, 1, 2 }, { 11139, 1, 1 } },
	{ 41, 45, { 11137, 2, 5 }, { 11174, 1, 2 }, { 11177, 1, 1 } },
	{ 46, 50, { 11176, 1, 2 }, { 11175, 1, 2 }, { 11178, 1, 1 } },
	{ 51, 55, { 11176, 2, 5 }, { 16202, 1, 2 }, { 14343, 1, 1 } },
	{ 56, 60, { 16204, 1, 2 }, { 16203, 1, 2 }, { 14344, 1, 1 } },
	{ 61, math.huge, { 16204, 2, 5 }, { 16203, 1, 3 }, { 14344, 1, 1 } },
}

-- Normally 75% dust, 20% essence and 5% shard, with exceptions in low levels.
local function YieldFor(reagentID, itemLevel)
	for _, row in ipairs(ARMOR) do
		if itemLevel >= row[1] and itemLevel <= row[2] then
			for slot = 3, 5 do
				local material = row[slot]
				if material and material[1] == reagentID then
					local chance = material[4] or (slot == 3 and 0.75 or slot == 4 and 0.20 or 0.05)
					return chance, material[2], material[3]
				end
			end
			return nil
		end
	end
end

-- Cheapest learned Tailoring armor for this reagent, based on average disenchant yields.
-- Ignore secondary random drops when calculating cost to avoid overvaluing a craft.
---@param reagentID integer
---@return SkillUpDisenchantEstimate?
function ns.BestTailoringDisenchant(reagentID)
	local professions = ns.PlayerProfessions()
	if not (professions[197] and professions[333]) then
		return nil
	end

	local best
	for recipeID, recipe in pairs(ns.RecipeData or {}) do
		local output = recipe.output
		if recipe.skillLine == 197 and output and ns.IsLearned(recipeID) and not ns.IsSkipped(recipeID) then
			local _, _, quality, itemLevel, _, _, _, _, equipLoc, _, _, classID = C_Item.GetItemInfo(output.itemID)
			if quality == 2 and classID == 4 and equipLoc and equipLoc ~= "" and type(itemLevel) == "number" then
				local chance, minimum, maximum = YieldFor(reagentID, itemLevel)
				if chance and output.quantity and output.quantity > 0 then
					local craftCost = ns.CraftCost(recipeID)
					if craftCost then
						local expected = output.quantity * chance * (minimum + maximum) / 2
						local unitCost = craftCost / expected
						if
							not best
							or unitCost < best.unitCost
							or (unitCost == best.unitCost and recipeID < best.recipeID)
						then
							best = {
								recipeID = recipeID,
								itemID = output.itemID,
								quantity = output.quantity,
								chance = chance,
								minimum = minimum,
								maximum = maximum,
								expected = expected,
								craftCost = craftCost,
								unitCost = unitCost,
							}
						end
					end
				end
			end
		end
	end
	return best
end

-- Replace only the missing part of a priced Enchanting reagent when Tailoring is
-- cheaper on expected yield. The raw list includes held reagents so shopping can
-- compare against bags and bank. These are estimates, never guaranteed drops.
function ns.PlanDisenchant(plan, raw)
	if not (plan.profession and plan.profession.skillLine == 333) then
		return raw, {}
	end
	local needed, order = {}, {}
	for _, item in ipairs(raw) do
		if not needed[item.itemID] then
			needed[item.itemID] = 0
			order[#order + 1] = item.itemID
		end
		needed[item.itemID] = needed[item.itemID] + item.count
	end
	local choices, gearRemaining = {}, {}
	-- Iterate the original demand only. Materials introduced by Tailoring
	-- must never themselves trigger another disenchant substitution.
	for _, reagentID in ipairs(order) do
		local missing = math.max(0, needed[reagentID] - ns.Have(reagentID))
		local price = ns.ObtainCost and ns.ObtainCost(reagentID)
		local option = missing > 0 and price and price > 0 and ns.BestTailoringDisenchant(reagentID)
		if option then
			local perItem = option.expected / option.quantity
			local items = math.ceil(missing / perItem)
			if gearRemaining[option.itemID] == nil then
				gearRemaining[option.itemID] = ns.Have(option.itemID)
			end
			local held = math.min(gearRemaining[option.itemID], items)
			local crafts = math.ceil((items - held) / option.quantity)
			local totalItems = held + crafts * option.quantity
			local cost = crafts * option.craftCost
			if cost < missing * price then
				local subcrafts, materials = {}, {}
				if crafts > 0 then
					local sub, rawMaterials = ns.RecipeMaterials(option.recipeID, crafts, true)
					if rawMaterials then
						subcrafts, materials = sub or {}, rawMaterials
					end
				end
				if crafts == 0 or #materials > 0 then
					gearRemaining[option.itemID] = gearRemaining[option.itemID] - held
					needed[reagentID] = math.min(needed[reagentID], ns.Have(reagentID))
					for _, item in ipairs(materials) do
						if not needed[item.itemID] then
							needed[item.itemID] = 0
							order[#order + 1] = item.itemID
						end
						needed[item.itemID] = needed[item.itemID] + item.count
					end
					choices[#choices + 1] = {
						reagentID = reagentID,
						need = missing,
						recipeID = option.recipeID,
						itemID = option.itemID,
						held = held,
						crafts = crafts,
						items = totalItems,
						expected = totalItems * perItem,
						chance = option.chance,
						cost = cost,
						buyCost = missing * price,
						subcrafts = subcrafts,
						materials = materials,
					}
				end
			end
		end
	end
	local adjusted = {}
	for _, itemID in ipairs(order) do
		if needed[itemID] > 0 then
			adjusted[#adjusted + 1] = { itemID = itemID, count = needed[itemID] }
		end
	end
	return adjusted, choices
end
