-- Free income: missions, pass, attendance, free claims, red shop, newcomer.
package.path = "tools/test/?.lua;" .. package.path
local Stub = require("wowstub")
Stub.Install()
local H = require("harness")
H.loadToc()
local ns = H.ns
ns.InitDB()
local errors = 0
ns.Print = function() end
ns.Debug = function(fmt, ...) errors = errors + 1; print("DEBUG", string.format(fmt, ...)) end
local Hero, I = ns.Hero, ns.Income
local hero = Hero.New("windBreaker", "T")
Hero.SetActive(hero)
-- progress: kills, summons, dungeon events
for _ = 1, 5200 do ns.Fire("MONSTER_KILLED", hero, {}, {}, "hunt") end
local ok, dia = I.ClaimPass(hero)
assert(ok and dia == 1500, "pass total " .. tostring(dia))
for _, f in ipairs(ns.Data.FreeDaily) do assert(I.ClaimFree(hero, f.id), "free " .. f.id) end
-- free claims count as 광고 시청 and the free booster as 부스터 사용
local D = ns.Data
local function mission(list, id) for _, m in ipairs(list) do if m.def.id == id then return m end end end
assert(mission(I.DailyMissions(hero), "ad").done and mission(I.DailyMissions(hero), "booster").done, "ad / booster missions")
assert(mission(I.DailyMissions(hero), "kill").done, "2,000 kills")
-- dungeon clears and sweeps both count, per dungeon
ns.Fire("GROWTH_DUNGEON_CLEARED", hero, "weapon", 15, true)
ns.Fire("GROWTH_DUNGEON_SWEPT", hero, "weapon", 2)
for _ = 1, 3 do ns.Fire("GROWTH_DUNGEON_CLEARED", hero, "exp", 3, true) end
assert(mission(I.DailyMissions(hero), "weaponDungeon").done and mission(I.DailyMissions(hero), "expDungeon").done, "dungeon missions")
assert(not mission(I.DailyMissions(hero), "gearDungeon").done, "gear dungeon not done")
for _ = 1, 30 do ns.Fire("SUMMON_RESULT", hero, "weapon", { 1 }) end
for _ = 1, 15 do ns.Fire("ELITE_SUMMONED", hero, 1) end
-- the header counts claimed missions: 6 claimable -> not enough
local _, before = I.DailyMissions(hero)
assert(before == 0, "nothing claimed yet")
local okA, nA = I.ClaimAllMissions(hero, false)
assert(okA and nA == 7, "claim all daily (7 done) " .. tostring(nA))
assert(not hero.income.dayClaimed.__clear, "header needs 8")
ns.Fire("GROWTH_DUNGEON_SWEPT", hero, "gear", 3)
assert(I.ClaimMission(hero, "gearDungeon"), "gear dungeon mission")
local red0 = Hero.Count(hero, "redDia")
assert(I.ClaimDailyClear(hero), "daily clear")
assert(Hero.Count(hero, "redDia") - red0 == 5000, "daily clear 5,000 red")
-- daily red diamonds 2,400 and weekly 15,500 (community totals)
local dsum, wsum = 0, D.WeeklyMissionClear.rewards.redDia
for _, m in ipairs(D.DailyMissions) do dsum = dsum + (m.rewards.redDia or 0) end
for _, m in ipairs(D.WeeklyMissions) do wsum = wsum + (m.rewards.redDia or 0) end
assert(dsum == 2400 and wsum == 15500, "mission red diamond totals " .. dsum .. " " .. wsum)
-- attendance needs chapter 3-2
hero.campaign.maxChapter, hero.campaign.maxStage = 3, 3
local ok2, row = I.ClaimAttendance(hero)
assert(ok2 and row[1] == "weaponTicket", "attendance")
assert(not I.ClaimAttendance(hero), "attendance twice")
-- red shop
Hero.Add(hero, "redDia", 10000)
assert(I.BuyRed(hero, 1), "red shop")
-- newcomer
local nl = I.Newcomer(hero)
local okN = I.ClaimNewcomer(hero, 1, 5) -- free mission
assert(okN, "newcomer free mission")
local okK = I.ClaimNewcomer(hero, 1, 1) -- 4000 kills
assert(okK, "newcomer kills")
-- weekly missions: counters accumulate across days
assert(I.ClaimWeeklyClear(hero) == false, "weekly clear not reached yet")
ns.Hero.systems.income.daily(hero)
for _ = 1, 15000 do I.Track(hero, "kill", 1) end
I.Track(hero, "elite", 200); I.Track(hero, "summon_weapon", 1000); I.Track(hero, "worldboss", 1)
for _, k in ipairs({ "weapon", "exp", "training", "gear" }) do ns.Fire("GROWTH_DUNGEON_SWEPT", hero, k, 15) end
local wl = I.WeeklyMissions(hero)
assert(mission(wl, "kill").done and not mission(wl, "enhanceDungeon").done, "weekly progress")
local stone0, red1 = Hero.Count(hero, "weaponStone"), Hero.Count(hero, "redDia")
local okW, nW = I.ClaimAllMissions(hero, true)
assert(okW and nW == 9, "weekly: 8 missions + clear " .. tostring(nW))
assert(Hero.Count(hero, "redDia") - red1 == 500 * 6 + 12000, "weekly red diamonds")
assert(Hero.Count(hero, "weaponStone") - stone0 == 60000, "former guild weekly items")
assert(Hero.Count(hero, "expBooster50") >= 3, "exp booster 50% from the weekly mission")
ns.Hero.systems.income.weekly(hero)
assert(next(hero.income.week.count) == nil and not hero.income.week.claimed.__clear, "weekly reset")
-- daily reset
ns.Hero.systems.income.daily(hero)
assert(hero.income.passClaimed == 0, "daily reset")
-- summon level rewards: screen values and the level-up grant
local S = ns.Summon
assert(S.LevelReward("weapon", 5).weaponTicket == 100 and S.LevelReward("weapon", 6).weaponTicket == 150
    and S.LevelReward("weapon", 13).weaponTicket == 500, "weapon summon level rewards")
assert(S.LevelReward("companion", 7).companionTicket == 120 and S.LevelReward("companion", 8).companionTicket == 140,
    "companion summon level rewards")
local fresh = Hero.New("hero", "S")
Hero.Add(fresh, "weaponTicket", 100)
for _ = 1, 10 do assert(S.Pull(fresh, "weapon", 10), "pull") end
assert(S.Info(fresh, "weapon").level == 2 and Hero.Count(fresh, "weaponTicket") == 50, "Lv2 pays 50 weapon tickets")
-- UI
local ef = ns.eventFrame
ns.UI.Toggle()
ns.UI.ShowPanel("income")
for s = 1, 5 do ns.UI.panels.income.frame.section = s; ns.UI.RefreshPanel() end
print(string.format("income ok: tickets %d, companion tickets %d, redDia %d, errors %d", Hero.Count(hero, "weaponTicket"),
    Hero.Count(hero, "companionTicket"), Hero.Count(hero, "redDia"), errors))
assert(errors == 0)
