-- Chapter content: 챕터 사냥 (hunting field), 도전 (stage challenge) and 챕터 보스.
-- Monster stats, EXP per kill and spawn cycles come from Data.Chapters (client 1.18.0).
--
-- API
--   ns.Campaign.Stage(hero)                 -> chapter, stage, stageData
--   ns.Campaign.SetStage(hero, ch, st)      -- move to an unlocked hunting stage
--   ns.Campaign.CanChallenge(hero)          -> bool, reason
--   ns.Campaign.NewHuntController(hero)     -> battle controller (spawns, kills, rewards)
--   ns.Campaign.NewChallengeController(hero)
--   ns.Campaign.OfflineRewards(hero, seconds) -> rewards table (applied by Game on login)
local ADDON, ns = ...
local U = ns.U
local D = ns.Data
local Hero = ns.Hero

local C = {}
ns.Campaign = C

-- PROVISIONAL: challenge/boss time limits and monster attack values are not in the
-- extracted client data (see research/spec/combat-stages.md "Missing / unknown").
C.CHALLENGE_TIME_MS = 60000
C.BOSS_TIME_MS = 60000
C.CHALLENGE_ATTACK_MULT = 1.0
C.BOSS_ATTACK_MULT = 2.0
C.HERO_REVIVE_MS = 3000

Hero.RegisterSystem("campaign", {
    init = function(hero)
        hero.campaign = hero.campaign or {
            chapter = 1, stage = 1,             -- current hunting stage
            maxChapter = 1, maxStage = 1,       -- furthest unlocked hunting stage
            cleared = {},                       -- ["c-s"] = true (challenge/boss cleared)
            autoChallenge = true,
        }
    end,
})

function C.ChapterData(ch)
    return D.Chapters[ch]
end

function C.StageData(ch, st)
    local c = D.Chapters[ch]
    return c and c.stages[st]
end

function C.Stage(hero)
    local cp = hero.campaign
    return cp.chapter, cp.stage, C.StageData(cp.chapter, cp.stage)
end

function C.StageName(ch, st)
    local skin = ns.Skin and ns.Skin.ChapterName and ns.Skin.ChapterName(ch)
    return string.format("%s %d-%d", skin or ("챕터 " .. ch), ch, st)
end

local function key(ch, st) return ch .. "-" .. st end

function C.IsUnlocked(hero, ch, st)
    local cp = hero.campaign
    if ch < cp.maxChapter then return true end
    if ch == cp.maxChapter then return st <= cp.maxStage end
    return false
end

function C.SetStage(hero, ch, st)
    if not C.IsUnlocked(hero, ch, st) then return false end
    local sd = C.StageData(ch, st)
    if not sd or not sd.hunt then return false end
    hero.campaign.chapter, hero.campaign.stage = ch, st
    Hero.Changed(hero, "stage")
    ns.Fire("STAGE_CHANGED", hero, ch, st)
    return true
end

-- The challenge row of stage s gates hunting on stage s; the last stage of a
-- chapter is the chapter boss which opens the next chapter.
function C.NextChallenge(hero)
    local cp = hero.campaign
    local ch, st = cp.maxChapter, cp.maxStage
    local cd = D.Chapters[ch]
    if not cd then return nil end
    local nst = st + 1
    local nsd = cd.stages[nst]
    if not nsd then
        if D.Chapters[ch + 1] then return ch + 1, 1, "unlock" end
        return nil
    end
    if nsd.boss or nsd.bossFight then return ch, nst, "boss" end
    if nsd.challenge then return ch, nst, "challenge" end
    return ch, nst, "unlock"
end

function C.CanChallenge(hero)
    local ch, st, kind = C.NextChallenge(hero)
    if not ch then return false, "모든 챕터를 클리어했습니다." end
    return true, nil, ch, st, kind
end

