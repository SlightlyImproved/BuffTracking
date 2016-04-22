-- Slightly Improved™ Buff Tracking 1.0.0 (Apr 21 2016)
-- Licensed under CC BY-NC-SA 4.0

NAMESPACE = "SlightlyImprovedBuffTracking"

-- local function d() end
local FADING_ANIMATION_THRESHOLD = 3

function Sibt_Effect_OnMouseEnter(control)
    InitializeTooltip(GameTooltip, control, BOTTOM, 0, -5)
    for _, effect in ipairs(control.effects) do
        GameTooltip:AddLine(effect.buffName)
    end
end

function Sibt_Effect_OnMouseExit(control)
    ClearTooltip(GameTooltip)
end

function Sibt_Effect_OnUpdate(control)
    local effect = control.effects[1]
    if effect.isTimed then
        if (effect.endTime >= GetFrameTimeSeconds()) then
            local time = effect.endTime - GetFrameTimeSeconds()

            local text = ZO_FormatTime(time, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
            GetControl(control, "Time"):SetText(zo_strsplit(" ", text))

            local animation = ZO_AlphaAnimation_GetAnimation(control)
            if (time < FADING_ANIMATION_THRESHOLD) then
                if not animation:IsPlaying() then
                    animation:PingPong(1, 0, 600)
                end
            end
        end
    end
end

EVENT_MANAGER:RegisterForEvent(NAMESPACE, EVENT_ADD_ON_LOADED, function(eventCode, addOnName)
    if (addOnName == NAMESPACE) then
        local effectsBar = CreateControlFromVirtual("Sibt_EffectsBar1", ACTION_BAR_FRAGMENT.control, "Sibt_EffectsBar")
        local effectsPool = ZO_ControlPool:New("Sibt_Effect", effectsBar, "Effect")

        effectsPool:SetCustomFactoryBehavior(function(control)
            control.effects = {}
            ZO_AlphaAnimation:New(control)
        end)

        effectsPool:SetCustomResetBehavior(function(control)
            control:ClearAnchors()
            control.effects = {}
            local animation = ZO_AlphaAnimation_GetAnimation(control)
            animation:Stop()
        end)

        local function UpdateEffectsBar()
            effectsPool:ReleaseAllObjects()

            local previousEffectControl
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
                effect.isTimed = effect.endTime > effect.startTime
                effect.duration = effect.endTime - effect.startTime

                -- d(effect, "---")

                if (effect.buffSlot > 0 and effect.buffName ~= "") then
                    local key = effect.iconFile..effect.effectType
                    local effectControl = effectsPool:AcquireObject(key)
                    table.insert(effectControl.effects, effect)

                    table.sort(effectControl.effects, function(a, b)
                        return a.duration < b.duration
                    end)

                    GetControl(effectControl, "Icon"):SetTexture(effect.iconFile)

                    if (effect.effectType ~= BUFF_EFFECT_TYPE_BUFF) then
                        GetControl(effectControl, "Highlight"):SetHidden(false)
                    end
                end
            end

            local previousEffectControl
            for _, effectControl in pairs(effectsPool:GetActiveObjects()) do
                if previousEffectControl then
                    effectControl:SetAnchor(LEFT, previousEffectControl, RIGHT, 2, 0)
                else
                    effectControl:SetAnchor(LEFT)
                end
                previousEffectControl = effectControl
            end
        end
        EVENT_MANAGER:RegisterForEvent(NAMESPACE, EVENT_EFFECT_CHANGED, UpdateEffectsBar)
        EVENT_MANAGER:RegisterForEvent(NAMESPACE, EVENT_EFFECTS_FULL_UPDATE, UpdateEffectsBar)
        EVENT_MANAGER:RegisterForEvent(NAMESPACE, EVENT_PLAYER_ACTIVATED, UpdateEffectsBar)

        do
            -- The ActionBar shown at the bottom of the screen and the one shown in the
            -- abilities panel is actually the same fragment that changes when
            -- the abilities panel is open, so I have to hook in there and
            -- manually hide the buffs bar.
            local show = SKILLS_ACTION_BAR_FRAGMENT.Show
            function SKILLS_ACTION_BAR_FRAGMENT:Show()
                show(self)
                effectsBar:SetHidden(true)
            end

            local onStateChange = SKILLS_ACTION_BAR_FRAGMENT.OnStateChange
            function SKILLS_ACTION_BAR_FRAGMENT:OnStateChange(oldState, newState)
                onStateChange(self, oldState, newState)
                if (newState == SCENE_FRAGMENT_HIDDEN) then
                    effectsBar:SetHidden(false)
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
