-- Item / gacha systems: rates, pity, costs, enhancement, equipment values, elite summoning, stat providers.
-- Run from the repository root: lua5.1 tools/test/test_items.lua
package.path = "tools/test/?.lua;" .. package.path
local H = require("harness")
H.loadToc("UI\\")
local ns = H.ns
if not ns.Summon then
    -- not in the TOC yet: load in the intended order
    for _, f in ipairs({ "Data/Summon.lua", "Data/Weapons.lua", "Data/Companions.lua", "Data/Equipment.lua",
        "Systems/Weapons.lua", "Systems/Companions.lua", "Systems/Equipment.lua", "Systems/Summon.lua" }) do
        H.load(f)
    end
end
local D, U, Hero = ns.Data, ns.U, ns.Hero
local W, C, E, S = ns.Weapons, ns.Companions, ns.Equipment, ns.Summon
-- UI / timer listeners of other modules need WoW frames; only report errors raised by these systems
ns.Debug = function(fmt, ...)
    local msg = string.format(fmt, ...)
    if not msg:find("Compat.lua", 1, true) and not msg:find("CreateFrame", 1, true) then print("DEBUG", msg) end
end

local pass, fail = 0, 0
local function check(cond, msg)
    if cond then pass = pass + 1 else fail = fail + 1; print("FAIL " .. msg) end
end
local function eq(got, want, msg)
    check(got == want, string.format("%s (got %s, want %s)", msg, tostring(got), tostring(want)))
end
local function near(got, want, tol, msg)
    check(math.abs(got - want) <= tol, string.format("%s (got %.6f, want %.6f)", msg, got, want))
end

U.rng = U.NewRNG(12345)
local function newHero(job, level)
    local h = Hero.New(job or "hero", "테스트")
    h.level = level or 1
    return h
end

---------------------------------------------------------------------------
print("== rates")
for lv = 1, D.WeaponSummon.maxLevel do
    local sum = 0
    for _, r in ipairs(D.WeaponSummon.rates[lv]) do sum = sum + r[3] end
    eq(sum, 10000000, "weapon weights sum lv" .. lv)
    local pct = 0
    for _, r in ipairs(S.Rates("weapon", lv)) do pct = pct + r.percent end
    near(pct, 100, 1e-9, "weapon percent sum lv" .. lv)
