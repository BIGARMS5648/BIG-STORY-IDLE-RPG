-- Headless content test: runs every content mode once with a strong test profile and checks
-- rewards, tickets / keys, entry counts and daily / weekly resets.
-- Usage (repo root): lua5.1 tools/test/test_content.lua
package.path = "tools/test/?.lua;" .. package.path
local Stub = require("wowstub")
Stub.Install()
local H = require("harness")
H.loadToc()
-- content files (until they are listed in the TOC)
local function loadIfMissing(path, check)
    if not check() then H.load(path) end
end
local ns = H.ns
loadIfMissing("Data/Content.lua", function() return ns.Data.ContentGrowth end)
loadIfMissing("Systems/Content.lua", function() return ns.Content end)
loadIfMissing("Systems/ContentDungeons.lua", function() return ns.Content.Growth end)
loadIfMissing("Systems/ContentBosses.lua", function() return ns.Content.Raid end)
loadIfMissing("Systems/ContentParty.lua", function() return ns.Content.PartyQuest end)
loadIfMissing("UI/ContentPanel.lua", function() return ns.UI.panels.content end)

local C = ns.Content
local D = ns.Data
local Hero = ns.Hero
local SB = ns.SkillBook
local U = ns.U

local errors, checks, failed = 0, 0, 0
ns.Print = function(fmt, ...)
    local msg = select("#", ...) > 0 and string.format(fmt, ...) or tostring(fmt)
    if msg:find("오류") then errors = errors + 1; print("PRINT", msg) end
end
ns.Debug = function(fmt, ...) errors = errors + 1; if errors < 20 then print("DEBUG", string.format(fmt, ...)) end end

local function check(cond, what)
    checks = checks + 1
    if not cond then failed = failed + 1; print("FAIL", what) end
end
local function approx(a, b, rel) return math.abs(a - b) <= math.abs(b) * (rel or 0.01) end

local ef = ns.eventFrame
ef._scripts.OnEvent(ef, "ADDON_LOADED", "BigStoryIdleRPG")
ef._scripts.OnEvent(ef, "PLAYER_LOGIN")

local clock = os.time()
U.Now = function() return clock end

local hero = Hero.New("hero", "테스터")
hero.level = 140
hero.campaign.maxChapter, hero.campaign.maxStage = 47, 20
Hero.SetActive(hero)
Stub.RunTimers()

-- strong test profile (level 140, all masteries, huge stats)
local job = SB.JobByKey("hero")
local set = SB.Build({ jobKey = "hero", level = 140, masteries = SB.AllMasteriesAt(job, 140) })
C.profileOverride = {
    name = "테스터", jobKey = "hero", level = 140, skillSet = set,
    stats = { adds = { Attack = 1e17, MaxHp = 1e24, MaxMp = 1e7, MpRegen = 1e5, Defence = 1e6, Str = 1e6,
        CriticalChance = 1000, CriticalPower = 2000, MinDamageRatio = 1000, MaxDamageRatio = 1200, HitChance = 5000,
        RunSpeedMms = 6000, AttackPowerToBoss = 2000 }, ratios = {}, chains = { AttackSpeed = { 1000 } }, mults = {} },
}

local function run(b, maxMs)
    check(b ~= nil, "battle started")
    if not b then return end
    local stop = b.time + (maxMs or 600000)
    while not b.ended and b.time < stop do b:Step() end
    check(b.ended, "battle ended")
    Stub.RunTimers()
end

local function last(key) return C.LastResult(hero, key) or {} end
local function W(key) return Hero.Count(hero, key) end
local function show(key)
    local r = last(key)
    print(string.format("  %-20s %s", key, table.concat(r.lines or { "-" }, " | ")))
end

