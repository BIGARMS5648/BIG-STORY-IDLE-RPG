-- Hero save data, wallet, stat providers and the battle profile builder.
--
-- Contract for every growth system (Systems/*.lua):
--   ns.Hero.RegisterSystem(name, {
--       init   = function(hero) end,                  -- create hero.<name> sub-table with defaults
--       daily  = function(hero, dayIndex) end,        -- daily reset (00:00 KST)
--       weekly = function(hero, weekIndex) end,       -- weekly reset (Monday 00:00 KST)
--   })
--   ns.Hero.RegisterStatProvider(name, function(hero, acc) end)
--       acc:Add(stat, raw)    flat / additive stat (percent stats in 0.1% units)
--       acc:Ratio(stat, raw)  % multiplier layer (Attack/MaxHp/MaxMp/Defence/main stats: plus*(1000+r)/1000)
--       acc:Chain(stat, raw)  chained stats (AttackSpeed, PiercePower, Toughness, CoolTimeReduceRatio)
--       acc:Mult(stat, raw)   multiplicative stats (FinalDamage..FinalDamage5)
--     Stat names are client StatType names (see Engine/Creature.lua).
--   Wallet: ns.Hero.Add(hero, key, n, reason), ns.Hero.Spend(hero, key, n, reason) -> bool, ns.Hero.Count(hero, key)
--   Change notification: ns.Hero.Changed(hero, what) fires "HERO_CHANGED"(hero, what)
local ADDON, ns = ...
local U = ns.U
local D = ns.Data

local H = {}
ns.Hero = H

H.systems = {}
H.systemOrder = {}
H.statProviders = {}
H.providerOrder = {}

function H.RegisterSystem(name, def)
    if not H.systems[name] then table.insert(H.systemOrder, name) end
    H.systems[name] = def
end

function H.RegisterStatProvider(name, fn)
    if not H.statProviders[name] then table.insert(H.providerOrder, name) end
    H.statProviders[name] = fn
end

---------------------------------------------------------------------------
-- Creation / lookup
---------------------------------------------------------------------------
local function newId()
    return string.format("%d-%d", U.Now(), math.random(100000, 999999))
end

function H.New(jobKey, name)
    local hero = {
        id = newId(),
        name = name or (UnitName and UnitName("player")) or "모험가",
        jobKey = jobKey,
        level = 1,
        exp = 0,
        createdAt = U.Now(),
        lastOnline = U.Now(),
        wallet = {},
        stats = { kills = 0, playSeconds = 0 },
        resets = { day = U.DayIndex(), week = U.WeekIndex() },
    }
    H.InitSystems(hero)
    return hero
end

function H.InitSystems(hero)
    for _, name in ipairs(H.systemOrder) do
        local s = H.systems[name]
        if s.init then
            local ok, err = pcall(s.init, hero)
            if not ok then ns.Print("|cffff4040초기화 오류|r %s: %s", name, tostring(err)) end
        end
    end
end

function H.Active()
    local db = ns.db
    if not db then return nil end
    local id = db.active[ns.CharKey()]
    return id and db.heroes[id] or nil
end

function H.SetActive(hero)
    ns.db.heroes[hero.id] = hero
    ns.db.active[ns.CharKey()] = hero.id
    H.InitSystems(hero)      -- fills tables added by newer versions
    H.CheckResets(hero)
    ns.Fire("HERO_ACTIVATED", hero)
end

function H.List()
    local out = {}
    for id, hero in pairs(ns.db.heroes) do out[#out + 1] = hero end
    table.sort(out, function(a, b) return (a.createdAt or 0) < (b.createdAt or 0) end)
    return out
end

function H.Delete(hero)
    ns.db.heroes[hero.id] = nil
    for k, id in pairs(ns.db.active) do
        if id == hero.id then ns.db.active[k] = nil end
    end
end

function H.Job(hero)
    return ns.SkillBook.JobByKey(hero.jobKey)
end

function H.Changed(hero, what)
    hero.dirty = true
    ns.Fire("HERO_CHANGED", hero, what)
end

---------------------------------------------------------------------------
-- Wallet (currencies, tickets and materials share one table)
---------------------------------------------------------------------------
function H.Count(hero, key)
    return hero.wallet[key] or 0
end

function H.Add(hero, key, n, reason)
    if not n or n == 0 then return end
    hero.wallet[key] = (hero.wallet[key] or 0) + n
    ns.Fire("WALLET_CHANGED", hero, key, n, reason)
end

function H.Spend(hero, key, n, reason)
    n = n or 0
    if (hero.wallet[key] or 0) < n then return false end
    if n == 0 then return true end
    hero.wallet[key] = (hero.wallet[key] or 0) - n
    ns.Fire("WALLET_CHANGED", hero, key, -n, reason)
    return true
end

-- rewards = { {key, n}, ... } or { key = n }
function H.Grant(hero, rewards, reason)
    if not rewards then return end
    if rewards[1] then
        for _, r in ipairs(rewards) do H.Add(hero, r[1], r[2], reason) end
    else
        for k, n in pairs(rewards) do H.Add(hero, k, n, reason) end
    end
end

---------------------------------------------------------------------------
-- Levels and EXP
---------------------------------------------------------------------------
function H.ExpToNext(level)
    return D.ExpTable[level] or math.huge
end

function H.GainExp(hero, amount)
    if amount <= 0 then return end
    hero.exp = hero.exp + amount
    local leveled = false
    while hero.level < D.MaxLevel do
        local need = H.ExpToNext(hero.level)
        if hero.exp < need then break end
        hero.exp = hero.exp - need
        hero.level = hero.level + 1
        leveled = true
        ns.Fire("HERO_LEVEL_UP", hero, hero.level)
    end
    if hero.level >= D.MaxLevel then
        hero.exp = math.min(hero.exp, H.ExpToNext(hero.level - 1) or hero.exp)
    end
    if leveled then H.Changed(hero, "level") end
end

---------------------------------------------------------------------------
-- Daily / weekly resets
---------------------------------------------------------------------------
function H.CheckResets(hero)
    local day, week = U.DayIndex(), U.WeekIndex()
    hero.resets = hero.resets or { day = day, week = week }
    if hero.resets.day ~= day then
        hero.resets.day = day
        for _, name in ipairs(H.systemOrder) do
            local s = H.systems[name]
            if s.daily then pcall(s.daily, hero, day) end
        end
        ns.Fire("DAILY_RESET", hero)
    end
    if hero.resets.week ~= week then
        hero.resets.week = week
        for _, name in ipairs(H.systemOrder) do
            local s = H.systems[name]
            if s.weekly then pcall(s.weekly, hero, week) end
        end
        ns.Fire("WEEKLY_RESET", hero)
    end
end

---------------------------------------------------------------------------
-- Profile (stats + skill set) for the battle engine
---------------------------------------------------------------------------
local Acc = {}
Acc.__index = Acc

function H.NewAccumulator()
    return setmetatable({ adds = {}, ratios = {}, chains = {}, mults = {}, sources = {} }, Acc)
end

function Acc:Add(stat, v)
    if not v or v == 0 then return end
    local R = ns.StatRules
    if R.CHAINED[stat] then return self:Chain(stat, v) end
    if R.MULT[stat] then return self:Mult(stat, v) end
    self.adds[stat] = (self.adds[stat] or 0) + v
end
function Acc:Ratio(stat, v)
    if not v or v == 0 then return end
    self.ratios[stat] = (self.ratios[stat] or 0) + v
end
function Acc:Chain(stat, v)
    if not v or v == 0 then return end
    self.chains[stat] = self.chains[stat] or {}
    table.insert(self.chains[stat], v)
end
function Acc:Mult(stat, v)
    if not v or v == 0 then return end
    self.mults[stat] = self.mults[stat] or {}
    table.insert(self.mults[stat], v)
end
-- convenience: StatType + value as stored in item/option tables
-- kind "R" (ratio) or nil (flat)
function Acc:Apply(stat, v, kind)
    if kind == "R" then return self:Ratio(stat, v) end
    return self:Add(stat, v)
end

-- Base stats every hero gets (from Data.BaseStats when present).
local function baseStats(hero, acc, job)
    local B = D.BaseStats
    if B and B.Apply then
        B.Apply(hero, acc, job)
        return
    end
end

function H.BuildProfile(hero, opts)
    opts = opts or {}
    local acc = H.NewAccumulator()
    local job = H.Job(hero)
    baseStats(hero, acc, job)
    for _, name in ipairs(H.providerOrder) do
        local ok, err = pcall(H.statProviders[name], hero, acc)
        if not ok then ns.Debug("stat provider %s: %s", name, tostring(err)) end
    end
    local set, statAdds = ns.SkillBook.Build({
        jobKey = hero.jobKey,
        level = hero.level,
        skillBonus = acc.skillBonus or {
            allSkill = acc.adds.AllSkillLevel or 0,
            [1] = acc.adds.JobStep1SkillLevel or 0, [2] = acc.adds.JobStep2SkillLevel or 0,
            [3] = acc.adds.JobStep3SkillLevel or 0, [4] = acc.adds.JobStep4SkillLevel or 0,
        },
        masteries = hero.masteries or {},
        disabledActives = hero.disabledActives,
    })
    for k, v in pairs(statAdds) do acc:Add(k, v) end
    return {
        name = hero.name,
        jobKey = hero.jobKey,
        level = hero.level,
        stats = { adds = acc.adds, ratios = acc.ratios, chains = acc.chains, mults = acc.mults },
        skillSet = set,
        companions = acc.companions,
        masteries = hero.masteries,
    }
end

-- Creature definition for the battle engine from a profile
function H.CreatureDef(profile, side, x)
    return {
        name = profile.name,
        side = side or 1,
        isHero = true,
        level = profile.level,
        job = ns.SkillBook.JobByKey(profile.jobKey),
        stats = profile.stats,
        skillSet = profile.skillSet,
        x = x or 0,
        facing = (side == 2) and -1 or 1,
        radiusMm = 300,
    }
end

---------------------------------------------------------------------------
-- 전투력 / PvP 전투력: official formula (in-game guide 3.1 / 3.2). Stats are the
-- profile's own stats (skills do not count), masteries count only when learned.
---------------------------------------------------------------------------
local CP_MAIN_GROUPS = {
    { 12, 15, 19, 22, 26 }, { 32, 37, 42, 47, 52, 56 }, { 62, 66, 71, 76, 80, 84, 88, 92, 96 },
    { 102, 106, 111, 116, 120, 124, 128, 132, 136 },
}
local CP_SUB_GROUPS = {
    { 21, 24 }, { 39, 44, 49, 54 }, { 68, 73, 78, 82, 90, 94 }, { 98, 104, 108, 113, 118, 122, 126, 130, 134, 138 },
}

local function masteryFactors(profile)
    local job = ns.SkillBook.JobByKey(profile.jobKey)
    local learned = profile.masteries or {}
    local mainAt, subAt = {}, {}
    for _, m in ipairs(job and job.masteries or {}) do
        if learned[m.MasteryIndex] then
            if m.IsMainNode then mainAt[m.RequireCreatureLevel] = true else subAt[m.RequireCreatureLevel] = true end
        end
    end
    local f = 1
    for _, g in ipairs(CP_MAIN_GROUPS) do
        local n = 0
        for _, lv in ipairs(g) do if mainAt[lv] then n = n + 1 end end
        f = f * (1 + n * 80000 / 1e6)
    end
    for _, g in ipairs(CP_SUB_GROUPS) do
        local n = 0
        for _, lv in ipairs(g) do if subAt[lv] then n = n + 1 end end
        f = f * (1 + n * 25000 / 1e6)
    end
    return f
end

function H.ProfileCreature(profile)
    local b = ns.Battle.New({ seed = 7 })
    local def = H.CreatureDef(profile, 1, 0)
    def.skillSet = nil
    return ns.Creature.New(b, { name = def.name, side = 1, level = def.level, job = def.job, stats = def.stats })
end

local function combatPower(profile, pvp)
    local c = H.ProfileCreature(profile)
    local function s(k) return c:Stat(k) end
    local function g(x) return 1 + x / 1e6 end
    local cp = (s("Attack") * 4 + s("MaxHp") * 0.1 + s("Defence") * 0.2)
        * g(s("MaxHp") * 0.9 + s("Defence") * 20 + (s("MaxMp") - 500) * 10)
        * g(s("AttackPower") * 700)
        * g(s("AttackSpeed") * 700)
        * g(s("CriticalChance") * 350 + (s("CriticalPower") - 300) * 550 + s("CriticalResist") * (pvp and 1500 or 350))
        * g((s("MaxDamageRatio") - 1000) * 350 + (s("MinDamageRatio") - 650) * 350)
        * g(pvp and (s("HitChance") * 5000 + s("AvoidChance") * 5000) or (s("HitChance") * 2800 + s("AvoidChance") * 800))
    if not pvp then
        cp = cp * g(s("AttackPowerExcludeBoss") * 350 + s("AttackPowerToBoss") * 350)
    end
    cp = cp * g(s("AttackPowerInCc") * 350)
        * g(s("SkillPower") * 300 + s("BaseAttackPower") * 500)
        * g(s("PiercePower") * 1000)
        * g(s("JobStep1SkillLevel") * 500 + s("JobStep2SkillLevel") * 1000 + s("JobStep3SkillLevel") * 2500
            + s("JobStep4SkillLevel") * 4500 + s("AllSkillLevel") * 7000)
        * g(s("BuffDurationRatio") * 250)
        * g(s("SupporterDurationRatio") * 250)
        * g(s("CoolTimeReduce") * 25 + s("CoolTimeReduceRatio") * 250)
    if not pvp then
        cp = cp * g(s("BaseAttackMaxHitCount") * 30000)
    end
    cp = cp * g(s("Toughness") * (pvp and 600 or 200))
        * g(s("MainDamagePower") * 700)
        * g(s("FinalDamage") * 700)
        * g(s("AttackPower2") * 700)
        * g((s("DebuffResist") + s("DebuffResistIgnore")) * (pvp and 1500 or 300))
        * masteryFactors(profile)
    return math.floor(math.max(0, cp))
end

function H.CombatPower(profile) return combatPower(profile, false) end
function H.PvpCombatPower(profile) return combatPower(profile, true) end
