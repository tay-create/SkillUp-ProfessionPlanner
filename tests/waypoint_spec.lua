-- Run from the repository root: luajit tests/waypoint_spec.lua
local Client = dofile("tests/client.lua")
local ForeverCore = dofile("tests/forever_core.lua")
local equal = Client.equal

-- One vendor in Elwynn Forest (uiMapID 1429) at 42.1, 65.9, as the catalogue reads it from QuestieDB.
local calls
---@type table<integer, table>
local npcs = { [1250] = { name = "Drake Lindgren", side = "A", map = 1429, x = 0.421, y = 0.659 } }
local ns = {
	Catalogue = {
		NPC = function(npcID)
			return npcs[npcID]
		end,
	},
	Print = function(message)
		calls.printed = message
	end,
}
local maps = {
	[1429] = { mapID = 1429, name = "Elwynn Forest", mapType = 3, parentMapID = 1415 },
	[1415] = { mapID = 1415, name = "Eastern Kingdoms", mapType = 2 },
	[1434] = { mapID = 1434, name = "Stranglethorn Vale", mapType = 3, parentMapID = 1415 },
}
local currentMap = 1429
local placed = 0
local env = setmetatable({
	UNKNOWN = "Unknown",
	C_Map = {
		GetBestMapForUnit = function()
			return currentMap
		end,
		GetMapInfo = function(map)
			return maps[map]
		end,
		GetAreaInfo = function(area)
			return area == 1581 and "The Deadmines" or nil
		end,
		-- Elwynn Forest is on continent 0, its x running north to south.
		GetWorldPosFromMapPos = function(_, point)
			placed = placed + 1
			return 0, {
				GetXY = function()
					return -point.x * 10000, 100
				end,
			}
		end,
		CanSetUserWaypointOnMap = function()
			return true
		end,
		SetUserWaypoint = function(point)
			calls.native = point
		end,
	},
	C_SuperTrack = {
		SetSuperTrackedUserWaypoint = function(on)
			calls.superTracked = on
		end,
	},
	UiMapPoint = {
		CreateFromCoordinates = function(map, x, y)
			return { map = map, x = x, y = y }
		end,
	},
	CreateVector2D = function(x, y)
		return { x = x, y = y }
	end,
	C_Item = {
		GetItemNameByID = function(itemID)
			return itemID == 6289 and "Raw Longjaw Mud Snapper" or nil
		end,
	},
}, { __index = _G })
assert(loadfile("Locales/enUS.lua"))("ProfessionPlanner", ns)
setfenv(assert(loadfile("Integrations/Sources.lua")), env)("ProfessionPlanner", ns)

---@param accepts boolean?
local function Run(accepts, version)
	calls = {}
	if accepts == nil then
		env.ShortestPathForever = nil
	else
		env.ShortestPathForever = {
			API = {
				version = version or 1,
				Navigate = function(owner, map, x, y, title)
					calls.navigate = { owner = owner, map = map, x = x, y = y, title = title }
					return accepts
				end,
			},
		}
	end
	calls.result = ns.SetWaypoint(1250)
end

Run(true)
equal(calls.result, true, "an accepted route reports it started")
equal(calls.navigate.owner, "ProfessionPlanner", "Shortest Path Forever gets the addon as owner")
equal(calls.navigate.map, 1429, "Shortest Path Forever gets the NPC's map")
equal(calls.navigate.x, 0.421, "Shortest Path Forever gets the NPC's x")
equal(calls.navigate.y, 0.659, "Shortest Path Forever gets the NPC's y")
equal(calls.navigate.title, "Drake Lindgren", "Shortest Path Forever names the stop after the NPC")
equal(calls.native, nil, "an accepted route sets no map waypoint")
equal(calls.printed, "route set to Drake Lindgren, Elwynn Forest  42, 66.", "an accepted route says where")

Run(true, 2)
equal(calls.navigate and calls.navigate.owner, "ProfessionPlanner", "API v2 keeps the navigation contract")
equal(calls.native, nil, "API v2 navigation needs no native fallback")

Run(false)
equal(calls.navigate ~= nil, true, "Shortest Path Forever is asked first")
equal(calls.native and calls.native.map, 1429, "a declined route falls back to the map waypoint")
equal(calls.superTracked, true, "the fallback waypoint is super-tracked")
equal(calls.printed, "waypoint set to Drake Lindgren, Elwynn Forest  42, 66.", "the fallback says where")
equal(calls.result, true, "a map waypoint counts as started")

Run(nil)
equal(calls.native and calls.native.x, 0.421, "without Shortest Path Forever the map waypoint is set")
equal(calls.superTracked, true, "without Shortest Path Forever the waypoint is super-tracked")

