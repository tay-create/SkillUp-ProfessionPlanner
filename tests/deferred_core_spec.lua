-- Run from the repository root: luajit tests/deferred_core_spec.lua
local Client = dofile("tests/client.lua")
local equal = Client.equal

-- ForeverCore 1.15+ publishes its facade after the consumer's initial load.
local client = Client.load({ deferCore = true })
equal(client.ns.broken, nil, "deferred core does not disable the addon")
equal(type(client.ns.core), "table", "deferred core registers the addon")
equal(type(client.G.SlashCmdList.PROFESSIONPLANNER), "function", "slash command is registered")
equal(type(client.G.ProfessionPlanner_OnAddonCompartmentClick), "function", "compartment button is registered")
equal(type(client.ns.AttachHeaderButton), "function", "profession window button can attach")

Client.report("deferred_core_spec")