---------------------------------------------------------------------------
-- Monster definitions
---------------------------------------------------------------------------
local function monsterDef(ch, st, opts)
    local sd = C.StageData(ch, st)
    local h = sd.hunt or {}
    local hp = opts.hp or h.hp or 100
    local def = {
        name = opts.name or (ns.Skin and ns.Skin.MonsterName and ns.Skin.MonsterName(ch, st, opts.variant)) or "몬스터",
        side = 2,
        level = opts.level or 1,
        isBoss = opts.boss or false,
        x = opts.x or 2000,
        stats = {
            adds = {
                MaxHp = hp,
                Attack = opts.atk or h.atk or 1,
                Defence = opts.def or h.def or 0,
                HitChance = opts.hit or h.hit or 0,
                AvoidChance = opts.avoid or h.avoid or 0,
            },
        },
        radiusMm = opts.boss and 500 or 300,
        reachMm = opts.boss and 900 or 500,
        speedMms = opts.boss and 600 or 900,
        attackIntervalMs = opts.boss and 2500 or 2000,
        model = ns.Skin and ns.Skin.MonsterModel and ns.Skin.MonsterModel(ch, st, opts.variant, opts.boss) or nil,
        chapter = ch, stage = st, variant = opts.variant,
    }
    return def
end
C.MonsterDef = monsterDef

---------------------------------------------------------------------------
-- Rewards: EXP per kill (client chapter table) + per-kill drops (Data.HuntDrops)
---------------------------------------------------------------------------
local function stageKey(ch, st) return ch .. "-" .. st end

-- online: every drop rolls independently (probability per 1,000,000)
function C.KillRewards(hero, ch, st, sd, stats, rng)
    local rewards = {}
    local expBonus = stats and stats.BonusExpPercent or 0
    rewards.exp = (sd.exp or 0) * (1 + expBonus / 1000)
    local drops = D.HuntDrops and D.HuntDrops[stageKey(ch, st)]
    if drops then
        rng = rng or U.rng
        for _, dr in ipairs(drops) do
            if rng:Float() * 1000000 < dr.ppm then
                local n = dr.n
                if dr.key == "meso" and stats and stats.BonusGoldPercent then
                    n = math.floor(n * (1 + stats.BonusGoldPercent / 1000))
                end
                rewards[dr.key] = (rewards[dr.key] or 0) + n
            end
        end
    end
    return rewards
end

function C.ApplyRewards(hero, rewards, reason)
    for k, v in pairs(rewards) do
        if k == "exp" then
            Hero.GainExp(hero, v)
        elseif v > 0 then
            Hero.Add(hero, k, v, reason)
        end
    end
end

function C.FirstClearRewards(ch, st, kind)
    if kind == "boss" then
        local b = D.BossRewards and D.BossRewards[ch]
        return b and b.rewards
    end
    local t = D.TrialRewards and D.TrialRewards[stageKey(ch, st)]
    return t and t.rewards
end

---------------------------------------------------------------------------
-- Hunting controller
---------------------------------------------------------------------------
local Hunt = {}
Hunt.__index = Hunt

function C.NewHuntController(hero)
    local ch, st, sd = C.Stage(hero)
    return setmetatable({ hero = hero, ch = ch, st = st, sd = sd, nextSpawn = 0, kind = "hunt" }, Hunt)
end

function Hunt:Spawn(b)
    local sd = self.sd
    local sp = sd.spawn or { n = 10, cycle = 20 }
    local alive = 0
    for _, c in ipairs(b.creatures) do
        if c.alive and c.side == 2 then alive = alive + 1 end
    end
    local hero = b.heroCreature
    local baseX = hero and hero.x or 0
    local n = math.max(0, (sp.n or 10) - alive)
    local variants = (sd.hunt and sd.hunt.variants) or 1
    for i = 1, n do
        local v = ((i - 1) % variants) + 1
        local x = baseX + 1500 + b.rng:Int(0, 14000)
        local def = monsterDef(self.ch, self.st, { x = x, variant = v, level = self.ch * 3 })
        def.aggroMm = 1200
        b:AddCreature(def)
    end
end