-- 10th-stage first clear pays 5x the stage reward (+1 key); 무기 던전 40: 250 / 68,500
do
    local G2 = C.Growth
    local rw = G2.StageReward("weapon", 40, U.NewRNG(1))
    check(rw.weaponTicket == 50 and rw.weaponStone == 13700, "weapon dungeon stage 40 reward 50 / 13,700")
    check(G2.StageReward("weapon", 10, U.NewRNG(1)).weaponStone == 4700, "weapon dungeon stage 10 stones 4,700")
    check(G2.StageReward("gear", 1, U.NewRNG(1)).eliteSummonPoint == 200, "gear dungeon stage 1 = 200")
    check(G2.StageReward("training", 1, U.NewRNG(1)).heroToken == 250, "training stage 1 = 250")
    check(G2.StageReward("enhance", 1, U.NewRNG(1)).spellTrace == 155, "enhance stage 1 = 155 traces")
end

-- 1. AI allies ----------------------------------------------------------------
local allies = C.MakeAllies(hero, C.profileOverride, 7, U.NewRNG(3))
local seen = {}
for _, a in ipairs(allies) do
    check(a.isSupporter and a.side == 1 and a.skillSet and a.skillSet.basic, "ally def " .. a.name)
    check(not seen[a.jobKey] and a.jobKey ~= "hero", "distinct ally job " .. a.jobKey)
    seen[a.jobKey] = true
    check(a.statFactor >= C.ALLY_STAT_MIN and a.statFactor <= C.ALLY_STAT_MAX, "ally factor")
