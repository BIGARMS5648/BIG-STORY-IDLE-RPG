-- 동료 (Companions): 69 companions (노말 5, 레어/에픽/유니크/레전드리 16 each), copies -> level up,
-- promotion (승급), 1 main + 6 sub slots, equip and owned (보유) effects, battle supporters.
-- Data: Data/Companions.lua (client 1.18.0 + KR SupporterTable extract).
--
-- A companion is identified by its client SupporterIndex `sid` (1..5, 101..116, 201..216, 301..316, 401..416).
-- Saved data: hero.companions = { owned = { [sid] = { level = 1, count = 0 } }, main = sid|nil, subs = { [1..6] = sid } }
--   count = spare copies (조각); the first copy unlocks the companion ("획득 1개 별도").
--
-- Public API (ns.Companions)
--   C.Def(sid)                         -> data row { sid, name, job (Data.Jobs key), grade 1..5, maxLevel, equip, owned, spawnMs }
--   C.All()                            -> list of sids (sorted)
--   C.ByGrade(grade)                   -> list of sids of that grade
--   C.GradeInfo(grade)                 -> D.CompanionGrades[grade]
--   C.Get(hero, sid)                   -> owned record or nil
--   C.Add(hero, sid, n, silent)        -> isNew
--   C.LevelUpCost(sid, level)          -> copies for level -> level+1 (nil at max)
--   C.LevelUp(hero, sid, times)        -> levels gained          (times nil = as many as possible)
--   C.LevelUpAll(hero)                 -> total levels gained
--   C.PromoteCost(grade)               -> copies of `grade` needed for one promotion (nil for 레전드리)
--   C.PromotableCopies(hero, grade)    -> spare copies available for promotion
--   C.Promote(hero, grade)             -> new sid | nil, err
--   C.SubSlotsUnlocked(hero)           -> 0..6 (by companion summon level)
--   C.SetMain(hero, sid|nil)           -> ok, err
--   C.SetSub(hero, slot, sid|nil)      -> ok, err     (a companion occupies at most one slot; it moves)
--   C.Equipped(hero)                   -> mainSid, { [slot] = sid }
--   C.Value(sid, kind, stat, level)    -> raw value (kind "equip" | "owned")
--   C.Effects(sid, level)              -> { equip = { {stat, raw} }, owned = { {stat, raw} } }
--   C.AttackInheritM(sid, level, heroLevel) -> main companion attack inheritance in permille of hero Attack
--   C.AutoEquip(hero)                  -> main = best grade/level, subs = greedy best combat power
--   C.BattleSupporters(hero, maxCount) -> list of companions that fight (default: the main companion only):
--        { sid, name, jobKey, jobStep (0..4), grade, level, isMain, attackInheritM, spawnMs, skills }
--        maxCount > 1 adds sub companions in slot order (KR 길드 현상수배: main + 2 subs).
--        Spawn timing: Data.Combat.supporter (first at 60 s x ratio, every 90 s, 30 s each).
-- Stat provider "companions": owned effects of every owned companion + equip effects of main and subs.
-- Events: "COMPANION_CHANGED"(hero, sid, what)
local ADDON, ns = ...
local U = ns.U
local D = ns.Data
local H = ns.Hero

local C = {}
ns.Companions = C

