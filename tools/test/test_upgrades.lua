-- Upgrade systems: data sanity (probabilities sum), pity rules, costs and stat output.
-- Run from the repository root: lua5.1 tools/test/test_upgrades.lua
package.path = "tools/test/?.lua;" .. package.path
local H = require("harness")
H.loadToc("UI\\")
local ns = H.ns
if not ns.StarForce then
    for _, f in ipairs({ "Data/Upgrades.lua", "Systems/StarForce.lua", "Systems/Potential.lua", "Systems/Scrolls.lua",
        "Systems/HeroPower.lua", "Systems/Ability.lua", "Systems/Artifacts.lua", "Systems/Journey.lua" }) do
        H.load(f)
    end
end
ns.Print = function() end
local D, U, UP = ns.Data, ns.U, ns.Upgrades
local Hero = ns.Hero

local pass, fail = 0, 0
local function check(cond, msg, ...)
    if cond then pass = pass + 1 else
        fail = fail + 1
        print("FAIL: " .. string.format(msg, ...))
    end
end
local function eq(a, b, msg, ...)
    check(a == b, "%s (got %s, want %s)", string.format(msg, ...), tostring(a), tostring(b))
end

-- scripted rng: Weighted -> fixed index, ChanceM -> fixed bool
local function fixedRng(idx, chance)
    local r = U.NewRNG(1)
    r.Weighted = function() return idx end
    r.ChanceM = function() return chance end
    return r
end

local clock = 1700000000
U.Now = function() return clock end

local function newHero()
    local h = Hero.New(D.Jobs[1].key, "테스터")
    h.campaign = h.campaign or {}
    h.campaign.cleared = h.campaign.cleared or {}
    return h
end

---------------------------------------------------------------------------
print("== data sanity")
local SF = ns.StarForce
for star = 0, 29 do
    local row = SF.Row(star)
    eq(row.success + row.fail + row.down + row.destroy, 1000000, "starforce row %d sums", star)
    local ch = SF.Chances({ star = star }, { preventDown = true, preventDestroy = true })
    eq(ch.success + ch.fail + ch.down + ch.destroy, 1000000, "protected row %d sums", star)
end
for part, grades in pairs(D.Potential.pools) do
    for g = 1, 6 do
        for ln = 1, 3 do
            local s = 0
            for _, o in ipairs(grades[g][ln]) do s = s + o[3] end
            eq(s, 1000000, "potential %s G%d line%d sums", part, g, ln)
        end
    end
end
for lv, l in ipairs(D.Ability.levels) do
    local s = 0
    for _, w in ipairs(l.weights) do s = s + w end
    eq(s, 10000, "ability level %d weights", lv)
    local p = 0
    for i = 1, #D.Ability.options do p = p + ns.Ability.OptionChance(lv, i) end
    check(math.abs(p - 1) < 1e-9, "ability level %d option chances sum to 1 (%f)", lv, p)
end
for _, pch in ipairs(D.Scrolls.enchant.pouches) do
    local s = 0
    for _, v in ipairs(pch.odds) do s = s + v end
    eq(s, 1000, "pouch %s odds", pch.name)
end
for _, b in ipairs(D.Scrolls.dungeonDrop.bands) do
    local s = 0
    for _, v in pairs(b.pct) do s = s + v end
    check(math.abs(s - 10) < 1e-6, "enhance dungeon band %d-%d sums to 10%% (%f)", b.from, b.to, s)
