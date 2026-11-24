-- Battle simulation: skill operation VM, damage formula, timeline loop.
-- Mirrors the client's skill table semantics (research/spec/jobs-skills.md):
-- skill levels and curves, masteries (ModSkill/ModSkillR/SetSkill), passives,
-- triggers, states, projectiles, DoT/HoT and the client damage order
-- (공격·방어 -> 치명타 -> 최소·최대 배율 -> 상태이상 -> 최종 데미지).
local ADDON, ns = ...
local U = ns.U
local E = ns.Expr
local Creature = ns.Creature
local trunc = U.trunc
local D = ns.Data

local Battle = {}
Battle.__index = Battle
ns.Battle = Battle

Battle.TICK = 50              -- ms per simulation step
local MAX_TRIGGER_DEPTH = 4

---------------------------------------------------------------------------
-- helpers
---------------------------------------------------------------------------
local function flagSet(str)
    local set = {}
    if type(str) == "string" then
        for f in str:gmatch("[^,|%s]+") do set[f] = true end
    end
    return set
end

local function curveFactor(curveId, level)
    local c = D.SkillCurves[curveId]
    if not c then return 1000 end
    if level < 1 then level = 1 end
    return c[level] or c[#c]
end

---------------------------------------------------------------------------
-- Expression environment
---------------------------------------------------------------------------
local Env = {}
Env.__index = Env

local function newEnv(battle, ctx)
    return setmetatable({ battle = battle, ctx = ctx }, Env)
end

function Env:Sel(name)
    local ctx = self.ctx
    if name == "FiredCreature" or name == "UsedCreature" or name == "Myself" then return ctx.caster end
    if name == "TargetCreature" or name == "Target" then return ctx.target or ctx.caster end
    if name == "TriggerSelf" then return ctx.trigger and ctx.trigger.self or ctx.caster end
    if name == "TriggerTarget" then return ctx.trigger and ctx.trigger.target or ctx.target end
    return ctx.caster
end

function Env:Trigger(field)
    local t = self.ctx.trigger
    if not t then return 0 end
    if field == "Flag" or field == "DamageFlag" then return t.flag or 0 end
    if field == "StateName" then return t.stateName or "" end
    if field == "SkillIndex" then return t.skillId or 0 end
    if field == "IsAlly" then return t.isAlly and true or false end
    if field == "StateFlag" then return t.stateFlag or 0 end
    if field == "SkillAttrFlag" then return t.attrFlag or "" end
    if field == "IsBaseAttack" then return t.isBase and true or false end
    return 0
end

function Env:Call(name, a)
    local b, ctx = self.battle, self.ctx
    if name == "CreatureStateCount" then
        local c = self:Sel(a[1]); return c and c:StateCount(tostring(a[2])) or 0
    elseif name == "CreatureStateMaxCount" then
        local c = self:Sel(a[1]); return c and c:StateMax(tostring(a[2])) or 0
    elseif name == "CreatureStateCountByFiredCreature" then
        local c = self:Sel(a[1]); return c and c:StateCountBy(tostring(a[2]), ctx.caster) or 0
    elseif name == "CreatureStateMaxCountByFiredCreature" then
        local c = self:Sel(a[1]); local s = tostring(a[2])
        return c and (c:StateMax(s) + (ctx.caster.firedStateMaxBonus[s] or 0)) or 0
    elseif name == "CreatureFinalStat" then
        local c = self:Sel(a[1]); local s = tostring(a[2])
        if not c then return 0 end
        if s == "HpRatio" then return c:HpRatioM() end
        if s == "MpRatio" then return c:MpRatioM() end
        if s == "Hp" or s == "HP" then return c.hp end
        if s == "Mp" then return c.mp end
        return c:Stat(s)
    elseif name == "CreatureAttrStateCount" then
        local c = self:Sel(a[1]); local k = tostring(a[2])
        return c and c:AttrStateCount(k == "CC" and "cc" or (k == "Buff" and "buff" or "debuff")) or 0
    elseif name == "CreatureIsGround" then return 1
    elseif name == "CreatureIsAir" then return 0
    elseif name == "IsFlyMode" then return 0
    elseif name == "CreatureIsBoss" then
        local c = self:Sel(a[1]); return (c and c.isBoss) and 1 or 0
    elseif name == "CreatureHasPassiveSkill" then
        local c = self:Sel(a[1]); return (c and c.passiveSkills[tonumber(a[2])]) and 1 or 0
    elseif name == "CreatureSkillCoolTime" then
        local c = self:Sel(a[1]); return c and math.max(0, c.cooldowns[tonumber(a[2])] or 0) or 0
    elseif name == "CreatureProjectileCount" then
        local c = self:Sel(a[1]); return c and b:ProjectileCount(c, tonumber(a[2])) or 0
    elseif name == "CreatureEnemyCount" then
        return #b:Enemies(ctx.caster)
    elseif name == "CreatureAllyCount" then
        return #b:Allies(ctx.caster)
    elseif name == "CreatureBossCount" then
        local n = 0
        for _, e in ipairs(b:Enemies(ctx.caster)) do if e.isBoss then n = n + 1 end end
        return n
    elseif name == "EnemyCreatureCountInArea" then
        local r = tonumber(a[2]) or 1000
        local cx = ctx.center or ctx.caster.x
        local n = 0
        for _, e in ipairs(b:Enemies(ctx.caster)) do if math.abs(e.x - cx) <= r + e.radius then n = n + 1 end end
        return n
    elseif name == "EnemyCreatureCountInRectArea" then
        local front, back = tonumber(a[2]) or 0, tonumber(a[3]) or 0
        return #b:TargetsInRect(ctx.caster, front, back, 99)
    elseif name == "ExistCreatureInProjectileArea" then
        return #b:Enemies(ctx.caster) > 0 and 1 or 0
    elseif name == "CheckDungeonType" then
        return (b.dungeonType == tostring(a[1])) and 1 or 0
    elseif name == "CheckIsTrial" then
        return b.isTrial and 1 or 0
    elseif name == "BattleRandom" then
        local lo, hi = E.num(a[1]), E.num(a[2])
        if hi < lo then lo, hi = hi, lo end
        return b.rng:Int(lo, hi)
    elseif name == "Min" then return math.min(E.num(a[1]), E.num(a[2]))
    elseif name == "Max" then return math.max(E.num(a[1]), E.num(a[2]))
    elseif name == "CreatureLevel" then
        local c = self:Sel(a[1]); return c and c.level or 1
    elseif name == "DungeonDifficulty" then return b.difficulty or 0
    elseif name == "MonsterTier" then return 0
    elseif name == "CreatureSpawnNo" then return 0
    elseif name == "ProjectileFireCount" then return ctx.projectile and ctx.projectile.fired or 0
    elseif name == "CreaturePosition" then
        local c = self:Sel(a[1]); return c and c.x or 0
    elseif name == "ProjectilePosition" then
        return ctx.caster.x
    elseif name == "CreatureWarpSpotCount" then return 0
    elseif name == "CreatureIsStateImmune" then return 0
    end
    return 0
end

---------------------------------------------------------------------------
-- Construction
---------------------------------------------------------------------------
-- opts = { seed, mode, dungeonType ("Campaign"...), isTrial, difficulty, timeLimitMs, hooks }
function Battle.New(opts)
    local b = setmetatable({}, Battle)
    b.opts = opts or {}
    b.time = 0
    b.rng = U.NewRNG(b.opts.seed or 1)
    b.creatures = {}
    b.events = {}
    b.projectiles = {}
    b.hooks = b.opts.hooks or {}
    b.dungeonType = b.opts.dungeonType or "Campaign"
    b.isTrial = b.opts.isTrial or false
    b.difficulty = b.opts.difficulty
    b.timeLimit = b.opts.timeLimitMs
    b.ended = false
    b.stats = { damage = {}, kills = 0 }
    return b
end

function Battle:Hook(name, ...)
    local fn = self.hooks[name]
    if fn then
        local ok, err = pcall(fn, self, ...)
        if not ok and ns.Debug then ns.Debug("hook %s: %s", name, tostring(err)) end
    end
end

function Battle:Schedule(delayMs, fn)
    local ev = { at = self.time + math.max(0, delayMs or 0), fn = fn }
    self.events[#self.events + 1] = ev
    return ev
end

function Battle:AddCreature(def)
    local c = Creature.New(self, def)
    self.creatures[#self.creatures + 1] = c
    if c.job or def.skillSet then self:SetupSkills(c, def) end
    c.hp = c:Stat("MaxHp")
    c.mp = c:Stat("MaxMp")
    self:Hook("onSpawn", c)
    return c
end

function Battle:Enemies(c)
    local out = {}
    for _, o in ipairs(self.creatures) do
        if o.alive and o.side ~= c.side and not o.untargetable then out[#out + 1] = o end
    end
    return out
end

function Battle:Allies(c)
    local out = {}
    for _, o in ipairs(self.creatures) do
        if o.alive and o.side == c.side and o ~= c then out[#out + 1] = o end
    end
    return out
end

function Battle:Nearest(c, list)
    local best, bd
    for _, o in ipairs(list or self:Enemies(c)) do
        local d = math.abs(o.x - c.x)
        if not bd or d < bd then best, bd = o, d end
    end
    return best, bd
end

-- enemies of c inside [front, back] along c.facing, nearest first
function Battle:TargetsInRect(c, front, back, max, centerX, facing)
    local cx = centerX or c.x
    local f = facing or c.facing
    local list = {}
    for _, o in ipairs(self:Enemies(c)) do
        local dx = (o.x - cx) * f
        if dx <= front + o.radius and dx >= -(back + o.radius) then
            list[#list + 1] = { c = o, d = math.abs(dx) }
        end
    end
    table.sort(list, function(a, b) return a.d < b.d end)
    local out = {}
    for i = 1, math.min(#list, max or #list) do out[i] = list[i].c end
    return out
end

function Battle:TargetsInRadius(c, radius, max, centerX)
    local cx = centerX or c.x
    local list = {}
    for _, o in ipairs(self:Enemies(c)) do
        local d = math.abs(o.x - cx)
        if d <= radius + o.radius then list[#list + 1] = { c = o, d = d } end
    end
    table.sort(list, function(a, b) return a.d < b.d end)
    local out = {}
    for i = 1, math.min(#list, max or #list) do out[i] = list[i].c end
    return out
end

---------------------------------------------------------------------------
-- Skill instances (per creature) with mastery / passive modifications
---------------------------------------------------------------------------
local function newMod() return { add = 0, ratio = 0, set = nil } end
local SKILL_LEVEL_FIELDS = { SkillCoolTimeMs = true, SkillTriggerRatio = true, SkillTargetCount = true,
    SkillTriggerTimeMs = true }

function Battle:Inst(c, sid)
    sid = tonumber(sid)
    if not sid then return nil end
    local inst = c.skills[sid]
    if inst then return inst end
    local data = D.Skills[sid]
    if not data then return nil end
    inst = {
        id = sid,
        data = data,
        level = 1,
        flags = flagSet(data.TriggerFlag),
        ops = {},
        skillMods = {},          -- [field] = {add, ratio, set}
        projMods = {},           -- [projIdx] = {[field] = mod}
        pipe = {},               -- [opNo] = { GiveDamagePower1=sum, ..., fd = {list} }
    }
    for i, op in ipairs(data.Operations or {}) do
        local f = flagSet(op.Flag)
        inst.ops[i] = { op = op, enabled = not f.Disabled, mods = {}, flags = f }
    end
    -- level: hero row level, FollowLevelIndex owner level, else 1
    local lv = c.skillLevels and c.skillLevels[sid]
    if not lv and data.FollowLevelIndex then
        lv = c.skillLevels and c.skillLevels[tonumber(data.FollowLevelIndex)]
    end
    inst.level = lv or 1
    c.skills[sid] = inst
    return inst
end

local function modField(t, key)
    local m = t[key]
    if not m then m = newMod(); t[key] = m end
    return m
end

local function applyMod(base, m)
    if not m then return base end
    local v = m.set ~= nil and m.set or base
    return trunc(v * (1000 + m.ratio) / 1000) + m.add
end

-- numeric op field after mastery mods
function Battle:OpField(inst, opNo, field, base)
    local o = inst.ops[opNo]
    if not o then return base end
    return applyMod(base, o.mods[field])
end

function Battle:SkillField(inst, field, base)
    return applyMod(base, inst.skillMods[field])
end

-- value of op.Values[vi] (1-based) with expressions, mastery mods and level curve
function Battle:OpValue(ctx, inst, opNo, vi)
    local o = inst.ops[opNo]
    local op = o.op
    local raw = op.Values and op.Values[vi]
    local setm = o.mods["Value:" .. (vi - 1)]
    local v
    if setm and setm.expr then
        v = E.Num(setm.expr, newEnv(self, ctx))
    elseif E.IsExpr(raw) then
        v = E.Num(raw, newEnv(self, ctx))
    else
        v = tonumber(raw) or 0
    end
    if setm then
        v = trunc(v * (1000 + setm.ratio) / 1000) + setm.add
    end
    local lf = op.ValueLevelFactors
    if lf then
        for k = 1, #lf - 1, 2 do
            if lf[k] + 1 == vi then
                v = trunc(v * curveFactor(lf[k + 1], inst.level) / 1000)
            end
        end
    end
    return v
end

-- Static (OnStart, sticky) operations that modify other skills or permanent stats.
function Battle:ApplyStaticOp(c, owner, opNo, op)
    local t = op.Type
    local V = op.Values or {}
    local ctx = { caster = c, inst = owner, target = c }
    if t == "ModSkill" or t == "ModSkillR" or t == "SetSkill" then
        local tgt = self:Inst(c, V[1])
        if not tgt then return end
        local opIdx, field = tonumber(V[2]) or 0, tostring(V[3])
        local key = field
        if field == "Value" then key = "Value:" .. tostring(t == "SetSkill" and (V[5] or 0) or (V[5] or 0)) end
        local mods = {}
        if opIdx == 0 and SKILL_LEVEL_FIELDS[field] then
            mods[1] = modField(tgt.skillMods, key)
        elseif opIdx == 0 then
            for _, o in pairs(tgt.ops) do mods[#mods + 1] = modField(o.mods, key) end
        else
            local o = tgt.ops[opIdx]
            if not o then return end
            mods[1] = modField(o.mods, key)
        end
        local val
        if t ~= "SetSkill" then
            val = E.IsExpr(V[4]) and E.Num(V[4], newEnv(self, ctx)) or (tonumber(V[4]) or 0)
            if op.ValueLevelFactors then val = self:OpValue(ctx, owner, opNo, 4) end
        end
        for _, m in ipairs(mods) do
            if t == "SetSkill" then
                if E.IsExpr(V[4]) then m.expr = V[4] else m.set = tonumber(V[4]) end
            elseif t == "ModSkillR" then m.ratio = m.ratio + val
            else m.add = m.add + val end
        end
    elseif t == "ModSkillStat" then
        local tgt = self:Inst(c, V[1])
        if not tgt then return end
        local opIdx, stat = tonumber(V[2]) or 0, tostring(V[3])
        local val = self:OpValue(ctx, owner, opNo, 4)
        local p = tgt.pipe[opIdx] or {}
        tgt.pipe[opIdx] = p
        if stat == "FinalDamage" then
            p.fd = p.fd or {}
            table.insert(p.fd, val)
        else
            p[stat] = (p[stat] or 0) + val
        end
    elseif t == "ModSkillEnabled" or t == "ModSkillDisabled" then
        local tgt = self:Inst(c, V[1])
        if not tgt then return end
        local o = tgt.ops[tonumber(V[2]) or 0]
        if o then o.enabled = (t == "ModSkillEnabled") end
    elseif t == "ChangeSkill" then
        c.changeSkill = c.changeSkill or {}
        c.changeSkill[tonumber(V[1])] = tonumber(V[2])
    elseif t == "ModSkillProjectile" or t == "ModSkillProjectileR" then
        local pidx, field = tonumber(V[1]), tostring(V[2])
        c.projMods = c.projMods or {}
        c.projMods[pidx] = c.projMods[pidx] or {}
        local key = field .. (V[4] and (":" .. V[4]) or "")
        local m = modField(c.projMods[pidx], key)
        local val = tonumber(V[3]) or 0
        if t == "ModSkillProjectileR" then m.ratio = m.ratio + val else m.add = m.add + val end
    elseif t == "ModStateMaxStack" then
        local s = tostring(V[1])
        c.stateMaxBonus[s] = (c.stateMaxBonus[s] or 0) + (tonumber(V[2]) or 0)
    elseif t == "ModFiredStateMaxStack" then
        local s = tostring(V[1])
        c.firedStateMaxBonus[s] = (c.firedStateMaxBonus[s] or 0) + (tonumber(V[2]) or 0)
    elseif t == "ModDamagePipelineStat" then
        c.pipeline = c.pipeline or {}
        table.insert(c.pipeline, { skill = tonumber(V[1]) or 0, opNo = tonumber(V[2]) or 0, stat = tostring(V[3]), value = V[4],
            owner = owner, opIndex = opNo })
    elseif t == "ModAttrDamagePipelineStat" then
        c.pipeline = c.pipeline or {}
        table.insert(c.pipeline, { attr = tostring(V[1]), stat = tostring(V[2]), value = V[3], owner = owner, opIndex = opNo,
            valueIndex = 3 })
    elseif t == "UsePassiveSkill" then
        self:RegisterPassive(c, tonumber(V[1]))
    else
        return false
    end
    return true
end

-- passive (triggered) skills: OnAttack/OnTimer/OnHit...; OnStart ones run immediately
function Battle:RegisterPassive(c, sid)
    if not sid or c.passiveSkills[sid] then return end
    local inst = self:Inst(c, sid)
    if not inst then return end
    c.passiveSkills[sid] = inst
    local tt = inst.data.TriggerType
    if tt == "OnStart" then
        self:RunOnStart(c, inst)
    elseif tt and tt ~= "None" then
        c.triggers[tt] = c.triggers[tt] or {}
        table.insert(c.triggers[tt], inst)
        if tt == "OnTimer" then
            local tm = inst.data.TriggerTimeMs or { 1000, 1000 }
            local env = newEnv(self, { caster = c, inst = inst, target = c })
            local first = E.Num(tm[1] or 1000, env)
            local interval = self:SkillField(inst, "SkillTriggerTimeMs", E.Num(tm[2] or tm[1] or 1000, env))
            inst.nextTimer = self.time + first
            inst.timerInterval = math.max(50, interval)
            inst.timerExpr = (E.IsExpr(tm[2]) and tm[2]) or nil
        end
    end
end

function Battle:RemovePassive(c, sid)
    local inst = c.passiveSkills[sid]
    if not inst then return end
    c.passiveSkills[sid] = nil
    local list = c.triggers[inst.data.TriggerType]
    if list then
        for i = #list, 1, -1 do if list[i] == inst then table.remove(list, i) end end
    end
end

function Battle:RunOnStart(c, inst)
    for i, o in ipairs(inst.ops) do
        if o.enabled then
            local handled = self:ApplyStaticOp(c, inst, i, o.op)
            if not handled then
                -- permanent stat mods / states from OnStart skills
                self:ExecOp({ caster = c, inst = inst, target = c, opTargets = {}, depth = 0, static = true }, i)
            end
        end
    end
end

-- Build the hero's skill book: levels, passives, masteries.
-- def.skillSet = { levels = {[sid]=lv}, passives = {sid...}, actives = {sid...}, basic = sid, masteries = {sid...} }
function Battle:SetupSkills(c, def)
    local ss = def.skillSet or {}
    c.skillLevels = ss.levels or {}
    c.activeList = {}
    -- OnStart passives first in data order, then masteries (they reference passives)
    for _, sid in ipairs(ss.passives or {}) do self:RegisterPassive(c, sid) end
    for _, sid in ipairs(ss.masteries or {}) do self:RegisterPassive(c, sid) end
    for _, sid in ipairs(ss.extraPassives or {}) do self:RegisterPassive(c, sid) end
    for _, sid in ipairs(ss.actives or {}) do
        local inst = self:Inst(c, sid)
        if inst then table.insert(c.activeList, inst) end
    end
    c.basicSkill = ss.basic and self:Inst(c, ss.basic)
    -- every active starts ready (the client staggers via InitialMinCoolTimeMs on a few skills)
    for _, inst in ipairs(c.activeList) do
        local d = inst.data
        if d.InitialMinCoolTimeMs then
            c.cooldowns[inst.id] = self.rng:Int(d.InitialMinCoolTimeMs, d.InitialMaxCoolTimeMs or d.InitialMinCoolTimeMs)
        end
    end
    c:Dirty()
end

---------------------------------------------------------------------------
-- Damage
---------------------------------------------------------------------------
local function pf(rawPermille) -- 1 + raw/1000, floored at 0
    local v = 1 + rawPermille / 1000
    if v < 0 then return 0 end
    return v
end

-- Returns damage, isCrit, isMiss
-- line = { pct = number (display % of the line, e.g. 430.3), isBase = bool, localStats = {StatType=raw}, attr = "Ice" }
---------------------------------------------------------------------------
-- PvP damage (Arena / Colosseum / World Arena, official formula since 2026-07-02,
-- research/spec/research-arena.md 2.2). Player-vs-player hits only.
---------------------------------------------------------------------------
Battle.PVP_CONST = { Arena = 7206000000, Colosseum = 4323600000, WorldArena = 5764800000 }
-- level correction bands: damage change per level above 30 (Arena / World Arena)
Battle.PVP_LEVEL_BANDS = { { 31, 60, 0.005 }, { 61, 100, 0.013 }, { 101, 9999, 0.015 } }
Battle.PVP_LEVEL_BANDS_COLOSSEUM = { { 31, 60, 0.005 }, { 61, 70, 0.013 }, { 71, 100, 0.015 }, { 101, 9999, 0.025 } }

function Battle:PvpLevelFactor(level)
    local bands = (self.dungeonType == "Colosseum") and Battle.PVP_LEVEL_BANDS_COLOSSEUM or Battle.PVP_LEVEL_BANDS
    local f = 1
    for _, b in ipairs(bands) do
        for _ = b[1], math.min(level, b[2]) do f = f * (1 - b[3]) end
    end
    return f
end

-- the PvP reduction divisor uses the target's own stats taken before the fight
function Battle:PvpDivisor(c)
    if c.pvpDivisor then return c.pvpDivisor end
    local function s(k) return c:Stat(k) end
    local function f(k) return 1 + s(k) / 1000 end
    local critW = 1 + math.max(0, s("CriticalPower")) / 1000 * U.clamp(s("CriticalChance") / 1000, 0, 1)
    local offense = math.max(0, s("Attack")) * f("PiercePower") * f("AttackPower") * f("AttackPower2")
        * (1 + (s("BaseAttackPower") + s("SkillPower")) / 2000) * f("MainDamagePower") * critW
        * ((math.min(s("MinDamageRatio"), s("MaxDamageRatio")) + s("MaxDamageRatio")) / 2000) * f("FinalDamage")
    local A = (offense + 1e9) ^ 0.23
    local B = (math.max(1, s("MaxHp")) * 1e8) ^ 0.12
    local C = ((math.max(0, s("Defence")) + 6000) * 1e12) ^ 0.14
    local Dd = ((1 + math.min(950, s("Toughness")) / 1000) * 1e6) ^ 0.5
    c.pvpDivisor = A * B * C * Dd / 1e7
    return c.pvpDivisor
end

function Battle:ComputePvpHit(att, tgt, line)
    local function pf2(v) return math.max(0, 1 + v / 1000) end
    local def = math.max(0, tgt:Stat("Defence"))
    local pierce = math.min(999, math.max(0, att:Stat("PiercePower")))
    local base = math.max(0, att:Stat("Attack")) * 5000 / (6000 + def * (1000 - pierce) / 1000)
    base = base * pf2(tgt:Stat("Weakness")) * (1 - math.min(950, tgt:Stat("Toughness")) / 1000)
    base = base * pf2(att:Stat("AttackPower")) * pf2(att:Stat("AttackPower2"))
    base = base * (line.isBase and pf2(att:Stat("BaseAttackPower")) or pf2(att:Stat("SkillPower")))
    base = base * pf2(att:Stat("MainDamagePower"))
    local crit = false
    local cr = att:Stat("CriticalChance") - tgt:Stat("CriticalResist")
    if cr > 0 and self.rng:Float() * 1000 < cr then
        crit = true
        base = base * (1 + math.max(0, att:Stat("CriticalPower")) / 1000)
    end
    local minR, maxR = trunc(att:Stat("MinDamageRatio")), trunc(att:Stat("MaxDamageRatio"))
    if minR > maxR then minR = maxR end
    base = base * (minR + (maxR - minR) * self.rng:Float()) / 1000
    if tgt:IsCC() then base = base * pf2(att:Stat("AttackPowerInCc")) end
    base = base * pf2(att:Stat("FinalDamage")) * pf2(att:Stat("FinalDamage2")) * pf2(att:Stat("FinalDamage3"))
    local const = Battle.PVP_CONST[self.dungeonType] or Battle.PVP_CONST.Arena
    -- PROVISIONAL: "레벨에 의한 피해량 감소% x 2" - the attacker's level band factor, times 2 as written
    local inner, coef = Battle.SplitLine(line)
    local dmg = math.sqrt(base * inner) * (coef / 100) * self:PvpLevelFactor(att.level or 1) * 2 * const
        / self:PvpDivisor(tgt) / 1e6
    if line.extraMult then dmg = dmg * line.extraMult end
    if dmg < 1 then dmg = 1 end
    return math.floor(dmg), crit
end

-- divisor from the profile's own stats only (no passives, buffs or on-start effects)
function Battle:SetPvpBaseline(c, def)
    local base = Creature.New(self, { name = def.name, side = def.side, level = def.level, job = def.job, stats = def.stats })
    c.pvpDivisor = self:PvpDivisor(base)
end

-- skill coefficient (outside the root) and the rest of the line multipliers (inside):
-- mastery / passive damage increases belong to the base formula (official guide 1.3)
local function splitLine(line)
    local pct = line.pct or 100
    local coef = line.coef
    if not coef or coef <= 0 then return 1, pct end
    return pct / coef, coef
end
Battle.SplitLine = splitLine

-- 파티 퀘스트 and 자쿰·혼테일 boss raids: √ damage adjustment before the skill coefficient
function Battle:SqrtContent()
    local dt = self.dungeonType
    if dt == "PartyDungeon" then return true end
    if dt == "BossRaid" then
        local ctl = self.opts.controller
        return not (ctl and ctl.boss == "pinkbean")
    end
    return false
end

function Battle:IsPvp(att, tgt)
    return Battle.PVP_CONST[self.dungeonType] and (att.isHero or att.isSupporter or att.owner)
        and (tgt.isHero or tgt.isSupporter) and att.side ~= tgt.side
end

function Battle:ComputeHit(att, tgt, line, ctx)
    -- hit / avoid
    local gap = (tgt:Stat("AvoidChance") or 0) - (att:Stat("HitChance") or 0)
    if gap > 0 then
        if gap > 100 then gap = 100 end
        local miss = D.Combat.missPermilleByGap[gap] or 700
        if self.rng:Float() * 1000 < miss then return 0, false, true end
    end
    if self:IsPvp(att, tgt) then
        local dmg, crit = self:ComputePvpHit(att, tgt, line)
        return dmg, crit, false
    end
    local atk = att:Stat("Attack")
    if atk <= 0 then atk = 0 end
    local dmg = atk
        * pf(att:Stat("AttackPower"))
        * pf(att:Stat("AttackPower2"))
        * pf(att:Stat("MainDamagePower"))
    -- defense (attack/defense stage)
    local def = math.max(0, trunc(tgt:Stat("Defence")))
    local pierce = math.min(999, math.max(0, att:Stat("PiercePower")))
    local rawEff = def * (1000 - pierce) / 1000
    local eff = (rawEff > 0 and rawEff < 1) and 1 or trunc(rawEff)
    if eff > 0 then dmg = dmg * D.Combat.defNumerator / (eff + D.Combat.defOffset) end
    -- critical
    local crit = false
    local cr = att:Stat("CriticalChance") - tgt:Stat("CriticalResist")
    if cr > 0 and self.rng:Float() * 1000 < cr then
        crit = true
        dmg = dmg * (1 + math.max(0, att:Stat("CriticalPower")) / 1000)
    end
    -- min / max damage ratio
    local minR = trunc(att:Stat("MinDamageRatio"))
    local maxR = trunc(att:Stat("MaxDamageRatio"))
    if minR > maxR then minR = maxR end
    local roll = minR + (maxR - minR) * self.rng:Float()
    dmg = dmg * roll / 1000
    -- status-ailment damage
    if tgt:IsCC() then dmg = dmg * pf(att:Stat("AttackPowerInCc")) end
    -- final damage
    dmg = dmg * pf(att:Stat("FinalDamage")) * pf(att:Stat("FinalDamage2")) * pf(att:Stat("FinalDamage3"))
        * pf(att:Stat("FinalDamage4")) * pf(att:Stat("FinalDamage5"))
    -- target layer: boss / normal, basic / skill, weakness
    local boss = tgt.isBoss
    local loc = line.localStats or {}
    if boss then
        dmg = dmg * pf(att:Stat("AttackPowerToBoss") + (loc.AttackPowerToBoss or 0))
    else
        dmg = dmg * pf(att:Stat("AttackPowerExcludeBoss") + (loc.AttackPowerExcludeBoss or 0))
    end
    if line.isBase then
        dmg = dmg * pf(att:Stat("BaseAttackPower"))
        dmg = dmg * (1 - math.min(950, tgt:Stat("BaseAttackToughness")) / 1000) * pf(tgt:Stat("BaseAttackWeakness"))
    else
        dmg = dmg * pf(att:Stat("SkillPower"))
        dmg = dmg * (1 - math.min(950, tgt:Stat("SkillToughness")) / 1000) * pf(tgt:Stat("SkillWeakness"))
    end
    dmg = dmg * pf(tgt:Stat("Weakness"))
    -- target damage reduction (Toughness)
    local tough = tgt:Stat("Toughness")
    if tough > 0 then dmg = dmg * (1 - tough / 1000) end
    if line.extraMult then dmg = dmg * line.extraMult end
    if self:SqrtContent() and att.side == 1 then
        local inner, coef = Battle.SplitLine(line)
        dmg = math.sqrt(math.max(0, dmg * inner)) * coef / 100
    else
        dmg = dmg * (line.pct or 100) / 100
    end
    if dmg < 1 then dmg = 1 end
    return math.floor(dmg), crit, false
end

-- percent multiplier of one hit of op (site resolveDamage):
-- ratioM/10 * (1+G1) * (1+G2) * (1+G3) * prod(1+FD)
function Battle:LinePercent(ctx, inst, opNo, ratioM, target)
    local p = inst.pipe[opNo] or {}
    local p0 = inst.pipe[0] or {}
    if opNo == 0 then p0 = p end
    local g1 = (p.GiveDamagePower1 or 0) + (p0 ~= p and p0.GiveDamagePower1 or 0)
    local g2 = (p.GiveDamagePower2 or 0) + (p0 ~= p and p0.GiveDamagePower2 or 0)
    local g3 = (p.GiveDamagePower3 or 0) + (p0 ~= p and p0.GiveDamagePower3 or 0)
    local fd = 1
    if p.fd then for i = 1, #p.fd do fd = fd * (1 + p.fd[i] / 1000) end end
    if p0 ~= p and p0.fd then for i = 1, #p0.fd do fd = fd * (1 + p0.fd[i] / 1000) end end
    -- creature-level pipelines (ModDamagePipelineStat / ModAttrDamagePipelineStat)
    local c = ctx.caster
    if c.pipeline then
        local attr = inst.data.AttrFlag
        local env
        for _, pl in ipairs(c.pipeline) do
            local match
            if pl.attr then
                match = attr and tostring(attr):find(pl.attr, 1, true) ~= nil
            else
                match = (pl.skill == 0 or pl.skill == inst.id or pl.skill == ctx.rootSkill) and (pl.opNo == 0 or pl.opNo == opNo)
            end
            if match then
                env = env or newEnv(self, { caster = c, target = target, inst = inst })
                local v
                if pl.valueIndex and pl.owner then
                    local sub = { caster = c, target = target, inst = pl.owner }
                    v = self:OpValue(sub, pl.owner, pl.opIndex, pl.valueIndex)
                else
                    v = E.Num(pl.value, env)
                end
                if pl.stat == "GiveDamagePower1" then g1 = g1 + v
                elseif pl.stat == "GiveDamagePower2" then g2 = g2 + v
                elseif pl.stat == "GiveDamagePower3" then g3 = g3 + v
                elseif pl.stat == "FinalDamage" then fd = fd * (1 + v / 1000) end
            end
        end
    end
    return ratioM / 10 * (1 + g1 / 1000) * (1 + g2 / 1000) * (1 + g3 / 1000) * fd
end

function Battle:DealDamage(att, tgt, amount, crit, info)
    if not tgt.alive then return end
    if tgt.invincibleUntil and tgt.invincibleUntil > self.time then amount = 0 end
    if tgt.shield > 0 and amount > 0 then
        local absorbed = math.min(tgt.shield, amount)
        tgt.shield = tgt.shield - absorbed
        amount = amount - absorbed
    end
    tgt.hp = tgt.hp - amount
    tgt.aggro = true
    att.dmgDealt = att.dmgDealt + amount
    local key = info.skillId or 0
    self.stats.damage[key] = (self.stats.damage[key] or 0) + amount
    self:Hook("onDamage", att, tgt, amount, crit, info)
    if tgt.hp <= 0 and tgt.noDie then tgt.hp = 1 end
    if tgt.hp <= 0 then
        local minHp = tgt:Stat("MinHpRatio")
        if tgt.isHero and minHp > 0 and not tgt.usedMinHp then
            tgt.usedMinHp = true
            tgt.hp = math.max(1, trunc(tgt:Stat("MaxHp") * minHp / 1000))
        else
            self:Kill(tgt, att)
        end
    end
    -- OnDamage triggers on the victim
    if tgt.alive then
        self:FireTriggers(tgt, "OnDamage", { target = att, self = tgt, flag = info.flag, skillId = info.skillId, isAlly = false },
            (info.depth or 0) + 1)
    end
end

function Battle:Kill(c, killer)
    if not c.alive then return end
    c.alive = false
    c.hp = 0
    if c.side ~= 1 then self.stats.kills = self.stats.kills + 1 end
    self:Hook("onDeath", c, killer)
    if killer and killer.alive then
        self:FireTriggers(killer, "OnEnemyDie", { target = c, self = killer }, 1)
        self:FireTriggers(killer, "OnKill", { target = c, self = killer }, 1)
    end
    -- projectiles that expire on owner death
    for i = #self.projectiles, 1, -1 do
        local p = self.projectiles[i]
        if p.owner == c and p.expireOnDie then table.remove(self.projectiles, i) end
    end
end

---------------------------------------------------------------------------
-- Operation execution
---------------------------------------------------------------------------
local function opDelay(op)
    local d = op.DelayMs or 0
    if op.QueueDelayMs and op.QueueDelayMs[1] then d = d + op.QueueDelayMs[1] end
    return d
end

function Battle:ResolveTargets(ctx, o)
    local op = o.op
    local tt = op.TargetType
    if op.ParentOperationNo then
        return ctx.opTargets[op.ParentOperationNo] or {}
    end
    if tt == "Myself" or tt == "TriggerSelf" then return { ctx.caster } end
    if tt == "Target" or tt == "TriggerTarget" then
        if ctx.trigger and ctx.trigger.target and tt == "TriggerTarget" then return { ctx.trigger.target } end
        return ctx.target and { ctx.target } or {}
    end
    if tt == "Ally" or tt == "Friend" then
        local list = self:Allies(ctx.caster)
        table.insert(list, 1, ctx.caster)
        return list
    end
    return ctx.target and { ctx.target } or { ctx.caster }
end

function Battle:Enabled(ctx, o)
    if not o.enabled then return false end
    local cond = o.op.EnableCondition
    if cond and not E.Bool(cond, newEnv(self, ctx)) then return false end
    if o.op.FireChance and self.rng:Float() * 100 >= o.op.FireChance then return false end
    return true
end

-- ctx = { caster, inst, target, trigger, opTargets, depth, center, projectile, dmgScale, rootSkill }
function Battle:ExecOp(ctx, opNo)
    local inst = ctx.inst
    local o = inst.ops[opNo]
    if not o then return end
    local op = o.op
    local t = op.Type
    if not ctx.static and not self:Enabled(ctx, o) then return end
    local c = ctx.caster
    local V = op.Values or {}

    if t == "GetDamageR" then
        self:OpDamage(ctx, opNo)
    elseif t == "GetDotR" then
        local targets = self:ResolveTargets(ctx, o)
        local ratio = self:OpValue(ctx, inst, opNo, 1)
        for _, tg in ipairs(targets) do
            if tg.side ~= c.side and tg.alive then self:ApplyDot(ctx, tg, ratio, op) end
        end
        ctx.opTargets[opNo] = targets
    elseif t == "ModStat" or t == "ModStatR" then
        self:OpModStat(ctx, opNo)
    elseif t == "ModStatOnTick" then
        self:OpModStatOnTick(ctx, opNo)
    elseif t == "State" then
        local targets = self:ResolveTargets(ctx, o)
        for _, tg in ipairs(targets) do
            tg:AddState(op.State, op.DurationMs, c, nil)
        end
        ctx.opTargets[opNo] = targets
    elseif t == "ClearState" then
        local targets = self:ResolveTargets(ctx, o)
        for _, tg in ipairs(targets) do tg:ClearState(V[1]) end
    elseif t == "Stun" or t == "Frozen" then
        local targets = self:ResolveTargets(ctx, o)
        for _, tg in ipairs(targets) do
            local dur = (op.DurationMs or 1000) * (1 - self:DebuffReduction(c, tg))
            if tg.side ~= c.side and tg.alive and not tg.isBoss then
                tg:AddState(t, dur, c, { cc = true, debuff = true })
            elseif tg.side ~= c.side and tg.alive then
                tg:AddState(t == "Frozen" and "Frozen" or "Stun", math.floor(dur / 4), c, { cc = true, debuff = true })
            end
        end
    elseif t == "UseSkill" then
        local repeatN = tonumber(V[2]) or 1
        for _ = 1, math.max(1, repeatN) do
            self:UseSkillNow(c, tonumber(V[1]), ctx.target, ctx, ctx.depth + 1)
        end
    elseif t == "UseSkillToTarget" then
        local targets = self:ResolveTargets(ctx, o)
        for _, tg in ipairs(targets) do
            if tg.alive then self:UseSkillNow(c, tonumber(V[1]), tg, ctx, ctx.depth + 1) end
        end
    elseif t == "UsePassiveSkill" then
        self:RegisterPassive(c, tonumber(V[1]))
    elseif t == "RemovePassiveSkill" then
        self:RemovePassive(c, tonumber(V[1]))
    elseif t == "CreateProjectile" then
        self:CreateProjectile(ctx, tonumber(V[1]))
    elseif t == "CreateServantProjectile" then
        self:CreateProjectile(ctx, tonumber(V[2]))
    elseif t == "FireProjectile" then
        self:FireProjectileNow(c, tonumber(V[1]), ctx)
    elseif t == "DestroyProjectile" then
        self:DestroyProjectiles(c, tonumber(V[2]))
    elseif t == "ModCoolTime" or t == "ModCoolTimeR" then
        local sid = tonumber(V[1]) or 0
        local amount = E.IsExpr(V[2]) and E.Num(V[2], newEnv(self, ctx)) or (tonumber(V[2]) or 0)
        local targets = (op.RadiusMm and { c }) or { c }
        for _, tg in ipairs(targets) do
            for id, rem in pairs(tg.cooldowns) do
                if sid == 0 or id == sid then
                    if t == "ModCoolTimeR" then
                        tg.cooldowns[id] = rem + trunc(rem * amount / 1000)
                    else
                        tg.cooldowns[id] = rem + amount
                    end
                    if tg.cooldowns[id] < 0 then tg.cooldowns[id] = 0 end
                end
            end
        end
    elseif t == "ModRemainTriggerTime" then
        local target = c.passiveSkills[tonumber(V[1])]
        if target then target.nextTimer = self.time + (tonumber(V[2]) or 0) end
    elseif t == "GetHealByMaxHpR" or t == "GetHotByMaxHpR" then
        local targets = self:ResolveTargets(ctx, o)
        local ratio = self:OpValue(ctx, inst, opNo, 1)
        for _, tg in ipairs(targets) do
            if tg.side == c.side and tg.alive then
                if t == "GetHealByMaxHpR" then
                    self:Heal(tg, tg:Stat("MaxHp") * ratio / 1000)
                else
                    local ticks = math.floor((op.DurationMs or 1000) / (op.TickTimeMs or 1000))
                    for k = 1, ticks do
                        self:Schedule(k * (op.TickTimeMs or 1000), function()
                            if tg.alive then self:Heal(tg, tg:Stat("MaxHp") * ratio / 1000) end
                        end)
                    end
                end
            end
        end
        ctx.opTargets[opNo] = targets
    elseif t == "GetMpR" then
        local ratio = self:OpValue(ctx, inst, opNo, 1)
        c.mp = math.min(c:Stat("MaxMp"), c.mp + c:Stat("MaxMp") * ratio / 1000)
    elseif t == "CreateShieldByMaxHpR" then
        local ratio = self:OpValue(ctx, inst, opNo, 1)
        local targets = self:ResolveTargets(ctx, o)
        for _, tg in ipairs(targets) do
            if tg.side == c.side then
                local amt = tg:Stat("MaxHp") * ratio / 1000 * pf(tg:Stat("ShieldAmountRatio"))
                tg.shield = math.max(tg.shield, amt)
                local dur = op.DurationMs or 5000
                self:Schedule(dur, function() tg.shield = 0 end)
            end
        end
    elseif t == "DashFromMyself" then
        local dist = tonumber(V[1]) or 0
        local nearest = self:Nearest(c)
        if nearest then
            local gapX = math.abs(nearest.x - c.x) - 200
            dist = math.min(dist, math.max(0, gapX))
        end
        c.x = c.x + dist * c.facing
    elseif t == "DashToTarget" then
        local tg = ctx.target or self:Nearest(c)
        if tg then c.x = tg.x - (tonumber(V[1]) or 0) * c.facing end
    elseif t == "SpawnServant" then
        c.servants = c.servants or {}
        local st = op.State or "Servant"
        c:AddState(st, op.DurationMs or 15000, c, { buff = true })
        c.servantState = st
    elseif t == "SetServantSkill" then
        c.servantSkills = c.servantSkills or {}
        local ratio = self:OpValue(ctx, inst, opNo, 4)
        c.servantSkills[tonumber(V[2])] = { skill = tonumber(V[3]), ratio = ratio, state = c.servantState }
    elseif t == "Dispel" or t == "Cleanse" then
        if t == "Cleanse" then
            for name, st in pairs(c.states) do
                if st.attr and st.attr.debuff then c:ClearState(name) end
            end
        end
    else
        -- EffectOnly, EnableDoubleJump, warp spots, projectile locks: visual / movement only
        if t == "EffectOnly" and (op.RectAreaMm or op.RadiusMm) then
            ctx.opTargets[opNo] = self:AreaTargets(ctx, op)
        end
    end
end

function Battle:AreaTargets(ctx, op, max)
    local c = ctx.caster
    local center = ctx.center
    if op.AreaOffsetMm and op.AreaOffsetMm[1] then
        center = (center or c.x) + (op.AreaOffsetMm[1] or 0) * c.facing
    end
    if op.RectAreaMm then
        local r = op.RectAreaMm
        return self:TargetsInRect(c, r[1] or 0, r[2] or 0, max, center)
    elseif op.RadiusMm then
        return self:TargetsInRadius(c, op.RadiusMm, max, center)
    end
    return ctx.target and { ctx.target } or {}
end

function Battle:OpDamage(ctx, opNo)
    local inst = ctx.inst
    local o = inst.ops[opNo]
    local op = o.op
    local c = ctx.caster
    local maxTargets = self:OpField(inst, opNo, "MaxHitCount", op.MaxHitCount or inst.data.TargetCount or 1)
    if inst.isBasic or (ctx.rootSkill and c.basicSkill and ctx.rootSkill == c.basicSkill.id) then
        maxTargets = maxTargets + c:Stat("BaseAttackMaxHitCount")
    end
    local targets
    if op.ParentOperationNo then
        targets = ctx.opTargets[op.ParentOperationNo] or {}
    elseif op.TargetType == "Target" or op.TargetType == "TriggerTarget" then
        local tg = (op.TargetType == "TriggerTarget" and ctx.trigger and ctx.trigger.target) or ctx.target
        targets = (tg and tg.alive) and { tg } or {}
    elseif op.RectAreaMm or op.RadiusMm then
        targets = self:AreaTargets(ctx, op, maxTargets)
    else
        targets = (ctx.target and ctx.target.alive) and { ctx.target } or {}
    end
    local ratio = self:OpValue(ctx, inst, opNo, 1)
    local hits = self:OpValue(ctx, inst, opNo, 3)
    if hits < 1 then hits = 1 end
    local isBase = inst.isBasic or (ctx.rootSkill and c.basicSkill and ctx.rootSkill == c.basicSkill.id) or false
    local localStats = {}
    if op.ModStats then
        for _, ms in ipairs(op.ModStats) do
            local add = self:OpField(inst, opNo, "ModStatAddValue", ms.StatValue or 0)
            localStats[ms.StatType] = (localStats[ms.StatType] or 0) + add
        end
    end
    local hitList = {}
    for ti, tg in ipairs(targets) do
        if tg.alive and tg.side ~= c.side then
            hitList[#hitList + 1] = tg
            local pct = self:LinePercent(ctx, inst, opNo, ratio, tg) * (ctx.dmgScale or 1)
            local line = { pct = pct, coef = ratio / 10 * (ctx.dmgScale or 1), isBase = isBase, localStats = localStats,
                attr = inst.data.AttrFlag }
            local total, anyCrit = 0, false
            for h = 1, hits do
                local dmg, crit, miss = self:ComputeHit(c, tg, line, ctx)
                if not miss then
                    total = total + dmg
                    anyCrit = anyCrit or crit
                    local flag = (crit and E.DamageFlag.Critical or 0) + (isBase and E.DamageFlag.BaseAttack or 0)
                    self:DealDamage(c, tg, dmg, crit, { skillId = ctx.rootSkill or inst.id, opSkill = inst.id, hit = h,
                        flag = flag, depth = ctx.depth })
                    if not tg.alive then break end
                else
                    self:Hook("onMiss", c, tg, inst.id)
                end
            end
            -- OnHit triggers (per target)
            self:FireTriggers(c, "OnHit", { target = tg, self = c, skillId = inst.id, isBase = isBase,
                flag = (anyCrit and E.DamageFlag.Critical or 0) + (isBase and E.DamageFlag.BaseAttack or 0),
                attrFlag = inst.data.AttrFlag }, ctx.depth + 1)
        end
    end
    ctx.opTargets[opNo] = hitList
    if #hitList > 0 then
        self:FireTriggers(c, "OnAttack", { target = hitList[1], self = c, skillId = ctx.rootSkill or inst.id, isBase = isBase,
            flag = isBase and E.DamageFlag.BaseAttack or 0, attrFlag = inst.data.AttrFlag }, ctx.depth + 1)
    end
end

function Battle:ApplyDot(ctx, tg, ratio, op)
    local c = ctx.caster
    local tick = op.TickTimeMs or 1000
    local dur = op.DurationMs or 5000
    local stateName = op.State and tostring(op.State) or ("dot" .. ctx.inst.id)
    tg:AddState(stateName, dur, c, { debuff = true })
    local token = {}
    tg.dots = tg.dots or {}
    -- one DoT instance per (state, caster); refresh replaces the old one
    local key = stateName .. "#" .. c.id
    tg.dots[key] = token
    local inst = ctx.inst
    local ticks = math.floor(dur / tick)
    for k = 1, ticks do
        self:Schedule(k * tick, function()
            if tg.dots[key] ~= token or not tg.alive or not c.alive then return end
            local stacks = math.max(1, tg:StateCountBy(stateName, c))
            local pct = self:LinePercent(ctx, inst, 0, ratio, tg) * (ctx.dmgScale or 1)
            local dmg, crit, miss = self:ComputeHit(c, tg, { pct = pct * stacks,
                coef = ratio / 10 * (ctx.dmgScale or 1) * stacks, isBase = false }, ctx)
            if not miss then
                self:DealDamage(c, tg, dmg, crit, { skillId = ctx.rootSkill or inst.id, dot = true,
                    flag = E.DamageFlag.Dot, depth = ctx.depth + 1 })
            end
        end)
    end
end

-- 디버프 내성 vs 디버프 내성 무시: a gap of 100 or more reduces debuff duration by 85% (cap).
-- PROVISIONAL: values between 0 and 100 are not published; linear interpolation is used.
function Battle:DebuffReduction(att, tgt)
    local gap = tgt:Stat("DebuffResist") - att:Stat("DebuffResistIgnore")
    if gap <= 0 then return 0 end
    return math.min(0.85, 0.85 * gap / 100)
end

function Battle:Heal(c, amount)
    if not c.alive then return end
    amount = amount * pf(c:Stat("HealPower")) * pf(c:Stat("FinalHpRecoverPower"))
    c.hp = math.min(c:Stat("MaxHp"), c.hp + amount)
    self:Hook("onHeal", c, amount)
end

function Battle:OpModStat(ctx, opNo)
    local inst = ctx.inst
    local o = inst.ops[opNo]
    local op = o.op
    local c = ctx.caster
    local V = op.Values or {}
    local stat = tostring(V[1])
    local kind = (op.Type == "ModStatR") and "ratio" or "add"
    local targets = self:ResolveTargets(ctx, o)
    if op.TargetType == "Parent" and op.ParentOperationNo then
        -- child modifier of a parent op: lives on the parent's targets while its state lasts
        local parent = inst.ops[op.ParentOperationNo] and inst.ops[op.ParentOperationNo].op
        if parent and (parent.Type == "ModStat" or parent.Type == "ModStatR" or parent.Type == "State") then
            targets = self:ResolveTargets(ctx, inst.ops[op.ParentOperationNo])
        end
    end
    local watched = op.WatchOperationNo and inst.ops[op.WatchOperationNo] and inst.ops[op.WatchOperationNo].op
    local duration = op.DurationMs or (watched and watched.DurationMs)
    local stateName = op.State and tostring(op.State)
    local whileState
    if not stateName and (op.ParentOperationNo or op.WatchOperationNo) then
        local p = inst.ops[op.ParentOperationNo or op.WatchOperationNo]
        whileState = p and p.op.State and tostring(p.op.State)
    end
    local dynamic = E.IsExpr(V[2])
    local valueNow = (not dynamic) and self:OpValue(ctx, inst, opNo, 2) or nil
    local permanent = (duration == nil and not stateName and not whileState) or (duration and duration >= 99999999)

    for _, tg in ipairs(targets) do
        if tg.alive then
            local valueFn
            if dynamic then
                local sub = { caster = c, target = tg, inst = inst, trigger = ctx.trigger }
                valueFn = function() return self:OpValue(sub, inst, opNo, 2) end
            end
            local modKey = inst.id .. ":" .. opNo .. ":" .. c.id
            tg.opMods = tg.opMods or {}
            if stateName then
                -- stacking state modifier: one mod per (skill, op, caster), value * stacks
                local isDebuff = tg.side ~= c.side
                tg:AddState(stateName, (duration and duration < 99999999) and duration or nil, c,
                    { buff = not isDebuff, debuff = isDebuff })
                if not tg.opMods[modKey] then
                    local m = tg:AddMod(stat, kind, valueFn or valueNow, modKey)
                    if dynamic then m.whileState = stateName else m.state = stateName end
                    tg.opMods[modKey] = m
                elseif not dynamic then
                    tg.opMods[modKey].value = valueNow
                end
            elseif whileState then
                if not tg.opMods[modKey] then
                    local m = tg:AddMod(stat, kind, valueFn or valueNow, modKey)
                    m.whileState = whileState
                    tg.opMods[modKey] = m
                end
            elseif permanent then
                if not tg.opMods[modKey] then
                    tg.opMods[modKey] = tg:AddMod(stat, kind, valueFn or valueNow, modKey)
                end
            else
                local m = tg:AddMod(stat, kind, valueFn or valueNow, modKey .. ":" .. self.time)
                self:Schedule(duration, function() tg:RemoveMod(m) end)
            end
        end
    end
    ctx.opTargets[opNo] = targets
end

function Battle:OpModStatOnTick(ctx, opNo)
    local inst = ctx.inst
    local op = inst.ops[opNo].op
    local c = ctx.caster
    local V = op.Values or {}
    local stat = tostring(V[1])
    local per = self:OpValue(ctx, inst, opNo, 2)
    local maxTicks = tonumber(V[3]) or 10
    local stateName = tostring(op.State or ("tick" .. inst.id))
    local watched = op.WatchOperationNo and inst.ops[op.WatchOperationNo] and inst.ops[op.WatchOperationNo].op
    local watchState = watched and watched.State and tostring(watched.State)
    local m = c:AddMod(stat, "add", 0, "tick:" .. inst.id)
    local tick = op.TickTimeMs or 1000
    local n = 0
    local function step()
        if not c.alive then return end
        if watchState and c:StateCount(watchState) <= 0 then c:RemoveMod(m) return end
        if n < maxTicks then
            n = n + 1
            m.value = per * n
            c:Dirty()
        end
        self:Schedule(tick, step)
    end
    self:Schedule(op.DelayMs or 0, step)
end

---------------------------------------------------------------------------
-- Projectiles (periodic emitters)
---------------------------------------------------------------------------
function Battle:ProjField(c, pidx, field, base, idx)
    local pm = c.projMods and c.projMods[pidx]
    if not pm then return base end
    local m = pm[field .. (idx and (":" .. idx) or "")] or pm[field]
    return applyMod(base, m)
end

function Battle:ProjectileCount(c, pidx)
    local n = 0
    for _, p in ipairs(self.projectiles) do
        if p.owner == c and p.index == pidx and p.alive then n = n + 1 end
    end
    return n
end

function Battle:CreateProjectile(ctx, pidx)
    local pd = D.Projectiles[pidx]
    if not pd then return end
    local c = ctx.caster
    local maxCount = pd.MaxProjectileCount
    if maxCount and self:ProjectileCount(c, pidx) >= maxCount then
        self:DestroyProjectiles(c, pidx, true)
    end
    local flags = flagSet(pd.Flag)
    local tick = pd.TickTimeMs or {}
    local first = self:ProjField(c, pidx, "TickTimeMs", tick[1] or 0, 0)
    local interval = self:ProjField(c, pidx, "TickTimeMs", tick[2] or tick[1] or 0, 1)
    local p = {
        index = pidx, data = pd, owner = c, alive = true, fired = 0,
        x = (ctx.target and ctx.target.x) or c.x,
        follow = pd.FollowTargetType,
        expireAt = self.time + math.min(pd.DurationTimeMs or 1000, 60 * 60 * 1000),
        nextFire = self.time + math.max(0, first),
        interval = (interval and interval > 0 and interval < 99999999) and interval or nil,
        maxFire = self:ProjField(c, pidx, "MaxFireCount", pd.MaxFireCount or (interval and interval < 99999999 and 9999 or 1)),
        maxTargets = self:ProjField(c, pidx, "MaxTargetCount", pd.MaxTargetCount or 1),
        expireOnDie = flags.ExpireOnCreatureDie,
        ctx = ctx,
        noAuto = (tick[1] == 99999999),
    }
    if p.follow == "Myself" then p.x = c.x end
    self.projectiles[#self.projectiles + 1] = p
    -- child projectiles are created with their parent
    if pd.ChildProjectileIndices then
        for _, child in ipairs(pd.ChildProjectileIndices) do
            if D.Projectiles[child] and not D.Projectiles[child].SkillIndex then
                self:CreateProjectile(ctx, child)
            end
        end
    end
    return p
end

function Battle:FireProjectile(p)
    local c = p.owner
    if not c.alive then p.alive = false return end
    p.fired = p.fired + 1
    local skills = p.data.SkillIndex or {}
    local target
    if p.follow == "CloseCreature" or p.follow == nil then
        target = self:Nearest(c)
        if target then p.x = target.x end
    else
        p.x = c.x
        target = self:Nearest(c)
    end
    for _, sid in ipairs(skills) do
        self:UseSkillNow(c, sid, target, { projectile = p, center = p.x, rootSkill = p.ctx and p.ctx.rootSkill,
            dmgScale = p.ctx and p.ctx.dmgScale }, (p.ctx and p.ctx.depth or 0) + 1)
    end
    if p.fired >= (p.maxFire or 1) then p.alive = false end
end

function Battle:FireProjectileNow(c, pidx, ctx)
    for _, p in ipairs(self.projectiles) do
        if p.owner == c and p.index == pidx and p.alive then
            self:FireProjectile(p)
            return
        end
    end
end

function Battle:DestroyProjectiles(c, pidx)
    for _, p in ipairs(self.projectiles) do
        if p.owner == c and (pidx == nil or pidx == 0 or p.index == pidx) then p.alive = false end
    end
end

function Battle:UpdateProjectiles()
    local now = self.time
    for i = #self.projectiles, 1, -1 do
        local p = self.projectiles[i]
        if p.alive and now >= p.expireAt then p.alive = false end
        if p.alive and not p.noAuto and p.data.SkillIndex and now >= p.nextFire then
            self:FireProjectile(p)
            if p.interval then p.nextFire = now + p.interval else p.nextFire = math.huge end
        end
        if not p.alive then table.remove(self.projectiles, i) end
    end
end

---------------------------------------------------------------------------
-- Skill use
---------------------------------------------------------------------------
function Battle:Resolve(c, sid)
    if c.changeSkill and c.changeSkill[sid] then return c.changeSkill[sid] end
    return sid
end

-- Execute all ops of a skill (immediately or at op delays).
function Battle:UseSkillNow(c, sid, target, parentCtx, depth)
    if not sid or depth > 8 then return end
    sid = self:Resolve(c, sid)
    local inst = self:Inst(c, sid)
    if not inst then return end
    local d = inst.data
    local ctx = {
        caster = c, inst = inst, target = target,
        trigger = parentCtx and parentCtx.trigger,
        opTargets = {}, depth = depth or 0,
        center = parentCtx and parentCtx.center,
        projectile = parentCtx and parentCtx.projectile,
        rootSkill = (parentCtx and parentCtx.rootSkill) or sid,
        dmgScale = parentCtx and parentCtx.dmgScale,
    }
    local ops = inst.ops
    -- ops without delay run in order; delayed ones are scheduled
    local tickMs = (d.TickTimeMs and d.TickTimeMs[1]) or 0
    if type(tickMs) == "string" then tickMs = tonumber(tickMs:match("^%d+")) or 0 end
    local speed = parentCtx and parentCtx.speedScale or 1
    for i = 1, #ops do
        local delay = opDelay(ops[i].op)
        if ops[i].op.Type == "GetDamageR" or ops[i].op.Type == "CreateProjectile" then delay = delay + tickMs end
        delay = math.floor(delay * speed)
        if delay > 0 and not (parentCtx and parentCtx.immediate) then
            self:Schedule(delay, function()
                if c.alive then self:ExecOp(ctx, i) end
            end)
        else
            self:ExecOp(ctx, i)
        end
    end
    -- servant copies (e.g. shadow servant repeats the owner's attacks)
    if c.servantSkills and c.servantSkills[sid] then
        local s = c.servantSkills[sid]
        if not s.state or c:StateCount(s.state) > 0 then
            self:Schedule(150, function()
                if c.alive then
                    self:UseSkillNow(c, s.skill, target, { dmgScale = (s.ratio or 1000) / 1000, rootSkill = sid }, (depth or 0) + 1)
                end
            end)
        end
    end
    return ctx
end

function Battle:FireTriggers(c, ttype, trig, depth)
    if depth > MAX_TRIGGER_DEPTH or not c.alive then return end
    local list = c.triggers[ttype]
    if not list then return end
    for _, inst in ipairs(list) do
        local d = inst.data
        local ok = true
        if ttype == "OnActiveSkill" or ttype == "OnAttack" then
            -- passives do not trigger on their own hits
            if trig.skillId == inst.id then ok = false end
        end
        if ok and d.TriggerCondition then
            ok = E.Bool(d.TriggerCondition, newEnv(self, { caster = c, target = trig.target, inst = inst, trigger = trig }))
        end
        if ok then
            local ratio = d.TriggerRatio or 1000
            if type(ratio) == "string" then
                ratio = E.Num(ratio, newEnv(self, { caster = c, target = trig.target, inst = inst, trigger = trig }))
            end
            ratio = self:SkillField(inst, "SkillTriggerRatio", ratio)
            local cdLeft = c.cooldowns[inst.id]
            if (not cdLeft or cdLeft <= 0) and self.rng:ChanceM(ratio) then
                if d.CoolTimeMs then c.cooldowns[inst.id] = self:SkillField(inst, "SkillCoolTimeMs", d.CoolTimeMs) end
                local target = trig.target
                if d.SkillTargetType == "Enemy" or d.SkillTargetType == "RandomEnemy" then
                    if not target or target.side == c.side or not target.alive then target = self:Nearest(c) end
                end
                self:UseSkillNow(c, inst.id, target, { trigger = trig }, depth)
            end
        end
    end
end

function Battle:OnStateChanged(c, name, added)
    if self.inStateTrigger then return end
    self.inStateTrigger = true
    if c.triggers and c.alive then
        if added then
            self:FireTriggers(c, "OnState", { self = c, target = c, stateName = name }, 1)
        else
            self:FireTriggers(c, "OnStateEnd", { self = c, target = c, stateName = name }, 1)
        end
    end
    self.inStateTrigger = false
end

---------------------------------------------------------------------------
-- Creature AI
---------------------------------------------------------------------------
local function rangeFront(d)
    local r = d.MaxRangeMm
    if type(r) == "table" then return r[1] or 3000 end
    return 3000
end

function Battle:CooldownFor(c, inst)
    local base = self:SkillField(inst, "SkillCoolTimeMs", inst.data.CoolTimeMs or 0)
    if base <= 0 then return 0 end
    -- % reduction first, then the flat reduction; below 7 s each second of flat
    -- reduction only counts half and the result never drops under 4 s
    local cdr = c:Stat("CoolTimeReduceRatio")
    local v = base * (1000 - cdr) / 1000
    local flat = c:Stat("CoolTimeReduce")
    if flat > 0 and v > 4000 then
        local above = math.max(0, v - 7000)
        if flat <= above then
            v = v - flat
        else
            v = math.min(v, 7000) - (flat - above) * 0.5
            if v < 4000 then v = 4000 end
        end
    end
    return math.max(0, trunc(v))
end

function Battle:CanCast(c, inst, target)
    local d = inst.data
    if (c.cooldowns[inst.id] or 0) > 0 then return false end
    local flags = inst.flags
    if flags.NoAutoUse then return false end
    if d.Mp and d.Mp > 0 then
        local cost = d.Mp * pf(c:Stat("MpConsumeRatio"))
        if c.mp < cost then return false end
    end
    if d.TriggerCondition then
        if not E.Bool(d.TriggerCondition, newEnv(self, { caster = c, target = target, inst = inst })) then return false end
    end
    if d.AutoTriggerCondition then
        if not E.Bool(d.AutoTriggerCondition, newEnv(self, { caster = c, target = target, inst = inst })) then return false end
    end
    if d.SkillTargetType == "Enemy" or d.SkillTargetType == "RandomEnemy" or d.SkillTargetType == "MinStatEnemy" then
        if not target then return false end
        local dist = math.abs(target.x - c.x)
        if dist > rangeFront(d) + target.radius then return false end
    end
    return true
end

function Battle:Cast(c, inst, target, isBasic)
    local d = inst.data
    if d.Mp and d.Mp > 0 then
        local cost = d.Mp * pf(c:Stat("MpConsumeRatio"))
        c.mp = math.max(0, c.mp - cost)
    end
    local duration = d.DurationTimeMs or 1000
    local speedScale = 1
    if isBasic then
        local as = math.min(1500, c:Stat("AttackSpeed"))
        speedScale = 1000 / (1000 + as)
        duration = duration * speedScale
    end
    if target then c.facing = (target.x >= c.x) and 1 or -1 end
    -- time that ran past the previous cast of the same skill carries over (official guide 4.1)
    if c.castSkill == inst.id and c.castUntil and self.time - c.castUntil < Battle.TICK then
        duration = math.max(0, duration - (self.time - c.castUntil))
    end
    c.castSkill = inst.id
    c.castUntil = self.time + math.max(50, duration)
    c.castCanMove = inst.flags.CanMoveWhileUse
    if not isBasic then
        c.cooldowns[inst.id] = self:CooldownFor(c, inst)
    end
    inst.isBasic = isBasic
    self:Hook("onCast", c, inst.id, isBasic, target)
    if not isBasic then
        self:FireTriggers(c, "OnActiveSkill", { self = c, target = target, skillId = inst.id }, 1)
    end
    self:FireTriggers(c, "OnTryAttack", { self = c, target = target, skillId = inst.id, isBase = isBasic }, 1)
    self:UseSkillNow(c, inst.id, target, { speedScale = speedScale, rootSkill = inst.id }, 0)
end

function Battle:HeroThink(c, dt)
    if c:IsCC() then return end
    local target, dist = self:Nearest(c)
    local casting = c.castUntil and c.castUntil > self.time
    if not casting then
        -- buffs (self target) whenever enemies are around
        for _, inst in ipairs(c.activeList) do
            local d = inst.data
            local tgt = (d.SkillTargetType == "Myself" or d.SkillTargetType == "Ally") and c or target
            if target and self:CanCast(c, inst, tgt) then
                self:Cast(c, inst, tgt, false)
                return
            end
        end
        local basic = c.basicSkill
        if basic and target then
            local resolved = self:Inst(c, self:Resolve(c, basic.id)) or basic
            if dist <= rangeFront(resolved.data) + target.radius then
                self:Cast(c, resolved, target, true)
                return
            end
        end
    end
    -- movement toward the nearest enemy when out of basic range
    if target and (not casting or c.castCanMove) then
        local reach = c.basicSkill and rangeFront(c.basicSkill.data) or 1500
        if dist > reach * 0.8 then
            local speed = (c:Stat("RunSpeedMms") > 0) and c:Stat("RunSpeedMms") or 3000
            local step = speed * dt / 1000
            c.facing = (target.x >= c.x) and 1 or -1
            c.x = c.x + math.min(step, dist - reach * 0.6) * c.facing
        end
    end
end

-- simple monster AI: walk to the nearest hostile and hit it
function Battle:MonsterThink(c, dt)
    if c:IsCC() then return end
    local target, dist = self:Nearest(c)
    if not target then return end
    -- field monsters stay put until the hero comes close or hits them
    if c.def.aggroMm and not c.aggro then
        if dist > c.def.aggroMm then return end
        c.aggro = true
    end
    c.facing = (target.x >= c.x) and 1 or -1
    local reach = c.def.reachMm or 600
    if dist > reach then
        if not c.def.stationary then
            local step = (c.def.speedMms or 900) * dt / 1000
            c.x = c.x + math.min(step, dist - reach * 0.9) * c.facing
        end
        return
    end
    c.nextAttack = c.nextAttack or (self.time + (c.def.firstAttackMs or 800))
    if self.time >= c.nextAttack then
        c.nextAttack = self.time + (c.def.attackIntervalMs or 2000)
        self:MonsterAttack(c, target)
    end
end

function Battle:MonsterAttack(c, target)
    -- miss check: monster hit vs hero avoid
    local gap = target:Stat("AvoidChance") - c:Stat("HitChance")
    if gap > 0 then
        local miss = D.Combat.missPermilleByGap[math.min(100, gap)] or 700
        if self.rng:Float() * 1000 < miss then
            self:Hook("onMiss", c, target, 0)
            return
        end
    end
    local atk = c:Stat("Attack")
    local def = math.max(0, trunc(target:Stat("Defence")))
    local dmg = atk
    if def > 0 then dmg = dmg * D.Combat.defNumerator / (def + D.Combat.defOffset) end
    dmg = dmg * (1 - math.min(950, target:Stat("Toughness")) / 1000)
    dmg = math.max(1, math.floor(dmg))
    self:DealDamage(c, target, dmg, false, { skillId = 0, flag = 0, depth = 0, monster = true })
end

---------------------------------------------------------------------------
-- Main loop
---------------------------------------------------------------------------
function Battle:Step()
    if self.ended then return end
    local dt = Battle.TICK
    self.time = self.time + dt
    local now = self.time

    -- scheduled events
    if #self.events > 0 then
        local due = {}
        for i = #self.events, 1, -1 do
            local ev = self.events[i]
            if ev.at <= now then
                due[#due + 1] = ev
                table.remove(self.events, i)
            end
        end
        table.sort(due, function(a, b) return a.at < b.at end)
        for _, ev in ipairs(due) do
            local ok, err = pcall(ev.fn)
            if not ok and ns.Debug then ns.Debug("event: %s", tostring(err)) end
        end
    end

    for _, c in ipairs(self.creatures) do
        if c.alive then
            c:UpdateStates(now)
            -- cooldowns (100 ms progress scaled by CoolTimeSpeed)
            local speed = 1 + c:Stat("CoolTimeSpeed") / 1000
            for id, rem in pairs(c.cooldowns) do
                if rem > 0 then c.cooldowns[id] = rem - dt * speed end
            end
            -- OnTimer passives
            local timers = c.triggers["OnTimer"]
            if timers then
                for _, inst in ipairs(timers) do
                    if inst.nextTimer and now >= inst.nextTimer then
                        if inst.timerExpr then
                            inst.timerInterval = math.max(50, E.Num(inst.timerExpr, newEnv(self, { caster = c, inst = inst, target = c })))
                        end
                        inst.nextTimer = now + (inst.timerInterval or 1000)
                        local ratio = inst.data.TriggerRatio or 1000
                        if type(ratio) ~= "number" then ratio = 1000 end
                        local ok = true
                        if inst.data.TriggerCondition then
                            ok = E.Bool(inst.data.TriggerCondition, newEnv(self, { caster = c, target = c, inst = inst }))
                        end
                        if ok and self.rng:ChanceM(ratio) then
                            self:UseSkillNow(c, inst.id, self:Nearest(c) or c, { trigger = { self = c } }, 1)
                        end
                    end
                end
            end
            -- MP regeneration + potions
            if c.isHero then
                local maxMp = c:Stat("MaxMp")
                c.mp = math.min(maxMp, c.mp + (c:Stat("MpRegen") * (1 + c:Stat("MpRegenRatio") / 1000)) * dt / 1000)
                self:Potions(c)
            end
        end
    end

    self:UpdateProjectiles()

    for _, c in ipairs(self.creatures) do
        if c.alive then
            if c.isHero or c.isSupporter then
                self:HeroThink(c, dt)
            else
                self:MonsterThink(c, dt)
            end
        end
    end

    if self.opts.controller and self.opts.controller.Update then
        self.opts.controller:Update(self, dt)
    end

    if self.timeLimit and now >= self.timeLimit then
        self:End("timeout")
    end
end

-- Auto potions (client potion values are not in the extracted data:
-- HpPotionPower / MpPotionPower and the cooldown stats scale these defaults).
Battle.POTION = { hpThreshold = 500, mpThreshold = 300, hpRatio = 300, mpRatio = 300, cooldownMs = 10000 }

-- content potion rules (official guide 2.4): Arena / Colosseum / World Arena HP 10%, MP 80%;
-- 자쿰·혼테일 raids: HP potion cooldown 30 s, then the cooldown reduction applies
Battle.POTION_RULES = {
    Arena = { hp = 0.1, mp = 0.8 }, Colosseum = { hp = 0.1, mp = 0.8 }, WorldArena = { hp = 0.1, mp = 0.8 },
}

function Battle:Potions(c)
    local P = Battle.POTION
    local rule = Battle.POTION_RULES[self.dungeonType] or {}
    local hpCd = P.cooldownMs
    if self.dungeonType == "BossRaid" and self:SqrtContent() then hpCd = 30000 end
    c.hpPotionReady = c.hpPotionReady or 0
    c.mpPotionReady = c.mpPotionReady or 0
    if c:HpRatioM() < P.hpThreshold and self.time >= c.hpPotionReady then
        self:Heal(c, c:Stat("MaxHp") * P.hpRatio / 1000 * pf(c:Stat("HpPotionPower")) * (rule.hp or 1))
        c.hpPotionReady = self.time + hpCd * (1 - c:Stat("HpPotionCoolTimeReduceRatio") / 1000)
    end
    if c:MpRatioM() < P.mpThreshold and self.time >= c.mpPotionReady then
        c.mp = math.min(c:Stat("MaxMp"), c.mp + c:Stat("MaxMp") * P.mpRatio / 1000 * pf(c:Stat("MpPotionPower")) * (rule.mp or 1))
        c.mpPotionReady = self.time + P.cooldownMs * (1 - c:Stat("MpPotionCoolTimeReduceRatio") / 1000)
    end
end

-- a new wave of enemies appeared (artifacts / passives with OnWaveStart)
function Battle:WaveStart()
    for _, c in ipairs(self.creatures) do
        if c.alive and c.side == 1 then
            self:FireTriggers(c, "OnWaveStart", { self = c, target = self:Nearest(c) or c }, 1)
        end
    end
end

function Battle:End(reason)
    if self.ended then return end
    self.ended = true
    self.endReason = reason
    self:Hook("onEnd", reason)
end

-- run headless until end or maxMs
function Battle:RunFor(ms)
    local stop = self.time + ms
    while not self.ended and self.time < stop do self:Step() end
end

function Battle:Remove(c)
    for i = #self.creatures, 1, -1 do
        if self.creatures[i] == c then table.remove(self.creatures, i) end
    end
end

function Battle:Cleanup()
    for i = #self.creatures, 1, -1 do
        local c = self.creatures[i]
        if not c.alive and not c.isHero then table.remove(self.creatures, i) end
    end
end
