local _, ns = ...

-- The game refuses to load this addon when ForeverCore is absent (## Dependencies), but an older ForeverCore still
-- loads. Its API version stays at 1 while it adds members, so a core is out of date when a member this addon calls is
-- missing, never because of a version comparison.
--
-- API 1 has the report window, the tracker host, the family suggestions, the map, settings and context menu openers,
-- all of which this addon calls. The API kit arrived after it
-- (ForeverCore 1.1.0) and Core/API.lua builds this addon's own API on its Hub and NotReady. Publishing to the suite's
-- list (APIKit.Publish) is guarded by the kit's minor, so an older kit is not a reason to stop. The tracker section
-- and line arrived after it too (ForeverCore 1.2.0): UI/Shopping.lua builds its section with Section.Create and makes
-- its lines clickable with Line.SetInteractive. UI/Pages.lua registers the Professions side tab with
-- ProfessionTabs.Register (ForeverCore 1.4.0) and UI/RecipeList.lua sizes the window with ProfessionTabs.SetMinWidth
-- (ForeverCore 1.5.0). ProfessionTabs minor 2 (ForeverCore 1.8.1) hides the client's page beneath SkillUp's, so an
-- older core leaves this addon's page over the native one and the addon stops.
--
-- The warning itself is Core/ForeverRequire.lua, shared by every Forever addon: one line on screen, never a chat
-- message, naming the addon to update and never ForeverCore.
-- ForeverCore 1.15+ elects and publishes its implementation at PLAYER_LOGIN.
-- Consumer files load earlier, so wait for its ready callback before checking capabilities.
function ns.OnCoreReady(callback)
	local core = rawget(_G, "ForeverCore")
	if type(core) == "table" then
		return callback(core)
	end
	local loader = rawget(_G, "ForeverCoreLoader")
	if type(loader) == "table" and type(loader.OnReady) == "function" then
		return loader.OnReady(callback)
	end
end

local function CheckCore(core)
	local ready = type(core) == "table"
		and type(core.APIKit) == "table"
		and type(core.APIKit.Hub) == "function"
		and type(core.APIKit.NotReady) == "function"
		and type(core.TrackerSection) == "table"
		and type(core.TrackerSection.Create) == "function"
		and type(core.TrackerLine) == "table"
		and type(core.TrackerLine.SetInteractive) == "function"
		and type(core.ProfessionTabs) == "table"
		and type(core.ProfessionTabs.Register) == "function"
		and type(core.ProfessionTabs.SetMinWidth) == "function"
		and (tonumber(core.ProfessionTabs.minor) or 0) >= 2

	ns.ForeverRequire(ready)
end

if rawget(_G, "ForeverCore") ~= nil or rawget(_G, "ForeverCoreLoader") ~= nil then
	ns.OnCoreReady(CheckCore)
else
	ns.ForeverRequire(false)
end