end
do
    local s = 0
    for _, a in ipairs(ns.Artifacts.List()) do s = s + ns.Artifacts.ChestChance(a.id) end
    check(math.abs(s - 1000000) < 1e-6, "artifact chest chances sum to 1e6 (%f)", s)
    eq(#ns.Artifacts.List(), 36, "36 artifacts")
    local t = 0
    for _, v in ipairs(D.Journey.trail.gradeOdds) do t = t + v end
    eq(t, 1000, "trail grade odds")
    for prev = 0, 3 do
        local s2 = 0
        for _, v in ipairs(D.Journey.chest.blessOdds[prev]) do s2 = s2 + v end
        eq(s2, 1000, "blessing transition row %d", prev)
    end
    local a = 0
    for _, o in ipairs(D.Journey.treasure.weeklyAccel) do a = a + o.prob end
    eq(a, 1000, "weekly acceleration odds")
end
eq(#D.Scrolls.list, 31, "31 equipment scrolls")
eq(#D.Scrolls.enchant.scrolls, 127, "127 enchant scrolls")
eq(#D.Ability.options, 78, "78 ability options")
eq(#D.HeroPower.stages, 9, "9 hero power stages")
eq(#D.Journey.treasure.levelExp, 1000, "1000 journey levels")

---------------------------------------------------------------------------
print("== star force")
do
    local hero = newHero()
    local ch = SF.Chances({ star = 21 }, { preventDown = true })
    eq(ch.down, 0, "21★ 하락 방지 down")
    eq(ch.fail, 705000 + 80000, "21★ 하락 방지 fail")
    ch = SF.Chances({ star = 28 }, { preventDown = true, preventDestroy = true })
    eq(ch.down, 20000, "28★ protected down"); eq(ch.destroy, 10000, "28★ protected destroy")
    local c = SF.Cost({ star = 21 }, { preventDown = true, preventDestroy = true })
    eq(c.starforceScroll, 38 * 3, "21★ protected scrolls"); eq(c.meso, 750000 * 3, "21★ protected meso")
    c = SF.Cost({ star = 21, sfDowns = 2 }, { preventDown = true, preventDestroy = true })
    eq(c.starforceScroll, 38, "chance time pays base only")

    -- point pity: 12★ needs 8 points; fails give 1 point each
    local item = { star = 12 }
    Hero.Add(hero, "starforceScroll", 1e9); Hero.Add(hero, "meso", 1e13)
    for i = 1, 8 do eq(SF.Enhance(hero, item, nil, fixedRng(2)), "fail", "12★ fail %d", i) end
    local _, guaranteed, why = SF.Chances(item)
    check(guaranteed and why == "points", "12★ guaranteed after 8 points")
    eq(SF.Enhance(hero, item, nil, fixedRng(2)), "success", "point-guaranteed success")
    eq(item.star, 13, "13★ after pity"); eq(item.sfPoints[12], nil, "points reset on success")

    -- chance time after 2 consecutive downs
    item = { star = 23 }
    SF.Enhance(hero, item, nil, fixedRng(3)); SF.Enhance(hero, item, nil, fixedRng(3))
    eq(item.star, 21, "two downs"); eq(item.sfPoints[23], 2, "down = 2 points"); eq(item.sfPoints[22], 2, "down = 2 points (22)")
    _, guaranteed, why = SF.Chances(item)
    check(guaranteed and why == "chance", "chance time")
    eq(SF.Enhance(hero, item, nil, fixedRng(3)), "success", "chance time success"); eq(item.sfDowns, 0, "downs reset")

    -- destroy and restore
    item = { star = 22 }
    eq(SF.Enhance(hero, item, nil, fixedRng(4)), "destroy", "destroy")
    eq(item.star, 12, "destroyed -> 12★"); check(SF.IsDestroyed(item), "destroyed flag")
    eq(#SF.ItemStats(item), 0, "no star force bonus while destroyed")
    local t = SF.RestoreTargets(item)
    eq(t[1], 12, "restore from 12"); eq(t[#t], 20, "restore up to 20")
    local rc = SF.RestoreCost(16)
    eq(rc.redDia, 5000, "restore red dia"); eq(rc.meso, 4960000, "restore 16 meso"); eq(rc.starforceScroll, 220, "restore 16 scrolls")
    check(not SF.Restore(hero, item, 16), "restore needs red diamonds")
    Hero.Add(hero, "redDia", 5000)
    check(SF.Restore(hero, item, 16), "restore 16★"); eq(item.star, 16, "restored star")

    -- amplification
    local gear = { star = 10, main = { { type = "Attack", value = 100 }, { type = "MaxHp", value = 1000 } },
        sub = { { type = "CriticalChance", value = 50 } } }
    local st = SF.ItemStats(gear)
    eq(st[1][2], 150, "10★ main +150%%"); eq(st[2][2], 1500, "10★ MaxHp"); eq(st[3][2], 12, "10★ sub floor(50*250/1000)")
    gear.star = 30
    st = SF.ItemStats(gear)
    eq(st[1][2], 2500, "30★ main x25"); eq(st[#st][1], "FinalDamage", "30★ final damage"); eq(st[#st][2], 150, "30★ FD 15%%")
    -- monte carlo of 21★ odds
    local rng = U.NewRNG(12345)
    local n, k = 0, { success = 0, fail = 0, down = 0, destroy = 0 }
    for _ = 1, 50000 do
        local it = { star = 21 }
        local r = SF.Enhance(hero, it, nil, rng)
        k[r] = k[r] + 1; n = n + 1
    end
    check(math.abs(k.success / n - 0.115) < 0.006, "21★ success ≈ 11.5%% (%.4f)", k.success / n)
    check(math.abs(k.destroy / n - 0.10) < 0.006, "21★ destroy ≈ 10%% (%.4f)", k.destroy / n)
    check(math.abs(k.down / n - 0.08) < 0.006, "21★ down ≈ 8%% (%.4f)", k.down / n)
end

---------------------------------------------------------------------------
print("== potential")
do
    local P = ns.Potential
    local hero = newHero()
    Hero.Add(hero, "cubeMiracle", 10000); Hero.Add(hero, "cubeAdditional", 10000); Hero.Add(hero, "meso", 1e10)
    local item = { part = "Glove", star = 2 }
    check(not P.UseCube(hero, item, "miracle"), "potential needs 3★")
    item.star = 12
    local never = fixedRng(1, false)
    for i = 1, 32 do P.UseCube(hero, item, "miracle", never) end
    eq(item.potential.grade, 1, "no grade-up before pity")
    eq(hero.wallet.meso, 1e10 - 32 * 7000, "meso per miracle roll at 노말")
    local _, up = P.UseCube(hero, item, "miracle", never)
    check(up and item.potential.grade == 2, "miracle pity 33 -> 레어")
    for i = 1, 41 do P.UseCube(hero, item, "additional", never) end
    eq(item.additional.grade, 1, "additional no grade-up at 41")
    P.UseCube(hero, item, "additional", never)
    eq(item.additional.grade, 2, "additional pity 42")
    local always = fixedRng(1, true)
    P.UseCube(hero, item, "miracle", always)
    eq(item.potential.grade, 3, "chance grade-up")
    eq(#item.potential.lines, 3, "3 lines")
    -- line distribution of 미스틱 장갑 line 1 vs data
    local st = { grade = 6, lines = {}, pity = 0 }
    local rng = U.NewRNG(99)
    local hits, n = {}, 40000
    for _ = 1, n do
        P.RollState(st, "Glove", "miracle", rng)
        local l = st.lines[1]
        hits[l[1]] = (hits[l[1]] or 0) + 1
    end
    for _, o in ipairs(P.LineOptions("Glove", 6, 1)) do
        local p = o[3] / 1e6
        check(math.abs((hits[o[1]] or 0) / n - p) < 0.01, "glove mystic line1 %s ≈ %.3f (%.3f)", o[1], p, (hits[o[1]] or 0) / n)
    end
    local stats = P.ItemStats(item)
    eq(#stats, 6, "potential + additional lines")
end

---------------------------------------------------------------------------
print("== scrolls / enchant")
do
    local S = ns.Scrolls
    local hero = newHero()
    hero.level = 120
    eq(S.SuccessRate("lv85_70", 1), 700, "slot 1 rate")
    eq(S.SuccessRate("lv85_70", 5), 800, "slot 5 +10%%p")
    eq(S.SuccessRate("lv85_15", 10), 350, "slot 10 +20%%p")
    eq(S.SuccessRate("lv85_70", 10, 200), 1000, "rate capped at 100%%")
    local c = S.Cost("lv85_15")
    eq(c.spellTrace, 800, "85 15%% trace cost"); eq(c.meso, 50000, "85 15%% meso (global guide)")
    Hero.Add(hero, "spellTrace", 100000); Hero.Add(hero, "meso", 1e9)
    Hero.Add(hero, "scrollMystery", 2); Hero.Add(hero, "scrollCertainty", 2)
    local item = { part = "Glove", grade = "Grade4", sub = { { type = "Attack", value = 300 }, { type = "CriticalPower", value = 50 } } }
    check(S.Use(hero, item, "mystery", fixedRng(3, true)) == true, "mystery on slot 1")
    eq(item.scroll.slots[1].stats.Attack, 3000, "mystery roll row 3 attack")
    eq(item.scroll.slots[1].stats.AttackPower2, 18, "mystery roll row 3 amp 1.8%%")
    check(not S.CanUse(hero, item, "mystery"), "mystery only slot 1")
    for i = 2, 9 do S.Use(hero, item, "lv85_70", fixedRng(1, i % 2 == 0)) end
    check(S.CanUse(hero, item, "lv85_70"), "slot 10 usable")
    check(S.Use(hero, item, "certainty", fixedRng(2, true)) == true, "certainty on slot 10")
    eq(item.scroll.slots[10].stats.MainStat, 1000, "certainty 30%% row")
    eq(S.NextSlot(item), nil, "10 slots used")
    local st = S.ItemStats(item)
    local sum = {}
    for _, s in ipairs(st) do sum[s[1]] = (sum[s[1]] or 0) + s[2] end
    eq(sum.Attack, 3000 + 4 * 200, "scroll attack sum"); eq(sum.AttackPower2, 18 + 4 * 2 + 30, "scroll amp sum")
    local trace = hero.wallet.spellTrace
    check(S.Reset(hero, item), "innocent reset"); eq(hero.wallet.spellTrace, trace - 50, "innocent costs 50 traces")
    eq(S.NextSlot(item), 1, "slots cleared")
    -- enhance dungeon drop
    local rng = U.NewRNG(7)
    local got, n = 0, 100000
    local epic = 0
    for _ = 1, n do
        local k = S.RollDungeonDrop(150, rng)
        if k then got = got + 1 end
        if k == "epic15" then epic = epic + 1 end
    end
    check(math.abs(got / n - 0.10) < 0.004, "dungeon 150 drop ≈ 10%% (%.4f)", got / n)
    check(math.abs(epic / n - 0.013333) < 0.0015, "dungeon 150 epic15 ≈ 1.333%% (%.4f)", epic / n)
    -- enchant
    hero.campaign.cleared["14-10"] = true
    Hero.Add(hero, "enchantPouchTop", 50)
    local ids = S.OpenPouch(hero, "enchantPouchTop", 50, U.NewRNG(5))
    eq(#ids, 50, "50 enchant scrolls from pouches")
    local bag = S.Bag(hero)
    -- give a known scroll: 에픽 공격력 (id 9)
    bag[9] = (bag[9] or 0) + 1
    local opts = S.EnchantOptions(hero, item, 1)
    local has9 = false
    for _, id in ipairs(opts) do if id == 9 then has9 = true end; check(S.Enchant(id).stat == "Attack", "enchant option matches sub stat") end
    check(has9, "에픽 공격력 usable on Attack line")
    check(not S.ApplyEnchant(hero, item, 2, 9), "stat mismatch refused")
    eq(S.ApplyEnchant(hero, item, 1, 9, fixedRng(1, true)), true, "enchant success")
    local e = item.scroll.enchant[1]
    check(e.value >= 247 and e.value <= 371, "enchant value in 247..371 (%s)", tostring(e.value))
end

---------------------------------------------------------------------------
print("== hero power / ability")
do
    local HP, A = ns.HeroPower, ns.Ability
    local hero = newHero()
    local total = 0
    for _, st in ipairs(D.HeroPower.stages) do
        for _, sl in ipairs(st.slots) do for _, c in ipairs(sl.costs) do total = total + c end end
    end
    eq(total, 3477408, "cumulative 용사의 증표 to finish stage 9")
    Hero.Add(hero, "heroToken", 1698)
    for s = 1, 3 do HP.LevelUp(hero, s, 10) end
    eq(Hero.Count(hero, "heroToken"), 0, "stage 1 costs 1698")
    check(HP.IsStageComplete(hero), "stage 1 complete")
    check(HP.StartAdvance(hero), "start stage 2")
    eq(HP.AdvanceRemaining(hero), 300, "stage 2 wait 300 s")
    clock = clock + 300
    HP.Update(hero)
    eq(hero.heroPower.stage, 2, "stage 2")
    local stats = {}
    for _, s in ipairs(HP.Stats(hero)) do stats[s[1]] = (stats[s[1]] or 0) + s[2] end
    eq(stats.Attack, 100, "stage 2 attack base = stage 1 max"); eq(stats.MaxHpR, 100, "stage 2 bonus MaxHp 10%%")
    eq(stats.MainStat, 100, "stage 2 bonus MainStat 100")
    eq(A.SlotCount(hero), 1, "ability slot 1 at stage 2")
    eq(A.ConvertCost(hero), 20, "ability Lv1 cost 0 locked")
    Hero.Add(hero, "honorMedal", 100000)
    check(A.Convert(hero, U.NewRNG(3)), "ability convert")
    hero.heroPower.stage = 5
    eq(A.SlotCount(hero), 4, "4 slots at stage 5")
    A.Convert(hero, U.NewRNG(4))
    local keep = hero.ability.lines[1].opt
    A.SetLock(hero, 1, true)
    eq(A.ConvertCost(hero), 30, "Lv1 cost with 1 lock")
    for _ = 1, 20 do A.Convert(hero, U.NewRNG(_)) end
    eq(hero.ability.lines[1].opt, keep, "locked line kept")
    hero.ability.exp = 5000
    eq((A.ExpInfo(hero)), 2, "5000 EXP -> Lv2")
    hero.ability.exp = 6540800
    eq((A.ExpInfo(hero)), 20, "6,540,800 EXP -> Lv20")
end

---------------------------------------------------------------------------
print("== artifacts")
do
    local AR = ns.Artifacts
    local hero = newHero()
    Hero.Add(hero, "artifactChest", 2000)
    local got = AR.OpenChest(hero, 2000, U.NewRNG(11))
    eq(#got, 2000, "2000 chests opened")
    local epic = 0
    for _, id in ipairs(got) do if AR.Get(id).grade == 3 then epic = epic + 1 end end
    check(math.abs(epic / 2000 - 0.895) < 0.03, "epic share ≈ 89.5%% (%.3f)", epic / 2000)
    eq(AR.SlotCount(hero), 1, "1 slot at 0 awakening")
    hero.artifacts.owned[301] = { awakening = 0, dupes = 12 }
    for _ = 1, 5 do AR.Awaken(hero, 301) end
    eq(hero.artifacts.owned[301].awakening, 5, "awakened to 5")
    check(not AR.Awaken(hero, 301), "max awakening")
    local inv = AR.InventoryEffect(301, 5)
    eq(inv[1][2], 300, "죽은자의 부적 보유 Attack at 5"); eq(inv[2][2], 3000, "MaxHp at 5")
    local leg = AR.InventoryEffect(517, 1)
    eq(leg[1][2], 360, "양초 awakening 1 = 36%% (published)")
    leg = AR.InventoryEffect(501, 5)
    check(leg[1][3] and leg[1][2] == 600, "성배 awakening 5 provisional 60%%")
    check(AR.Equip(hero, "Campaign", 1, 301), "equip")
    local sk = AR.EquipSkills(hero, "Campaign")
    eq(sk[1], 9030150, "equip skill of awakening 5")
    check(D.Skills[9030150] ~= nil, "artifact skill registered in D.Skills")
    eq(AR.ResonanceMax(hero), 50 + 10 * AR.TotalAwakening(hero), "resonance max")
    Hero.Add(hero, "artifactStone", 1500 + 1518)
    local ok, n = AR.Resonate(hero, 5)
    check(ok and n == 2, "resonance 2 levels with 3018 stones")
    -- the profile carries artifact skills and the battle registers them
    local p = Hero.BuildProfile(hero)
    eq(p.skillSet.artifactSkills.Campaign[1], 9030150, "profile artifact skills")
    local b = ns.Battle.New({ seed = 1 })
    local c = b:AddCreature(Hero.CreatureDef(p, 1, 0))
    check(c.passiveSkills[9030150] ~= nil, "battle registered artifact passive")
end

---------------------------------------------------------------------------
print("== journey")
do
    local J = ns.Journey
    local hero = newHero()
    J.AddKills(hero, 20, 1, 1000)
    eq(hero.journey.treasure.exp, 0, "locked before 20 boss")
    hero.campaign.cleared["20-10"] = true
    J.Update(hero)
    eq(Hero.Count(hero, "journeyKey"), 5, "5 keys on unlock")
    local per = J.KillExp(20, 1)
    check(math.abs(per - 4.5207058) < 1e-9, "kill exp 20-1 = 45207058e-7")
    J.AddKills(hero, 20, 1, 764500)     -- 3,456,000 / 4.52 ≈ 764,486
    eq(hero.journey.treasure.stored, 1, "first reward stored")
    eq(hero.journey.treasure.level, 2, "level 2")
    J.AddKills(hero, 47, 19, 10000000)
    eq(hero.journey.treasure.stored, 2, "capped at 2 rewards")
    eq(J.TreasureGauge(hero), 2000, "gauge 200%%")
    check(not J.CanAccelerate(hero), "no acceleration at 200%")
    check(J.ClaimTreasure(hero, 1), "claim star force card")
    eq(Hero.Count(hero, "starforceScroll"), 20, "card step 1 = 20 scrolls")
    local cards = J.Cards(hero)
    eq(cards[1].step, 1, "picked card reset"); eq(cards[4].step, 2, "other card advanced"); eq(cards[4].amount, 4800000, "meso step 2")
    for _ = 1, 6 do hero.journey.treasure.stored = 1; J.ClaimTreasure(hero, 1) end
    eq(J.Cards(hero)[2].step, 5, "card step capped at 5")
    local okA, g = J.Accelerate(hero, fixedRng(3))
    check(okA and g == 300, "acceleration +30%%")
    check(not J.Accelerate(hero), "acceleration once a week")
    -- chest
    hero.journey.chest.bless = { 3, 3, 1, 1, 1, 1, 1 }
    local tokens = J.OpenChest(hero, 2)
    eq(tokens, math.floor(10280 * 2 * 1.2), "chest ch20 x2 keys +20%%")
    -- trail
    Hero.Add(hero, "meso", 1e9); Hero.Add(hero, "journeyToken", 1e7); Hero.Add(hero, "journeyEnergy", 5)
    check(J.OpenTrail(hero, 20), "open trail 20")
    eq(J.TrailRemaining(hero), 96000, "trail 20 opens in 1d 2h 40m")
    clock = clock + 96000
    J.Update(hero)
    check(hero.journey.trail.opened[20] ~= nil, "trail 20 opened")
    eq(Hero.Count(hero, "cubeMiracle"), 10, "trail reward cubes")
    local before = Hero.Count(hero, "journeyToken")
    J.RerollTrail(hero, 20, fixedRng(4))
    eq(Hero.Count(hero, "journeyToken"), before - 1900, "reroll cost 1900 tokens")
    local s = {}
    for _, x in ipairs(J.TrailStats(hero)) do s[x[1]] = (s[x[1]] or 0) + x[2] end
    eq(s.Attack, 1200, "unique attack ch20"); eq(s.MainStatR, 50, "special main stat 5%%")
    J.SetTrailLock(hero, 20, 1)
    local rc = J.RerollCost(hero, 20)
    eq(rc.meso, 15000, "locked reroll meso"); eq(rc.journeyEnergy, 1, "locked reroll energy")
end

---------------------------------------------------------------------------
print("== sample hero / item stat output")
do
    local hero = newHero()
    hero.level = 100
    hero.heroPower.stage = 3
    hero.heroPower.levels = { 20, 20, 20, 20, 20 }
    local acc = Hero.NewAccumulator()
    local item = { part = "Glove", star = 15, grade = "Grade5",
        main = { { type = "Attack", value = 1000 }, { type = "MaxHp", value = 5000 } },
        sub = { { type = "CriticalPower", value = 80 } },
        potential = { grade = 4, lines = { { "CriticalPower", 200 }, { "StrR", 90 }, { "MainStatPerLevel1", 5 } } },
        scroll = { slots = { { key = "lv85_70", ok = true, stats = { Attack = 200, MaxHp = 1000, AttackPower2 = 2 } } } } }
    UP.DispatchItem(item, acc, hero)
    Hero.statProviders.heroPower(hero, acc)
    local mk = UP.MainStatKey(hero)
    eq(acc.adds.Attack, 3000 + 200 + 725, "item+hero power attack")     -- 15★ main +300%
    eq(acc.adds.CriticalPower, 40 + 200, "15★ sub +50%% + potential")
    eq(acc.ratios.Str, 90, "STR%% ratio")
    eq(acc.adds[mk], 5 * 100 + 350 + 200, "main stat: per-level + hero power + stage bonus")
    eq(acc.ratios.MaxHp, 200, "stage 3 MaxHp 20%%")
    for _, s in ipairs({ "Attack", "CriticalPower", mk, "AttackPower2", "AttackPower" }) do
        print(string.format("  %-16s add %-8s %s", s, tostring(acc.adds[s] or 0), UP.FormatStat(s == mk and "MainStat" or s, acc.adds[s] or 0)))
    end
    local p = Hero.BuildProfile(hero)
    print("  combat power:", Hero.CombatPower(p))
end

---------------------------------------------------------------------------
-- integration with Systems/Equipment.lua (runs once Equipment is in the TOC)
if ns.Equipment and ns.Equipment.Give and ns.Data.Gear then
    print("== equipment integration")
    local E = ns.Equipment
    check(UP.BindEquipment(), "item hooks bound to Equipment")
    local hero = newHero()
    hero.level = 100
    local code
    for c, g in pairs(ns.Data.Gear) do if g.part == "Glove" and g.grade == "Grade5" then code = c; break end end
    local item = E.Give(hero, code, 100)
    item.subs = {} -- sub options get their own star-force amplification; measure main options only
    local main = E.ItemBaseOptions(item)
    local function atk() local acc = Hero.NewAccumulator(); E.ItemStats(item, acc, hero); return acc.adds.Attack or 0 end
    local base = atk()
    item.star = 10
    eq(atk(), base + math.floor(main[1].value * 1500 / 1000), "10★ glove attack through Equipment")
end

print(string.format("passed %d, failed %d", pass, fail))
if fail > 0 then os.exit(1) end