function Hunt:Update(b, dt)
    if not self.init then
        self.init = true
        -- 1-1 is NoUserDie in the client; other hunt stages restart on death (ExitToRetry)
        if self.ch == 1 and self.st == 1 and b.heroCreature then b.heroCreature.noDie = true end
    end
    if b.time >= self.nextSpawn then
        self:Spawn(b)
        local cycle = (self.sd.spawn and self.sd.spawn.cycle) or 20
        self.nextSpawn = b.time + cycle * 1000
    end
    local hero = b.heroCreature
    if hero and not hero.alive then
        if not hero.reviveAt then
            hero.reviveAt = b.time + C.HERO_REVIVE_MS
            -- stage restarts: clear the field and respawn after the revive
            for _, c in ipairs(b.creatures) do
                if c.side == 2 and c.alive then c.alive = false; b:Hook("onDespawn", c) end
            end
            self.nextSpawn = hero.reviveAt
            hero.x = 0
        end
        if b.time >= hero.reviveAt then
            hero.reviveAt = nil
            hero.alive = true
            hero.hp = hero:Stat("MaxHp")
            hero.mp = hero:Stat("MaxMp")
            hero.states = {}
            hero:Dirty()
            b:Hook("onRevive", hero)
        end
    end
    if b.time % 5000 < dt then b:Cleanup() end
end

function Hunt:OnKill(b, victim)
    if victim.side ~= 2 then return end
    local hero = self.hero
    local rewards = C.KillRewards(hero, self.ch, self.st, self.sd, b.heroCreature and b.heroCreature.statCache, b.rng)
    C.ApplyRewards(hero, rewards, "hunt")
    hero.stats.kills = (hero.stats.kills or 0) + 1
    ns.Fire("MONSTER_KILLED", hero, victim, rewards, "hunt")
end

---------------------------------------------------------------------------
-- Challenge / boss controller
---------------------------------------------------------------------------
local Chal = {}
Chal.__index = Chal

function C.NewChallengeController(hero)
    local ok, reason, ch, st, kind = C.CanChallenge(hero)
    if not ok then return nil, reason end
    if kind == "unlock" then
        -- stage without a challenge row: unlock directly
        local cp = hero.campaign
        cp.maxChapter, cp.maxStage = ch, st
        cp.chapter, cp.stage = ch, st
        Hero.Changed(hero, "stage")
        return nil, "unlocked"
    end
    local sd = C.StageData(ch, st)
    local row = (kind == "boss") and (sd.bossFight or sd.challenge) or sd.challenge
    local self = setmetatable({ hero = hero, ch = ch, st = st, sd = sd, row = row or {}, kind = kind, spawned = 0,
        killed = 0 }, Chal)
    self.total = (row and row.monsterCount) or 1
    if kind == "boss" then
        local br = D.BossRewards and D.BossRewards[ch]
        self.bossInfo = br
        self.timeLimit = (br and br.time and br.time * 1000) or C.BOSS_TIME_MS
    else
        local tr = D.TrialRewards and D.TrialRewards[ch .. "-" .. st]
        self.timeLimit = (tr and tr.time and tr.time * 1000) or C.CHALLENGE_TIME_MS
        if tr and tr.maxAcc then self.total = tr.maxAcc end
    end
    self.alreadyCleared = hero.campaign.cleared[key(ch, st)] and true or false
    return self
end

function Chal:Update(b, dt)
    local hero = b.heroCreature
    if not self.started then
        self.started = true
        self:SpawnWave(b)
    end
    if hero and not hero.alive then
        b:End("fail")
        return
    end
    -- refill normal monsters, then the boss last
    local alive = 0
    for _, c in ipairs(b.creatures) do
        if c.alive and c.side == 2 then alive = alive + 1 end
    end
    if alive == 0 and self.spawned < self.total then self:SpawnWave(b) end
    if self.killed >= self.total then b:End("clear") end
    if b.time >= self.timeLimit then b:End("timeout") end
end

