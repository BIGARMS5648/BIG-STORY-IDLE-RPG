-- Battle creature: stat aggregation (client accumulation rules) and states.
local ADDON, ns = ...
local U = ns.U
local trunc = U.trunc

local Creature = {}
Creature.__index = Creature
ns.Creature = Creature

---------------------------------------------------------------------------
-- Accumulation rules (client 1.18.0, see research/spec/combat-stages.md)
---------------------------------------------------------------------------
-- chained: new = cur + (R - cur) * add / R      (raw units, 1000 = 100%)
local CHAINED = {
    AttackSpeed = { R = 1500, cap = 1500 },
    PiercePower = { R = 1000, cap = 999 },
    Toughness = { R = 1000, cap = 950 },
    CoolTimeReduceRatio = { R = 1000, cap = 999 },
}
-- multiplicative: total = prod(1 + v/1000) - 1
local MULT = { FinalDamage = true, FinalDamage2 = true, FinalDamage3 = true, FinalDamage4 = true, FinalDamage5 = true }
-- "plus * (1000 + ratio) / 1000" stats (base included in plus)
local PLUS_RATIO = { Attack = true, MaxHp = true, MaxMp = true, Defence = true }
local MAIN_STATS = { Str = true, Dex = true, Int = true, Luk = true }
ns.StatRules = { CHAINED = CHAINED, MULT = MULT, PLUS_RATIO = PLUS_RATIO }

-- default max stacks for states the data does not list explicitly
local DEFAULT_MAX_STACKS = { ComboAttack = 5, Ice = 5, ArchMagePoison = 5, Burn = 5 }

local nextId = 0

-- def = {
--   name, side, isHero, isBoss, level, job (Data.Jobs entry or nil), x, facing,
--   stats = { adds = {Stat=raw}, ratios = {Stat=raw}, chains = {Stat={raw,...}}, mults = {Stat={raw,...}} },
--   radiusMm, runSpeed, model = {...}
-- }
function Creature.New(battle, def)
    nextId = nextId + 1
    local c = setmetatable({}, Creature)
    c.id = nextId
    c.battle = battle
    c.def = def
    c.name = def.name or "?"
    c.side = def.side or 2
    c.isHero = def.isHero or false
    c.isBoss = def.isBoss or false
    c.isSupporter = def.isSupporter or false
    c.isServant = def.isServant or false
    c.owner = def.owner
    c.level = def.level or 1
    c.job = def.job
    c.x = def.x or 0
    c.y = 0
    c.facing = def.facing or (c.side == 1 and 1 or -1)
    c.radius = def.radiusMm or 300
    c.alive = true
    c.mods = {}        -- dynamic modifiers {stat, kind, value|fn, state}
    c.states = {}      -- [name] = {stacks = {...}, max = n}
    c.stateMaxBonus = {}
    c.firedStateMaxBonus = {}
    c.statCache = nil
    c.cooldowns = {}
    c.skills = {}
    c.passiveSkills = {}
    c.triggers = {}
    c.projectiles = {}
    c.shield = 0
    c.dmgDealt = 0
    c.statsDef = def.stats or { adds = {}, ratios = {}, chains = {}, mults = {} }
    c.hp = c:Stat("MaxHp")
    c.mp = c:Stat("MaxMp")
    return c
end

function Creature:Dirty() self.statCache = nil end

