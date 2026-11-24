-- Companions fighting in battle (동료 소환): spawn timing from the client
-- SupporterSpawn skill (first summon 60 s x content ratio / 1000, re-summon
-- every 90 s, 30 s on the field), attack inherited from the hero.
--
-- API
--   ns.Companions.SetupSupporters(battle, hero, profile, opts)   -- called by Game.NewBattle
--   ns.Supporters.CONTENT_RATIO[dungeonType]                      -- first-summon ratio (1000 = 60 s)
local ADDON, ns = ...
local U = ns.U
local D = ns.Data
local SB = ns.SkillBook

local S = {}
ns.Supporters = S

-- client ratios: weapon/enhancement dungeon 100, world boss / guild content 200
-- PROVISIONAL: the chapter-hunt ratio is not in the extracted data; 100 (6 s) is used.
S.CONTENT_RATIO = {
    Campaign = 100, WeaponDungeon = 100, EnhancementDungeon = 100, ExpDungeon = 100, GearDungeon = 100,
    WorldBoss = 200, GuildBoss = 200, GuildLeague = 200,
}

-- Skill set for a companion: its job's rows up to its job step (노말 0차 .. 레전드리 4차).
-- PROVISIONAL: the client SupporterTable skill list is only known as text
-- (D.CompanionSkillText); the job rows of the matching steps are used instead.
local function supporterSkillSet(jobKey, jobStep, level)
    local job = SB.JobByKey(jobKey)
    if not job then return nil end
    local set = { levels = {}, passives = {}, actives = {}, masteries = {}, extraPassives = {} }
    local basicStep = -1
    for _, row in ipairs(job.rows) do
        local step = row.JobStep or 0
        if step <= math.max(1, jobStep) then
            local sid = row.SkillIndex
            set.levels[sid] = SB.RowLevel(row, level, {})
            local cat = SB.Category(row)
            if cat == "basic" then
                if step > basicStep then basicStep = step; set.basic = sid end
            elseif cat == "active" and step >= 1 then
                table.insert(set.actives, sid)
            end
        end
    end
    set.basic = set.basic or job.initialBaseAttack
    return set, job
end

local function copyStats(stats, attackScale)
    local out = { adds = {}, ratios = {}, chains = {}, mults = {} }
    for k, v in pairs(stats.adds or {}) do out.adds[k] = v end
    for k, v in pairs(stats.ratios or {}) do out.ratios[k] = v end
    for k, l in pairs(stats.chains or {}) do out.chains[k] = { unpack(l) } end
    for k, l in pairs(stats.mults or {}) do out.mults[k] = { unpack(l) } end
    out.attackScale = attackScale
    return out
end

function S.Spawn(b, hero, profile, info)
    local heroC = b.heroCreature
    if not (heroC and heroC.alive) then return end
    local set, job = supporterSkillSet(info.jobKey, info.jobStep or 0, profile.level)
    if not set then return end
    -- attack = hero final attack x inheritance (permille)
    local atk = U.trunc(heroC:Stat("Attack") * (info.attackInheritM or 0) / 1000)
    local stats = copyStats(profile.stats)
    stats.adds.Attack = atk
    stats.ratios.Attack = 0
    stats.adds.Str, stats.adds.Dex, stats.adds.Int, stats.adds.Luk, stats.adds.MainStat = 0, 0, 0, 0, 0
    local c = b:AddCreature({
        name = info.name, side = 1, isSupporter = true, level = profile.level, job = job,
        stats = stats, skillSet = set, x = heroC.x - 300, facing = heroC.facing, radiusMm = 250,
        model = ns.Skin and ns.Skin.CompanionModel and ns.Skin.CompanionModel(info) or nil,
        companion = info,
    })
    c.noDie = true
    local dur = (info.spawnMs or D.Combat.supporter.durationMs or 30000)
        * (1 + heroC:Stat("SupporterDurationRatio") / 1000)
    b:Schedule(dur, function()
        if c.alive then
            c.alive = false
            b:Hook("onDespawn", c)
        end
    end)
    b:FireTriggers(heroC, "OnSpawnSupporterSkill", { self = heroC, target = heroC }, 1)
    return c
end

function S.Setup(b, hero, profile, opts)
    local list = profile.companions
    if not list or #list == 0 then return end
    local cfg = D.Combat.supporter
    local ratio = S.CONTENT_RATIO[b.dungeonType or "Campaign"] or 100
    local first = (cfg.initialCoolTimeMs or 60000) * ratio / 1000
    local function cycle()
        if b.ended then return end
        local heroC = b.heroCreature
        for _, info in ipairs(list) do S.Spawn(b, hero, profile, info) end
        local cd = (cfg.coolTimeMs or 90000)
        if heroC then cd = cd * (1 - math.min(999, heroC:Stat("SupporterCoolTimeReduceRatio")) / 1000) end
        b:Schedule(math.max(1000, cd), cycle)
    end
    b:Schedule(first, cycle)
end

ns.Companions = ns.Companions or {}
ns.Companions.SetupSupporters = S.Setup
