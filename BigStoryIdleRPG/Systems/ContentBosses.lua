-- 월드보스, 보스 레이드 (자쿰 / 혼테일 / 핑크빈), 길드 레이드 3종, 마왕 발록 (신규 용사 성장 챌린지).
-- Numbers: Data/Content.lua (client 1.18.0 boss.html tables, KR rules research-progression §10-§11,
-- research-income §2.14 / §3.8 / §6.1 / §6.4, drops items-gacha dropTables).
--
-- Party content is entered solo: party mode = player + 3 AI allies,
-- 마왕 발록 group = player + 3 AI allies (group size PROVISIONAL).
--
-- API
--   ns.Content.WorldBoss: W.Enter(hero, level) ; W.TierFor(score) -> tierRow, index ; W.Settle(hero, "daily"|"weekly")
--   ns.Content.Raid:      R.Enter(hero, boss, diffIndex, mode ("party"|"single"), { challenge, double })
--                         R.Sweep(hero, boss, diffIndex, double) ; R.Entries(hero, boss) ; R.BuyTicket(hero)
--                         R.RollReward(boss, diffIndex, rng) -> rewards
--   ns.Content.Balrog:    BL.Enter(hero, stage)
local ADDON, ns = ...
local U = ns.U
local D = ns.Data
local Hero = ns.Hero
local C = ns.Content

local F = U.FormatNumber

---------------------------------------------------------------------------
-- World boss
---------------------------------------------------------------------------
local W = {}
C.WorldBoss = W
local WD = D.ContentWorldBoss

-- PROVISIONAL: tiers are server-wide rankings in the original. Here the player's best score of the
-- day / week maps to a tier by thresholds: 브론즈1 = any score, 실버1 .. 챌린저1 = reaching the
-- cumulative max HP of levels 1..19, 챔피언3/2/1 = Lv20 damage >= 1x / 2x / 4x its nominal HP.
-- (The arena developer may replace this with addon-user rankings.)
W.PROVISIONAL_TIERS = true
local cumHp = { [0] = 0 }
for i, lv in ipairs(WD.levels) do cumHp[i] = cumHp[i - 1] + lv.hp end
W.thresholds = {}   -- [tierIndex] = min score (tier 1 = 챔피언1)
do
    local n = #WD.tiers
    W.thresholds[n] = 1
    for i = 1, 19 do W.thresholds[n - i] = cumHp[i] end
    local hp20 = WD.levels[20].hp
    W.thresholds[3] = cumHp[19] + hp20
    W.thresholds[2] = cumHp[19] + hp20 * 2
    W.thresholds[1] = cumHp[19] + hp20 * 4
end

function W.TierFor(score)
    if not score or score <= 0 then return nil end
    for i = 1, #WD.tiers do
        if score >= W.thresholds[i] then return WD.tiers[i], i end
    end
end

-- PROVISIONAL: entry count is not in the data -> unlimited attempts (only the best score counts).
W.DAILY_ENTRIES = nil

C.RegisterState("worldBoss", {
    init = function(hero, ct)
        ct.worldBoss = ct.worldBoss or { max = 0, best = 0, dayBest = 0, weekBest = 0, runs = 0 }
    end,
    daily = function(hero, ct) W.Settle(hero, "daily") end,
    weekly = function(hero, ct) W.Settle(hero, "weekly") end,
})

-- settlement at 00:00 (daily coins) and Monday 00:00 (weekly coins + 미라클 큐브)
function W.Settle(hero, which)
    local s = hero.content.worldBoss
    local score = which == "daily" and s.dayBest or s.weekBest
    local tier = W.TierFor(score)
    local rewards
    if tier then
        rewards = {}
        if which == "daily" then
            rewards.worldBossCoin = tier.daily
        else
            rewards.worldBossCoin = tier.weekly
            if tier.cubes > 0 then rewards.cubeMiracle = tier.cubes end
        end
        C.Grant(hero, rewards, "worldBoss" .. which)
    end
    s["last" .. which] = { tier = tier and tier.name, score = score, rewards = rewards, at = U.Now() }
    if which == "daily" then s.dayBest = 0 else s.weekBest = 0 end
end

function W.Score(level, damage, killed)
    local lv = WD.levels[level]
    local d = damage
    if not lv.infinite then d = killed and lv.hp or math.min(lv.hp, damage) end
    return cumHp[level - 1] + d
end

local WFight = C.Proto()

