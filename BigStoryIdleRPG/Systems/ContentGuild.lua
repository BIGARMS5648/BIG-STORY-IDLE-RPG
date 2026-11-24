-- 길드 콘텐츠: 토벌전, 대항전, 보스 대전, 수련장, 현상수배 (불꽃늑대의 소굴).
-- The guild is the player's WoW guild; every mode is a personal score attempt (as in the original),
-- scores stay local. Score formulas, boss tiers, waves and spawn tables: Data/Content.lua (guild.html).
--
-- PROVISIONAL: rankings are server/guild-wide in the original. Here the player's best weekly score maps
-- to a rank / tier through the threshold tables below (C.GUILD_THRESHOLDS); the arena developer may
-- replace them with addon-user rankings. 현상수배 uses the published minimum guild score per rank row,
-- with the player's cumulative hunt score as the guild score.
--
-- API (ns.Content.Guild)
--   GC.Enter(hero, mode, stage)    mode = "boss" | "league" | "match" | "training" | "bounty"
--   GC.Settle(hero, which)         which = "weekly" | "bounty" (Sunday 00:00)
--   GC.Raw / Converted scores in hero.content.guild[mode] = { used, dayBest, weekBest, best, lastWeek }
local ADDON, ns = ...
local U = ns.U
local D = ns.Data
local Hero = ns.Hero
local C = ns.Content
local F = U.FormatNumber

local GC = {}
C.Guild = GC
local GD = D.ContentGuild
GC.MODES = { "boss", "league", "match", "training", "bounty" }

-- PROVISIONAL: daily attempts per guild mode (not in the data); 현상수배 = unlimited attempts.
GC.DAILY_ENTRIES = { boss = 3, league = 3, match = 3, training = 3 }

-- PROVISIONAL thresholds on the player's best weekly score (see header)
C.GUILD_THRESHOLDS = {
    -- 토벌전 길드 티어 -> 노블레스 버프 (KR 11/5 values; not applied inside guild content), converted score
    boss = {
        { tier = "그랜드마스터 이상", min = 1e11, stats = { AttackPower = 100, BonusGoldPercent = 100, AttackPowerExcludeBoss = 100 } },
        { tier = "마스터1", min = 1e10, stats = { AttackPower = 100, BonusGoldPercent = 100, AttackPowerExcludeBoss = 100 } },
        { tier = "마스터2", min = 5e9, stats = { AttackPower = 100, BonusGoldPercent = 100, AttackPowerExcludeBoss = 80 } },
        { tier = "마스터3", min = 2e9, stats = { AttackPower = 100, BonusGoldPercent = 100, AttackPowerExcludeBoss = 60 } },
        { tier = "마스터4", min = 1e9, stats = { AttackPower = 100, BonusGoldPercent = 100, AttackPowerExcludeBoss = 40 } },
        { tier = "마스터5", min = 5e8, stats = { AttackPower = 100, BonusGoldPercent = 100, AttackPowerExcludeBoss = 20 } },
        { tier = "다이아몬드", min = 1e8, stats = { AttackPower = 100, BonusGoldPercent = 100 } },
        { tier = "플래티넘", min = 1e7, stats = { AttackPower = 100, BonusGoldPercent = 60 } },
        { tier = "골드", min = 1e6, stats = { AttackPower = 100, BonusGoldPercent = 20 } },
        { tier = "실버", min = 1e5, stats = { AttackPower = 60 } },
    },
    -- 대항전 rank 1..5 (converted score)
    league = { 1e9, 1e8, 1e7, 1e6, 1e5 },
    -- 수련장 rank 1..7 (raw score)
    training = { 5e7, 2e7, 1e7, 5e6, 2e6, 1e6, 1 },
}

C.RegisterState("guild", {
    init = function(hero, ct)
        ct.guild = ct.guild or {}
        for _, m in ipairs(GC.MODES) do
            ct.guild[m] = ct.guild[m] or { used = 0, dayBest = 0, weekBest = 0, best = 0 }
        end
        local b = ct.guild.bounty
        b.max = b.max or 0
        b.score = b.score or 0
        ct.guild.sundayWeek = ct.guild.sundayWeek or GC.SundayWeek()
    end,
    daily = function(hero, ct)
        for _, m in ipairs(GC.MODES) do
            ct.guild[m].used = 0
            ct.guild[m].dayBest = 0
        end
        local sw = GC.SundayWeek()
        if ct.guild.sundayWeek ~= sw then
            ct.guild.sundayWeek = sw
            GC.Settle(hero, "bounty")
        end
    end,
    weekly = function(hero, ct) GC.Settle(hero, "weekly") end,
})

