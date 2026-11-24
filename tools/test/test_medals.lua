-- 훈장: conditions latch, claim applies 보유 효과, Main Stat cap 1,500, equip, panel.
package.path = "tools/test/?.lua;" .. package.path
local Stub = require("wowstub")
Stub.Install()
local H = require("harness")
H.loadToc()
local ns = H.ns
ns.InitDB()
ns.Print = function() end
local errors = 0
ns.Debug = function(fmt, ...) errors = errors + 1; print("DEBUG", string.format(fmt, ...)) end
local Hero, M, D = ns.Hero, ns.Medals, ns.Data
local checks, failed = 0, 0
local function check(ok, msg)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL", msg) end
end
local ef = ns.eventFrame
ef._scripts.OnEvent(ef, "ADDON_LOADED", "BigStoryIdleRPG")
ef._scripts.OnEvent(ef, "PLAYER_LOGIN")

local hero = Hero.New("hero", "T")
hero.level = 140
Hero.SetActive(hero)
local function stat(key) return Hero.ProfileCreature(Hero.BuildProfile(hero)):Stat(key) end
local function acc(key)
    local p = Hero.BuildProfile(hero)
    return p.stats.adds[key] or 0, p.stats.mults[key]
end

check(M.Check(hero) == 0, "fresh hero has no medal")
-- arena wins: latched, claim gives Main Stat +30
hero.arena = hero.arena or {}
hero.arena.wins = 150
M.Check(hero)
check(hero.medals.achieved.arena100 and not hero.medals.claimed.arena100, "100 wins achieved, not claimed")
local ms0 = acc("MainStat")
check(M.Claim(hero, "arena100"), "claim arena100")
check(acc("MainStat") - ms0 == 30, "claimed medal gives Main Stat +30")
check(M.Equipped(hero) and M.Equipped(hero).id == "arena100", "first claimed medal is worn")
hero.arena.wins = 0
M.Check(hero)
check(hero.medals.claimed.arena100, "medal stays after the condition drops")
check(not M.Claim(hero, "arena500"), "cannot claim an unmet medal")
-- job advancement
hero.jobStep = 3
ns.Fire("JOB_ADVANCED", hero, 3)
check(hero.medals.achieved.job3 and not hero.medals.achieved.job4, "3rd job medal")
-- boss raids: top difficulty x5 -> boss damage +10%; relocated guild raid medal -> final damage +3%
for _ = 1, 5 do ns.Fire("BOSS_RAID_CLEARED", hero, "zakum", #D.ContentRaids.zakum.difficulties, "party") end
check(hero.medals.raidTop.zakum == 5 and hero.medals.achieved.zakumTop, "자쿰 파괴자 after 5 top clears")
check(hero.medals.achieved.zakumGuild, "guild raid medal from the top difficulty clear")
check(hero.medals.raidParty == 5, "party clears counted")
local boss0, fd0 = acc("AttackPowerToBoss"), #(select(2, acc("FinalDamage")) or {})
check(M.ClaimAll(hero), "claim all")
local boss1, fd1 = acc("AttackPowerToBoss"), #(select(2, acc("FinalDamage")) or {})
check(boss1 - boss0 == 100, "boss damage +10%")
check(fd1 - fd0 == 1, "final damage medal")
-- Main Stat cap
for _, d in ipairs(D.Medals) do hero.medals.achieved[d.id] = true end
M.ClaimAll(hero)
check(M.Totals(hero).MainStat == D.MedalMainStatCap, "Main Stat from medals capped at 1,500")
-- equip / unequip
check(M.Equip(hero, "star30") and M.Equipped(hero).id == "star30", "equip")
check(M.Equip(hero, nil) and M.Equipped(hero) == nil, "unequip")
-- journey special option counter
ns.Fire("JOURNEY_SPECIAL_OPENED", hero, 20)
check(hero.medals.journeySpecial == 1, "journey special counter")
-- panel
ns.UI.Toggle()
ns.UI.ShowPanel("medals")
for c = 1, #D.MedalCategories do ns.UI.panels.medals.frame.cat = c; ns.UI.RefreshPanel() end
print(string.format("medals: %d checks, %d failed, errors %d (%d medals)", checks, failed, errors, #D.Medals))
if failed > 0 or errors > 0 then os.exit(1) end
