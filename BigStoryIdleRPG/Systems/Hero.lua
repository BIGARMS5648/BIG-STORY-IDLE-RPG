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
    if (hero.wallet[key] or 0) < n then return false end
    hero.wallet[key] = hero.wallet[key] - n
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
-- Combat power (전투력): expected one-hit damage of the 4-scenario average
-- against the client's reference target (defense 10000, calcv4 default).
---------------------------------------------------------------------------
function H.CombatPower(profile)
    local b = ns.Battle.New({ seed = 7 })
    local c = b:AddCreature(H.CreatureDef(profile, 1, 0))
    local function pf(raw) return math.max(0, 1 + raw / 1000) end
    local s = function(k) return c:Stat(k) end
    local atk = s("Attack")
    local critAvg = 1 + U.clamp(s("CriticalChance") / 1000, 0, 1) * math.max(0, s("CriticalPower") / 1000)
    local rangeAvg = (math.min(s("MinDamageRatio"), s("MaxDamageRatio")) + s("MaxDamageRatio")) / 2000
    local eff = U.trunc(10000 * (1000 - math.min(999, s("PiercePower"))) / 1000)
    local defMult = 5000 / (eff + 6000)
    local common = atk * pf(s("AttackPower")) * pf(s("MainDamagePower")) * critAvg * rangeAvg * defMult
        * pf(s("FinalDamage")) * pf(s("FinalDamage2")) * pf(s("FinalDamage3"))
    local target = (pf(s("AttackPowerToBoss")) + pf(s("AttackPowerExcludeBoss"))) / 2
    local route = (pf(s("BaseAttackPower")) + pf(s("SkillPower"))) / 2
    local speed = 1 + math.min(1500, s("AttackSpeed")) / 1000
    return math.floor(common * target * route * speed)
end