function WFight:Setup(b)
    local lv = WD.levels[self.level]
    local hc = b.heroCreature
    local model, name = C.Look("worldBoss", nil, WD.monsterKo)
    self.boss = self:Spawn(b, { name = name, hp = lv.hp, atk = lv.atk, def = lv.def, hit = lv.hit, avoid = lv.avoid,
        boss = true, x = (hc and hc.x or 0) + WD.initialDistanceMm, model = model, infinite = lv.infinite,
        speed = 400, level = self.level })
    local p = WD.patterns
    self.phase0 = b.rng:Int(p.untargetable.startMinMs, p.untargetable.startMaxMs)
    self.downOffset = p.down.startMinMs - p.untargetable.startMinMs
end

function WFight:Tick(b, dt)
    local boss = self.boss
    if not boss.alive then b:End("clear") return end
    local p = WD.patterns
    local t = b.time - self.phase0
    local untarget, down = false, false
    if t >= 0 then
        local k = t % p.untargetable.intervalMs
        untarget = k < p.untargetable.durationMs
        down = k >= self.downOffset and k < self.downOffset + p.down.durationMs
    end
    -- PROVISIONAL simplification: the client lets basic attacks hit during 공격 불가; here the boss is untargetable
    boss.untargetable = untarget or nil
    if down and not self.downMods then
        self.downMods = {
            { c = boss, m = boss:AddMod("Weakness", "add", p.down.weaknessPct * 10, "wbDown") },
            { c = boss, m = boss:AddMod("Defence", "ratio", -math.floor((1 - p.down.defenceRatio) * 1000), "wbDown") },
        }
        if self.level < 10 then   -- player attack speed +100% while down (dungeon index < 10)
            for _, c in ipairs(self:SideOne(b)) do
                table.insert(self.downMods, { c = c, m = c:AddMod("AttackSpeed", "add", 1000, "wbDown") })
            end
        end
    elseif not down and self.downMods then
        for _, e in ipairs(self.downMods) do e.c:RemoveMod(e.m) end
        self.downMods = nil
    end
end

function WFight:UpdateTitle(b)
    self.title = string.format("월드보스 %d단계 · 피해 %s", self.level, F(self.heroDamage))
end

function WFight:Finish(b, reason)
    local hero = self.hero
    local s = hero.content.worldBoss
    local killed = reason == "clear"
    if reason == "fail" and self.heroDamage <= 0 then
        return C.Result(false, reason, string.format("월드보스 %d단계 실패", self.level))
    end
    local score = W.Score(self.level, self.heroDamage, killed)
    s.runs = (s.runs or 0) + 1
    if killed and self.level > s.max then s.max = self.level end
    s.dayBest = math.max(s.dayBest or 0, score)
    s.weekBest = math.max(s.weekBest or 0, score)
    s.best = math.max(s.best or 0, score)
    local tier = W.TierFor(s.dayBest)
    local ok = killed or WD.levels[self.level].infinite
    return C.Result(ok, reason, string.format("월드보스 %d단계 %s · 점수 %s", self.level,
        killed and "처치" or (C.REASON_KO[reason] or reason), F(score)),
        { string.format("오늘 최고 %s (%s)", F(s.dayBest), tier and tier.name or "-") }, { score = score })
end

