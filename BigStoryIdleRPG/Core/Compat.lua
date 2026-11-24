-- API compatibility layer for the WoW: Forever client (interface 16001).
-- Wraps APIs that moved between global functions and C_* namespaces so the
-- addon keeps working if the client exposes either form.
local ADDON, ns = ...
local C = {}
ns.Compat = C

-- Spell name / icon ---------------------------------------------------------
function C.GetSpellNameIcon(spellId)
    if not spellId then return nil end
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellId)
        if info then return info.name, info.iconID end
    end
    if GetSpellInfo then
        local name, _, icon = GetSpellInfo(spellId)
        if name then return name, icon end
    end
    if C_Spell and C_Spell.GetSpellTexture then
        local icon = C_Spell.GetSpellTexture(spellId)
        if icon then return nil, icon end
    end
    return nil
end

-- Addon messages --------------------------------------------------------------
function C.RegisterPrefix(prefix)
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        return C_ChatInfo.RegisterAddonMessagePrefix(prefix)
    elseif RegisterAddonMessagePrefix then
        return RegisterAddonMessagePrefix(prefix)
    end
end

function C.SendAddonMessage(prefix, text, chatType, target)
    if C_ChatInfo and C_ChatInfo.SendAddonMessage then
        return C_ChatInfo.SendAddonMessage(prefix, text, chatType, target)
    elseif SendAddonMessage then
        return SendAddonMessage(prefix, text, chatType, target)
    end
end

-- Timers ----------------------------------------------------------------------
function C.After(sec, fn)
    if C_Timer and C_Timer.After then return C_Timer.After(sec, fn) end
    -- fallback: OnUpdate based
    local f = CreateFrame("Frame")
    local t = 0
    f:SetScript("OnUpdate", function(self, elapsed)
        t = t + elapsed
        if t >= sec then
            self:SetScript("OnUpdate", nil)
            fn()
        end
    end)
end

function C.NewTicker(sec, fn)
    if C_Timer and C_Timer.NewTicker then return C_Timer.NewTicker(sec, fn) end
    local f = CreateFrame("Frame")
    local t = 0
    f:SetScript("OnUpdate", function(_, elapsed)
        t = t + elapsed
        while t >= sec do
            t = t - sec
            fn()
        end
    end)
    return { Cancel = function() f:SetScript("OnUpdate", nil) end }
end

-- Guild / group helpers -----------------------------------------------------
function C.InGuild()
    return IsInGuild and IsInGuild()
end

function C.GroupChannel()
    if IsInRaid and IsInRaid() then return "RAID" end
    if IsInGroup and IsInGroup() then return "PARTY" end
    if GetNumRaidMembers and GetNumRaidMembers() > 0 then return "RAID" end
    if GetNumPartyMembers and GetNumPartyMembers() > 0 then return "PARTY" end
    return nil
end

function C.ClassColor(classToken)
    local c = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS or {})[classToken or ""]
    if c then return c.r, c.g, c.b end
    return 1, 1, 1
end

-- Backdrop templates moved into BackdropTemplateMixin on modern clients.
C.BACKDROP_TEMPLATE = BackdropTemplateMixin and "BackdropTemplate" or nil
