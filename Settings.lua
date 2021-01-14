-- Slightly Improved™ Buff Tracking
-- The MIT License © 2016 Arthur Corenzan

local NAMESPACE = "SlightlyImprovedBuffTracking"

local settings = {}

local panel =
{
    type = "panel",
    name = "Slightly Improved™ Buff Tracking",
    displayName = "Slightly Improved™ Buff Tracking",
    author = nil,
    version = nil,
}

local options =
{
    {
        type = "dropdown",
        name = "Duration Indicator",
        tooltip = "Whether to use duration label or a cooldown effect to indicate how much time is left until the effect expires.",
        choices = {"Label", "Cooldown"},
        getFunc = function() return settings.durationIndicator end,
        setFunc = function(value) settings.durationIndicator = value end,
        -- requiresReload = true,
    },
}

CALLBACK_MANAGER:RegisterCallback(NAMESPACE.."_OnAddOnLoaded", function(savedVars)
    settings = savedVars

    local LAM = LibAddonMenu2 or LibStub("LibAddonMenu-2.0")
    LAM:RegisterAddonPanel(NAMESPACE, panel)
    LAM:RegisterOptionControls(NAMESPACE, options)
end)
