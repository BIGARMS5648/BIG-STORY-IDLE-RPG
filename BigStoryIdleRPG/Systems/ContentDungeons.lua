-- 성장 던전 5종 (무기 / 경험치 / 장비 / 용사의 수련장 / 강화), 빠른 사냥, 버닝 필드.
-- Monster stats, time limits, kill counts and IsHard come from Data/Content.lua (client 1.18.0).
--
-- Keys (KR): every dungeon recharges 3 keys at 00:00 KST, holding cap 10 (research-income §2.21).
-- A key is needed to enter; a failed run never uses it (KR IV130). 무기/경험치/장비/수련장: the key
-- is returned on clear (= challenges are free, keys pay for sweeps). 강화 던전: a clear uses the key
-- (보상권 clear, scroll roll), a failure returns it. Sweep (소탕) = 1 key -> reward of the highest
-- cleared stage; bulk sweep (일괄 소탕) of every key once all five dungeons reached stage 50.
--
-- API (ns.Content.Growth)
--   G.KEYS                          -> { "weapon", "exp", "gear", "training", "enhance" }
--   G.Info(hero, key)               -> { max, keys, walletKey, nameKo, rows }
--   G.Enter(hero, key, stage)       -> battle | nil, err
--   G.Sweep(hero, key, count)       -> ok, err, rewardLines
--   G.CanBulkSweep(hero)            -> bool ;  G.BulkSweep(hero) -> ok, err, rewardLines
--   G.StageReward(key, stage, rng)  -> rewards table (exp / wallet keys)
-- API (ns.Content.QuickHunt): Q.Kills(hero), Q.Options(hero), Q.Use(hero, pay) -> ok, err, lines
-- API (ns.Content.Burning): B.Use(hero) -> ok, err ; B.Active(hero) -> secondsLeft, killsLeft
local ADDON, ns = ...
local U = ns.U
local D = ns.Data
local Hero = ns.Hero
local C = ns.Content

local G = {}
C.Growth = G
local GD = D.ContentGrowth

G.KEYS = { "weapon", "exp", "gear", "training", "enhance" }
G.WALLET = { weapon = "weaponDungeonKey", exp = "expDungeonKey", gear = "gearDungeonKey",
    training = "heroPowerDungeonKey", enhance = "enhanceDungeonKey" }
G.SKIN = { weapon = "weapon", exp = "exp", gear = "gear", training = "heroTraining", enhance = "enhancement" }

