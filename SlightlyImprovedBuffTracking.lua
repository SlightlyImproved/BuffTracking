-- Slightly Improved™ Buff Tracking
-- The MIT License © 2016 Arthur Corenzan

local NAMESPACE = "SlightlyImprovedBuffTracking"

--
--
--

-- Move BuffDebuff to below the attribute bars.
local function DisplaceBuffDebuff()
    ZO_BuffDebuffTopLevelSelfContainer:ClearAnchors()
    ZO_BuffDebuffTopLevelSelfContainer:SetAnchor(BOTTOM, ZO_ActionBar1, TOP, 0, -2)
end

-- Move attribute bars up a bit to make room for the BuffDebuff.
local function DisplacePlayerAttributeBars()
    local anchor = ZO_Anchor:New()
    anchor:SetFromControlAnchor(ZO_PlayerAttribute, 0)
    anchor:AddOffsets(0, -38)
    anchor:Set(ZO_PlayerAttribute)
end

-- Reduce gutter between icons in BuffDebuff.
local function ReduceIconGap(control)
    local anchor = ZO_Anchor:New()
    anchor:SetFromControlAnchor(control, 0)
    anchor:AddOffsets(-3)
    anchor:Set(control)
end

local function OverrideCustomAcquireBehavior(controlPool)
    local customAcquireBehavior = controlPool.customAcquireBehavior
    function controlPool.customAcquireBehavior(control)
        customAcquireBehavior(control)
        ReduceIconGap(control, -3, 0)
    end
end

local function HookInBuffDebuffPools()
    for _, unitTag in ipairs({"player", "reticleover"}) do
        for _, poolName in ipairs({"buffPool", "debuffPool"}) do
            local controlPool = BUFF_DEBUFF.containerObjectsByUnitTag[unitTag][poolName]
            OverrideCustomAcquireBehavior(controlPool)
        end
    end
end

--
--
--

local defaultSavedVars = {
    durationIndicator = "Label",
}

EVENT_MANAGER:RegisterForEvent(NAMESPACE, EVENT_ADD_ON_LOADED, function(eventCode, addOnName)
    if (addOnName == NAMESPACE) then
        local savedVars = ZO_SavedVars:New(NAMESPACE.."_SavedVars", 1, nil, defaultSavedVars)
        do
            local mt = getmetatable(savedVars)
            local __newindex = mt.__newindex
            function mt.__newindex(self, key, value)
                CALLBACK_MANAGER:FireCallbacks(NAMESPACE.."_OnSavedVarChanged", key, value, self[key])
                __newindex(self, key, value)
            end
        end

        -- Drop duration label and enable cooldown effect.
        local buffDebuffIcon_OnInitialized = ZO_BuffDebuffIcon_OnInitialized
        function ZO_BuffDebuffIcon_OnInitialized(control)
            buffDebuffIcon_OnInitialized(control)

            control.duration:ClearAnchors()
            if (savedVars.durationIndicator == "Cooldown") then
                control.showCooldown = true
            else
                control.duration:SetAnchor(CENTER, control, nil, 0, -2)
            end
        end

        -- Move BuffDebuff tracker to below player attributes.
        DisplaceBuffDebuff()

        -- Displace player attributes up a bit.
        DisplacePlayerAttributeBars()

        -- Change gap between effect icons.
        HookInBuffDebuffPools()

        CALLBACK_MANAGER:FireCallbacks(NAMESPACE.."_OnAddOnLoaded", savedVars)
    end
end)