-- kind: "add" | "ratio" | "chain" | "mult"; value may be a function(creature)->raw
function Creature:AddMod(stat, kind, value, tag)
    local m = { stat = stat, kind = kind, value = value, tag = tag }
    self.mods[#self.mods + 1] = m
    self:Dirty()
    return m
end

function Creature:RemoveMod(m)
    for i = #self.mods, 1, -1 do
        if self.mods[i] == m then table.remove(self.mods, i) end
    end
    self:Dirty()
end

function Creature:RemoveModsByTag(tag)
    for i = #self.mods, 1, -1 do
        if self.mods[i].tag == tag then table.remove(self.mods, i) end
    end
    self:Dirty()
end

local function modValue(c, m)
    if m.whileState and c:StateCount(m.whileState) <= 0 then return 0 end
    if m.state and c:StateCount(m.state) <= 0 then return 0 end
    local v = m.value
    if type(v) == "function" then
        local ok, r = pcall(v, c)
        v = ok and r or 0
    end
    v = tonumber(v) or 0
    if m.state then
        v = v * c:StateCount(m.state)
    end
    return v
end

local function computeStats(c)
    local sd = c.statsDef
    local adds, ratios, chains, mults = {}, {}, {}, {}
    for k, v in pairs(sd.adds or {}) do adds[k] = v end
    for k, v in pairs(sd.ratios or {}) do ratios[k] = v end
    for k, list in pairs(sd.chains or {}) do
        local l = {}
        for i = 1, #list do l[i] = list[i] end
        chains[k] = l
    end
    for k, list in pairs(sd.mults or {}) do
        local l = {}
        for i = 1, #list do l[i] = list[i] end
        mults[k] = l
    end
    for i = 1, #c.mods do
        local m = c.mods[i]
        if not m.disabled then
            local v = modValue(c, m)
            if v ~= 0 then
                local s = m.stat
                if m.kind == "ratio" then
                    ratios[s] = (ratios[s] or 0) + v
                elseif CHAINED[s] then
                    chains[s] = chains[s] or {}
                    table.insert(chains[s], v)
                elseif MULT[s] then
                    mults[s] = mults[s] or {}
                    table.insert(mults[s], v)
                else
                    adds[s] = (adds[s] or 0) + v
                end
            end
        end
    end

    local out = {}
    -- main / sub stats
    for s in pairs(MAIN_STATS) do
        local plus = adds[s] or 0
        local r = ratios[s] or 0
        out[s] = math.max(0, trunc(plus * (1000 + r) / 1000))
    end
    -- additive stats (incl. ratio scaling for non base stats)
    for s, v in pairs(adds) do
        if not MAIN_STATS[s] and not PLUS_RATIO[s] then
            local r = ratios[s]
            if r then v = v * (1000 + r) / 1000 end
            out[s] = v
        end
    end
    for s, r in pairs(ratios) do
        if out[s] == nil and not MAIN_STATS[s] and not PLUS_RATIO[s] then out[s] = 0 end
    end
    -- chained
    for s, rule in pairs(CHAINED) do
        local cur = 0
        local list = chains[s]
        if list then
            for i = 1, #list do
                local a = list[i]
                if a > 0 then
                    cur = cur + (rule.R - cur) * a / rule.R
                else
                    cur = cur + a
                end
            end
        end
        cur = cur + (adds[s] or 0) -- plain adds (rare) stack additively
        if cur > rule.cap then cur = rule.cap end
        out[s] = trunc(cur)
    end
    -- multiplicative
    for s in pairs(MULT) do
        local total = 1
        local list = mults[s]
        if list then
            for i = 1, #list do total = total * (1 + list[i] / 1000) end
        end
        total = total * (1 + (adds[s] or 0) / 1000)
        out[s] = math.max(s == "FinalDamage" and -1000 or 0, trunc((total - 1) * 1000))
    end
    -- job main/sub stat conversion (attack + stat-proportional damage)
    local job = c.job
    local mainV, subV = 0, 0
    if job then
        local function key(t) return t:sub(1, 1) .. t:sub(2):lower() end
        mainV = (out[key(job.mainStat)] or 0) + (adds.MainStat or 0)
        subV = out[key(job.subStat)] or 0
        out.MainStatFinal = mainV
        out.SubStatFinal = subV
    end
    -- plus * ratio stats
    for s in pairs(PLUS_RATIO) do
        local plus = adds[s] or 0
        if s == "Attack" then plus = plus + trunc(mainV) + trunc(subV / 4) end
        out[s] = math.max(0, trunc(plus * (1000 + (ratios[s] or 0)) / 1000))
    end
    -- MainDamagePower (stat-proportional damage), raw 0.1% units
    out.MainDamagePower = (out.MainDamagePower or 0) + trunc(mainV / 10) + trunc(subV / 40)
    -- floors
    for _, s in ipairs({ "CriticalChance", "CriticalPower", "MinDamageRatio", "MaxDamageRatio", "HitChance", "AvoidChance" }) do
        if (out[s] or 0) < 0 then out[s] = 0 end
    end
    return out
end

function Creature:Stat(name)
    local cache = self.statCache
    if not cache then
        if self.computing then
            -- a dynamic modifier asked for a stat while stats are being built:
            -- answer from the previous snapshot to avoid recursion
            local prev = self.prevStatCache
            return prev and prev[name] or 0
        end
        self.computing = true
        local ok, res = pcall(computeStats, self)
        self.computing = false
        cache = ok and res or (self.prevStatCache or {})
        self.statCache = cache
        self.prevStatCache = cache
    end
    return cache[name] or 0
end

---------------------------------------------------------------------------
-- States
---------------------------------------------------------------------------
function Creature:StateMax(name)
    local base = ns.Data.StateMaxStacks and ns.Data.StateMaxStacks[name]
    if base == nil then base = ns.Data.StateMaxStacks and ns.Data.StateMaxStacks[tonumber(name) or -1] end
    if base == nil then base = DEFAULT_MAX_STACKS[name] or 1 end
    return base + (self.stateMaxBonus[name] or 0)
end

function Creature:StateCount(name)
    local st = self.states[name]
    if not st then return 0 end
    return #st.stacks
end

function Creature:StateCountBy(name, firedBy)
    local st = self.states[name]
    if not st then return 0 end
    local n = 0
    for i = 1, #st.stacks do
        if st.stacks[i].firedBy == firedBy then n = n + 1 end
    end
    return n
end

-- attrs: {buff=bool, debuff=bool, cc=bool}
function Creature:AttrStateCount(kind)
    local n = 0
    for _, st in pairs(self.states) do
        if #st.stacks > 0 and st.attr and st.attr[kind] then n = n + 1 end
    end
    return n
end

-- Adds one stack (or refreshes). Returns the state record.
function Creature:AddState(name, durationMs, firedBy, attr, maxBonus)
    name = tostring(name)
    local now = self.battle.time
    local st = self.states[name]
    if not st then
        st = { stacks = {}, attr = attr }
        self.states[name] = st
    end
    local max = self:StateMax(name) + (maxBonus or 0)
    local expire = (durationMs and durationMs < 99999999) and (now + durationMs) or math.huge
    if #st.stacks >= max then
        -- refresh: drop the oldest
        table.remove(st.stacks, 1)
    end
    st.stacks[#st.stacks + 1] = { expire = expire, firedBy = firedBy, at = now }
    -- refresh all stacks' duration like the client's shared stack timer
    for i = 1, #st.stacks do st.stacks[i].expire = expire end
    self:Dirty()
    self.battle:OnStateChanged(self, name, true)
    return st
end

function Creature:ClearState(name)
    name = tostring(name)
    if self.states[name] and #self.states[name].stacks > 0 then
        self.states[name].stacks = {}
        self:Dirty()
        self.battle:OnStateChanged(self, name, false)
    end
end

function Creature:UpdateStates(now)
    for name, st in pairs(self.states) do
        local before = #st.stacks
        if before > 0 then
            for i = before, 1, -1 do
                if st.stacks[i].expire <= now then table.remove(st.stacks, i) end
            end
            if #st.stacks ~= before then
                self:Dirty()
                if #st.stacks == 0 then self.battle:OnStateChanged(self, name, false) end
            end
        end
    end
end

function Creature:IsCC()
    return self:StateCount("Stun") > 0 or self:StateCount("Frozen") > 0 or self:StateCount("Stone") > 0
end

function Creature:HpRatioM()
    local max = self:Stat("MaxHp")
    if max <= 0 then return 0 end
    return trunc(self.hp * 1000 / max)
end

function Creature:MpRatioM()
    local max = self:Stat("MaxMp")
    if max <= 0 then return 1000 end
    return trunc(self.mp * 1000 / max)
end
