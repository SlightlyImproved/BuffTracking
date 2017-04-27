-- Slightly Improved™ Buff Tracking 1.1.1 (Aug 27 2016)
-- Licensed under MIT © 2016 Arthur Corenzan

local NAMESPACE = "SlightlyImprovedBuffTracking"

local function d() end
local function df() end

local PINGPONG_ANIMATION_THRESHOLD = 3

local SORT_VALUE_FOR_DEBUFF = 999000
local SORT_VALUE_FOR_LONGTERM = 99000

--
--
--

local BuffTracker = ZO_Object:Subclass()

function BuffTracker:New(parent)
    local tracker = ZO_Object.New(self)

    tracker.control = CreateControlFromVirtual("Sibt_BuffTracker1", parent, "Sibt_BuffTracker")
    tracker.pool = ZO_ControlPool:New("Sibt_BuffTrackerEntry", tracker.control, "Entry")

    tracker.pool:SetCustomFactoryBehavior(function(control)
        ZO_AlphaAnimation:New(control)
        control.effectStack = {}
    end)

    tracker.pool:SetCustomResetBehavior(function(control)
        control:ClearAnchors()
        control.effectStack = {}
    end)

    return tracker
end

function BuffTracker:Reset()
    self.pool:ReleaseAllObjects()
end

function BuffTracker:AddEffect(effect)
    if (effect.buffSlot > 0 and effect.buffName ~= "") then
        local key = effect.iconFile..effect.effectType
        local control = self.pool:AcquireObject(key)

        table.insert(control.effectStack, effect)
        table.sort(control.effectStack, function(effect1, effect2)
            return (effect1.duration < effect2.duration)
        end)

        control.shortestEffect = control.effectStack[1]

        GetControl(control, "Icon"):SetTexture(control.shortestEffect.iconFile)

        if (control.shortestEffect.effectType == BUFF_EFFECT_TYPE_DEBUFF) then
            GetControl(control, "Highlight"):SetHidden(false)
            control.sortValue = SORT_VALUE_FOR_DEBUFF
        else
            if (control.shortestEffect.duration == 0) then
                control.sortValue = SORT_VALUE_FOR_LONGTERM
            else
                control.sortValue = control.shortestEffect.duration
            end
        end
    end
end

function BuffTracker:Update()
    local children = {}
    for _, control in pairs(self.pool:GetActiveObjects()) do
        table.insert(children, control)
    end

    table.sort(children, function(child1, child2)
        if (child1 and child2) then
            return child1.sortValue > child2.sortValue
        else
            return false
        end
    end)

    local previousControl
    for i = 1, #children do
        local control = children[i]
        if previousControl then
            control:SetAnchor(LEFT, previousControl, RIGHT, 2, 0)
        else
            control:SetAnchor(LEFT)
        end
        previousControl = control
    end
end

--
--
--

local function StartPingPongAnimation(control)
    if (not control.isAnimating) then
        df("STARTING animation for %s", control.shortestEffect.buffName)
        local animation = ZO_AlphaAnimation_GetAnimation(control)
        animation:PingPong(1, 0, 600)
        control.isAnimating = true
    end
end

local function StopAnimation(control)
    if control.isAnimating then
        df("STOPPING animation for %s", control.shortestEffect.buffName)
        local animation = ZO_AlphaAnimation_GetAnimation(control)
        animation:FadeIn(0, 300)
        control.isAnimating = false
    end
end

function Sibt_BuffTrackerEntry_OnMouseEnter(control)
    InitializeTooltip(GameTooltip, control, BOTTOM, 0, -5)
    for _, effect in ipairs(control.effectStack) do
        GameTooltip:AddLine(zo_strformat("<<1>>", effect.buffName))
    end
end

function Sibt_BuffTrackerEntry_OnMouseExit(control)
    ClearTooltip(GameTooltip)
end

function Sibt_BuffTrackerEntry_OnUpdate(control)
    if (control.shortestEffect.duration > 0) then
        if (control.shortestEffect.endTime >= GetFrameTimeSeconds()) then
            local timeToExpire = control.shortestEffect.endTime - GetFrameTimeSeconds()

            local text = ""
            if (timeToExpire > 3600) then
                text = string.format("%dh", zo_round(timeToExpire / 3600))
            elseif (timeToExpire > 60) then
                text = string.format("%dm", zo_round(timeToExpire / 60))
            else
                text = string.format("%ds", zo_round(timeToExpire))
            end
            GetControl(control, "Time"):SetText(text)

            if (timeToExpire < PINGPONG_ANIMATION_THRESHOLD) then
                StartPingPongAnimation(control)
            else
                StopAnimation(control)
            end
        end
    end
end

EVENT_MANAGER:RegisterForEvent(NAMESPACE, EVENT_ADD_ON_LOADED, function(eventCode, addOnName)
    if (addOnName == NAMESPACE) then
        local tracker = BuffTracker:New(ACTION_BAR_FRAGMENT.control)

        local function UpdateBuffTracker()
            tracker:Reset()

            for i = 1, GetNumBuffs("player") do
                local effect = {}

                effect.buffName,
                effect.startTime,
                effect.endTime,
                effect.buffSlot,
                effect.stackCount,
                effect.iconFile,
                effect.buffType,
                effect.effectType,
                effect.abilityType,
                effect.statusEffectType = GetUnitBuffInfo("player", i)
                effect.duration = effect.endTime - effect.startTime

                -- d(effect, "---")

                tracker:AddEffect(effect)
            end

            tracker:Update()
        end

        EVENT_MANAGER:RegisterForEvent(NAMESPACE, EVENT_EFFECT_CHANGED, UpdateBuffTracker)
        EVENT_MANAGER:RegisterForEvent(NAMESPACE, EVENT_PLAYER_ACTIVATED, UpdateBuffTracker)
        EVENT_MANAGER:RegisterForEvent(NAMESPACE, EVENT_EFFECTS_FULL_UPDATE, UpdateBuffTracker)

        do
            -- The ActionBar shown at the bottom of the screen and the one shown in the
            -- abilities panel is actually the same fragment that changes when
            -- the abilities panel is open, so I have to hook in there and
            -- manually hide the buffs bar.
            local show = SKILLS_ACTION_BAR_FRAGMENT.Show
            function SKILLS_ACTION_BAR_FRAGMENT:Show()
                show(self)
                tracker.control:SetHidden(true)
            end

            local onStateChange = SKILLS_ACTION_BAR_FRAGMENT.OnStateChange
            function SKILLS_ACTION_BAR_FRAGMENT:OnStateChange(oldState, newState)
                onStateChange(self, oldState, newState)
                if (newState == SCENE_FRAGMENT_HIDDEN) then
                    tracker.control:SetHidden(false)
                end
            end
        end

        -- Move player's attribute bars up a bit.
        local anchor = ZO_Anchor:New()
        anchor:SetFromControlAnchor(PLAYER_ATTRIBUTE_BARS.control)
        anchor:AddOffsets(nil, -50)
        anchor:Set(PLAYER_ATTRIBUTE_BARS.control)
    end
end)