function W.Enter(hero, level)
    local s = hero.content.worldBoss
    level = level or math.min(#WD.levels, s.max + 1)
    if level < 1 or level > #WD.levels then return nil, "잘못된 단계입니다." end
    if level > s.max + 1 then return nil, "이전 단계를 먼저 처치하세요." end
    local lv = WD.levels[level]
    local _, _, bg = C.Look("worldBoss")
    local ctl = C.NewFight(WFight, { kind = "worldBoss", modeKey = "worldBoss", level = level,
        timeLimit = lv.time * 1000, dungeonType = WD.dungeonType, background = bg, title = "월드보스 " .. level .. "단계" })
    return C.Start(hero, ctl)
end

C.RegisterMode("worldBoss", {
    order = 30, group = "보스", title = "월드보스",
    selectors = {
        { key = "level", label = "단계", min = 1,
          max = function(hero) return math.min(#WD.levels, hero.content.worldBoss.max + 1) end,
          default = function(hero) return math.min(#WD.levels, hero.content.worldBoss.max + 1) end },
    },
    info = function(hero, sel)
        local s = hero.content.worldBoss
        local lv = WD.levels[sel.level or 1]
        local dt, dti = W.TierFor(s.dayBest)
        local wt = W.TierFor(s.weekBest)
        local lines = {
            string.format("%s %d단계: HP %s%s · 공격력 %s · 방어력 %s · 회피 %d · %d초", WD.monsterKo, sel.level or 1,
                F(lv.hp), lv.infinite and " (무한)" or "", F(lv.atk), F(lv.def), lv.avoid, lv.time),
            string.format("최고 처치 단계 %d · 오늘 최고 %s (%s) · 주간 최고 %s (%s)", s.max, F(s.dayBest),
                dt and dt.name or "-", F(s.weekBest), wt and wt.name or "-"),
        }
        if dt then
            lines[#lines + 1] = string.format("일일 정산 예정: 월드보스 코인 %s", U.Comma(dt.daily))
        end
        if wt then
            lines[#lines + 1] = string.format("주간 정산 예정: 월드보스 코인 %s%s", U.Comma(wt.weekly),
                wt.cubes > 0 and (" · 미라클 큐브 " .. wt.cubes) or "")
        end
        lines[#lines + 1] = "|cff999999티어 = 개인 최고 점수 기준 임시 구간 (원본은 서버 순위)|r"
        return lines
    end,
    actions = { { label = "도전", fn = function(hero, sel) local b, e = W.Enter(hero, sel.level); return b ~= nil, e end } },
})

---------------------------------------------------------------------------
-- Multi-part boss fight (boss raids)
---------------------------------------------------------------------------
-- spec = { kind = "zakum"|"horntail"|"pinkbean", primary, part, partCount, atk, def, avoid, hit,
--          persist = table (remaining HP per target carried over), statues..., names }
local PartFight = C.Proto()
C.PartFight = PartFight

-- PROVISIONAL interpretations (the data lists HP per part only):
--   자쿰: the body is untargetable until the 8 arms are destroyed (classic Zakum rule); clear = body.
--   혼테일: 8 spike parts; clear = all parts destroyed ("보스 판정 HP" is shown, not a separate target).
PartFight.ARM_SPREAD = 1600

function PartFight:Setup(b)
    local sp = self.spec
    local hc = b.heroCreature
    local x0 = (hc and hc.x or 0) + 2600
    local model, name = C.Look("raids", sp.kind, sp.nameKo)
    self.parts = {}
    local persist = sp.persist
    local level = self.profile and self.profile.level or 1
    if sp.kind == "pinkbean" then return self:SetupPinkBean(b, x0, model, name) end
    for i = 1, sp.partCount do
        local hp = sp.part
        local remain = persist and persist.parts and persist.parts[i]
        if remain == nil or remain > 0 then
            local c = self:Spawn(b, { name = string.format("%s (%s %d)", name, sp.partLabelShort or "부위", i),
                hp = hp, atk = sp.atk, def = sp.def, hit = sp.hit, avoid = sp.avoid, boss = true, stationary = true,
                x = x0 - self.ARM_SPREAD / 2 + (i - 1) * self.ARM_SPREAD / math.max(1, sp.partCount - 1),
                model = model, level = level, reach = 1500 })
            c.partIndex = i
            if remain then c.hp = remain end
            self.parts[#self.parts + 1] = c
        end
    end
    if sp.kind == "zakum" then
        local remain = persist and persist.body
        if remain == nil or remain > 0 then
            self.body = self:Spawn(b, { name = name, hp = sp.primary, atk = sp.atk, def = sp.def, hit = sp.hit,
                avoid = sp.avoid, boss = true, stationary = true, x = x0, model = model, level = level, reach = 1800,
                radius = 700, untargetable = true })
            if remain then self.body.hp = remain end
        end
    end
end

function PartFight:PartsAlive()
    local n = 0
    for _, c in ipairs(self.parts) do if c.alive then n = n + 1 end end
    return n
end

function PartFight:Tick(b, dt)
    local sp = self.spec
    if sp.kind == "pinkbean" then return self:TickPinkBean(b, dt) end
    if sp.kind == "zakum" then
        if self.body and self.body.untargetable and self:PartsAlive() == 0 then self.body.untargetable = nil end
        if (not self.body or not self.body.alive) and self:PartsAlive() == 0 then b:End("clear") end
    else
        if self:PartsAlive() == 0 then b:End("clear") end
    end
end

-- 핑크빈 ----------------------------------------------------------------------
function PartFight:SetupPinkBean(b, x0, model, name)
    local sp = self.spec
    local level = self.profile and self.profile.level or 1
    self.seals = sp.persist and sp.persist.seals or 0
    self.statues = {}
    for i, sname in ipairs(sp.statues) do
        local maxHp = self:StatueMaxHp(true)
        local c = self:Spawn(b, { name = sname, hp = maxHp, atk = sp.atk, def = sp.def, hit = sp.hit, avoid = sp.avoid,
            boss = true, stationary = true, x = x0 - 1600 + (i - 1) * 800, model = model, level = level, reach = 1500,
            noDie = true })
        c.statueName = sname
        self.statues[i] = c
    end
    local remain = sp.persist and sp.persist.body
    self.body = self:Spawn(b, { name = name, hp = sp.bodyHp, atk = sp.atk, def = sp.def, hit = sp.bodyHit or sp.hit,
        avoid = sp.avoid, boss = true, stationary = true, x = x0, model = model, level = level, reach = 1800,
        radius = 700, untargetable = true })
    if remain then self.body.hp = remain end
    self.bodyAppearAt = nil
end

-- statue max HP: first wake = base x firstWakeHpRatio; after the n-th shared seal = base x growth^(n-1)
function PartFight:StatueMaxHp(firstWake)
    local sp = self.spec
    if firstWake and self.seals == 0 then return math.floor(sp.statueBaseHp * sp.firstWakeHpRatio) end
    return math.floor(sp.statueBaseHp * sp.statueHpGrowth ^ math.max(0, self.seals - 1))
end

function PartFight:SetStatueMax(c, maxHp)
    c.statsDef.adds.MaxHp = maxHp
    c:Dirty()
end

function PartFight:Seal(b, c)
    local sp = self.spec
    self.seals = self.seals + 1
    c.sealedUntil = b.time + sp.sealSec * 1000
    c.untargetable = true
    c.stunUntil = c.sealedUntil
    c:AddState("Stun", sp.sealSec * 1000, nil, { cc = true })
    -- seal buff for the whole party
    local buff = sp.sealBuffs and sp.sealBuffs[c.statueName]
    if buff then
        for _, a in ipairs(self:SideOne(b)) do
            for _, st in ipairs(buff.stats or {}) do
                if st[1] ~= "CcImmune" then
                    local m = a:AddMod(st[1], "add", st[2], "pbSeal")
                    b:Schedule(buff.sec * 1000, function() a:RemoveMod(m) end)
                end
            end
        end
        self.lastBuff = c.statueName
    end
    -- other statues: max HP grows with the shared seal count, healed 58~62% of max HP
    for _, o in ipairs(self.statues) do
        if o ~= c and not o.sealedUntil then
            self:SetStatueMax(o, self:StatueMaxHp(false))
            local heal = o:Stat("MaxHp") * (sp.healOnSealMin + (sp.healOnSealMax - sp.healOnSealMin) * b.rng:Float())
            o.hp = math.min(o:Stat("MaxHp"), o.hp + heal)
        end
    end
    if self.seals == 1 then self.bodyAppearAt = b.time + sp.bodyAppearMs end
    if self.seals >= 2 and sp.groggySec then self.groggyUntil = b.time + sp.groggySec * 1000 end
end

function PartFight:TickPinkBean(b, dt)
    local sp = self.spec
    for _, c in ipairs(self.statues) do
        if c.alive and not c.sealedUntil and c.hp <= 1 then
            self:Seal(b, c)
        elseif c.sealedUntil and b.time >= c.sealedUntil then
            -- wakes up with the current max HP
            c.sealedUntil = nil
            c.untargetable = nil
            self:SetStatueMax(c, self:StatueMaxHp(false))
            c.hp = c:Stat("MaxHp")
        end
    end
    local body = self.body
    if self.bodyAppearAt and b.time >= self.bodyAppearAt and body.untargetable then
        body.untargetable = nil
    end
    -- Pink Bean body damage reduction 0% at 100% HP rising to 95% at 5% HP (re-evaluated every 0.5 s),
    -- groggy: damage taken x(2 - reduction) for 10 s
    if sp.bodyReduction and body.alive and (not self.nextRed or b.time >= self.nextRed) then
        self.nextRed = b.time + (sp.bodyReductionCheckMs or 500)
        local ratio = body.hp / math.max(1, body:Stat("MaxHp"))
        local red = math.min(sp.bodyReductionMaxPct / 100, math.max(0, 1 - ratio))
        local groggy = self.groggyUntil and b.time < self.groggyUntil
        if self.redMod then body:RemoveMod(self.redMod) end
        if self.weakMod then body:RemoveMod(self.weakMod); self.weakMod = nil end
        if groggy then
            self.redMod = body:AddMod("Toughness", "add", 0, "pbRed")
            self.weakMod = body:AddMod("Weakness", "add", math.floor((1 - red) * 1000), "pbRed")
        else
            self.redMod = body:AddMod("Toughness", "add", math.floor(red * 1000), "pbRed")
        end
    end
    if not body.alive then b:End("clear") end
end

function PartFight:Snapshot()
    local s = { parts = {}, seals = self.seals }
    for _, c in ipairs(self.parts or {}) do s.parts[c.partIndex] = c.alive and c.hp or 0 end
    if self.body then s.body = self.body.alive and self.body.hp or 0 end
    return s
end

function PartFight:UpdateTitle(b)
    local sp = self.spec
    local prog
    if sp.kind == "pinkbean" then
        prog = string.format("봉인 %d · 본체 %d%%", self.seals or 0,
            math.floor(100 * math.max(0, self.body.hp) / math.max(1, self.body:Stat("MaxHp"))))
    else
        prog = string.format("%s %d/%d", sp.partLabelShort or "부위", #self.parts - self:PartsAlive(), #self.parts)
    end
    local deaths = self.teamDeaths and string.format(" · 사망 %d/%d", self.deaths, self.teamDeaths) or ""
    self.title = string.format("%s · %s%s", self.baseTitle or sp.nameKo, prog, deaths)
end

---------------------------------------------------------------------------
-- Boss raids
---------------------------------------------------------------------------
local R = {}
C.Raid = R
local RD = D.ContentRaids
R.BOSSES = { "zakum", "horntail", "pinkbean" }
R.MODE_KO = { party = "파티", single = "싱글" }
R.PART_SHORT = { zakum = "팔", horntail = "가시", pinkbean = "석상" }

-- PROVISIONAL: party-mode time / death limits of 자쿰 and 혼테일 are not in the data (only 핑크빈 has
-- 480 s / team 15); single mode uses 8 revives for every boss (KR 9/3). Time limits fall back to 480 s.
R.DEFAULT_TIME = 480
R.DEFAULT_TEAM_DEATHS = 15
-- PROVISIONAL: unlocks missing from the data (혼테일 보통+). 자쿰/핑크빈/혼테일 쉬움 are data.
R.UNLOCK_PROVISIONAL = { horntail = { [2] = { 31, 15 }, [3] = { 36, 15 }, [4] = { 41, 20 } } }

C.RegisterState("raids", {
    init = function(hero, ct)
        ct.raids = ct.raids or { refills = 0 }
        for _, k in ipairs(R.BOSSES) do
            ct.raids[k] = ct.raids[k] or { entries = RD.rules.weeklyPerBoss, cleared = {}, clears = 0 }
        end
        if not ct.raidTicketsGiven then
            ct.raidTicketsGiven = true
            C.Recharge(hero, "bossRaidTicket", RD.rules.weeklyShared, RD.rules.weeklyShared)
        end
    end,
    weekly = function(hero, ct)
        for _, k in ipairs(R.BOSSES) do
            ct.raids[k].entries = math.max(ct.raids[k].entries or 0, RD.rules.weeklyPerBoss)
        end
        ct.raids.refills = 0
        C.Recharge(hero, "bossRaidTicket", RD.rules.weeklyShared, RD.rules.weeklyShared)
    end,
})

function R.Unlock(boss, diffIndex)
    local u = RD.rules.unlocks[boss] and RD.rules.unlocks[boss][diffIndex]
    if u then return u[1], u[2], false end
    u = R.UNLOCK_PROVISIONAL[boss] and R.UNLOCK_PROVISIONAL[boss][diffIndex]
    if u then return u[1], u[2], true end
end

function R.IsUnlocked(hero, boss, diffIndex)
    local ch, st = R.Unlock(boss, diffIndex)
    if not ch then return true end
    return C.StageReached(hero, ch, st), C.GateText(ch, st)
end

function R.Entries(hero, boss)
    return hero.content.raids[boss].entries or 0, Hero.Count(hero, "bossRaidTicket")
end

local function spendEntries(hero, boss, n)
    local st = hero.content.raids[boss]
    local base, shared = R.Entries(hero, boss)
    if base + shared < n then return false end
    local useBase = math.min(base, n)
    st.entries = base - useBase
    if n - useBase > 0 then Hero.Spend(hero, "bossRaidTicket", n - useBase, "bossRaid") end
    return true
end

-- one reward pick: equipment (data %) / scroll (data %) / fallback (71%, KR 9/3 amounts)
function R.RollReward(boss, diffIndex, rng, single)
    local dd = RD[boss].difficulties[diffIndex]
    local rows = {}
    for _, g in ipairs(dd.drops) do rows[#rows + 1] = { permille = g.permille, gear = g } end
    for _, s in ipairs(dd.scrolls) do rows[#rows + 1] = { permille = s.permille, key = s.key, n = 1 } end
    for _, f in ipairs(RD.rules.fallback) do rows[#rows + 1] = { permille = f.permille, key = f.key, n = f.n } end
    local pick = C.PickPermille(rows, rng)
    local out = {}
    if pick and pick.gear then
        out.gear = { { code = pick.gear.code, name = pick.gear.item, source = "bossRaid", single = single } }
    elseif pick then
        out[pick.key] = pick.n
    end
    return out
end

local function mergeRewards(a, b)
    for k, v in pairs(b) do
        if k == "gear" then
            a.gear = a.gear or {}
            for _, g in ipairs(v) do a.gear[#a.gear + 1] = g end
        else
            C.AddReward(a, k, v)
        end
    end
    return a
end

local RaidFight = setmetatable({}, { __index = PartFight })
RaidFight.__index = RaidFight

function RaidFight:Finish(b, reason)
    local hero = self.hero
    local head = string.format("%s %s (%s)", RD[self.boss].nameKo, RD[self.boss].difficulties[self.diff].nameKo,
        R.MODE_KO[self.mode])
    if reason ~= "clear" then
        return C.Result(false, reason, head .. " " .. (C.REASON_KO[reason] or reason) .. " · 입장권 미사용")
    end
    local st = hero.content.raids[self.boss]
    st.cleared[self.diff] = st.cleared[self.diff] or {}
    st.cleared[self.diff][self.mode] = true
    st.clears = (st.clears or 0) + 1
    if self.challenge then
        return C.Result(true, reason, head .. " 클리어 (도전 모드: 보상 없음)")
    end
    local n = self.double and RD.rules.doubleTickets or 1
    if not spendEntries(hero, self.boss, n) then
        return C.Result(true, reason, head .. " 클리어 (입장권 부족: 보상 없음)")
    end
    local rewards = {}
    for _ = 1, n do mergeRewards(rewards, R.RollReward(self.boss, self.diff, b.rng, self.mode == "single")) end
    local lines = C.Grant(hero, rewards, "bossRaid")
    ns.Fire("BOSS_RAID_CLEARED", hero, self.boss, self.diff, self.mode)
    return C.Result(true, reason, head .. " 클리어", lines, { rewards = rewards })
end

function R.Spec(boss, diffIndex, mode)
    local b = RD[boss]
    local dd = b.difficulties[diffIndex]
    local m = dd[mode] or dd.party
    local spec = { kind = boss, nameKo = b.nameKo, primary = m.primary, part = m.part, partCount = b.partCount,
        atk = m.atk, def = m.def, avoid = m.avoid, partLabelShort = R.PART_SHORT[boss] }
    if boss == "pinkbean" then
        spec.bodyHp = m.primary
        spec.statueBaseHp = m.part
        spec.statues = b.statues
        spec.firstWakeHpRatio = b.firstWakeHpRatio
        local gp = D.ContentPinkBeanSeal
        -- seal mechanics (PROVISIONAL for the normal raid: the growth / heal values were published for
        -- the former guild raid; the normal raid notes "이후 체력 변화·회복" too)
        spec.statueHpGrowth = gp.statueHpGrowth
        spec.healOnSealMin, spec.healOnSealMax = gp.healOnSealMin, gp.healOnSealMax
        spec.sealSec, spec.bodyAppearMs = gp.sealSec, gp.bodyAppearMs
        spec.sealBuffs = gp.sealBuffs
    end
    return spec
end

function R.CanEnter(hero, boss, diffIndex, mode, opts)
    opts = opts or {}
    local dd = RD[boss] and RD[boss].difficulties[diffIndex]
    if not dd then return false, "잘못된 난이도입니다." end
    local ok, gate = R.IsUnlocked(hero, boss, diffIndex)
    if not ok then return false, gate .. " 후 입장할 수 있습니다." end
    if not opts.challenge then
        local base, shared = R.Entries(hero, boss)
        local need = opts.double and RD.rules.doubleTickets or 1
        if base + shared < need then return false, "입장 횟수가 부족합니다." end
    end
    if C.Busy() then return false, "다른 콘텐츠를 진행 중입니다." end
    return true
end

function R.Enter(hero, boss, diffIndex, mode, opts)
    opts = opts or {}
    mode = mode or "party"
    local ok, err = R.CanEnter(hero, boss, diffIndex, mode, opts)
    if not ok then return nil, err end
    local b = RD[boss]
    local dd = b.difficulties[diffIndex]
    local single = mode == "single"
    local _, _, bg = C.Look("raids", boss)
    local ctl = C.NewFight(RaidFight, {
        kind = "bossRaid", modeKey = "raid_" .. boss, boss = boss, diff = diffIndex, mode = mode,
        spec = R.Spec(boss, diffIndex, mode), challenge = opts.challenge, double = opts.double,
        allies = single and 0 or 3,
        timeLimit = (dd.time or R.DEFAULT_TIME) * 1000,
        teamDeaths = single and RD.rules.singleRevives or (dd.teamDeaths or R.DEFAULT_TEAM_DEATHS),
        dungeonType = "BossRaid", difficulty = diffIndex - 1, noSupporter = b.noSupporter, background = bg,
        baseTitle = string.format("%s %s %s", b.nameKo, dd.nameKo, R.MODE_KO[mode]),
    })
    ctl.title = ctl.baseTitle
    return C.Start(hero, ctl)
end

function R.Sweep(hero, boss, diffIndex, double)
    local st = hero.content.raids[boss]
    if not st.cleared[diffIndex] then return false, "클리어한 난이도만 소탕할 수 있습니다." end
    local n = double and RD.rules.doubleTickets or 1
    if not spendEntries(hero, boss, n) then return false, "입장 횟수가 부족합니다." end
    local rewards = {}
    for _ = 1, n do mergeRewards(rewards, R.RollReward(boss, diffIndex, U.rng, false)) end
    local lines = C.Grant(hero, rewards, "bossRaidSweep")
    C.Record(hero, "raid_" .. boss, C.Result(true, "sweep", string.format("%s %s 소탕", RD[boss].nameKo,
        RD[boss].difficulties[diffIndex].nameKo), lines, { rewards = rewards }))
    return true, nil, lines
end

-- red-diamond refill of the shared ticket: 2,000 / 3,000 / 5,000 / 5,000 per week (novasmc)
function R.BuyTicket(hero)
    local ct = hero.content.raids
    local price = RD.rules.refillRedDia[(ct.refills or 0) + 1]
    if not price then return false, "이번 주 충전 횟수를 모두 사용했습니다." end
    if not Hero.Spend(hero, "redDia", price, "bossRaidRefill") then return false, "레드 다이아가 부족합니다." end
    ct.refills = (ct.refills or 0) + 1
    Hero.Add(hero, "bossRaidTicket", 1, "bossRaidRefill")
    return true, nil, { "보스 레이드 입장권 +1" }
end

local function diffOptions(boss)
    local out = {}
    for i, dd in ipairs(RD[boss].difficulties) do out[i] = dd.nameKo end
    return out
end

for i, boss in ipairs(R.BOSSES) do
    local bd = RD[boss]
    C.RegisterMode("raid_" .. boss, {
        order = 40 + i, group = "보스 레이드", title = bd.nameKo .. " 레이드",
        selectors = {
            { key = "diff", label = "난이도", options = diffOptions(boss) },
            { key = "mode", label = "모드", options = { "파티", "싱글" }, values = { "party", "single" } },
            { key = "double", label = "보상", options = { "1배", "2배 (입장 2회)" }, values = { false, true } },
        },
        info = function(hero, sel)
            local di = sel.diff or 1
            local dd = bd.difficulties[di]
            local mode = sel.mode or "party"
            local m = dd[mode] or dd.party
            local base, shared = R.Entries(hero, boss)
            local unlocked, gate = R.IsUnlocked(hero, boss, di)
            local lines = {
                string.format("%s %s: %s %s · %s %s ×%d · 공격력 %s · 방어력 %s · 회피 %d", dd.nameKo, R.MODE_KO[mode],
                    bd.primaryLabel, F(m.primary), bd.partLabel, F(m.part), bd.partCount, F(m.atk), F(m.def), m.avoid),
                string.format("기본 입장 %d회 (주 %d) · 공용 입장권 %d장 (주 %d) · %s",
                    base, RD.rules.weeklyPerBoss, shared, RD.rules.weeklyShared,
                    mode == "single" and ("부활 " .. RD.rules.singleRevives .. "회 · 1인")
                        or ("AI 동료 3명 · 팀 사망 " .. (dd.teamDeaths or R.DEFAULT_TEAM_DEATHS) .. "회")),
            }
            if not unlocked and gate then lines[#lines + 1] = "|cffff6060" .. gate .. " 필요|r" end
            local drops = {}
            for _, g in ipairs(dd.drops) do drops[#drops + 1] = string.format("%s %.0f%%", g.item, g.permille / 10) end
            lines[#lines + 1] = "장비: " .. table.concat(drops, ", ")
            lines[#lines + 1] = "장비 없을 때: 메소 10만 / 엘리트 포인트 400 / 무기 강화석 2만 / 주문의 흔적 400 / 시간 단축 200 중 1"
            return lines
        end,
        actions = {
            { label = "입장", fn = function(hero, sel)
                local b, e = R.Enter(hero, boss, sel.diff or 1, sel.mode or "party", { double = sel.double })
                return b ~= nil, e end },
            { label = "도전 모드", fn = function(hero, sel)
                local b, e = R.Enter(hero, boss, sel.diff or 1, sel.mode or "party", { challenge = true })
                return b ~= nil, e end },
            { label = "소탕", fn = function(hero, sel) return R.Sweep(hero, boss, sel.diff or 1, sel.double) end },
            { label = "입장권 충전", fn = function(hero) return R.BuyTicket(hero) end },
        },
    })
end

---------------------------------------------------------------------------
-- 마왕 발록 (신규 용사 성장 챌린지 도전 보스)
---------------------------------------------------------------------------
local BL = {}
C.Balrog = BL
local BD = D.ContentBalrog
-- PROVISIONAL: group size is not in the data -> player + 3 AI allies share the boss HP.
BL.GROUP_ALLIES = 3

C.RegisterState("balrog", {
    init = function(hero, ct)
        ct.balrog = ct.balrog or { max = 0, best20 = 0 }
        if not ct.balrogTicketGiven then
            ct.balrogTicketGiven = true
            C.Recharge(hero, "balrogTicket", BD.ticket.daily, BD.ticket.cap)
        end
    end,
    daily = function(hero, ct, elapsed)
        C.Recharge(hero, "balrogTicket", BD.ticket.daily * elapsed, BD.ticket.cap)
    end,
})

local BLFight = C.Proto()

function BLFight:Setup(b)
    local row = BD.stages[self.stage]
    local hc = b.heroCreature
    self.boss = self:Spawn(b, { name = BD.nameKo, hp = row.hp, atk = row.atk, def = row.def, avoid = row.avoid,
        boss = true, x = (hc and hc.x or 0) + 2500, speed = 500, infinite = self.stage == BD.unkillableStage,
        level = self.stage })
end

function BLFight:Tick(b)
    if not self.boss.alive then b:End("clear") end
end

function BLFight:UpdateTitle(b)
    self.title = string.format("마왕 발록 %d단계 · 피해 %s", self.stage, F(self.damage))
end

function BLFight:Finish(b, reason)
    local hero = self.hero
    local s = hero.content.balrog
    local head = string.format("마왕 발록 %d단계", self.stage)
    if self.stage == BD.unkillableStage then
        s.best20 = math.max(s.best20 or 0, self.damage)
    end
    if reason ~= "clear" then
        return C.Result(false, reason, string.format("%s %s · 피해 %s (입장권 사용)", head,
            C.REASON_KO[reason] or reason, F(self.damage)))
    end
    -- the ticket is refunded on a kill
    Hero.Add(hero, "balrogTicket", 1, "balrogRefund")
    local rewards
    if self.stage > s.max then
        s.max = self.stage
        rewards = BD.stages[self.stage].rewards
    end
    local lines = C.Grant(hero, rewards, "balrog")
    return C.Result(true, reason, head .. " 처치 (입장권 반환)", lines, { rewards = rewards })
end

function BL.Enter(hero, stage)
    local s = hero.content.balrog
    stage = stage or math.min(#BD.stages, s.max + 1)
    if hero.level < BD.unlockLevel then return nil, string.format("%d레벨부터 참여할 수 있습니다.", BD.unlockLevel) end
    if stage < 1 or stage > #BD.stages or stage > s.max + 1 then return nil, "도전할 수 없는 단계입니다." end
    if not Hero.Spend(hero, "balrogTicket", 1, "balrog") then return nil, "마왕 발록 입장권이 없습니다." end
    local row = BD.stages[stage]
    local ctl = C.NewFight(BLFight, { kind = "balrog", modeKey = "balrog", stage = stage, allies = BL.GROUP_ALLIES,
        timeLimit = row.time * 1000, dungeonType = "GroupChallenge", revive = true,
        title = "마왕 발록 " .. stage .. "단계" })
    local b, err = C.Start(hero, ctl)
    if not b then Hero.Add(hero, "balrogTicket", 1, "balrogRefund") end
    return b, err
end

C.RegisterMode("balrog", {
    order = 35, group = "보스", title = "마왕 발록",
    selectors = {
        { key = "stage", label = "단계", min = 1,
          max = function(hero) return math.min(#BD.stages, hero.content.balrog.max + 1) end,
          default = function(hero) return math.min(#BD.stages, hero.content.balrog.max + 1) end },
    },
    info = function(hero, sel)
        local s = hero.content.balrog
        local row = BD.stages[sel.stage or 1]
        local lines = {
            string.format("%d단계: HP %s%s · 공격력 %s · 방어력 %s · %d초 · 그룹 (나 + AI %d명)", sel.stage or 1,
                F(row.hp), (sel.stage == BD.unkillableStage) and " (처치 불가)" or "", F(row.atk), F(row.def), row.time,
                BL.GROUP_ALLIES),
            string.format("최고 단계 %d · 입장권 %d장 (매일 +%d, 최대 %d, 처치 시 반환) · 20단계 최고 피해 %s", s.max,
                Hero.Count(hero, "balrogTicket"), BD.ticket.daily, BD.ticket.cap, F(s.best20 or 0)),
        }
        if row.rewards then lines[#lines + 1] = "최초 처치 보상: " .. table.concat(C.RewardLines(row.rewards), ", ") end
        if hero.level < BD.unlockLevel then lines[#lines + 1] = "|cffff6060" .. BD.unlockLevel .. "레벨 필요|r" end
        return lines
    end,
    actions = { { label = "도전", fn = function(hero, sel) local b, e = BL.Enter(hero, sel.stage); return b ~= nil, e end } },
})
