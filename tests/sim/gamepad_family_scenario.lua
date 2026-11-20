-- luacheck: read globals scenario ADDON
-- With the gamepad interface on, the addon's settings subpage uses native rows the cursor can enter.
local ForeverCore = dofile("tests/forever_core.lua")

scenario(
	"the gamepad cursor enters the Profession Planner addon settings",
	{ addons = ForeverCore.addons() },
	function(sim)
		local G = sim.G
		-- The client opens the panel itself: a C function that calls SettingsPanel:OpenToCategory.
		sim.impl["C_SettingsUtil.OpenSettingsPanel"] = function(categoryID, scrollTo)
			G.SettingsPanel:OpenToCategory(categoryID, scrollTo)
		end
		sim:setGamepad(true)
		sim:login()
		local ns
		for _, entry in ipairs(sim.loader.addons) do
			if entry.name == ADDON then
				ns = entry.ns
			end
		end
		assert(ns and G.ForeverCore and G.ForeverCore.OpenSettingsPanel, "the shared settings opener is loaded")
		local category
		for _, c in ipairs(G.SettingsPanel:GetAllCategories()) do
			if c:GetName() == "Profession Planner" then
				category = c
			end
		end
		assert(category, "Profession Planner is under Options > AddOns")
		local sub
		for _, s in ipairs(category:GetSubcategories()) do
			if s:GetName() == "Addon" then
				sub = s
			end
		end
		assert(sub, "the Addon settings subpage is registered")
		assert(
			G.SettingsPanel:GetLayout(sub):IsVerticalLayout(),
			"Addon settings use a canvas page, which the gamepad cursor cannot enter (cjber/tweaks-forever#382)"
		)
		-- The page opens through the addon's own opener, which asks the client's restricted function through its secure
		-- delegate (cjber/forever-core#333), so this path is walked too.
		sim:input(function()
			G.ForeverCore.OpenSettingsPanel(category:GetID())
		end)
		sim:input(function()
			G.SettingsPanel:SelectCategory(sub)
		end)
		sim:advance(0.1)
		local first = G.SettingsPanel:GetFirstSmartNavFocusableSettingFrame()
		assert(first and first:IsVisible(), "the cursor lands on a visible row of the Addon settings subpage")
		sim:expectNoErrors(ADDON)
	end
)