end
check(#allies == 7, "7 allies")

-- 2. growth dungeons -------------------------------------------------------------
local G = C.Growth
for _, key in ipairs(G.KEYS) do
    local wk = G.WALLET[key]
    check(W(wk) == 3, key .. " starts with 3 keys")
    local before = W(wk)
    run(G.Enter(hero, key, 1), 120000)
    local r = last("growth_" .. key)
    check(r.ok, key .. " stage 1 clear")
    check(hero.content.growth[key].max == 1, key .. " max stage 1")
    -- first clear of a stage gives +1 key of that dungeon (all dungeons)
    if key == "enhance" then
        check(W(wk) == before, "enhance clear uses a key, first clear gives one back")
    else
        check(W(wk) == before + 1, key .. " key returned on clear + 1 for the first clear")
    end
    show("growth_" .. key)
end
-- failure keeps the key: weapon stage 2 with a weak profile
local strong = C.profileOverride
C.profileOverride = { name = "약함", jobKey = "hero", level = 1, skillSet = SB.Build({ jobKey = "hero", level = 1 }),
    stats = { adds = { Attack = 1, MaxHp = 50, MaxMp = 10, MinDamageRatio = 800, MaxDamageRatio = 1000 }, ratios = {},
        chains = {}, mults = {} } }
local keysBefore = W("weaponDungeonKey")
run(G.Enter(hero, "weapon", 2), 60000)
check(not last("growth_weapon").ok, "weak profile fails weapon 2")
check(W("weaponDungeonKey") == keysBefore, "failure keeps the key")
C.profileOverride = strong
-- sweep: 1 key -> reward of the highest stage
local tickets = W("weaponTicket")
check(G.Sweep(hero, "weapon", 1), "weapon sweep")
check(W("weaponDungeonKey") == keysBefore - 1, "sweep uses a key")
check(W("weaponTicket") > tickets, "sweep gives weapon tickets")
local expBefore = hero.exp
hero.level = 30
check(G.Sweep(hero, "exp", 1), "exp sweep")
check(hero.level > 30 or hero.exp > expBefore, "exp sweep gives EXP (" .. D.ContentGrowth.exp.sweepExp[1] .. ")")
hero.level = 140
check(not G.CanBulkSweep(hero), "bulk sweep locked before 50")
for _, key in ipairs(G.KEYS) do hero.content.growth[key].max = 50 end
check(G.CanBulkSweep(hero), "bulk sweep unlocked at 50 x 5")
check(G.BulkSweep(hero), "bulk sweep")
for _, key in ipairs(G.KEYS) do check(W(G.WALLET[key]) == 0, key .. " keys used by bulk sweep") end
-- enhancement scroll odds: 10% total
local rng, n, got = U.NewRNG(11), 20000, 0
for _ = 1, n do
    local rw = G.StageReward("enhance", 150, rng)
    for k in pairs(rw) do if k:find("^scroll") then got = got + 1 end end
end
check(math.abs(got / n - 0.10) < 0.01, string.format("enhance scroll rate %.3f ~ 0.10", got / n))

-- stage 40 first clear: stage reward (50 / 13,700) + 5x bonus (250 / 68,500) + 1 key
do
    hero.content.growth.weapon.max = 39
    Hero.Add(hero, "weaponDungeonKey", 1)
    local t0, s0, k0 = W("weaponTicket"), W("weaponStone"), W("weaponDungeonKey")
    run(G.Enter(hero, "weapon", 40), 120000)
    check(last("growth_weapon").ok, "weapon stage 40 clear")
    check(W("weaponTicket") - t0 == 300 and W("weaponStone") - s0 == 82200,
        "stage 40 first clear 50+250 tickets, 13,700+68,500 stones (got " .. (W("weaponTicket") - t0) .. ", "
        .. (W("weaponStone") - s0) .. ")")
    check(W("weaponDungeonKey") == k0 + 1, "stage 40 first clear +1 key")
end

-- 3. daily reset: +3 keys (cap 10), quick hunt counters, balrog ticket
local function nextDay(days)
    clock = clock + 86400 * (days or 1)
    Hero.CheckResets(hero)
    Stub.RunTimers()
end
Hero.Add(hero, "expDungeonKey", 8)
local wk0 = W("weaponDungeonKey")
nextDay(1)
check(W("weaponDungeonKey") == math.min(10, math.max(wk0, wk0 + 3)), "daily +3 keys")
check(W("expDungeonKey") == 10, "daily keys capped at 10")
nextDay(3)
check(W("weaponDungeonKey") == 10, "3 missed days accumulate to cap 10")

-- 4. quick hunt
local Q = C.QuickHunt
check(Q.Kills(hero) == 1000, "quick hunt first use 1000 kills")
check(Q.Use(hero), "quick hunt free")
check(Q.Kills(hero) == 1005, "quick hunt +5 per use")
check(Q.Use(hero), "quick hunt ad->free")
Hero.Add(hero, "redDia", 600)
local red0 = W("redDia")
check(Q.Use(hero), "quick hunt red 500")
check(W("redDia") == red0 - 500 + (last("quickHunt").rewards.redDia or 0), "quick hunt cost 500 red")
Hero.Spend(hero, "redDia", W("redDia"))
check(not Q.Use(hero, "red"), "second red use needs 750")
show("quickHunt")
nextDay(1)
check(Q.Options(hero).free == 1 and Q.Options(hero).red == 500, "quick hunt daily reset")

-- 5. burning field
Hero.Add(hero, "burningBooster", 1)
check(C.Burning.Use(hero), "burning booster")
check(C.Burning.Active(hero) == 600, "burning 600 s")

-- 6. world boss
local WB = C.WorldBoss
run(WB.Enter(hero, 1), 60000)
check(last("worldBoss").ok and hero.content.worldBoss.max == 1, "world boss Lv1 kill")
show("worldBoss")
hero.content.worldBoss.max = 19
run(WB.Enter(hero, 20), 100000)
local s20 = last("worldBoss").score or 0
check(s20 > 0 and hero.content.worldBoss.dayBest >= s20, "world boss Lv20 damage score")
show("worldBoss")
local coins = W("worldBossCoin")
local tier = WB.TierFor(hero.content.worldBoss.dayBest)
nextDay(1)
check(tier and W("worldBossCoin") == coins + tier.daily, "world boss daily tier coins (" .. (tier and tier.name or "-") .. ")")
check(hero.content.worldBoss.dayBest == 0, "world boss daily best reset")

-- 7. boss raids
local R = C.Raid
local function raid(boss, diff, mode, opts)
    local base, shared = R.Entries(hero, boss)
    run(R.Enter(hero, boss, diff, mode, opts), 600000)
    show("raid_" .. boss)
    return base, shared
end
local base, shared = raid("zakum", 1, "party")
check(last("raid_zakum").ok, "zakum easy party clear")
check(R.Entries(hero, "zakum") == base - 1, "zakum base entry used")
base, shared = raid("horntail", 2, "single")
check(last("raid_horntail").ok, "horntail normal single clear")
base, shared = raid("pinkbean", 2, "party", { double = true })
check(last("raid_pinkbean").ok, "pinkbean normal party clear (2 tickets)")
local b2, s2 = R.Entries(hero, "pinkbean")
check(b2 == 0 and s2 == shared, "double reward uses 2 base entries")
raid("zakum", 4, "party", { challenge = true })
check(R.Entries(hero, "zakum") == 1, "challenge mode uses no entry")
check(R.Sweep(hero, "zakum", 1), "zakum sweep")
check(R.Entries(hero, "zakum") == 0, "sweep uses an entry")
check(not R.Sweep(hero, "zakum", 1) or W("bossRaidTicket") == shared - 1, "sweep falls back to shared ticket")
-- reward distribution: 25% gear, 4% scroll, 71% fallback
local cnt = { gear = 0, scroll = 0, other = 0 }
rng = U.NewRNG(5)
for _ = 1, 20000 do
    local rw = R.RollReward("zakum", 2, rng)
    if rw.gear then cnt.gear = cnt.gear + 1
    elseif rw.scrollZakum1 or rw.scrollZakum2 then cnt.scroll = cnt.scroll + 1
    else cnt.other = cnt.other + 1 end
end
check(math.abs(cnt.gear / 20000 - 0.25) < 0.01 and math.abs(cnt.scroll / 20000 - 0.04) < 0.005,
    string.format("raid odds gear %.3f scroll %.3f", cnt.gear / 20000, cnt.scroll / 20000))
local inbox = #hero.content.gearInbox
local eqItems = ns.Equipment and ns.Equipment.ItemCount and ns.Equipment.ItemCount(hero) or 0
print(string.format("  gear: equipment items %d, inbox %d", eqItems, inbox))
-- weekly reset
clock = clock + 7 * 86400
Hero.CheckResets(hero)
Stub.RunTimers()
check(R.Entries(hero, "zakum") == 2 and R.Entries(hero, "pinkbean") == 2, "weekly raid entries 2 per boss")
check(W("bossRaidTicket") >= 2, "weekly shared raid tickets")
local red1, rt = W("redDia"), W("bossRaidTicket")
Hero.Add(hero, "redDia", 2000)
check(R.BuyTicket(hero) and W("redDia") == red1 and W("bossRaidTicket") == rt + 1, "raid ticket refill 2000 red")

-- 9. 마왕 발록
local BL = C.Balrog
local tk = W("balrogTicket")
local wt = W("weaponTicket")
run(BL.Enter(hero, 1), 120000)
show("balrog")
check(last("balrog").ok and W("balrogTicket") == tk, "balrog kill refunds the ticket")
check(W("weaponTicket") == wt + 100, "balrog stage 1 reward 무기 소환권 100")

-- 10. party quests + expedition + monster park
local PQ = C.PartyQuest
run(PQ.Enter(hero, 1, 1), 400000)
show("pq_first")
check(last("pq_first").ok, "PQ 첫 번째 동행 쉬움 clear")
run(PQ.Enter(hero, 4, 4), 400000)
show("pq_romeo")
check(last("pq_romeo").ok, "PQ 로미오와 줄리엣 카오스 clear")
local et = W("explorationTicket")
check(PQ.Expedition(hero, 1, 1) and W("explorationTicket") == et - 1, "PQ expedition")
local MP = C.MonsterPark
local mt = W("monsterParkTicket")
run(MP.Enter(hero, 1, true), 1800000)
check(last("monsterPark").ok and W("monsterParkTicket") == mt, "monster park practice: no ticket")
run(MP.Enter(hero, 1), 1800000)
show("monsterPark")
check(last("monsterPark").ok and W("monsterParkTicket") == mt - 1, "monster park clear uses a ticket")

-- 11. rewards moved from the removed guild content
local Rl = ns.Relocated
check(Rl ~= nil and C.Guild == nil and C.GuildRaid == nil, "guild content removed")
check(D.Currencies.guildCoin == nil and D.Currencies.wolfCoin == nil, "guild coins removed")
hero.relocated.raidWeek.cleared.zakum = true
hero.relocated.parkBest = 10
hero.relocated.trainingPlayed = true
hero.content.growth.training.max = math.max(hero.content.growth.training.max, 1)
hero.content.worldBoss.weekBest = 1e30
local add, cubes, wt2, wbc, stones = W("cubeAdditional"), W("cubeMiracle"), W("weaponTicket"), W("worldBossCoin"), W("subOptionStone")
clock = clock + 7 * 86400
Hero.CheckResets(hero)
check(W("cubeAdditional") >= add + 10, "boss raid week -> 에디셔널 큐브 10 (former 길드 보스 대전)")
check(W("cubeMiracle") >= cubes + 15, "monster park week -> 미라클 큐브 15 (former 길드 대항전)")
check(W("weaponTicket") >= wt2 + 100, "용사의 수련장 week -> 무기 소환권 (former 길드 수련장)")
check(W("worldBossCoin") >= wbc + 14000 and W("subOptionStone") >= stones + 300, "world boss week -> bounty rewards")
check(#C.ActiveBuffs(hero) > 0, "relocated weekly buffs")
Hero.Add(hero, "worldBossCoin", 5000)
check(Rl.BuyWB(hero, 6), "world boss coin shop (최상급 마법 부여 주머니)")
print("  relocated: " .. table.concat(hero.relocated.lastWeek.lines, ", "))

-- 12. UI panel
ns.UI.Toggle()
ns.UI.ShowPanel("content")
local p = ns.UI.panels.content.frame
for _, def in ipairs(C.Modes()) do
    p.current = def.key
    ns.UI.RefreshPanel()
end
check(#C.Modes() >= 17, "modes registered: " .. #C.Modes())

-- 전직 시험: 2차 (collect 30) -> 3차 (clone) -> 4차 (two 13조 bosses); skills above the step stay locked
do
    local JA = ns.JobAdvance
    hero.jobStep = 1
    local function nActives(step)
        local set = SB.Build({ jobKey = "hero", level = 140, jobStep = step })
        return #set.actives + #set.passives
    end
    check(nActives(1) < nActives(2) and nActives(2) < nActives(4), "job steps unlock more skills")
    local p1 = Hero.BuildProfile(hero)
    check(p1.jobStep == 1, "profile carries the job step")
    for step = 2, 4 do
        local nx = JA.Next(hero)
        check(nx and nx.step == step and nx.ready, "job test " .. step .. " ready")
        run(JA.Enter(hero))
        local res = C.LastResult(hero, "jobAdvance")
        check(res and res.ok and hero.jobStep == step, "job advancement " .. step .. " cleared")
    end
    check(JA.Next(hero) == nil, "all job advancements done")
    local low = Hero.New("paladin", "L")
    low.level = 29
    check(not JA.Next(low).ready and not JA.Enter(low), "2nd job test needs Lv30")
    check(JA.StepForLevel(100) == 4 and JA.StepForLevel(59) == 2, "migration step by level")
end

print(string.format("content test: %d checks, %d failed, %d errors · Lv %d · wallet: %s", checks, failed, errors,
    hero.level, (function()
        local parts = {}
        for _, k in ipairs(U.Keys(hero.wallet)) do parts[#parts + 1] = k .. "=" .. U.FormatNumber(hero.wallet[k]) end
        return table.concat(parts, " ")
    end)()))
if failed > 0 or errors > 0 then os.exit(1) end