local CURVES = D.CompanionCurves
local defs, bySid, byGrade, sids = D.Companions, {}, { {}, {}, {}, {}, {} }, {}
for _, c in ipairs(defs) do
    bySid[c.sid] = c
    table.insert(byGrade[c.grade], c.sid)
    sids[#sids + 1] = c.sid
end
table.sort(sids)
local SUB_SLOTS = #D.CompanionSlots.subUnlockSummonLevel

function C.Def(sid) return bySid[sid] end
function C.All() return sids end
function C.ByGrade(grade) return byGrade[grade] or {} end
function C.GradeInfo(grade) return D.CompanionGrades[grade] end

local function state(hero)
    local s = hero.companions
    if not s then
        s = { owned = {}, main = nil, subs = {} }
        hero.companions = s
    end
    s.owned = s.owned or {}
    s.subs = s.subs or {}
    return s
end

local function changed(hero, sid, what)
    ns.Fire("COMPANION_CHANGED", hero, sid, what)
    H.Changed(hero, "companion")
end

function C.Get(hero, sid) return state(hero).owned[sid] end

function C.Add(hero, sid, n, silent)
    n = n or 1
    if not bySid[sid] or n <= 0 then return false end
    local s = state(hero)
    local rec = s.owned[sid]
    local isNew = false
    if rec then
        rec.count = rec.count + n
    else
        s.owned[sid] = { level = 1, count = n - 1 }
        isNew = true
        if not s.main then s.main = sid end
    end
    if not silent then changed(hero, sid, "add") end
    return isNew
end

---------------------------------------------------------------------------
-- Level up / promotion
---------------------------------------------------------------------------
function C.LevelUpCost(sid, level)
    local c = bySid[sid]
    if not c or level >= c.maxLevel then return nil end
    local g = D.CompanionGrades[c.grade]
    return math.min(g.beginCost + math.floor((level - 1) / g.costGap) * g.costAdd, g.maxCost)
end

function C.LevelUp(hero, sid, times)
    local rec = C.Get(hero, sid)
    if not rec then return 0 end
    times = times or math.huge
    local gained = 0
    while gained < times do
        local need = C.LevelUpCost(sid, rec.level)
        if not need or rec.count < need then break end
        rec.count = rec.count - need
        rec.level = rec.level + 1
        gained = gained + 1
    end
    if gained > 0 then changed(hero, sid, "level") end
    return gained
end

function C.LevelUpAll(hero)
    local total = 0
    for _, sid in ipairs(sids) do
        if C.Get(hero, sid) then total = total + C.LevelUp(hero, sid) end
    end
    return total
end

function C.PromoteCost(grade)
    local g = D.CompanionGrades[grade]
    return g and g.promoteCount or nil
end

-- PROVISIONAL: promotion uses spare copies only (the unlocked companion itself is never consumed).
function C.PromotableCopies(hero, grade)
    local s, n = state(hero), 0
    for _, sid in ipairs(byGrade[grade] or {}) do
        local rec = s.owned[sid]
        if rec then n = n + rec.count end
    end
    return n
end

function C.Promote(hero, grade)
    local need = C.PromoteCost(grade)
    if not need then return nil, "승급할 수 없는 등급입니다." end
    if C.PromotableCopies(hero, grade) < need then
        return nil, string.format("같은 등급 동료가 %d개 필요합니다.", need)
    end
    -- KR 2025-12-18 / 2026-09-22: promotion consumes the owned companions of the grade evenly
    local s = state(hero)
    for _ = 1, need do
        local best, bestN
        for _, sid in ipairs(byGrade[grade]) do
            local rec = s.owned[sid]
            if rec and rec.count > 0 and (not bestN or rec.count > bestN) then best, bestN = sid, rec.count end
        end
        s.owned[best].count = s.owned[best].count - 1
    end
    -- PROVISIONAL: the promoted companion is drawn uniformly from the next grade (rule not published)
    local pool = byGrade[grade + 1]
    local sid = pool[ns.U.rng:Int(1, #pool)]
    C.Add(hero, sid, 1, true)
    changed(hero, sid, "promote")
    return sid
end

---------------------------------------------------------------------------
-- Slots
---------------------------------------------------------------------------
function C.SubSlotsUnlocked(hero)
    local lv = hero.summon and hero.summon.companion and hero.summon.companion.level or 1
    local n = 0
    for i, need in ipairs(D.CompanionSlots.subUnlockSummonLevel) do
        if lv >= need then n = i end
    end
    return n
end

local function removeEverywhere(s, sid)
    if s.main == sid then s.main = nil end
    for i = 1, SUB_SLOTS do
        if s.subs[i] == sid then s.subs[i] = nil end
    end
end

function C.SetMain(hero, sid)
    local s = state(hero)
    if sid and not s.owned[sid] then return false, "보유하지 않은 동료입니다." end
    if sid then removeEverywhere(s, sid) end
    s.main = sid
    changed(hero, sid, "equip")
    return true
end

function C.SetSub(hero, slot, sid)
    local s = state(hero)
    if slot < 1 or slot > C.SubSlotsUnlocked(hero) then return false, "잠긴 슬롯입니다." end
    if sid and not s.owned[sid] then return false, "보유하지 않은 동료입니다." end
    if sid then removeEverywhere(s, sid) end
    s.subs[slot] = sid
    changed(hero, sid, "equip")
    return true
end

function C.Equipped(hero)
    local s = state(hero)
    local subs = {}
    local open = C.SubSlotsUnlocked(hero)
    for i = 1, open do
        local sid = s.subs[i]
        if sid and s.owned[sid] then subs[i] = sid end
    end
    return (s.main and s.owned[s.main]) and s.main or nil, subs
end

---------------------------------------------------------------------------
-- Effects
---------------------------------------------------------------------------
function C.Value(sid, kind, stat, level)
    local c = bySid[sid]
    for _, e in ipairs(c[kind]) do
        if e[1] == stat then
            local curve = CURVES[e[2]]
            return curve[U.clamp(level, 1, #curve)]
        end
    end
    return 0
end

function C.Effects(sid, level)
    local c = bySid[sid]
    local out = { equip = {}, owned = {} }
    for _, kind in ipairs({ "equip", "owned" }) do
        for _, e in ipairs(c[kind]) do
            local curve = CURVES[e[2]]
            table.insert(out[kind], { e[1], curve[U.clamp(level, 1, #curve)] })
        end
    end
    return out
end

local function applyKind(acc, jobKey, sid, level, kind)
    for _, e in ipairs(bySid[sid][kind]) do
        local curve = CURVES[e[2]]
        ns.ApplyStat(acc, jobKey, e[1], curve[U.clamp(level, 1, #curve)])
    end
end

function C.AttackInheritM(sid, level, heroLevel)
    local c = bySid[sid]
    local link = D.CompanionLink[c.grade]
    local m = link.m[U.clamp(level, 1, #link.m)]
    if link.compareLevel and heroLevel and heroLevel < link.compareLevel then
        m = math.floor(m * heroLevel / link.compareLevel)
    end
    return m
end

---------------------------------------------------------------------------
-- Auto equip
---------------------------------------------------------------------------
function C.AutoEquip(hero)
    local s = state(hero)
    local list = {}
    for sid, rec in pairs(s.owned) do list[#list + 1] = sid end
    if #list == 0 then return end
    -- main: highest grade, then level (the main companion fights; subs only give equip effects)
    table.sort(list, function(a, b)
        local ga, gb = bySid[a].grade, bySid[b].grade
        if ga ~= gb then return ga > gb end
        local la, lb = s.owned[a].level, s.owned[b].level
        if la ~= lb then return la > lb end
        return a > b
    end)
    s.main = list[1]
    s.subs = {}
    local open = C.SubSlotsUnlocked(hero)
    local used = { [s.main] = true }
    for slot = 1, open do
        local best, bestP
        for _, sid in ipairs(list) do
            if not used[sid] then
                s.subs[slot] = sid
                local p = H.CombatPower(H.BuildProfile(hero))
                if not bestP or p > bestP then best, bestP = sid, p end
            end
        end
        s.subs[slot] = best
        if not best then break end
        used[best] = true
    end
    changed(hero, s.main, "equip")
end

---------------------------------------------------------------------------
-- Battle supporters
---------------------------------------------------------------------------
local function supporter(hero, sid, isMain)
    local c = bySid[sid]
    local rec = C.Get(hero, sid)
    return {
        sid = sid,
        name = c.name,
        jobKey = c.job,
        jobStep = c.grade - 1,
        grade = c.grade,
        level = rec.level,
        isMain = isMain,
        attackInheritM = C.AttackInheritM(sid, rec.level, hero.level),
        spawnMs = c.spawnMs or (D.Combat and D.Combat.supporter and D.Combat.supporter.durationMs) or 30000,
        skills = D.CompanionSkillText[sid],
    }
end

function C.BattleSupporters(hero, maxCount)
    maxCount = maxCount or 1
    local out = {}
    local main, subs = C.Equipped(hero)
    if main then out[#out + 1] = supporter(hero, main, true) end
    for i = 1, SUB_SLOTS do
        if #out >= maxCount then break end
        if subs[i] then out[#out + 1] = supporter(hero, subs[i], false) end
    end
    return out
end

---------------------------------------------------------------------------
-- Registration
---------------------------------------------------------------------------
H.RegisterSystem("companions", {
    init = function(hero) state(hero) end,
})

H.RegisterStatProvider("companions", function(hero, acc)
    local s = hero.companions
    if not s then return end
    local job = hero.jobKey
    for sid, rec in pairs(s.owned) do
        if bySid[sid] then applyKind(acc, job, sid, rec.level, "owned") end
    end
    local main, subs = C.Equipped(hero)
    if main then applyKind(acc, job, main, s.owned[main].level, "equip") end
    for _, sid in pairs(subs) do applyKind(acc, job, sid, s.owned[sid].level, "equip") end
    -- Hero.BuildProfile copies acc.companions into profile.companions for the battle
    acc.companions = C.BattleSupporters(hero)
end)