-- weeks that start Sunday 00:00 KST (현상수배 settlement)
function GC.SundayWeek(t)
    return math.floor((U.DayIndex(t) + 4) / 7)
end

local function buff(hero, id, nameKo, stats, days, excludeGuild)
    C.AddBuff(hero, { id = id, nameKo = nameKo, stats = stats, ["until"] = U.Now() + days * 86400,
        excludeGuild = excludeGuild })
end

function GC.Settle(hero, which)
    local g = hero.content.guild
    local R = GD.rewards
    local out = {}
    if which == "bounty" then
        local row = C.TierFor(g.bounty.score, GD.bounty.weekly, "min")
        if row and g.bounty.score > 0 then
            local rw = { wolfCoin = row.wolfCoin }
            if row.pouch then rw[row.pouch[1]] = row.pouch[2] end
            if row.stones then rw.subOptionStone = row.stones end
            for _, l in ipairs(C.Grant(hero, rw, "bountyWeekly")) do out[#out + 1] = l end
            g.bounty.lastWeek = { rank = row.rank, score = g.bounty.score, at = U.Now() }
        end
        return out
    end
    -- 토벌전 -> noblesse tier buff for a week (excluded inside guild content)
    local bossRow = C.TierFor(g.boss.weekBest, C.GUILD_THRESHOLDS.boss, "min")
    if bossRow then
        buff(hero, "guildNoblesse", "토벌전 " .. bossRow.tier, bossRow.stats, 7, true)
        out[#out + 1] = "토벌전 " .. bossRow.tier
    end
    -- 대항전 rank 1..5 -> 미라클 큐브 + EXP / meso buff
    for rank, min in ipairs(C.GUILD_THRESHOLDS.league) do
        if g.league.weekBest >= min then
            local r = R.league[rank]
            C.Grant(hero, { cubeMiracle = r.cubeMiracle }, "guildLeague")
            buff(hero, "guildLeague", "대항전 " .. rank .. "위", { BonusExpPercent = r.expPct * 10,
                BonusGoldPercent = r.mesoPct * 10 }, 7)
            out[#out + 1] = string.format("대항전 %d위: 미라클 큐브 %d", rank, r.cubeMiracle)
            break
        end
    end
    -- 보스 대전 win / lose (PROVISIONAL rival = last week's own best)
    if g.match.weekBest > 0 then
        local win = g.match.weekBest >= (g.match.lastWeekBest or 0)
        local r = win and R.match.win or R.match.lose
        C.Grant(hero, { cubeAdditional = r.cubeAdditional }, "guildMatch")
        buff(hero, "guildMatch", win and "보스 대전 승리" or "보스 대전 패배",
            { BonusExpPercent = r.expPct * 10, BonusGoldPercent = r.mesoPct * 10 }, r.days)
        out[#out + 1] = (win and "보스 대전 승리" or "보스 대전 패배")
    end
    g.match.lastWeekBest = g.match.weekBest
    -- 수련장 rank 1..7 -> 무기 소환권
    for rank, min in ipairs(C.GUILD_THRESHOLDS.training) do
        if g.training.weekBest >= min then
            local r = R.training[rank]
            C.Grant(hero, { weaponTicket = r.weaponTicket }, "guildTraining")
            out[#out + 1] = string.format("수련장 %d위: 무기 소환권 %d", rank, r.weaponTicket)
            break
        end
    end
    for _, m in ipairs(GC.MODES) do
        g[m].lastWeek = g[m].weekBest
        g[m].weekBest = 0
    end
    g.lastSettle = { lines = out, at = U.Now() }
    return out
end

local function record(hero, mode, score)
    local s = hero.content.guild[mode]
    s.dayBest = math.max(s.dayBest or 0, score)
    s.weekBest = math.max(s.weekBest or 0, score)
    s.best = math.max(s.best or 0, score)
end

---------------------------------------------------------------------------
-- 토벌전: endless tiered boss, 50 s +5 s for the first 10 kills (max 100 s)
---------------------------------------------------------------------------
local BossFight = C.Proto()

function BossFight:Setup(b)
    self.tier = 0
    self.killsT = 0
    self:NextBoss(b)
end

function BossFight:NextBoss(b)
    self.tier = math.min(#GD.boss.tiers, self.tier + 1)
    local t = GD.boss.tiers[self.tier]
    local hc = b.heroCreature
    self.boss = self:Spawn(b, { name = string.format("토벌 보스 %d단계", self.tier), hp = t.hp, atk = t.atk, def = t.def,
        avoid = t.avoid, boss = true, stationary = true, x = (hc and hc.x or 0) + 1500, level = self.tier })
end

function BossFight:OnEnemyKilled(b, victim)
    if victim ~= self.boss then return end
    self.killsT = self.killsT + 1
    if self.killsT <= GD.boss.timeKillsMax then
        b.timeLimit = math.min(GD.boss.timeMax * 1000, b.timeLimit + GD.boss.timePerKill * 1000)
    end
    self:NextBoss(b)
end

function BossFight:UpdateTitle(b)
    self.title = string.format("길드 토벌전 · %d단계 · 원점수 %s", self.tier, F(self.heroDamage))
end

function BossFight:Finish(b, reason)
    local raw = self.heroDamage
    local score = C.ConvertScore(raw, GD.boss.brackets)
    record(self.hero, "boss", score)
    return C.Result(true, reason, string.format("길드 토벌전 %d단계 도달 · 원점수 %s → %s점", self.tier, F(raw), F(score)),
        nil, { score = score })
end

---------------------------------------------------------------------------
-- 대항전: waves of 6 minions + boss (targetable after the minions); raw score = boss damage
-- (incl. shield) + minion kill score (max HP + shield of each killed minion)
---------------------------------------------------------------------------
local LeagueFight = C.Proto()

function LeagueFight:Setup(b)
    self.wave = 0
    self.raw = 0
    self:NextWave(b)
end

function LeagueFight:NextWave(b)
    self.wave = math.min(#GD.league.waves, self.wave + 1)
    local w = GD.league.waves[self.wave]
    local hc = b.heroCreature
    local x0 = (hc and hc.x or 0) + 1200
    self.waveStart = b.time
    self.minions = {}
    for i = 1, GD.league.minions do
        local c = self:Spawn(b, { name = "길드 대항전 잡몹", hp = w.minionHp, shield = w.minionShield, atk = w.minionAtk,
            def = w.minionDef, avoid = w.minionAvoidEnd, x = x0 + i * 250, aggro = 1500, tag = "minion" })
        -- avoid starts 20 higher and falls to the base value over about 8 s
        local born, extra = b.time, w.minionAvoidStart - w.minionAvoidEnd
        local decay = GD.league.minionAvoidDecaySec * 1000
        c:AddMod("AvoidChance", "add", function()
            return math.floor(extra * math.max(0, 1 - (b.time - born) / decay))
        end, "avoidDecay")
        c.bornAt = born
        self.minions[#self.minions + 1] = c
    end
    self.boss = self:Spawn(b, { name = "길드 대항전 보스", hp = w.bossHp, shield = w.bossShield, atk = w.bossAtk,
        def = w.bossDef, avoid = w.bossAvoid, boss = true, stationary = true, x = x0 + 2000, untargetable = true,
        tag = "boss" })
end

function LeagueFight:OnDamage(b, att, tgt, dealt)
    if tgt.tag == "boss" and self:IsPlayer(att, b) then self.raw = self.raw + dealt end
end

function LeagueFight:OnEnemyKilled(b, victim)
    if victim.tag == "minion" then
        -- kill score = max HP - remaining HP at death (= max HP)
        self.raw = self.raw + victim:Stat("MaxHp")
    elseif victim.tag == "boss" then
        local bonus = math.min(GD.league.bossKillBonusMax * 1000, b.time - (self.waveStart or 0))
        b.timeLimit = b.timeLimit + bonus
        self:NextWave(b)
    end
end

function LeagueFight:Tick(b)
    if self.boss and self.boss.untargetable then
        local alive = 0
        for _, c in ipairs(self.minions) do
            if c.alive then
                alive = alive + 1
                if b.time - c.bornAt < GD.league.minionAvoidDecaySec * 1000 + 100 then c:Dirty() end
            end
        end
        if alive == 0 then self.boss.untargetable = nil end
    end
end

function LeagueFight:UpdateTitle(b)
    self.title = string.format("길드 대항전 · %d웨이브 · 원점수 %s", self.wave, F(self.raw))
end

function LeagueFight:Finish(b, reason)
    local score = C.ConvertScore(self.raw, GD.league.brackets)
    record(self.hero, "league", score)
    return C.Result(true, reason, string.format("길드 대항전 %d웨이브 · 원점수 %s → %s점", self.wave, F(self.raw), F(score)),
        nil, { score = score })
end

---------------------------------------------------------------------------
-- 보스 대전: unlimited HP, 100 s, damage-reduction stacks (+30% each, max 2), 11.7 s down window
---------------------------------------------------------------------------
local MatchFight = C.Proto()
-- PROVISIONAL timings (not in the data): stack 1 at 30 s, stack 2 at 60 s, down window from 75 s;
-- the down window ("최종 피해 감소 -30%") is applied as +30% damage taken.
MatchFight.STACK_AT = { 30000, 60000 }
MatchFight.DOWN_AT = 75000

function MatchFight:Setup(b)
    local m = GD.match
    local hc = b.heroCreature
    self.boss = self:Spawn(b, { name = "길드 보스", hp = 1e15, atk = m.atk, def = m.def, avoid = m.avoid, boss = true,
        stationary = true, x = (hc and hc.x or 0) + 1500, infinite = true })
    self.stacks = 0
end

function MatchFight:Tick(b)
    local m = GD.match
    while self.stacks < m.maxStacks and b.time >= self.STACK_AT[self.stacks + 1] do
        self.stacks = self.stacks + 1
        self.boss:AddMod("Toughness", "add", m.stackToughness, "matchStack")
    end
    if not self.downMod and b.time >= self.DOWN_AT and b.time < self.DOWN_AT + m.downSec * 1000 then
        self.downMod = self.boss:AddMod("Weakness", "add", -m.downDefencePower, "matchDown")
    elseif self.downMod and b.time >= self.DOWN_AT + m.downSec * 1000 then
        self.boss:RemoveMod(self.downMod)
        self.downMod = false
    end
end

function MatchFight:UpdateTitle(b)
    self.title = string.format("길드 보스 대전 · 피해 %s · 피해감소 %d스택", F(self.heroDamage), self.stacks or 0)
end

function MatchFight:Finish(b, reason)
    record(self.hero, "match", self.heroDamage)
    return C.Result(true, reason, string.format("길드 보스 대전 누적 피해 %s", F(self.heroDamage)), nil,
        { score = self.heroDamage })
end

---------------------------------------------------------------------------
-- 수련장: 84 normal + 3 special spawn points; each point's respawn count picks the stat / score row;
-- 90 s, +2 s every 30 kills; special mobs take exactly 1 damage per hit
---------------------------------------------------------------------------
local TrainFight = C.Proto()
TrainFight.FIELD_MM = 24000   -- PROVISIONAL: spread of the spawn points along the 1D battlefield

function TrainFight:Setup(b)
    local T = GD.training
    self.points = {}
    self.score = 0
    self.kills = 0
    local hc = b.heroCreature
    local x0 = (hc and hc.x or 0) + 600
    local total = T.normalPoints + T.specialPoints
    for i = 1, total do
        local special = i % math.floor(total / T.specialPoints) == 0 and self:SpecialCount() < T.specialPoints
        local p = { x = x0 + (i - 1) * self.FIELD_MM / total, special = special, count = 0, respawnAt = 0 }
        self.points[#self.points + 1] = p
        self:SpawnPoint(b, p)
    end
end

function TrainFight:SpecialCount()
    local n = 0
    for _, p in ipairs(self.points or {}) do if p.special then n = n + 1 end end
    return n
end

function TrainFight:SpawnPoint(b, p)
    local T = GD.training
    p.count = math.min(#T.regular, p.count + 1)
    local row = p.special and T.special[p.count] or T.regular[p.count]
    local c = self:Spawn(b, { name = p.special and "특수 수련 몬스터" or "수련 몬스터", hp = p.special and row.hits or row.hp,
        atk = row.atk, def = row.def, avoid = row.avoid, x = p.x, stationary = true, aggro = 600,
        boss = false, tag = p.special and "special" or "normal" })
    if p.special then c.hitCounter = true end
    c.point = p
    c.scoreValue = row.score
    p.creature = c
    p.respawnAt = nil
end

function TrainFight:OnEnemyKilled(b, victim)
    local p = victim.point
    if not p then return end
    self.score = self.score + (victim.scoreValue or 0)
    self.kills = self.kills + 1
    if self.kills % GD.training.plusPerKills == 0 then b.timeLimit = b.timeLimit + GD.training.plusSec * 1000 end
    p.respawnAt = b.time + (p.special and GD.training.specialRespawnSec or GD.training.normalRespawnSec) * 1000
end

function TrainFight:Tick(b)
    for _, p in ipairs(self.points) do
        if p.respawnAt and b.time >= p.respawnAt then self:SpawnPoint(b, p) end
    end
end

function TrainFight:UpdateTitle(b)
    self.title = string.format("길드 수련장 · 처치 %d · 점수 %s", self.kills, F(self.score))
end

function TrainFight:Finish(b, reason)
    record(self.hero, "training", self.score)
    return C.Result(true, reason, string.format("길드 수련장 처치 %d · 점수 %s", self.kills, F(self.score)), nil,
        { score = self.score })
end

---------------------------------------------------------------------------
-- 현상수배 (불꽃늑대의 소굴): 100 stages, 120 s; first clear adds the stage's hunt score
---------------------------------------------------------------------------
local WolfFight = C.Proto()
GC.BOUNTY_UNLOCK = { 14, 0 }   -- research-income: 길드 현상수배 = 14챕터 보스 + 길드

function WolfFight:Setup(b)
    local s = GD.bounty.stages[self.stage]
    local hc = b.heroCreature
    self.boss = self:Spawn(b, { name = "불꽃늑대", hp = s.hp, atk = s.atk, def = s.def, avoid = s.avoid, boss = true,
        x = (hc and hc.x or 0) + 2000, speed = 800, level = self.stage })
end

function WolfFight:Tick(b) if not self.boss.alive then b:End("clear") end end

function WolfFight:UpdateTitle(b)
    self.title = string.format("불꽃늑대의 소굴 %d단계 · %d%%", self.stage,
        math.floor(100 * math.max(0, self.boss.hp) / math.max(1, self.boss:Stat("MaxHp"))))
end

function WolfFight:Finish(b, reason)
    local hero = self.hero
    local st = hero.content.guild.bounty
    local head = string.format("불꽃늑대의 소굴 %d단계", self.stage)
    if reason ~= "clear" then return C.Result(false, reason, head .. " " .. (C.REASON_KO[reason] or reason)) end
    local lines = {}
    if self.stage > st.max then
        st.max = self.stage
        local add = GD.bounty.stages[self.stage].score
        st.score = st.score + add
        lines[#lines + 1] = string.format("사냥 실적 +%s (누적 %s)", U.Comma(add), U.Comma(st.score))
    end
    record(hero, "bounty", st.score)
    return C.Result(true, reason, head .. " 클리어", lines)
end

---------------------------------------------------------------------------
-- Entry
---------------------------------------------------------------------------
local PROTO = { boss = BossFight, league = LeagueFight, match = MatchFight, training = TrainFight, bounty = WolfFight }
local NAME = { boss = "길드 토벌전", league = "길드 대항전", match = "길드 보스 대전", training = "길드 수련장",
    bounty = "불꽃늑대의 소굴" }
local TIME = { boss = GD.boss.timeBase, league = GD.league.timeBase, match = GD.match.time, training = GD.training.time }

function GC.CanEnter(hero, mode, stage)
    if not C.InGuild() then return false, "길드에 가입해야 합니다." end
    local s = hero.content.guild[mode]
    local cap = GC.DAILY_ENTRIES[mode]
    if cap and s.used >= cap then return false, "오늘 입장 횟수를 모두 사용했습니다." end
    if mode == "bounty" then
        local u = GC.BOUNTY_UNLOCK
        if not C.StageReached(hero, u[1], u[2]) then return false, C.GateText(u[1], u[2]) .. " 후 입장할 수 있습니다." end
        if not stage or stage < 1 or stage > math.min(#GD.bounty.stages, s.max + 1) then
            return false, "도전할 수 없는 단계입니다."
        end
    end
    return true
end

function GC.Enter(hero, mode, stage)
    if mode == "bounty" then stage = stage or math.min(#GD.bounty.stages, hero.content.guild.bounty.max + 1) end
    local ok, err = GC.CanEnter(hero, mode, stage)
    if not ok then return nil, err end
    local s = hero.content.guild[mode]
    s.used = s.used + 1
    local limit = mode == "bounty" and GD.bounty.stages[stage].time or TIME[mode]
    local ctl = C.NewFight(PROTO[mode], { kind = "guild", modeKey = "guild_" .. mode, mode = mode, stage = stage,
        timeLimit = limit * 1000, dungeonType = GD[mode].dungeonType, guildContent = true, title = NAME[mode] })
    local b, e = C.Start(hero, ctl)
    if not b then s.used = s.used - 1 end
    return b, e
end

---------------------------------------------------------------------------
-- UI
---------------------------------------------------------------------------
local function header(hero, mode)
    local s = hero.content.guild[mode]
    local cap = GC.DAILY_ENTRIES[mode]
    return string.format("%s · 오늘 %s · 오늘 최고 %s · 주간 최고 %s · 지난주 %s", C.GuildName(),
        cap and string.format("%d/%d회", s.used, cap) or "무제한", F(s.dayBest), F(s.weekBest), F(s.lastWeek or 0))
end

local INFO = {
    boss = function(hero)
        local row = C.TierFor(hero.content.guild.boss.weekBest, C.GUILD_THRESHOLDS.boss, "min")
        return { "단계별 보스 51종 · 50초 (첫 10회 처치마다 +5초, 최대 100초) · 원점수 = 누적 피해 → 환산 점수",
            "이번 주 예상 노블레스: " .. (row and row.tier or "-") .. " (길드 콘텐츠 밖에서 적용)" }
    end,
    league = function(hero)
        return { "잡몹 6 + 보스 웨이브 81개 · 35초 (보스 처치 시 최대 +20초) · 보호막: 잡몹 30% / 보스 60%",
            "주간 1~5위: 미라클 큐브 15/10/7/5/3 + 경험치·메소 버프 7일" }
    end,
    match = function(hero)
        return { "무한 HP 보스 · 100초 누적 피해 · 받는 피해 감소 30%씩 최대 2스택 · 다운 11.7초",
            "주간 승리: 경험치·메소 +16% 7일 + 에디셔널 큐브 10 / 패배: 경험치 +7% + 에디셔널 큐브 3" }
    end,
    training = function(hero)
        return { "일반 84 + 특수 3 소환 위치 · 90초 (30킬마다 +2초) · 일반몹 점수 = 3 × [100n + 3(n−1)³]",
            "주간 1~7위: 무기 소환권 750/500/350/250/200/150/100" }
    end,
}

for i, mode in ipairs({ "boss", "league", "match", "training" }) do
    C.RegisterMode("guild_" .. mode, {
        order = 70 + i, group = "길드", title = NAME[mode],
        info = function(hero)
            local lines = { header(hero, mode) }
            for _, l in ipairs(INFO[mode](hero)) do lines[#lines + 1] = l end
            lines[#lines + 1] = "|cff999999순위 = 개인 최고 점수 기준 임시 구간 · 입장 횟수 임시값|r"
            return lines
        end,
        actions = { { label = "입장", fn = function(hero) local b, e = GC.Enter(hero, mode); return b ~= nil, e end } },
    })
end

C.RegisterMode("guild_bounty", {
    order = 75, group = "길드", title = "현상수배",
    selectors = {
        { key = "stage", label = "단계", min = 1,
          max = function(hero) return math.min(#GD.bounty.stages, hero.content.guild.bounty.max + 1) end,
          default = function(hero) return math.min(#GD.bounty.stages, hero.content.guild.bounty.max + 1) end },
    },
    info = function(hero, sel)
        local st = hero.content.guild.bounty
        local s = GD.bounty.stages[sel.stage or 1]
        local row = C.TierFor(st.score, GD.bounty.weekly, "min")
        return {
            string.format("불꽃늑대 %d단계: HP %s · 공격력 %s · 방어력 %s · %d초 · 최초 클리어 실적 %s", sel.stage or 1, F(s.hp),
                F(s.atk), F(s.def), s.time, U.Comma(s.score)),
            string.format("최고 단계 %d · 사냥 실적 %s · 일요일 정산 예상 %s", st.max, U.Comma(st.score),
                row and string.format("%s (늑대 코인 %s)", row.rank, U.Comma(row.wolfCoin)) or "-"),
            "|cff999999길드 실적 = 내 사냥 실적 (솔로 길드)|r",
        }
    end,
    actions = { { label = "도전", fn = function(hero, sel) local b, e = GC.Enter(hero, "bounty", sel.stage); return b ~= nil, e end } },
})
