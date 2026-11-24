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
loadIfMissing("Systems/ContentGuild.lua", function() return ns.Content.Guild end)
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

-- 0. score conversion against the published examples ---------------------------
local GD = D.ContentGuild
check(approx(C.ConvertScore(1e8, GD.boss.brackets), 9.585e6, 0.002), "토벌전 1억 -> 958.5만")
check(approx(C.ConvertScore(1e12, GD.boss.brackets), 2.315e9, 0.002), "토벌전 1조 -> 23.15억")
check(approx(C.ConvertScore(1e8, GD.league.brackets), 1.2917e6, 0.002), "대항전 1억 -> 129.17만")
check(approx(C.ConvertScore(1e16, GD.league.brackets), 2.6889e10, 0.002), "대항전 1경 -> 268.89억")

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
    if key == "enhance" then
        check(W(wk) == before - 1, "enhance clear uses a key")
    else
        check(W(wk) == before, key .. " key returned on clear")
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

-- 3. daily reset: +3 keys (cap 10), quick hunt counters, balrog ticket
local function nextDay(days)
    clock = clock + 86400 * (days or 1)
    Hero.CheckResets(hero)
    Stub.RunTimers()
end
Hero.Add(hero, "expDungeonKey", 8)
nextDay(1)
check(W("weaponDungeonKey") == 3, "daily +3 keys")
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

-- 8. guild raids
local GR = C.GuildRaid
run(GR.Enter(hero, "zakum"), 600000)
show("guildRaid_zakum")
check(GR.Progress(hero, "zakum") > 0, "guild raid zakum damage")
check(W("scrollZakum1") >= 3, "guild raid cumulative scroll reward")
run(GR.Enter(hero, "horntail"), 600000)
show("guildRaid_horntail")
run(GR.Enter(hero, "pinkbean"), 600000)
show("guildRaid_pinkbean")
check(GR.Progress(hero, "pinkbean") > 0, "pink bean guild raid body damage")
check(hero.content.guildRaid.pinkbean.snapshot and (hero.content.guildRaid.pinkbean.snapshot.seals or 0) > 0,
    "pink bean statues sealed")

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

-- 11. guild content
local GC = C.Guild
for _, mode in ipairs({ "boss", "league", "match", "training" }) do
    run(GC.Enter(hero, mode), 400000)
    show("guild_" .. mode)
    check((last("guild_" .. mode).score or 0) > 0, "guild " .. mode .. " score")
end
run(GC.Enter(hero, "bounty", 1), 200000)
show("guild_bounty")
check(hero.content.guild.bounty.score == 100, "bounty first clear hunt score 100")
-- weekly settlement (Monday) + bounty settlement (Sunday)
local cubes, add, wolf = W("cubeMiracle"), W("cubeAdditional"), W("wolfCoin")
clock = clock + 7 * 86400
Hero.CheckResets(hero)
check(W("cubeAdditional") > add, "guild boss battle weekly reward")
-- bounty settles Sunday 00:00: score 100 meets the "501~1,000위 (min 100)" row -> 6,800 coins
check(W("wolfCoin") == wolf + 6800, "bounty weekly rank reward (score 100 -> 6,800 coins)")
check(#C.ActiveBuffs(hero) > 0, "guild weekly buffs")
print("  guild settle: " .. table.concat(hero.content.guild.lastSettle and hero.content.guild.lastSettle.lines or {}, ", "))

-- 12. UI panel
ns.UI.Toggle()
ns.UI.ShowPanel("content")
local p = ns.UI.panels.content.frame
for _, def in ipairs(C.Modes()) do
    p.current = def.key
    ns.UI.RefreshPanel()
end
check(#C.Modes() >= 20, "modes registered: " .. #C.Modes())

print(string.format("content test: %d checks, %d failed, %d errors · Lv %d · wallet: %s", checks, failed, errors,
    hero.level, (function()
        local parts = {}
        for _, k in ipairs(U.Keys(hero.wallet)) do parts[#parts + 1] = k .. "=" .. U.FormatNumber(hero.wallet[k]) end
        return table.concat(parts, " ")
    end)()))
if failed > 0 or errors > 0 then os.exit(1) end
