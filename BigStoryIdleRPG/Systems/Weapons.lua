-- 무기 (Weapons): ownership, enhancement (무기 강화석), awakening (각성), promotion (승급),
-- equip effect and owned (보유) effect. Data: Data/Weapons.lua (client 1.18.0).
--
-- A weapon is identified by its tier index idx = 1..29 (노말 하급 .. 이터니티 하급, D.Weapons.tiers order).
-- Weapons are per job, but the stats are identical for all 16 jobs, so a hero simply owns tiers.
--
-- Saved data: hero.weapons = { owned = { [idx] = { level = 1, awaken = 0, count = 0 } }, equipped = idx|nil }
--   count = spare duplicates (the first copy is the weapon itself).
--
-- Public API (ns.Weapons)
--   W.Count()                          -> 29
--   W.Tier(idx)                        -> data row { id, grade, tier, label, equipM[], ownedM[], hit, aspdM, cost[] }
--   W.IndexOf(grade, tier)             -> idx or nil
--   W.Name(hero, idx)                  -> "에픽 상급 활" (display)
--   W.Get(hero, idx)                   -> owned record or nil
--   W.Add(hero, idx, n, silent)        -> isNew (adds n copies; first copy unlocks the weapon)
--   W.MaxLevel(rec)                    -> current level cap from awakening (100..200)
--   W.EnhanceCost(idx, level)          -> 무기 강화석 for level -> level+1 (nil at 200)
--   W.CostRange(idx, from, to)         -> total stones from level `from` to `to`
--   W.Enhance(hero, idx, times)        -> levelsGained, stonesSpent   (times nil = as many as affordable)
--   W.AwakenCost(rec)                  -> duplicates needed for the next awakening stage (nil at 5)
--   W.Awaken(hero, idx)                -> ok, err
--   W.CanPromote(hero, idx)            -> ok, err
--   W.Promote(hero, idx, times)        -> number promoted (5 spare copies of a 5-awakened weapon -> 1 next tier)
--   W.Equip(hero, idx)                 -> ok, err      fires Hero.Changed(hero, "weapon")
--   W.Equipped(hero)                   -> idx, rec
--   W.EquippedGrade(hero)              -> 1..8 or nil
--   W.EquipBest(hero)                  -> idx (highest equip ATK% at current level)
--   W.Effects(idx, level)              -> { equipM, ownedM, hit, aspdM }
--   W.OwnedTotalM(hero)                -> summed owned ATK% (raw 0.1 %)
-- Stat provider "weapons": equip ATK% -> Ratio Attack, hit -> HitChance, attack speed -> AttackSpeed (chained),
-- owned ATK% of every owned weapon (equipped one included) -> Ratio Attack.
-- Events: "WEAPON_CHANGED"(hero, idx, what)
--
-- Also defines ns.ApplyStat(acc, jobKey, stat, raw): shared by Weapons/Companions/Equipment to route item
-- StatTypes (MainStat, MainStatR, MaxHpR, MaxMpR ...) onto the accumulator.
local ADDON, ns = ...
local U = ns.U
local D = ns.Data
local H = ns.Hero

local W = {}
ns.Weapons = W

---------------------------------------------------------------------------
-- PROVISIONAL rules (not published anywhere; see report)
---------------------------------------------------------------------------
-- PROVISIONAL: duplicates consumed per awakening stage. Only an unverified web snippet ("5 copies per star")
-- exists; KR data only says "같은 무기와 합성 재료" are used.
W.AWAKEN_COPIES = { 5, 5, 5, 5, 5 }
W.MAX_AWAKEN = 5
-- Promotion (KR 2026-10-15 notice + global wiki): 5 copies of a fully awakened weapon -> 1 of the next tier.
W.PROMOTE_COPIES = 5
-- PROVISIONAL: weapon type noun per job (display only; the original has per-job weapon names not in the data).
W.WEAPON_NOUN = {
    hero = "양손검", paladin = "양손 둔기", darkKnight = "장창", archMageIL = "지팡이", archMageFP = "지팡이",
    bishop = "홀", bowMaster = "활", marksman = "석궁", nightLord = "표창", shadower = "단검", viper = "너클",
    captain = "총", nightWalker = "표창", windBreaker = "활", flameWizard = "지팡이", soulMaster = "한손검",
}

