-- End-to-end progression: a hero hunts, pulls weapons/companions with earned
-- currency, equips the best, fights with companion supporters.
package.path = "tools/test/?.lua;" .. package.path
local Stub = require("wowstub")
Stub.Install()
local H = require("harness")
H.loadToc()
local ns = H.ns
ns.InitDB()
ns.Print = function() end
local errors = 0
ns.Debug = function(fmt, ...) errors = errors + 1; if errors < 10 then print("DEBUG", string.format(fmt, ...)) end end

local hero = ns.Hero.New(arg[1] or "nightLord", "테스터")
ns.Hero.SetActive(hero)
local Hero, G = ns.Hero, ns.Game
local clock = os.time()
ns.U.Now = function() return clock end
local supporterSpawns, waveTriggers = 0, 0
G.uiHooks.onSpawn = function(b, c) if c.isSupporter then supporterSpawns = supporterSpawns + 1 end end

local function play(minutes)
    for i = 1, minutes * 600 do
        clock = clock + 0.1
        G.Tick(0.1)
        if G.battle and G.battle.ended and G.mode ~= "hunt" then G.StartHunt() end
    end
end

local function spendAndEquip()
    -- summon with everything we have (tickets first, then red diamonds)
    local S = ns.Summon
    for _, kind in ipairs({ "companion", "weapon" }) do
        local n = 0
        while S.CanPull(hero, kind, 10) and n < 200 do S.Pull(hero, kind, 10); n = n + 1 end
        while S.CanPull(hero, kind, 1) and n < 400 do S.Pull(hero, kind, 1); n = n + 1 end
    end
    if ns.Weapons.EquipBest then ns.Weapons.EquipBest(hero) end
    if ns.Companions.AutoEquip then ns.Companions.AutoEquip(hero) end
    if ns.Equipment.EliteSummon then
        for _ = 1, 50 do if not pcall(ns.Equipment.EliteSummon, hero) then break end end
    end
    if ns.Equipment.AutoEquip then ns.Equipment.AutoEquip(hero) end
    Hero.Changed(hero, "equipment")
end

local cp0 = Hero.CombatPower(Hero.BuildProfile(hero))
play(10)
Hero.Add(hero, "weaponTicket", 300); Hero.Add(hero, "redDia", 20000)
spendAndEquip()
local cp1 = Hero.CombatPower(Hero.BuildProfile(hero))
play(20)
spendAndEquip()
local cp2 = Hero.CombatPower(Hero.BuildProfile(hero))
local cp = hero.campaign
local ownedW = 0
for _ in pairs(hero.weapons and hero.weapons.owned or {}) do ownedW = ownedW + 1 end
local ownedC = 0
for _ in pairs(hero.companions and hero.companions.owned or {}) do ownedC = ownedC + 1 end
local looks = ns.Skin.GearLooks(hero)
print(string.format("%s Lv%d stage %d-%d kills %d | CP %s -> %s -> %s | weapons %d companions %d | supporter spawns %d | looks %d | errors %d",
    hero.jobKey, hero.level, cp.maxChapter, cp.maxStage, hero.stats.kills, ns.U.FormatNumber(cp0), ns.U.FormatNumber(cp1),
    ns.U.FormatNumber(cp2), ownedW, ownedC, supporterSpawns, #looks, errors))
assert(cp2 > cp0, "combat power did not grow")
assert(errors == 0, "debug errors")
