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
ns.Fire("GROWTH_DUNGEON_CLEARED", hero, "weapon", 15, true)
for _ = 1, 2 do ns.Fire("GROWTH_DUNGEON_CLEARED", hero, "exp", 3, true) end
for _ = 1, 10 do ns.Fire("SUMMON_RESULT", hero, "weapon", { 1 }) end
I.Track(hero, "elite", 10); I.Track(hero, "arena", 3); I.Track(hero, "worldboss", 1); I.Track(hero, "quickhunt", 1)
local list = I.DailyMissions(hero)
for _, m in ipairs(list) do assert(I.ClaimMission(hero, m.def.id), "mission " .. m.def.id) end
assert(I.ClaimDailyClear(hero), "daily clear")
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
-- weekly gauge
assert(I.ClaimWeekly(hero, 1) == false, "weekly not reached yet")
-- daily reset
ns.Hero.systems.income.daily(hero)
assert(hero.income.passClaimed == 0, "daily reset")
-- UI
local ef = ns.eventFrame
ns.UI.Toggle()
ns.UI.ShowPanel("income")
for s = 1, 4 do ns.UI.panels.income.frame.section = s; ns.UI.RefreshPanel() end
print(string.format("income ok: tickets %d, companion tickets %d, redDia %d, errors %d", Hero.Count(hero, "weaponTicket"),
    Hero.Count(hero, "companionTicket"), Hero.Count(hero, "redDia"), errors))
assert(errors == 0)