-- Another API version, or version 1 without Navigate, is never called.
calls = {}
env.ShortestPathForever = {
	API = {
		version = 3,
		Navigate = function()
			calls.navigate = true
			return true
		end,
	},
}
ns.SetWaypoint(1250)
equal(calls.navigate, nil, "another API version isn't asked")
equal(calls.native and calls.native.map, 1429, "another API version falls back to the map waypoint")
calls = {}
env.ShortestPathForever = { API = { version = 1 } }
ns.SetWaypoint(1250)
equal(calls.native and calls.native.map, 1429, "an API without Navigate falls back to the map waypoint")

-- Companion hints under a waypoint click to the nearest NPC,
-- what Shortest Path Forever adds; under an Artisan quest step, what Adventure Guide Forever adds.
local addons, hints = {}, {}
env.C_AddOns = {
	IsAddOnLoaded = function(name)
		return addons[name] == "loaded"
	end,
	DoesAddOnExist = function(name)
		return addons[name] ~= nil
	end,
	GetAddOnInfo = function(name)
		return name, name, "", addons[name] ~= "disabled", addons[name] == "disabled" and "DISABLED" or nil, "INSECURE"
	end,
}
env.GameTooltip_AddDisabledLine = function(_, text)
	hints[#hints + 1] = text
end
ns.db = { suggestFamily = true, familyDismissed = {} }
local TRAVEL = "With Shortest Path Forever, this picks the nearest by travel time and leads you there."
local ENABLE = "Enable Shortest Path Forever for walked routes and boat times."
local CHAIN = "Adventure Guide Forever can plan this quest chain."
local function Hint(state, single)
	addons.ShortestPathForever, hints = state, {}
	ns.AddCompanionHint({}, single)
	equal(#hints <= 1, true, "at most one Shortest Path line")
	return hints[1]
end
local function Chain(state)
	addons.AdventureGuideForever, hints = state, {}
	ns.AddQuestChainHint({})
	return hints[1]
end
equal(Hint(nil), TRAVEL, "missing: the travel-time line")
equal(Hint("disabled"), ENABLE, "turned off: how to get it back")
equal(Hint("installed"), nil, "installed but not loaded for another reason: nothing")
equal(Hint("loaded"), nil, "running: no hint")
equal(Hint(nil, true), "With Shortest Path Forever, a click leads you there.", "one fixed NPC: no nearest to pick")
local getInfo = env.C_AddOns.GetAddOnInfo
env.C_AddOns.GetAddOnInfo = function()
	error("secret value")
end
equal(Hint("disabled"), nil, "an answer the client won't give shows no line")
env.C_AddOns.GetAddOnInfo = getInfo
equal(Chain(nil), CHAIN, "Adventure Guide missing: the quest chain line")
equal(Chain("disabled"), nil, "Adventure Guide turned off: the player chose that")
equal(Chain("loaded"), nil, "Adventure Guide running: no hint")
ns.db.suggestFamily = false
equal(Hint(nil), nil, "the setting off hides the travel-time line")
equal(Hint("disabled"), nil, "and the enable line")
equal(Chain(nil), nil, "and the quest chain line")
ns.db.suggestFamily = true
ns.db.familyDismissed["ProfessionPlanner:travel"] = true
equal(Hint(nil), nil, "a dismissed travel hint stays away")
equal(Hint("disabled"), ENABLE, "the enable line isn't a suggestion, so dismissing doesn't hide it")
equal(Chain(nil), CHAIN, "dismissing one hint leaves the other")
ns.db.familyDismissed["ProfessionPlanner:questChain"] = true
equal(Chain(nil), nil, "a dismissed quest chain hint stays away")
ns.db.familyDismissed = {}

-- An NPC is named by its zone and its place on the zone's map.
local where = ns.NPCLocation(1250)
equal(ns.LocationText(where), "Elwynn Forest  42, 66", "the NPC is named by zone and zone coordinates")
equal(where.map, 1429, "the waypoint is on the zone's map")
npcs[1260] = { name = "Lost", side = "", map = 99, x = 0.5, y = 0.5 }
equal(ns.LocationText(ns.NPCLocation(1260)), "unknown location", "a map the client lacks has no place")
equal(ns.NPCLocation(1261).name, "Unknown", "an NPC QuestieDB lacks has no name")
calls = {}
equal(ns.SetWaypoint(1261), false, "and starts no route")
equal(calls.printed, nil, "without a word")

-- Nearest by travel: 1251 is nearer in a straight line, 1252 across the water but a quicker trip; 1253 is of
-- the other faction and 1254 hostile to both.
npcs[1251] = { name = "Near", side = "", map = 1429, x = 0.91, y = 0.5 }
npcs[1252] = { name = "Quick", side = "", map = 1429, x = 0.95, y = 0.5 }
npcs[1253] = { name = "Horde", side = "H", map = 1429, x = 0.905, y = 0.5 }
npcs[1254] = { name = "Hostile", map = 1429, x = 0.905, y = 0.5 }
local combat, estimated = false, 0
env.UnitFactionGroup = function()
	return "Alliance"
end
env.UnitPosition = function()
	return -9050, 100, 0, 0
end
env.InCombatLockdown = function()
	return combat
end
env.C_Map.GetBestMapForUnit = function()
	return currentMap
end
env.C_Map.GetPlayerMapPosition = function()
	return {
		GetXY = function()
			return 0.5, 0.5
		end,
	}
end
local seconds = { [0.91] = 300, [0.95] = 60 }
env.ShortestPathForever = {
	API = {
		version = 1,
		Estimate = function(_, _, _, _, toX)
			estimated = estimated + 1
			return seconds[toX], seconds[toX] == nil and "unreachable" or nil
		end,
	},
}
local sellers = { 1253, 1254, 1251, 1252 }
equal(ns.NearestNPC(sellers), 1251, "without byTravel the straight-line nearest wins")
equal(placed, 2, "each NPC this character can deal with is placed in the world")
equal(estimated, 0, "without byTravel nothing is estimated")
equal(ns.NearestNPC(sellers, true), 1252, "byTravel prefers the quicker trip")
equal(estimated, 2, "only this faction's vendors are estimated")
equal(placed, 2, "and placed only once")
seconds = {}
equal(ns.NearestNPC(sellers, true), 1251, "no estimate keeps the straight-line nearest")
combat, estimated = true, 0
equal(ns.NearestNPC(sellers, true), 1251, "in combat the straight-line nearest wins")
equal(estimated, 0, "nothing is estimated in combat")
combat, env.ShortestPathForever = false, nil
equal(ns.NearestNPC(sellers, true), 1251, "without Shortest Path Forever the straight-line nearest wins")
env.ShortestPathForever = { API = { version = 1 } }
equal(ns.NearestNPC(sellers, true), 1251, "an API without Estimate keeps the straight-line nearest")

-- On another continent no vendor has a distance: only a travel estimate, or being the only one, picks one.
local position = env.UnitPosition
env.UnitPosition = function()
	return 0, 0, 0, 5
end
env.ShortestPathForever = nil
equal(ns.NearestNPC(sellers), nil, "with every vendor on another continent none is the nearest")
equal(ns.NearestNPC(sellers, true), nil, "nor by travel without Shortest Path Forever")
equal(ns.NearestNPC({ 1253, 1252 }), 1252, "the only vendor there is is named")
seconds = { [0.91] = 300, [0.95] = 60 }
env.ShortestPathForever = {
	API = {
		version = 1,
		Estimate = function(_, _, _, _, toX)
			return seconds[toX]
		end,
	},
}
equal(ns.NearestNPC(sellers, true), 1252, "a travel estimate ranks vendors on another continent")
seconds = {}
equal(ns.NearestNPC(sellers, true), nil, "and without one none is the nearest")
env.UnitPosition, env.ShortestPathForever = position, { API = { version = 1 } }

-- A dungeon NPC has no map point: only a chat line, and no route started.
calls = {}
npcs[1255] = { name = "Sneed", area = 1581 }
equal(ns.SetWaypoint(1255), false, "a dungeon NPC starts no route")
equal(calls.printed, "Sneed is in The Deadmines.", "and says where it is")
equal(ns.NearestNPC({ 1255, 1261 }), nil, "and is nobody's nearest vendor")

-- Zone-only fish get an explicitly approximate destination to a known zone.
ns.FishingZones = { [6289] = { 1429, 1434 } }
calls = {}
equal(ns.FindFishing(6289), true, "the fish is available in the current zone")
equal(
	calls.printed,
	"Fishing waypoint for Raw Longjaw Mud Snapper: Elwynn Forest (approximate zone; look for fishable water).",
	"the zone destination is labeled approximate"
)
equal(calls.native and calls.native.map, 1429, "the current fishing zone receives a waypoint")
equal(calls.native and calls.native.x, 0.5, "the approximate zone destination is centered")
currentMap = 1415
env.UnitPosition = function()
	return -9000, 100, 0, 0
end
env.C_Map.GetWorldPosFromMapPos = function(mapID)
	return 0, {
		GetXY = function()
			return mapID == 1434 and -8000 or -5000, 100
		end,
	}
end
calls = {}
equal(ns.FindFishing(6289), true, "known zones are available outside the current zone")
equal(
	calls.printed,
	"Fishing waypoint for Raw Longjaw Mud Snapper: Stranglethorn Vale (approximate zone; look for fishable water).",
	"the nearest mapped zone gets an approximate destination"
)
equal(calls.native and calls.native.map, 1434, "the closest known zone receives the waypoint")
env.UnitPosition = function()
	return nil
end
calls = {}
equal(ns.FindFishing(6289), true, "zones are still available when the player has no world position")
equal(calls.native and calls.native.map, 1429, "unknown distance uses a known zone as a fallback")
calls = {}
equal(ns.FindFishing(999), false, "unknown fish return no destination")
equal(calls.printed, "No known fishing zone for item 999.", "missing fishing data is explained")

-- Reported catches navigate to the nearest same-instance point; repeated hooks try alternatives.
ns.FishingPoints = {
	[6289] = {
		[1429] = { 200, 300, 800, 700 },
		[1434] = { 100, 200 },
	},
}
env.UnitPosition = function()
	return -2100, 100, 0, 0
end
env.C_Map.GetWorldPosFromMapPos = function(mapID, point)
	return mapID == 1434 and 1 or 0, {
		GetXY = function()
			return -point.x * 10000, 100
		end,
	}
end
env.ShortestPathForever = nil
calls = {}
equal(ns.FindFishing(6289), true, "the fish has a reported location")
equal(calls.native and calls.native.map, 1429, "a catch from another instance is skipped")
equal(calls.native and calls.native.x, 0.2, "the nearest report is selected")
equal(calls.native and calls.native.y, 0.3, "the reported map y is preserved")
equal(calls.superTracked, true, "the fishing point is super-tracked")
equal(calls.printed:find("reported catch", 1, true) ~= nil, true, "the waypoint is labeled as a report")
calls = {}
equal(ns.FindFishing(6289), true, "the next click finds another report")
equal(calls.native and calls.native.x, 0.8, "the next-nearest unvisited point is selected")
calls = {}
equal(ns.FindFishing(6289), true, "reported points can be retried after exhaustion")
equal(calls.native and calls.native.x, 0.2, "the selection cycles after all reports were offered")

calls = {}
env.ShortestPathForever = {
	API = {
		version = 1,
		Navigate = function(owner, map, x, y, title)
			calls.navigate = { owner = owner, map = map, x = x, y = y, title = title }
			return true
		end,
	},
}
equal(ns.FindFishing(6289), true, "a reported catch supports Shortest Path Forever")
equal(calls.navigate and calls.navigate.owner, "ProfessionPlanner", "the fishing route uses the addon name")
equal(calls.navigate and calls.navigate.x, 0.8, "the route uses the next point")
equal(calls.native, nil, "an accepted route needs no fallback waypoint")

env.ShortestPathForever = nil
env.TomTom = {
	AddWaypoint = function(_, map, x, y, options)
		calls.tomtom = { map = map, x = x, y = y, options = options }
	end,
}
calls = {}
equal(ns.FindFishing(6289), true, "a reported catch supports TomTom")
equal(calls.tomtom and calls.tomtom.x, 0.2, "TomTom receives a precise coordinate")
equal(calls.native, nil, "TomTom does not need the native waypoint")

env.TomTom = nil
env.C_Map.CanSetUserWaypointOnMap = function()
	return false
end
calls = {}
equal(ns.FindFishing(6289), false, "without a waypoint provider navigation fails cleanly")
equal(calls.printed:find("Unable to set waypoint", 1, true) ~= nil, true, "the failed waypoint is explained")
equal(calls.native, nil, "an unsupported map receives no native waypoint")

env.UnitPosition = function()
	return nil
end
calls = {}
equal(ns.FindFishing(6289), false, "without a position, historical catches are still considered")
equal(calls.printed:find("reported catch", 1, true) == nil, true, "no route is claimed when navigation is unavailable")

-- Across instances, a recorded location is still navigable when Shortest Path Forever accepts it.
currentMap = 1434
env.UnitPosition = function()
	return -2100, 100, 0, 2
end
env.ShortestPathForever = {
	API = {
		version = 2,
		Navigate = function(owner, map, x, y)
			calls.navigate = { owner = owner, map = map, x = x, y = y }
			return true
		end,
	},
}
calls = {}
equal(ns.FindFishing(6289), true, "a historical catch across instances can start a route")
equal(calls.navigate and calls.navigate.map, 1434, "the known zone of the player is preferred for remote reports")
equal(calls.navigate and calls.navigate.x, 0.1, "the recorded coordinates are used remotely")
equal(calls.printed:find("Fishing route", 1, true) ~= nil, true, "an accepted route is identified")

Client.report("waypoint_spec")