end
do
    local last = D.WeaponSummon.rates[19][#D.WeaponSummon.rates[19]]
    eq(last[1] * 10 + last[2], 81, "lv19 top entry is 이터니티 하급")
    eq(last[3], 70, "lv19 이터니티 하급 weight (0.0007%)")
end
for lv = 1, D.CompanionSummon.maxLevel do
    local sum = 0
    for _, w in ipairs(D.CompanionSummon.gradeWeights[lv]) do sum = sum + w end
    eq(sum, 100000, "companion weights sum lv" .. lv)
    for _, kind in ipairs({ "companion", "pickup" }) do
        local pct = 0
        for _, g in ipairs(S.Rates(kind, lv)) do
            for _, p in pairs(g.perCompanion) do pct = pct + p end
        end
        near(pct, 100, 1e-9, kind .. " per-companion sum lv" .. lv)
    end
end
do
    local r = S.Rates("pickup", 13)[5]
    near(r.perCompanion[415], 0.012, 1e-12, "pickup 플레임위자드(4차) 0.012%")
    near(r.perCompanion[401], 0.04 * 0.4 / 14, 1e-12, "pickup 히어로(4차) 40%/14")
    near(S.Rates("companion", 13)[5].perCompanion[401], 0.0025, 1e-12, "normal legendary each 0.0025%")
    near(S.Rates("companion", 1)[1].perCompanion[1], 19.4, 1e-12, "lv1 지망생 each 19.4%")
end
for lv = 1, D.EliteSummon.maxLevel do
    local sum = 0
    for _, r in ipairs(D.EliteSummon.levels[lv].rates) do sum = sum + r[3] end
    eq(sum, 10000, "elite rates sum lv" .. lv)
end
do
    local n = 0
    for code, g in pairs(D.Gear) do
        local s = 0
        for _, p in ipairs(g.lines) do s = s + p end
        if s ~= 1000 then print("bad lines", code) else n = n + 1 end
    end
    eq(n, 291, "gear sub-line odds sum to 1000")
end

---------------------------------------------------------------------------
print("== summon costs, levels, pity")
do
    local h = newHero()
    Hero.Add(h, "weaponTicket", 5); Hero.Add(h, "redDia", 100)
    local res = S.Pull(h, "weapon", 10)
    check(res ~= nil, "pull 10 with 5 tickets + 100 red")
    eq(#res, 10, "10 results")
    eq(Hero.Count(h, "weaponTicket"), 0, "tickets used first")
    eq(Hero.Count(h, "redDia"), 0, "5 x 20 red diamonds")
    eq(res.spent.ticket, 5, "spent tickets")
    local ok = S.Pull(h, "weapon", 1)
    eq(ok, nil, "no currency -> fail")
    Hero.Add(h, "weaponTicket", 2000)
    check(S.Pull(h, "weapon", 1001) == nil, "lv1 max draw 1000")
    S.Pull(h, "weapon", 90)
    local info = S.Info(h, "weapon")
    eq(info.level, 2, "100 pulls -> weapon summon lv2")
    eq(info.exp, 0, "exp carried")
    eq(info.need, 250, "lv2 needs 250")
    check(W.Equipped(h) ~= nil, "first weapon auto-equipped")
    Hero.Add(h, "companionTicket", 100)
    check(S.Pull(h, "companion", 5) == nil, "companion batch must be 1 or 10")
    check(S.Pull(h, "pickup", 10) == nil, "pickup locked below companion lv9")
    eq(#S.Pull(h, "companion", 10), 10, "companion pull 10")
    eq(Hero.Count(h, "companionTicket"), 90, "companion tickets")
end
do -- weapon pity at lv19
    local h = newHero()
    h.summon.weapon.level = 19
    h.summon.weapon.pity[19] = 357000 - 1
    Hero.Add(h, "weaponTicket", 10)
    local res = S.Pull(h, "weapon", 1)
    eq(res[1].grade * 10 + res[1].tier, 81, "357,000th pull = 이터니티 하급")
    eq(res[1].guaranteed, true, "flagged guaranteed")
    eq(h.summon.weapon.pity[19], 0, "pity reset after guarantee")
    -- natural top result resets the gauge
    local real = U.rng
    U.rng = { Float = function() return 0.9999999999 end, Int = real.Int, Weighted = real.Weighted, Next = real.Next }
    h.summon.weapon.pity[19] = 100
    res = S.Pull(h, "weapon", 1)
    eq(res[1].grade, 8, "forced top roll")
    eq(h.summon.weapon.pity[19], 0, "natural 이터니티 resets pity")
    U.rng = { Float = function() return 0 end, Int = real.Int, Weighted = real.Weighted, Next = real.Next }
    res = S.Pull(h, "weapon", 1)
    eq(res[1].grade, 1, "forced bottom roll")
    eq(h.summon.weapon.pity[19], 1, "pity counts")
    U.rng = real
    -- lv18 row only counts at lv18
    eq(h.summon.weapon.pity[18], nil, "lv18 gauge idle at lv19")
end
do -- companion pity at lv13 and pickup gauge
    local h = newHero()
    h.summon.companion.level = 13
    h.summon.companion.pity[13] = 6250 - 1
    Hero.Add(h, "companionTicket", 20)
    local res = S.Pull(h, "companion", 1)
    eq(res[1].grade, 5, "6,250th companion pull = 레전드리")
    eq(h.summon.companion.pity[13], 0, "companion pity reset")
    local res2 = S.Pull(h, "pickup", 10)
    eq(#res2, 10, "pickup pull at lv13")
    eq(h.summon.companion.pity[13], 0, "pickup pulls do not fill the normal gauge")
    check((h.summon.pickup.pity[13] or 0) > 0, "pickup gauge counts")
    eq(h.summon.companion.total, 11, "pickup shares the companion summon level gauge")
end
do -- distribution sanity (deterministic seed)
    U.rng = U.NewRNG(777)
    local h = newHero()
    h.summon.weapon.level = 19
    Hero.Add(h, "weaponTicket", 40000)
    local byGrade = {}
    for _ = 1, 8 do
        local res = S.Pull(h, "weapon", 5000)
        for _, r in ipairs(res) do byGrade[r.grade] = (byGrade[r.grade] or 0) + 1 end
    end
    near(byGrade[1] / 400, 38.7743, 1.0, "lv19 노말 ~38.77%")
    near(byGrade[2] / 400, 49.503, 1.0, "lv19 레어 ~49.50%")
    near((byGrade[3] or 0) / 400, 7.5, 0.5, "lv19 에픽 ~7.5%")
end

---------------------------------------------------------------------------
print("== weapons")
do
    eq(W.Count(), 29, "29 weapon tiers")
    eq(W.EnhanceCost(1, 1), 10, "노말 하급 Lv1->2 = 10 stones")
    eq(W.CostRange(1, 1, 200), 13819, "노말 하급 Lv1->200 = 13,819")
    eq(W.CostRange(29, 1, 200), 338967029, "이터니티 하급 Lv1->200 = 338,967,029")
    eq(W.CostRange(17, 1, 200), 2017291, "레전드리 하급 Lv1->200 = 2,017,291")
    eq(W.Tier(29).equipM[200], 365144, "이터니티 하급 Lv200 equip 36,514.4%")
    eq(W.Tier(1).ownedM[1], 43, "노말 하급 Lv1 owned 4.3%")
    local h = newHero()
    W.Add(h, 1, 1)
    Hero.Add(h, "weaponStone", 1e9)
    local gained, spent = W.Enhance(h, 1)
    eq(gained, 99, "enhance to the Lv100 cap")
    eq(spent, W.CostRange(1, 1, 100), "stones spent Lv1->100")
    eq(W.Enhance(h, 1), 0, "capped at 100 without awakening")
    check(not W.Awaken(h, 1), "awakening needs duplicates")
    W.Add(h, 1, W.AWAKEN_COPIES[1])
    check(W.Awaken(h, 1), "awaken stage 1")
    eq(W.MaxLevel(W.Get(h, 1)), 120, "cap 120 after awakening 1")
    eq(W.Enhance(h, 1), 20, "enhance to 120")
    check(not W.CanPromote(h, 1), "promotion needs full awakening")
    for i = 2, 5 do W.Add(h, 1, W.AWAKEN_COPIES[i]); W.Awaken(h, 1) end
    W.Add(h, 1, 5)
    eq(W.Promote(h, 1), 1, "5 copies of a 5-awakened weapon -> next tier")
    check(W.Get(h, 2) ~= nil, "노말 중급 obtained by promotion")
    W.Equip(h, 2)
    eq(W.EquippedGrade(h), 1, "equipped weapon grade")
end

---------------------------------------------------------------------------
print("== companions")
do
    eq(C.LevelUpCost(1, 1), 5, "노말 Lv1->2 = 5 copies")
    eq(C.LevelUpCost(1, 99), 299, "노말 Lv99->100 = 299 copies")
    eq(C.LevelUpCost(1, 100), nil, "노말 max 100")
    local want = { 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 5, 6, 6 }
    local okAll = true
    for l = 1, 17 do if C.LevelUpCost(401, l) ~= want[l] then okAll = false end end
    check(okAll, "레전드리 level-up copies 1,1,1,2,...,6")
    eq(C.Value(401, "equip", "MaxDamageRatio", 18), 540, "히어로(4차) Lv18 equip 54%")
    eq(C.Value(1, "owned", "MaxHp", 100), 17034, "전사 지망생 Lv100 owned MaxHp")
    local h = newHero()
    C.Add(h, 1, 1)
    C.Add(h, 2, 200); C.Add(h, 3, 150)
    eq(C.PromotableCopies(h, 1), 348, "spare normal copies")
    local sid = C.Promote(h, 1)
    check(sid and C.Def(sid).grade == 2, "promotion gives a 레어 companion")
    eq(C.PromotableCopies(h, 1), 48, "300 copies consumed")
    eq(C.Get(h, 2).count, 24, "consumed evenly (199 -> 24)")
    eq(C.Get(h, 3).count, 24, "consumed evenly (149 -> 24)")
    eq(C.SubSlotsUnlocked(h), 0, "no sub slot at companion summon lv1")
    h.summon.companion.level = 8
    eq(C.SubSlotsUnlocked(h), 6, "6 sub slots at lv8")
    C.Add(h, 1, 10)
    eq(C.LevelUp(h, 1), 1, "level up with copies (5 needed, 2 left)")
    eq(C.AttackInheritM(401, 1, 50), math.floor(D.CompanionLink[5].m[1] * 50 / 100), "inheritance reduced below Lv100")
end

---------------------------------------------------------------------------
print("== equipment")
do
    local row = D.Gear.GEAR_10_1_CAP.main[1]
    eq(row[1], "Attack", "cap main 1 = Attack")
    eq(E.LineBase(row, 1, 6), 10, "Lv1 step 6/6 = max")
    eq(E.LineBase(row, 1, 1), 5, "Lv1 step 1/6")
    eq(D.EquipLevelFactor[9][140], 13234, "factor 9 at Lv140")
    eq(E.LineBase(row, 140, 6), math.floor(4 * 13234 / 1000) + 6, "Lv140 value formula")
    local h = newHero("hero", 100)
    local item = E.Give(h, "GEAR_30_1_CAP", 100)
    eq(item.level, 100, "item level")
    eq(item.star, 0, "star field")
    check(E.ItemName(item) == "에픽 하급 투구", "name " .. E.ItemName(item))
    -- conversion
    item.subs = { { i = 1, s = 1 }, { i = 2, s = 1 } }
    Hero.Add(h, "subOptionStone", 100000); Hero.Add(h, "meso", 1e9)
    local costs = {}
    for n = 1, 10 do
        local st = E.ConversionCost(item)
        costs[n] = st
        check(E.ConvertSubOption(h, item.id, 1), "convert #" .. n)
    end
    eq(table.concat(costs, ","), "30,45,60,75,90,105,120,135,150,150", "에픽 하급 conversion stones")
    check(not E.ConvertSubOption(h, item.id, 2), "only the first converted slot can be converted")
    local pool = D.EquipOptionPools[D.Gear.GEAR_30_1_CAP.pool]
    check(pool[item.subs[1].i][1] ~= pool[item.subs[2].i][1], "converted type differs from other lines")
    -- equip + grades
    check(E.Equip(h, item.id), "equip")
    eq(E.EquippedGrades(h).Cap, "Grade3", "EquippedGrades")
    -- dismantle
    local junk = E.Give(h, "GEAR_10_1_SHOES", 10)
    local stones = E.Dismantle(h, { junk.id, item.id })
    eq(stones, E.DismantleValue(junk), "dismantle skips equipped gear")
    eq(Hero.Count(h, "gearStone"), stones, "gear stones granted")
    -- raid gear fixed option
    local zak = E.Give(h, "GEAR_RAID_ZAKUM_CAP_4", nil)
    eq(zak.level, 101, "raid gear level = hero level clamped to the drop range (101-110)")
    eq(E.Lines(zak)[#E.Lines(zak)].stat, "AllSkillLevel", "fixed sub option line")
end

---------------------------------------------------------------------------
print("== elite summoning")
do
    local h = newHero("hero", 30)
    eq(E.GainElitePoints(h, 5000), 1500, "points capped at Lv1 gauge 1,500")
    local items, n = E.EliteSummonInstant(h, 3)
    eq(n, 3, "3 summons")
    eq(#items, 6, "2 drops per kill at Lv1")
    eq(Hero.Count(h, "eliteSummonPoint"), 1500 - 180, "60 points per summon")
    local okParts = true
    for _, it in ipairs(items) do
        if it.part == "Shoulder" or E.GradeRank(it.grade) > 2 or it.level ~= 30 then okParts = false end
    end
    check(okParts, "Lv1 drops: 노말/레어, no shoulders, item level = hero level")
    Hero.Add(h, "gearStone", 140)
    check(E.EliteStep(h) and E.EliteStep(h), "2 steps x 70 stones")
    check(not E.EliteStep(h), "no third step")
    check(E.EliteStartLevelUp(h), "start level-up (0 meso)")
    eq(E.EliteUpdate(h, U.Now() + 4), false, "5 s wait")
    eq(E.EliteUpdate(h, U.Now() + 5), true, "level up after 5 s")
    eq(E.EliteInfo(h).level, 2, "elite level 2")
    eq(E.EliteInfo(h).cost, 63, "Lv2 cost 63 points")
end

---------------------------------------------------------------------------
print("== stat providers")
do
    local h = newHero("hero", 100)
    W.Add(h, 11, 1); W.Add(h, 1, 1)
    W.Get(h, 11).level = 50
    W.Equip(h, 11)
    h.summon.companion.level = 3
    C.Add(h, 401, 1); C.Add(h, 205, 1)
    C.Get(h, 401).level = 5
    C.Get(h, 205).level = 10
    C.SetMain(h, 401)
    check(C.SetSub(h, 1, 205), "sub slot 1 at summon lv3")
    check(not C.SetSub(h, 2, 1), "sub slot 2 locked")
    local cap = E.CreateItem(h, "GEAR_10_1_CAP", 1)
    cap.main = { 6, 10, 8 }
    cap.subs = {}
    E.AddItem(h, cap)
    E.Equip(h, cap.id)

    local acc = Hero.NewAccumulator()
    for _, name in ipairs({ "weapons", "companions", "equipment" }) do Hero.statProviders[name](h, acc) end
    local T11, T1 = W.Tier(11), W.Tier(1)
    eq(acc.ratios.Attack, T11.equipM[50] + T11.ownedM[50] + T1.ownedM[1], "Attack ratio = equip + owned ATK%")
    eq(acc.adds.HitChance, T11.hit, "weapon accuracy")
    eq(acc.chains.AttackSpeed and acc.chains.AttackSpeed[1], T11.aspdM, "weapon attack speed (chained)")
    eq(acc.adds.MaxDamageRatio, C.Value(401, "equip", "MaxDamageRatio", 5), "main companion equip effect")
    eq(acc.adds.CriticalChance, C.Value(205, "equip", "CriticalChance", 10), "sub companion equip effect")
    eq(acc.adds.AttackPower, C.Value(401, "owned", "AttackPower", 5), "owned AttackPower")
    eq(acc.ratios.MaxHp, C.Value(401, "owned", "MaxHpR", 5), "owned MaxHpR -> MaxHp ratio")
    eq(acc.adds.Str, C.Value(205, "owned", "MainStat", 10), "owned MainStat -> Str (hero main stat)")
    eq(acc.adds.Attack, 10, "cap Attack line")
    eq(acc.adds.MaxHp, C.Value(205, "owned", "MaxHp", 10) + 50, "MaxHp = companion owned + cap")
    eq(acc.adds.Defence, 15, "cap Defence line")
    eq(acc.companions[1].sid, 401, "profile companions = main companion")
    eq(acc.companions[1].jobKey, "hero", "supporter job key")
    eq(#C.BattleSupporters(h, 3), 2, "main + sub when asked")

    -- line hook (e.g. star force) and item stat hook
    E.RegisterLineHook(function(item, line)
        if item.testAmp and line.kind == "main" then return line.value + math.floor(line.base * 100 / 1000) end
    end)
    cap.testAmp = true
    local acc2 = Hero.NewAccumulator()
    Hero.statProviders.equipment(h, acc2)
    eq(acc2.adds.Attack, 11, "line hook amplifies main option")
    cap.testAmp = nil
    local m, sub = E.ItemBaseOptions(cap)
    eq(#m, 3, "ItemBaseOptions main list")
    eq(m[1].type .. "=" .. m[1].value, "Attack=10", "ItemBaseOptions value")
    eq(E.EquippedItems(h).Cap, cap, "EquippedItems")

    local profile = Hero.BuildProfile(h)
    local cp = Hero.CombatPower(profile)
    check(cp > 0, "combat power " .. tostring(cp))
    check(profile.companions and profile.companions[1].sid == 401, "profile.companions")
    local before = cp
    local better = E.Give(h, "GEAR_40_4_CAP", 100)
    eq(E.AutoEquip(h), 1, "auto-equip picks the better cap")
    eq(E.Equipped(h, "Cap").id, better.id, "better cap equipped")
    check(Hero.CombatPower(Hero.BuildProfile(h)) > before, "power increased")
    C.AutoEquip(h)
    eq(C.Equipped(h), 401, "auto main = highest grade")
end

print(string.format("\n%d passed, %d failed", pass, fail))
if fail > 0 then os.exit(1) end