---------------------------------------------------------------------------
-- Shared stat routing helper
---------------------------------------------------------------------------
local mainKeyCache = {}
local function mainStatKey(jobKey)
    local k = jobKey and mainKeyCache[jobKey]
    if k then return k end
    local job = jobKey and ns.SkillBook and ns.SkillBook.JobByKey(jobKey)
    local m = job and job.mainStat or "STR"
    k = m:sub(1, 1) .. m:sub(2):lower()
    if jobKey then mainKeyCache[jobKey] = k end
    return k
end

-- stat = client StatType name as used in items/companions, raw = client raw value
function ns.ApplyStat(acc, jobKey, stat, raw)
    if not raw or raw == 0 then return end
    if stat == "MainStat" then
        acc:Add(mainStatKey(jobKey), raw)          -- scaled by main stat % like the client's mainFlat
    elseif stat == "MainStatR" then
        acc:Ratio(mainStatKey(jobKey), raw)
    elseif stat == "MaxHpR" then
        acc:Ratio("MaxHp", raw)
    elseif stat == "MaxMpR" then
        acc:Ratio("MaxMp", raw)
    elseif stat == "AttackR" then
        acc:Ratio("Attack", raw)
    elseif stat == "DefenceR" then
        acc:Ratio("Defence", raw)
    else
        acc:Add(stat, raw)                          -- Acc:Add routes chained / multiplicative stats itself
    end
end
ns.MainStatKey = mainStatKey

---------------------------------------------------------------------------
-- Data access
---------------------------------------------------------------------------
local T = D.Weapons.tiers
local indexByGT = {}
for i, t in ipairs(T) do indexByGT[t.grade * 10 + t.tier] = i end

function W.Count() return #T end
function W.Tier(idx) return T[idx] end
function W.IndexOf(grade, tier) return indexByGT[grade * 10 + tier] end

function W.Name(hero, idx)
    local t = T[idx]
    if not t then return "?" end
    local noun = hero and W.WEAPON_NOUN[hero.jobKey] or "무기"
    return t.label .. " " .. noun
end

local function state(hero)
    local s = hero.weapons
    if not s then
        s = { owned = {}, equipped = nil }
        hero.weapons = s
    end
    s.owned = s.owned or {}
    return s
end

function W.Get(hero, idx) return state(hero).owned[idx] end

function W.MaxLevel(rec)
    return D.Weapons.awakenMaxLevel[rec and rec.awaken or 0] or 100
end

function W.Effects(idx, level)
    local t = T[idx]
    level = U.clamp(level or 1, 1, D.Weapons.maxLevel)
    return { equipM = t.equipM[level], ownedM = t.ownedM[level], hit = t.hit, aspdM = t.aspdM }
end

local function changed(hero, idx, what)
    ns.Fire("WEAPON_CHANGED", hero, idx, what)
    H.Changed(hero, "weapon")
end

---------------------------------------------------------------------------
-- Ownership
---------------------------------------------------------------------------
function W.Add(hero, idx, n, silent)
    n = n or 1
    if not T[idx] or n <= 0 then return false end
    local s = state(hero)
    local rec = s.owned[idx]
    local isNew = false
    if rec then
        rec.count = rec.count + n
    else
        rec = { level = 1, awaken = 0, count = n - 1 }
        s.owned[idx] = rec
        isNew = true
        if not s.equipped then s.equipped = idx end
    end
    if not silent then changed(hero, idx, "add") end
    return isNew
end

---------------------------------------------------------------------------
-- Enhancement
---------------------------------------------------------------------------
function W.EnhanceCost(idx, level)
    local t = T[idx]
    if not t or level >= D.Weapons.maxLevel then return nil end
    return t.cost[level + 1]
end

function W.CostRange(idx, from, to)
    local t, sum = T[idx], 0
    for l = from + 1, math.min(to, D.Weapons.maxLevel) do sum = sum + t.cost[l] end
    return sum
end