function Chal:SpawnWave(b)
    local row, sd = self.row, self.sd
    local hero = b.heroCreature
    local baseX = hero and hero.x or 0
    local remaining = self.total - self.spawned
    local hunt = sd.hunt or (C.StageData(self.ch, self.st - 1) or {}).hunt or {}
    if self.kind == "boss" or remaining == 1 then
        local atk = (hunt.atk or 1) * (self.kind == "boss" and C.BOSS_ATTACK_MULT or C.CHALLENGE_ATTACK_MULT)
        local bi = self.bossInfo
        if bi and bi.atk then atk = bi.atk end
        b:AddCreature(monsterDef(self.ch, self.st, { boss = true, x = baseX + 2500, hp = row.bossHp, atk = atk,
            def = row.defense, hit = row.hitChance, avoid = row.avoidChance, level = self.ch * 3 + 5,
            name = self.kind == "boss" and ns.Skin and ns.Skin.BossName and ns.Skin.BossName(self.ch) or nil }))
        self.spawned = self.spawned + 1
        return
    end
    local wave = math.min(remaining - 1, 12)
    for i = 1, wave do
        local hp = row.normalHpMin or hunt.hp
        if row.normalHpMax and row.normalHpMin and row.normalHpMax > row.normalHpMin then
            hp = row.normalHpMin + (row.normalHpMax - row.normalHpMin) * (self.spawned + i) / math.max(1, self.total)
        end
        b:AddCreature(monsterDef(self.ch, self.st, { x = baseX + 1200 + i * 280, hp = math.floor(hp or 100),
            atk = (hunt.atk or 1) * C.CHALLENGE_ATTACK_MULT, def = row.defense, hit = row.hitChance, avoid = row.avoidChance,
            variant = ((i - 1) % ((hunt.variants) or 1)) + 1, level = self.ch * 3 }))
    end
    self.spawned = self.spawned + wave
end

function Chal:OnKill(b, victim)
    if victim.side == 2 then self.killed = self.killed + 1 end
end

function Chal:OnEnd(b, reason)
    local hero = self.hero
    if reason == "clear" then
        local cp = hero.campaign
        cp.cleared[key(self.ch, self.st)] = true
        if self.kind == "boss" then
            if D.Chapters[self.ch + 1] then
                cp.maxChapter, cp.maxStage = self.ch + 1, 1
                cp.chapter, cp.stage = self.ch + 1, 1
            end
        else
            cp.maxChapter, cp.maxStage = self.ch, self.st
            cp.chapter, cp.stage = self.ch, self.st
        end
        if not self.alreadyCleared then
            local rw = C.FirstClearRewards(self.ch, self.st, self.kind)
            if rw then C.ApplyRewards(hero, rw, "firstClear") end
            self.firstRewards = rw
        end
        ns.Fire("STAGE_CLEARED", hero, self.ch, self.st, self.kind)
        Hero.Changed(hero, "stage")
    else
        ns.Fire("STAGE_FAILED", hero, self.ch, self.st, self.kind, reason)
    end
end

---------------------------------------------------------------------------
-- Offline rewards: 0.9 kills/s at the furthest stage reached, 5 min minimum,
-- 24 h cap (KR 2026-02-12), whole minutes; drops are deterministic
-- floor(kills x rate) x amount (global wiki Hunting_and_Offline_Rewards).
---------------------------------------------------------------------------
C.OFFLINE_CAP_SECONDS = 24 * 3600

function C.OfflineRewards(hero, seconds, stats)
    local off = D.Combat.offline
    local minS = tonumber(off.minimumRewardSeconds) or 300
    if seconds < minS then return nil end
    seconds = math.min(seconds, C.OFFLINE_CAP_SECONDS)
    seconds = math.floor(seconds / 60) * 60
    local kps = tonumber(off.killsPerSecond) or 0.9
    local kills = math.floor(kps * seconds)
    local cp = hero.campaign
    local ch, st = cp.maxChapter, cp.maxStage
    local sd = C.StageData(ch, st)
    if not sd or not sd.hunt then ch, st, sd = C.Stage(hero) end
    if not sd then return nil end
    local total = { kills = kills, seconds = seconds }
    local expBonus = stats and stats.BonusExpPercent or 0
    total.exp = (sd.exp or 0) * kills * (1 + expBonus / 1000)
    local drops = D.HuntDrops and D.HuntDrops[stageKey(ch, st)]
    if drops then
        for _, dr in ipairs(drops) do
            local n = math.floor(kills * dr.ppm / 1000000) * dr.n
            if dr.key == "meso" and stats and stats.BonusGoldPercent then
                n = math.floor(n * (1 + stats.BonusGoldPercent / 1000))
            end
            if n > 0 then total[dr.key] = (total[dr.key] or 0) + n end
        end
    end
    return total
end
