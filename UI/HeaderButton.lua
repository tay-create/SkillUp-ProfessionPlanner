---@type string, SkillUpNamespace
local _, ns = ...

if ns.broken then
	return
end

local button

function ns.RefreshHeaderButton()
	if button then
		button:SetEnabled(ns.Pages.CanOpen())
	end
end

-- Blizzard's profession window exists before the recipe list and our pages are initialized.
function ns.AttachHeaderButton()
	if button or not ProfessionsFrame then
		return
	end

	local frame = ProfessionsFrame
	button = CreateFrame("Button", "ProfessionPlannerHeaderButton", frame, "UIPanelButtonTemplate")
	button:SetSize(175, 24)
	button:SetPoint("TOPRIGHT", frame.TitleContainer or frame, "TOPRIGHT", -8, -2)
	button:SetText("")

	button.Icon = button:CreateTexture(nil, "ARTWORK")
	button.Icon:SetSize(18, 18)
	button.Icon:SetPoint("LEFT", button, "LEFT", 8, 0)
	button.Icon:SetTexture(ns.ICON)

	button.Label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	button.Label:SetPoint("LEFT", button.Icon, "RIGHT", 6, 0)
	button.Label:SetText(ns.L["Profession Planner"])
	button:SetScript("OnClick", function()
		ns.Pages.OpenLast()
	end)
	frame:HookScript("OnShow", ns.RefreshHeaderButton)
	EventRegistry:RegisterCallback("Professions.ProfessionSelected", ns.RefreshHeaderButton, button)
	ns.RefreshHeaderButton()
end
