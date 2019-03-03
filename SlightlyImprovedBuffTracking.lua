-- Slightly Improved™ Buff Tracking
-- The MIT License © 2016 Arthur Corenzan

local NAMESPACE = "SlightlyImprovedBuffTracking"

--
--
--

-- Change the duration indicator of given icon.
local function SetBuffDebuffIconDurationIndicator(control, indicator)
	if (indicator == "Cooldown") then
		control.duration:SetColor(1, 1, 1, 0)
		control.showCooldown = true
		control.cooldown:SetHidden(false)
	else
		control.duration:SetColor(unpack(control.duration.originalColor))
		control.showCooldown = false
		control.cooldown:SetHidden(true)
	end
end

-- Update duration indicator of all current active icons.
-- Used when the player changes the add-on settings.
local function UpdateBuffDebuffIconDurationIndicator(indicator)
	for _, unitTag in ipairs({"player", "reticleover"}) do
		for _, poolName in ipairs({"buffPool", "debuffPool"}) do
			local controlPool = BUFF_DEBUFF.containerObjectsByUnitTag[unitTag][poolName]
		    for _, control in pairs(controlPool.activeObjects) do
		        SetBuffDebuffIconDurationIndicator(control, indicator)
		    end
		end
	end
end

--
--
--

local defaultSavedVars = {
	durationIndicator = "Label",
}

CALLBACK_MANAGER:RegisterCallback(NAMESPACE.."_OnSavedVarChanged", function(savedVar, newValue, previousValue)
    if (savedVar == "durationIndicator") then
        UpdateBuffDebuffIconDurationIndicator(newValue)
    end
end)

CALLBACK_MANAGER:RegisterCallback(NAMESPACE.."_OnAddOnLoaded", function(savedVars)

	-- Hook into the initialization of each icon in buff/debuff bar
	-- to control which duration indicator should be shown.
	-- "Cooldown" is a clock-wise decreasing shadowy overlay on the icon.
	-- "Label" is a small text with the time left for the effect to expire.
	-- local buffDebuffIcon_OnInitialized = ZO_BuffDebuffIcon_OnInitialized
	-- function ZO_BuffDebuffIcon_OnInitialized(control)
	-- 	buffDebuffIcon_OnInitialized(control)
	-- end

	-- Move BuffDebuff icons to on top of the ability (action) bar.
	ZO_BuffDebuffTopLevelSelfContainer:ClearAnchors()
	ZO_BuffDebuffTopLevelSelfContainer:SetAnchor(BOTTOM, ZO_ActionBar1, TOP, 0, -2)

	-- Move attribute bars up a bit to make room for the BuffDebuff.
	local anchor = ZO_Anchor:New()
	anchor:SetFromControlAnchor(ZO_PlayerAttribute, 0)
	anchor:AddOffsets(0, -38)
	anchor:Set(ZO_PlayerAttribute)

	-- Reduce the gap between buff/debuff icons to match the gap between ability icons.
	-- For that we have to hook into the initialization method for
	-- when a new icon is added to the pool and reset its anchor.
	for _, unitTag in ipairs({"player", "reticleover"}) do
		for _, poolName in ipairs({"buffPool", "debuffPool"}) do
			local controlPool = BUFF_DEBUFF.containerObjectsByUnitTag[unitTag][poolName]
			local customAcquireBehavior = controlPool.customAcquireBehavior
			function controlPool.customAcquireBehavior(control)
				customAcquireBehavior(control)

				-- Center duration label on top of the icon.
				control.duration:ClearAnchors()
				control.duration:SetAnchor(CENTER)

				-- Save original color so we can restore it later.
				-- GetColor() returns 4 values (red, green, blue, and alpha) that's why we wrap it on a table.
				control.duration.originalColor =
				{
					control.duration:GetColor()
				}

				-- Apply the desired duration indicator.
				SetBuffDebuffIconDurationIndicator(control, savedVars.durationIndicator)

				-- Preserve existing anchor parameters.
				local anchor = ZO_Anchor:New()
				anchor:SetFromControlAnchor(control, 0)
				anchor:AddOffsets(-3)
				anchor:Set(control)

				-- Change duration label font.
				control.duration:SetFont("ZoFontWinH4")
			end
		end
	end
end)

-- Add-on entrypoint. You should NOT need to edit below this line.
-- Make sure you have set a NAMESPACE variable and you're good to go.
--
-- If you need to hook into the AddOnLoaded event use the NAMESPACE.."_OnAddOnLoaded" callback. e.g.
-- CALLBACK_MANAGER:RegisterCallback(NAMESPACE.."_OnAddOnLoaded", function(savedVars)
--     ...
-- end)
--
-- To listen to saved variables being changed use the NAMESPACE.."_OnSavedVarChanged" callback. e.g.
-- CALLBACK_MANAGER:RegisterCallback(NAMESPACE.."_OnSavedVarChanged", function(savedVar, newValue, previousValue)
--     ...
-- end)
--
EVENT_MANAGER:RegisterForEvent(NAMESPACE, EVENT_ADD_ON_LOADED, function(eventCode, addOnName)
	if (addOnName == NAMESPACE) then
		local savedVars = ZO_SavedVars:New(NAMESPACE.."_SavedVars", 1, nil, defaultSavedVars)
		do
			local t = getmetatable(savedVars)
			local __newindex = t.__newindex
			function t.__newindex(self, key, value)
				CALLBACK_MANAGER:FireCallbacks(NAMESPACE.."_OnSavedVarChanged", key, value, self[key])
				__newindex(self, key, value)
			end
		end
		CALLBACK_MANAGER:FireCallbacks(NAMESPACE.."_OnAddOnLoaded", savedVars)
	end
end)