---------------------------------------------------------------------------
-- Rewards
---------------------------------------------------------------------------
-- PROVISIONAL: per-stage amounts of 무기/장비/수련장/강화(주문의 흔적) are not published anywhere
-- (research-progression §9, research-income §10 #7). Only the reward TYPES are known. Replace this one
-- table (or provide D.ContentGrowthRewards[key][stage] = { walletKey = n }) when real numbers appear.
C.GROWTH_REWARDS_PROVISIONAL = {
    weapon = function(st) return { weaponTicket = 5 + math.floor(st / 5), weaponStone = 500 * st } end,
    gear = function(st) return { eliteSummonPoint = 100 + 10 * st } end,
    training = function(st) return { heroToken = 240 + 10 * st } end,  -- global 1.14 formula; KR 141-150 unpublished
    enhance = function(st) return { spellTrace = 100 + 10 * st } end,
}

local function scrollBand(stage)
    for _, b in ipairs(GD.enhance.scrollBands) do
        if stage >= b.from and stage <= b.to then return b end
    end
end

-- one clear / sweep reward of `stage`
function G.StageReward(key, stage, rng)
    rng = rng or U.rng
    local out = {}
    local real = D.ContentGrowthRewards and D.ContentGrowthRewards[key] and D.ContentGrowthRewards[key][stage]
    if real then
        for k, v in pairs(real) do out[k] = v end
    elseif key == "exp" then
        out.exp = GD.exp.sweepExp[stage]          -- exact, EXP % bonuses do not apply
    else
        local fn = C.GROWTH_REWARDS_PROVISIONAL[key]
        if fn then for k, v in pairs(fn(stage)) do out[k] = v end end
    end
    if key == "enhance" then
        -- random enhancement scroll: 6 kinds, 10% in total per clear / sweep (exact table, ppm)
        local band = scrollBand(stage)
        if band then
            local r = rng:Float() * 1000000
            for _, k in ipairs({ "scrollNormal", "scrollRare", "scrollRare25", "scrollEpic", "scrollEpic30", "scrollEpic15" }) do
                local ppm = band.drops[k]
                if ppm then
                    r = r - ppm
                    if r < 0 then out[k] = (out[k] or 0) + 1 break end
                end
            end
        end
    end
    return out
end

---------------------------------------------------------------------------
-- State / resets
---------------------------------------------------------------------------
C.RegisterState("growth", {
    init = function(hero, ct)
        ct.growth = ct.growth or {}
        for _, k in ipairs(G.KEYS) do ct.growth[k] = ct.growth[k] or { max = 0, clears = 0, sweeps = 0 } end
        if not ct.growthKeysGiven then
            ct.growthKeysGiven = true
            for _, k in ipairs(G.KEYS) do C.Recharge(hero, G.WALLET[k], GD.rules.dailyKeys, GD.rules.keyCap) end
        end
    end,
    daily = function(hero, ct, elapsed)
        for _, k in ipairs(G.KEYS) do
            C.Recharge(hero, G.WALLET[k], GD.rules.dailyKeys * elapsed, GD.rules.keyCap)
        end
    end,
})

function G.Info(hero, key)
    local st = hero.content.growth[key]
    local data = GD[key]
    return { max = st.max, keys = Hero.Count(hero, G.WALLET[key]), walletKey = G.WALLET[key], nameKo = data.nameKo,
        rows = data.rows, stages = GD.rules.stages }
end

function G.Row(key, stage) return GD[key].rows[stage] end

---------------------------------------------------------------------------
-- Controllers
---------------------------------------------------------------------------
-- PROVISIONAL constants for mechanics whose numbers are not in the data
C.PROV_GROWTH = {
    expAliveMin = 20,          -- EXP dungeon: "초기 최소 20마리" -> keep at least 20 alive
    expTimerMobEvery = 10,     -- EXP dungeon: 1 시간연장몹 per 10 spawns (map file AntCave_Exp.json unpublished)
    expTimerBuffAtkSpeed = 200, expTimerBuffMovePct = 200,   -- +20% / +20% for 10 s (amount not published)
    gearAlive = 20,            -- gear dungeon: monsters kept alive (map file GearDungeon_2.json unpublished)
    gearSpeedBuffMovePct = 500, -- yellow speed mob: +50% move speed for 5 s (amount not published)
    gearBombDamageRatio = 1.0, -- bomb explosion damage = bomb max HP x ratio to monsters in 3,300 mm
    trainingSpeedStackPct = 10, -- 수련장 buff mob speed stacks: +1% per stack (like the kill stack's move speed)
}

local Boss = C.Proto()      -- 무기 / 강화: one boss
local MobRush = C.Proto()   -- 경험치 / 장비: kill count
local Training = C.Proto()  -- 용사의 수련장

local function lookName(key, fallback)
    local model, name, bg = C.Look("dungeons", G.SKIN[key], fallback)
    return model, name, bg
end

function Boss:Setup(b)
    local row = self.row
    local hc = b.heroCreature
    local model, name = lookName(self.key, GD[self.key].monsterKo)
    self.boss = self:Spawn(b, { name = name, hp = row.hp, atk = row.atk, def = row.def, hit = row.hit,
        avoid = row.avoid, boss = true, x = (hc and hc.x or 0) + (GD[self.key].initialDistanceMm or 2500),
        model = model, level = self.stage })
    self.boss.ignoreCC = true
    if self.key == "enhance" then self.down = GD.enhance.bossDown end
end

function Boss:Tick(b, dt)
    -- 강화 던전 발록 다운: from 20.6 s for 4 s every 22 s: DEF -100%, player attack speed +100%
    local dn = self.down
    if dn and self.boss.alive then
        local t = b.time - dn.startMs
        local inDown = t >= 0 and (t % dn.intervalMs) < dn.durationMs
        if inDown and not self.downMods then
            self.downMods = { { c = self.boss, m = self.boss:AddMod("Defence", "ratio", -1000, "bossDown") } }
            for _, c in ipairs(self:SideOne(b)) do
                table.insert(self.downMods, { c = c, m = c:AddMod("AttackSpeed", "add", dn.atkSpeedPct * 10, "bossDown") })
            end
        elseif not inDown and self.downMods then
            for _, e in ipairs(self.downMods) do e.c:RemoveMod(e.m) end
            self.downMods = nil
        end
    end
    if not self.boss.alive then b:End("clear") end
end

function Boss:UpdateTitle(b)
    self.title = string.format("%s %d단계%s", GD[self.key].nameKo, self.stage, self.row.hard and " (어려움)" or "")
end

-- kill-count dungeons -------------------------------------------------------
function MobRush:Setup(b)
    self.kills = 0
    self.spawned = 0
    self.model, self.mobName = lookName(self.key, GD[self.key].nameKo)
    self:Refill(b)
end

function MobRush:SpawnOne(b)
    local row, P = self.row, C.PROV_GROWTH
    local hc = b.heroCreature
    local x = (hc and hc.x or 0) + 900 + b.rng:Int(0, 6000)
    self.spawned = self.spawned + 1
    local o = { x = x, atk = row.atk, def = row.def, aggro = 1500, model = self.model, level = self.stage }
    if self.key == "exp" then
        if self.spawned % P.expTimerMobEvery == 0 then
            o.name, o.hp, o.avoid, o.tag = "시간연장몹", row.timerHp, row.timerAvoid, "timer"
        else
            local v = b.rng:Int(1, 3)
            o.name, o.hp, o.avoid, o.tag = self.mobName, row.hp[v], row.avoid, "normal"
        end
    else
        local pool = GD.gear.pool
        local pick = b.rng:Weighted({ pool.normal, pool.bomb, pool.speed })
        if pick == 2 then
            o.name, o.hp, o.avoid, o.tag = "폭탄몹", row.bombHp, row.bombAvoid, "bomb"
        elseif pick == 3 then
            o.name, o.hp, o.avoid, o.tag = "가속몹", row.speedHp, row.speedAvoid, "speed"
        else
            o.name, o.hp, o.avoid, o.tag = self.mobName, row.hp, row.avoid, "normal"
        end
    end
    self:Spawn(b, o)
end

function MobRush:Refill(b)
    local want = (self.key == "exp") and C.PROV_GROWTH.expAliveMin or C.PROV_GROWTH.gearAlive
    local alive = self:EnemiesAlive(b)
    for _ = alive + 1, want do self:SpawnOne(b) end
end

function MobRush:Buff(b, stat, kind, v, ms)
    for _, c in ipairs(self:SideOne(b)) do
        local m = c:AddMod(stat, kind, v, "growthBuff")
        b:Schedule(ms, function() c:RemoveMod(m) end)
    end
end

function MobRush:OnEnemyKilled(b, victim)
    self.kills = self.kills + 1
    local P = C.PROV_GROWTH
    if victim.tag == "timer" then
        b.timeLimit = (b.timeLimit or 0) + GD.exp.timerBonusSec * 1000
        self:Buff(b, "AttackSpeed", "add", P.expTimerBuffAtkSpeed, GD.exp.timerBuffSec * 1000)
        self:Buff(b, "RunSpeedMms", "ratio", P.expTimerBuffMovePct, GD.exp.timerBuffSec * 1000)
    elseif victim.tag == "speed" then
        self:Buff(b, "RunSpeedMms", "ratio", P.gearSpeedBuffMovePct, GD.gear.speedBuffSec * 1000)
    elseif victim.tag == "bomb" then
        local x0, dmg = victim.x, victim:Stat("MaxHp") * P.gearBombDamageRatio
        local selfRef = self
        b:Schedule(GD.gear.bombDelayMs, function()
            local hc = b.heroCreature
            for _, c in ipairs(b.creatures) do
                if c.alive and c.side == 2 and math.abs(c.x - x0) <= GD.gear.bombRadiusMm and hc then
                    b:DealDamage(hc, c, math.floor(dmg), false, { skillId = 0, flag = 0, depth = 0, bomb = true })
                end
            end
            if selfRef.kills >= selfRef.row.kills and not b.ended then b:End("clear") end
        end)
    end
    if self.kills >= self.row.kills then b:End("clear") return end
end

function MobRush:Tick(b, dt)
    if self.kills >= self.row.kills then b:End("clear") return end
    self:Refill(b)
end

function MobRush:UpdateTitle(b)
    self.title = string.format("%s %d단계 · %d/%d", GD[self.key].nameKo, self.stage, self.kills, self.row.kills)
end

-- 용사의 수련장 -----------------------------------------------------------------
function Training:Setup(b)
    self.phase = "mobs"
    self.kills = 0
    self.stacks = { atk = {}, atkSpeed = {}, move = {} }
    self.model, self.mobName = lookName("training", "수련생")
    local selfRef = self
    local TD = GD.training
    local hc = b.heroCreature
    if hc then
        local function count(kind) return #selfRef.stacks[kind] end
        hc:AddMod("Attack", "ratio", function() return count("atk") * TD.killAtkPct * 10 end, "training")
        hc:AddMod("RunSpeedMms", "ratio", function()
            return count("move") * TD.killMovePct * 10 end, "training")
        hc:AddMod("AttackSpeed", "add", function()
            return count("atkSpeed") * C.PROV_GROWTH.trainingSpeedStackPct end, "training")
    end
    self:Refill(b)
end

function Training:AddStacks(b, kind, n)
    local TD = GD.training
    local list = self.stacks[kind]
    for _ = 1, n do
        if #list >= TD.killBuffMax then table.remove(list, 1) end
        list[#list + 1] = b.time + TD.killBuffSec * 1000
    end
    if b.heroCreature then b.heroCreature:Dirty() end
end

function Training:Refill(b)
    if self.phase ~= "mobs" then return end
    local row = self.row
    local hc = b.heroCreature
    local p = row.pool
    for _ = self:EnemiesAlive(b) + 1, row.minMobs do
        local pick = b.rng:Weighted({ p.normal, p.large, p.flying, p.atkSpeed, p.moveSpeed })
        local kind = ({ "normal", "large", "flying", "buff", "buff" })[pick]
        local o = { x = (hc and hc.x or 0) + 900 + b.rng:Int(0, 5000), hp = row.hp[kind], atk = row.atk[kind],
            def = kind == "buff" and row.buffDef or row.def, avoid = kind == "buff" and row.buffAvoid or row.avoid,
            name = kind == "buff" and "버프몹" or self.mobName, aggro = 1500, model = self.model, level = self.stage,
            tag = (pick == 4 and "buffAtkSpeed") or (pick == 5 and "buffMove") or kind }
        self:Spawn(b, o)
    end
end

function Training:OnEnemyKilled(b, victim)
    if victim == self.boss then b:End("clear") return end
    self.kills = self.kills + 1
    local TD = GD.training
    self:AddStacks(b, "atk", 1)
    self:AddStacks(b, "move", 1)
    if victim.tag == "buffAtkSpeed" then
        self:AddStacks(b, "atk", TD.buffMobStacks)
        self:AddStacks(b, "atkSpeed", TD.buffMobStacks)
    elseif victim.tag == "buffMove" then
        self:AddStacks(b, "atk", TD.buffMobStacks)
        self:AddStacks(b, "move", TD.buffMobStacks)
    end
end

function Training:Tick(b, dt)
    -- expire kill stacks
    local changed = false
    for _, list in pairs(self.stacks) do
        while list[1] and list[1] <= b.time do table.remove(list, 1); changed = true end
    end
    if changed and b.heroCreature then b.heroCreature:Dirty() end
    local row = self.row
    if self.phase == "mobs" then
        if b.time >= row.bossAt * 1000 then
            -- boss phase: remaining mobs removed, no more spawns
            self.phase = "boss"
            for _, c in ipairs(b.creatures) do
                if c.side == 2 and c.alive then c.alive = false; b:Hook("onDespawn", c) end
            end
            local hc = b.heroCreature
            local model, name = lookName("training", "수련장 보스")
            self.boss = self:Spawn(b, { name = name, hp = row.hp.boss, atk = row.atk.boss, def = row.bossDef,
                avoid = row.bossAvoid, boss = true, x = (hc and hc.x or 0) + 1500, model = model, level = self.stage })
        else
            self:Refill(b)
        end
    elseif self.boss and not self.boss.alive then
        b:End("clear")
    end
end

function Training:UpdateTitle(b)
    self.title = string.format("%s %d단계 · %s · 처치 %d (공격력 +%d%%)", GD.training.nameKo, self.stage,
        self.phase == "boss" and "보스" or "일반", self.kills, #self.stacks.atk * GD.training.killAtkPct)
end

-- common finish --------------------------------------------------------------
local function finish(self, b, reason)
    local hero = self.hero
    local st = hero.content.growth[self.key]
    local nameKo = GD[self.key].nameKo
    if reason ~= "clear" then
        return C.Result(false, reason, string.format("%s %d단계 %s (열쇠 미소모)", nameKo, self.stage,
            C.REASON_KO[reason] or reason))
    end
    st.clears = (st.clears or 0) + 1
    local first = self.stage > st.max
    if first then st.max = self.stage end
    local rewards, note
    if self.key == "enhance" then
        -- 보상권 clear: uses the key, rolls the reward
        Hero.Spend(hero, G.WALLET.enhance, 1, "growthClear")
        rewards = G.StageReward("enhance", self.stage, b.rng)
        note = "열쇠 1개 사용"
    else
        -- key returned on clear; the first clear of a new stage pays that stage's reward
        if first then
            rewards = G.StageReward(self.key, self.stage, b.rng)
            -- every 10th stage pays an extra first-clear bonus (published for 용사의 수련장)
            local bonus = D.ContentGrowthFirstClear and D.ContentGrowthFirstClear[self.key]
                and D.ContentGrowthFirstClear[self.key][self.stage]
            if bonus then for k, v in pairs(bonus) do rewards[k] = (rewards[k] or 0) + v end end
        end
        note = first and "최초 클리어 · 열쇠 반환" or "열쇠 반환"
    end
    local lines = C.Grant(hero, rewards, "growth")
    ns.Fire("GROWTH_DUNGEON_CLEARED", hero, self.key, self.stage, first)
    return C.Result(true, reason, string.format("%s %d단계 클리어 (%s)", nameKo, self.stage, note), lines,
        { rewards = rewards })
end
Boss.Finish, MobRush.Finish, Training.Finish = finish, finish, finish

---------------------------------------------------------------------------
-- Entry / sweep
---------------------------------------------------------------------------
function G.CanEnter(hero, key, stage)
    local st = hero.content.growth[key]
    local rows = GD[key].rows
    stage = stage or math.min(#rows, st.max + 1)
    if stage < 1 or stage > #rows then return false, "잘못된 단계입니다." end
    if key == "enhance" then
        if stage > st.max + 1 then return false, "이전 단계를 먼저 클리어하세요." end
    else
        if stage ~= st.max + 1 then
            if stage <= st.max then return false, "이미 클리어한 단계입니다. 소탕을 이용하세요." end
            return false, "이전 단계를 먼저 클리어하세요."
        end
    end
    if Hero.Count(hero, G.WALLET[key]) < 1 then return false, "열쇠가 없습니다." end
    return true, nil, stage
end

function G.Enter(hero, key, stage)
    local ok, err
    ok, err, stage = G.CanEnter(hero, key, stage)
    if not ok then return nil, err end
    local row = GD[key].rows[stage]
    local proto = (key == "weapon" or key == "enhance") and Boss or (key == "training" and Training or MobRush)
    local _, _, bg = C.Look("dungeons", G.SKIN[key])
    local ctl = C.NewFight(proto, { kind = "growth", modeKey = "growth_" .. key, key = key, stage = stage, row = row,
        timeLimit = (row.time or 30) * 1000, dungeonType = "GrowthDungeon", background = bg,
        title = string.format("%s %d단계", GD[key].nameKo, stage) })
    return C.Start(hero, ctl)
end

function G.Sweep(hero, key, count)
    count = count or 1
    local st = hero.content.growth[key]
    if st.max < 1 then return false, "클리어한 단계가 없습니다." end
    if Hero.Count(hero, G.WALLET[key]) < count then return false, "열쇠가 부족합니다." end
    Hero.Spend(hero, G.WALLET[key], count, "growthSweep")
    local total = {}
    for _ = 1, count do
        for k, v in pairs(G.StageReward(key, st.max, U.rng)) do C.AddReward(total, k, v) end
    end
    st.sweeps = (st.sweeps or 0) + count
    local lines = C.Grant(hero, total, "growthSweep")
    local res = C.Result(true, "sweep", string.format("%s %d단계 소탕 %d회", GD[key].nameKo, st.max, count), lines,
        { rewards = total })
    C.Record(hero, "growth_" .. key, res)
    return true, nil, lines
end

function G.CanBulkSweep(hero)
    for _, k in ipairs(G.KEYS) do
        if hero.content.growth[k].max < GD.rules.bulkSweepStage then return false end
    end
    return true
end

function G.BulkSweep(hero)
    if not G.CanBulkSweep(hero) then
        return false, string.format("5종 던전을 모두 %d단계까지 클리어해야 합니다.", GD.rules.bulkSweepStage)
    end
    local all = {}
    for _, k in ipairs(G.KEYS) do
        local n = Hero.Count(hero, G.WALLET[k])
        if n > 0 then
            local ok, _, lines = G.Sweep(hero, k, n)
            if ok then for _, l in ipairs(lines) do all[#all + 1] = l end end
        end
    end
    if #all == 0 then return false, "열쇠가 없습니다." end
    return true, nil, all
end

---------------------------------------------------------------------------
-- UI descriptors
---------------------------------------------------------------------------
local function stageInfo(key, stage)
    local row = GD[key].rows[stage]
    if not row then return "" end
    local F = U.FormatNumber
    if key == "weapon" or key == "enhance" then
        return string.format("%s HP %s · 공격력 %s · 방어력 %s · 회피 %d · %d초%s", GD[key].monsterKo, F(row.hp),
            F(row.atk), F(row.def), row.avoid, row.time, row.hard and " · 어려움" or "")
    elseif key == "exp" then
        return string.format("%d마리 처치 · %d초 (시간연장몹 +%d초) · HP %s~%s · 방어력 %s · 회피 %d%s", row.kills,
            row.time, GD.exp.timerBonusSec, F(row.hp[1]), F(row.hp[3]), F(row.def), row.avoid, row.hard and " · 어려움" or "")
    elseif key == "gear" then
        return string.format("%d마리 처치 · %d초 · HP %s (폭탄 %s) · 방어력 %s · 회피 %d%s", row.kills, row.time,
            F(row.hp), F(row.bombHp), F(row.def), row.avoid, row.hard and " · 어려움" or "")
    else
        return string.format("%d초 일반몹 → 보스 (총 %d초) · 보스 HP %s · 방어력 %s · 회피 %d%s", row.bossAt, row.time,
            F(row.hp.boss), F(row.bossDef), row.bossAvoid, row.hard and " · 어려움" or "")
    end
end

for i, key in ipairs(G.KEYS) do
    C.RegisterMode("growth_" .. key, {
        order = 10 + i, group = "성장 던전", title = GD[key].nameKo,
        selectors = {
            { key = "stage", label = "단계", min = 1,
              max = function(hero)
                  local st = hero.content.growth[key]
                  return key == "enhance" and math.min(#GD[key].rows, st.max + 1) or math.min(#GD[key].rows, st.max + 1)
              end,
              default = function(hero) return math.min(#GD[key].rows, hero.content.growth[key].max + 1) end },
        },
        info = function(hero, sel)
            local inf = G.Info(hero, key)
            local lines = {
                string.format("최고 단계 %d / %d · %s %d개 (매일 +%d, 최대 %d)", inf.max, inf.stages,
                    D.CurrencyName(inf.walletKey), inf.keys, GD.rules.dailyKeys, GD.rules.keyCap),
                stageInfo(key, sel.stage or 1),
            }
            local preview = G.StageReward(key, sel.stage or 1, U.NewRNG(1))
            local rl = C.RewardLines(preview)
            if key == "enhance" then rl[#rl + 1] = "강화 주문서 10% (단계별 등급표)" end
            lines[#lines + 1] = "보상: " .. table.concat(rl, ", ")
            if key ~= "exp" then lines[#lines + 1] = "|cff999999(보상 수량은 임시값 — 원본 미공개)|r" end
            lines[#lines + 1] = key == "enhance" and "클리어 시 열쇠 1개 사용 · 실패 시 반환"
                or "클리어 시 열쇠 반환 · 실패해도 열쇠는 소모되지 않습니다 · 소탕 = 열쇠 1개"
            return lines
        end,
        actions = {
            { label = "입장", fn = function(hero, sel) local b, err = G.Enter(hero, key, sel.stage); return b ~= nil, err end },
            { label = "소탕", fn = function(hero) return G.Sweep(hero, key, 1) end },
            { label = "일괄 소탕", fn = function(hero) return G.BulkSweep(hero) end,
              enabled = function(hero) return G.CanBulkSweep(hero) end },
        },
    })
end

---------------------------------------------------------------------------
-- 빠른 사냥 (quick hunt)
---------------------------------------------------------------------------
local Q = {}
C.QuickHunt = Q
local QD = D.ContentQuickHunt

C.RegisterState("quickHunt", {
    init = function(hero, ct)
        ct.quick = ct.quick or { uses = 0, free = 0, ad = 0, red = 0 }
    end,
    daily = function(hero, ct)
        ct.quick.free, ct.quick.ad, ct.quick.red = 0, 0, 0
    end,
})

-- kills of the next use: 1,000 on the first use, +5 per use, max 3,000
function Q.Kills(hero)
    return math.min(QD.maxKills, QD.firstKills + QD.perUse * (hero.content.quick.uses or 0))
end

-- what the next use costs: "free" (1/day), "ad" (the ad use, free here, 1/day), "ticket", "red" (500/750/1000)
function Q.Options(hero)
    local q = hero.content.quick
    local out = {
        free = math.max(0, QD.freePerDay - q.free),
        ad = math.max(0, QD.adPerDay - q.ad),
        ticket = Hero.Count(hero, "quickHuntTicket"),
        red = QD.redPrices[q.red + 1],
        redLeft = #QD.redPrices - q.red,
    }
    return out
end

function Q.Rewards(hero, kills)
    -- highest hunting stage reached (the chapter boss stage has no hunting field)
    local cp = hero.campaign
    local ch, st = cp.maxChapter, cp.maxStage
    local sd = ns.Campaign.StageData(ch, st)
    while st > 1 and not (sd and sd.hunt) do
        st = st - 1
        sd = ns.Campaign.StageData(ch, st)
    end
    if not sd or not sd.hunt then ch, st, sd = ns.Campaign.Stage(hero) end
    if not sd then return {} end
    -- highest stage reached; EXP / meso / drop boosts are not applied (deterministic like offline)
    local out = { exp = (sd.exp or 0) * kills }
    local drops = D.HuntDrops and D.HuntDrops[ch .. "-" .. st]
    for _, dr in ipairs(drops or {}) do
        local n = math.floor(kills * dr.ppm / 1000000) * dr.n
        if n > 0 then C.AddReward(out, dr.key, n) end
    end
    return out, ch, st
end

function Q.Use(hero, pay)
    local q = hero.content.quick
    local o = Q.Options(hero)
    if not pay then
        pay = (o.free > 0 and "free") or (o.ad > 0 and "ad") or (o.ticket > 0 and "ticket") or "red"
    end
    if pay == "free" then
        if o.free <= 0 then return false, "오늘 무료 횟수를 모두 사용했습니다." end
        q.free = q.free + 1
    elseif pay == "ad" then
        if o.ad <= 0 then return false, "오늘 추가 무료 횟수를 모두 사용했습니다." end
        q.ad = q.ad + 1
    elseif pay == "ticket" then
        if not Hero.Spend(hero, "quickHuntTicket", 1, "quickHunt") then return false, "빠른 사냥 티켓이 없습니다." end
    elseif pay == "red" then
        if not o.red then return false, "오늘 구매 가능 횟수를 모두 사용했습니다." end
        if not Hero.Spend(hero, "redDia", o.red, "quickHunt") then return false, "레드 다이아가 부족합니다." end
        q.red = q.red + 1
    else
        return false, "알 수 없는 결제 방식"
    end
    local kills = Q.Kills(hero)
    q.uses = (q.uses or 0) + 1
    local rewards, ch, st = Q.Rewards(hero, kills)
    local lines = C.Grant(hero, rewards, "quickHunt")
    hero.stats.kills = (hero.stats.kills or 0) + kills
    C.Record(hero, "quickHunt", C.Result(true, "clear",
        string.format("빠른 사냥 %s마리 (%s)", U.Comma(kills), ch and ns.Campaign.StageName(ch, st) or ""), lines,
        { rewards = rewards }))
    return true, nil, lines
end

C.RegisterMode("quickHunt", {
    order = 1, group = "사냥", title = "빠른 사냥",
    info = function(hero)
        local o = Q.Options(hero)
        local cp = hero.campaign
        return {
            string.format("다음 사용: %s마리 처치 (최고 도달 사냥터 %s 기준, 부스터·경험치%% 미적용)",
                U.Comma(Q.Kills(hero)), ns.Campaign.StageName(cp.maxChapter, cp.maxStage)),
            string.format("무료 %d회 · 추가 무료 %d회 · 티켓 %d장 · 레드 다이아 구매 %d회 남음%s", o.free, o.ad, o.ticket,
                o.redLeft, o.red and string.format(" (다음 %s)", U.Comma(o.red)) or ""),
            "사용할 때마다 처치 수 +5 (최대 3,000)",
        }
    end,
    actions = {
        { label = "사용", fn = function(hero) return Q.Use(hero) end },
        { label = "레드 다이아", fn = function(hero) return Q.Use(hero, "red") end },
    },
})

---------------------------------------------------------------------------
-- 버닝 필드 (burning field booster): chapter hunting kills give the stage's burning EXP.
-- Data: 600 s per booster, about 400 burning monsters per booster (level-experience-117.json).
-- PROVISIONAL interpretation: while active, up to 400 hunt kills per booster pay burnExp instead of exp.
---------------------------------------------------------------------------
local B = {}
C.Burning = B
local BD = D.ContentBurning

C.RegisterState("burning", {
    init = function(hero, ct) ct.burning = ct.burning or { untilT = 0, kills = 0 } end,
})

function B.Active(hero)
    local s = hero.content.burning
    local left = (s.untilT or 0) - U.Now()
    if left <= 0 or (s.kills or 0) <= 0 then return nil end
    return left, s.kills
end

function B.Use(hero)
    if not Hero.Spend(hero, "burningBooster", 1, "burning") then return false, "버닝 필드 부스터가 없습니다." end
    local s = hero.content.burning
    local now = U.Now()
    if (s.untilT or 0) < now then s.untilT, s.kills = now, 0 end
    s.untilT = s.untilT + BD.durationSec
    s.kills = (s.kills or 0) + BD.suggestedKills
    return true, nil, { string.format("버닝 필드 %d분 (%d마리)", BD.durationSec / 60, s.kills) }
end

ns.On("MONSTER_KILLED", function(hero, victim, rewards, kind)
    if kind ~= "hunt" or not hero.content or not B.Active(hero) then return end
    local def = victim.def or {}
    local sd = def.chapter and ns.Campaign.StageData(def.chapter, def.stage)
    if not (sd and sd.exp and sd.exp > 0 and sd.burnExp and rewards and rewards.exp) then return end
    local extra = rewards.exp * (sd.burnExp / sd.exp - 1)
    if extra > 0 then Hero.GainExp(hero, extra) end
    hero.content.burning.kills = hero.content.burning.kills - 1
end)

C.RegisterMode("burning", {
    order = 2, group = "사냥", title = "버닝 필드",
    info = function(hero)
        local left, kills = B.Active(hero)
        local cp = hero.campaign
        local sd = ns.Campaign.StageData(cp.chapter, cp.stage)
        return {
            left and string.format("진행 중: %s 남음 · 버닝 몬스터 %d마리", U.FormatDuration(left), kills) or "비활성",
            string.format("부스터 %d개 · 1개 = %d분, 버닝 몬스터 약 %d마리", Hero.Count(hero, "burningBooster"),
                BD.durationSec / 60, BD.suggestedKills),
            sd and string.format("현재 사냥터 처치 경험치 %s → 버닝 %s", U.FormatNumber(sd.exp or 0),
                U.FormatNumber(sd.burnExp or 0)) or "",
        }
    end,
    actions = { { label = "부스터 사용", fn = function(hero) return B.Use(hero) end } },
})