-- times = number of level-ups to try (nil = until the cap or out of stones)
function W.Enhance(hero, idx, times)
    local rec = W.Get(hero, idx)
    if not rec then return 0, 0 end
    local cap = W.MaxLevel(rec)
    local gained, spent = 0, 0
    times = times or math.huge
    while gained < times and rec.level < cap do
        local c = W.EnhanceCost(idx, rec.level)
        if not c or not H.Spend(hero, "weaponStone", c, "weaponEnhance") then break end
        rec.level = rec.level + 1
        gained = gained + 1
        spent = spent + c
    end
    if gained > 0 then changed(hero, idx, "enhance") end
    return gained, spent
end

---------------------------------------------------------------------------
-- Awakening / promotion
---------------------------------------------------------------------------
function W.AwakenCost(rec)
    if not rec or rec.awaken >= W.MAX_AWAKEN then return nil end
    return W.AWAKEN_COPIES[rec.awaken + 1]
end

function W.Awaken(hero, idx)
    local rec = W.Get(hero, idx)
    if not rec then return false, "보유하지 않은 무기입니다." end
    local need = W.AwakenCost(rec)
    if not need then return false, "이미 최대 각성입니다." end
    if rec.count < need then return false, string.format("같은 무기가 %d개 필요합니다.", need) end
    rec.count = rec.count - need
    rec.awaken = rec.awaken + 1
    changed(hero, idx, "awaken")
    return true
end

function W.CanPromote(hero, idx)
    local rec = W.Get(hero, idx)
    if not rec then return false, "보유하지 않은 무기입니다." end
    if not T[idx + 1] then return false, "더 높은 등급의 무기가 없습니다." end
    if rec.awaken < W.MAX_AWAKEN then return false, "최대 각성한 무기만 승급할 수 있습니다." end
    if rec.count < W.PROMOTE_COPIES then
        return false, string.format("같은 무기가 %d개 필요합니다.", W.PROMOTE_COPIES)
    end
    return true
end

function W.Promote(hero, idx, times)
    times = times or math.huge
    local done = 0
    while done < times and W.CanPromote(hero, idx) do
        local rec = W.Get(hero, idx)
        rec.count = rec.count - W.PROMOTE_COPIES
        W.Add(hero, idx + 1, 1, true)
        done = done + 1
    end
    if done > 0 then changed(hero, idx + 1, "promote") end
    return done
end

---------------------------------------------------------------------------
-- Equip
---------------------------------------------------------------------------
function W.Equip(hero, idx)
    local s = state(hero)
    if not s.owned[idx] then return false, "보유하지 않은 무기입니다." end
    s.equipped = idx
    changed(hero, idx, "equip")
    return true
end

function W.Equipped(hero)
    local s = state(hero)
    local idx = s.equipped
    if idx and s.owned[idx] then return idx, s.owned[idx] end
    return nil
end

function W.EquippedGrade(hero)
    local idx = W.Equipped(hero)
    return idx and T[idx].grade or nil
end

function W.EquipBest(hero)
    local best, bestV
    for idx, rec in pairs(state(hero).owned) do
        local v = T[idx].equipM[rec.level]
        if not bestV or v > bestV or (v == bestV and idx > best) then best, bestV = idx, v end
    end
    if best and best ~= state(hero).equipped then W.Equip(hero, best) end
    return best
end

function W.OwnedTotalM(hero)
    local sum = 0
    for idx, rec in pairs(state(hero).owned) do sum = sum + T[idx].ownedM[rec.level] end
    return sum
end

---------------------------------------------------------------------------
-- Registration
---------------------------------------------------------------------------
H.RegisterSystem("weapons", {
    init = function(hero) state(hero) end,
})

H.RegisterStatProvider("weapons", function(hero, acc)
    if not hero.weapons then return end
    acc:Ratio("Attack", W.OwnedTotalM(hero))
    local idx, rec = W.Equipped(hero)
    if idx then
        local t = T[idx]
        acc:Ratio("Attack", t.equipM[rec.level])
        acc:Add("HitChance", t.hit)
        acc:Add("AttackSpeed", t.aspdM)
    end
end)
