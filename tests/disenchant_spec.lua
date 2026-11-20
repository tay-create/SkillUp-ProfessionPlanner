-- Run from the repository root: luajit tests/disenchant_spec.lua
local Client = dofile("tests/client.lua")
local equal = Client.equal

local CLOTH, DUST = 7000, 11083
local DATA = {
	VendorPrices = {},
	GatheredBy = {},
	RecipeData = {
		[710] = {
			skillLine = 197,
			reagents = { { itemID = CLOTH, quantity = 1 } },
			output = { itemID = 8000, quantity = 1 },
		},
		[711] = {
			skillLine = 197,
			reagents = { { itemID = CLOTH, quantity = 2 } },
			output = { itemID = 8001, quantity = 1 },
		},
		[712] = {
			skillLine = 197,
			reagents = { { itemID = CLOTH, quantity = 1 } },
			output = { itemID = 8002, quantity = 1 },
		},
	},
}

local c = Client.load({ data = DATA })
local ns = c.ns
c.professions = {
	{ name = "Tailoring", id = 197, rank = 100, max = 150 },
	{ name = "Enchanting", id = 333, rank = 100, max = 150 },
}
c.items[8000] = { name = "Green cloak", quality = 2, itemLevel = 26, classID = 4, equipLoc = "INVTYPE_CLOAK" }
c.items[8001] = { name = "Green belt", quality = 2, itemLevel = 27, classID = 4, equipLoc = "INVTYPE_WAIST" }
c.items[8002] = { name = "White cloak", quality = 1, itemLevel = 27, classID = 4, equipLoc = "INVTYPE_CLOAK" }
c.auction[CLOTH], c.auction[DUST] = 90, 200
c.known[710], c.known[711], c.known[712] = true, true, true

local best = ns.BestTailoringDisenchant(DUST)
equal(best.recipeID, 710, "best known green armor has the lowest input cost")
equal(best.expected, 1.125, "one green armor has average 75% of 1.5 soul dust")
equal(best.unitCost, 80, "cost per expected dust is accurate")
equal(best.minimum, 1, "minimum outcome on a successful dust roll")
equal(best.maximum, 2, "maximum outcome on a successful dust roll")
equal(ns.BestTailoringDisenchant(99999), nil, "unknown enchanting material is not inferred")

c.items[8000].itemLevel = 12
equal(ns.BestTailoringDisenchant(10940).chance, 0.80, "lowest item band uses 80% dust")
equal(ns.BestTailoringDisenchant(10938).chance, 0.20, "lowest item band uses 20% essence")
c.items[8000].itemLevel = 23
equal(ns.BestTailoringDisenchant(10998).chance, 0.15, "item level 21-25 uses 15% essence")
equal(ns.BestTailoringDisenchant(10978).chance, 0.10, "item level 21-25 uses 10% shard")
c.items[8000].itemLevel = 26

c.known[710] = nil
best = ns.BestTailoringDisenchant(DUST)
equal(best.recipeID, 711, "unknown tailoring recipes are excluded")
c.items[8001].quality = 1
equal(ns.BestTailoringDisenchant(DUST), nil, "normal quality items cannot be disenchanted")
c.items[8001].quality, c.items[8001].classID = 2, 2
equal(ns.BestTailoringDisenchant(DUST), nil, "weapon results are excluded from the armor estimate")
c.items[8001].classID, c.items[8001].itemLevel = 4, nil
equal(ns.BestTailoringDisenchant(DUST), nil, "uncached levels are not guessed")
c.items[8001].itemLevel = 27
c.professions = { c.professions[1] }
equal(ns.BestTailoringDisenchant(DUST), nil, "both professions must be learned")
c.professions[#c.professions + 1] = { name = "Enchanting", id = 333, rank = 100, max = 150 }
c.auction[CLOTH] = nil
ns.Changed("prices")
equal(ns.BestTailoringDisenchant(DUST), nil, "unknown input prices do not count as free")

-- Planning must account for the materials needed to craft gear, including what
-- the character already holds, without double counting those held items.
c.auction[CLOTH] = 90
c.known[710] = true
ns.Changed("prices")
local plan = { profession = { skillLine = 333 }, crafts = {}, training = {}, ranks = {} }
local raw, choices = ns.PlanDisenchant(plan, { { itemID = DUST, count = 3 } })
equal(#choices, 1, "profitable tailoring is included in enchanting planning")
equal(choices[1].crafts, 3, "expected material output determines the number of crafts")
equal(choices[1].items, 3, "all crafted green items are assigned to disenchant")
equal(#raw, 1, "no missing dust is purchased when crafting covers the estimate")
equal(raw[1].itemID, CLOTH, "shopping substitutes cloth for enchanting dust")
equal(raw[1].count, 3, "the cloth needed for each craft is counted")

c.bags[DUST] = 2
raw, choices = ns.PlanDisenchant(plan, { { itemID = DUST, count = 3 } })
equal(choices[1].need, 1, "only the reagent shortfall is replaced")
equal(raw[1].itemID, DUST, "held enchantment reagents stay visible as route needs")
equal(raw[1].count, 2, "held reagents are not scheduled to be purchased")
equal(raw[2].count, 1, "one craft covers the missing reagent on average")

c.bags[8000] = 1
raw, choices = ns.PlanDisenchant(plan, { { itemID = DUST, count = 3 } })
equal(choices[1].held, 1, "held green gear is selected before extra crafting")
equal(choices[1].crafts, 0, "held gear avoids crafting the same item again")
equal(#raw, 1, "only the enchanting materials already held remain in the shopping list")

c.bags[DUST] = nil
c.auction[11082] = 5000
raw, choices = ns.PlanDisenchant(plan, { { itemID = DUST, count = 1 }, { itemID = 11082, count = 1 } })
equal(#choices, 2, "multiple enchanting reagents can have disenchant sources")
equal(#raw > 0, true, "the substitutions add their tailoring materials")
equal(choices[1].held, 1, "first material uses the held item")
equal(choices[2].held, 0, "another material cannot reuse the same green item")
equal(choices[2].crafts, 4, "second material requires its own crafts")

c.bags[8000] = nil
c.auction[CLOTH] = 400
ns.Changed("prices")
raw, choices = ns.PlanDisenchant(plan, { { itemID = DUST, count = 3 } })
equal(#choices, 0, "direct purchase wins when disenchant crafting costs more")
equal(raw[1].itemID, DUST, "expensive substitution leaves the original reagent")

c.auction[CLOTH] = nil
ns.Changed("prices")
raw, choices = ns.PlanDisenchant(plan, { { itemID = DUST, count = 3 } })
equal(#choices, 0, "unknown tailoring costs never count as free")
equal(#raw, 1, "unknown-price reagents remain on the route")

c.auction[CLOTH] = 90
ns.Changed("prices")
c.professions = { c.professions[2] }
raw, choices = ns.PlanDisenchant(plan, { { itemID = DUST, count = 3 } })
equal(#choices, 0, "a character without tailoring cannot receive a tailoring route")
equal(raw[1].itemID, DUST, "the material stays on the shopping list without tailoring")
c.professions[#c.professions + 1] = { name = "Tailoring", id = 197, rank = 100, max = 150 }

DATA.RecipeData[720] =
	{ skillLine = 333, reagents = { { itemID = DUST, quantity = 3 } }, output = { itemID = 9000, quantity = 1 } }
plan.crafts = { { recipeID = 720, crafts = 1 } }
local items, selected = ns.RouteReagents(plan)
equal(#selected, 1, "route exposes its selected tailoring and disenchant steps")
equal(#items, 1, "route shopping list substitutes exactly one raw material")
equal(items[1].itemID, CLOTH, "route shopping list uses the crafting material")
equal(items[1].need, 3, "route shopping list includes every tailoring craft")
equal(ns.PlanMoney(plan).buy, 270, "money preview uses substituted tailoring costs")
c.bags[CLOTH] = 1
equal(ns.PlanMoney(plan).buy, 180, "money preview deducts existing cloth from shopping")
c.bags[CLOTH] = nil

Client.report("disenchant_spec")
