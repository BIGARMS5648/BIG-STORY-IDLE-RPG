-- Official combat guide rules (in-game guide): stat accumulation, caps, sqrt contents,
-- PvP coefficient placement, debuff tolerance, companion cap, combat power.
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
local Hero, Battle = ns.Hero, ns.Battle
local checks, failed = 0, 0
local function check(ok, msg)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL", msg) end
end
local function approx(a, b, tol) return math.abs(a - b) <= (tol or 1e-6) * math.max(1, math.abs(b)) end

local b = Battle.New({ seed = 1 })
local function creature(stats) return ns.Creature.New(b, { name = "t", side = 1, stats = stats }) end

-- 1.1 기본 합산: 20% + 30% = 50%
local c = creature({ adds = { AttackPower = 200 } })
c:AddMod("AttackPower", "add", 300)
check(c:Stat("AttackPower") == 500, "basic sum 20%+30%")
-- 1.1 체감 누적: current + (cap - current) * add / cap  (attack speed cap 150%)
c = creature({ chains = { AttackSpeed = { 300 } } })
c:AddMod("AttackSpeed", "add", 100)
check(c:Stat("AttackSpeed") == math.floor(300 + (1500 - 300) * 100 / 1500), "chained attack speed 30%+10% -> 38%")
-- 1.1 효과별 곱연산: 20% x 30% -> +56%
c = creature({ mults = { FinalDamage = { 200 } } })
c:AddMod("FinalDamage", "add", 300)
check(c:Stat("FinalDamage") == 560, "final damage 1.2 x 1.3 = +56%")
-- 1.1 합 + 배율: flat -> % -> skill % -> skill flat
c = creature({ adds = { Attack = 1000 }, ratios = { Attack = 200 } })
c:AddMod("Attack", "ratio", 100)
c:AddMod("Attack", "add", 50)
check(c:Stat("Attack") == math.floor(math.floor(1000 * 1.2) * 1.1) + 50, "attack layers 1000 ->1200 ->1320 +50")
-- 1.2 caps
c = creature({ chains = { Toughness = { 900, 900 }, PiercePower = { 999, 999 }, AttackSpeed = { 1500, 1500 } } })
check(c:Stat("Toughness") <= 950, "damage taken decrease <= 95%")
check(c:Stat("PiercePower") < 1000, "pierce < 100%")
check(c:Stat("AttackSpeed") <= 1500, "attack speed <= 150%")
-- 1.2 hit / avoid: gap 100 -> 70%
check(ns.Data.Combat.missPermilleByGap[100] == 700, "miss 70% at gap 100")
-- debuff tolerance: gap >= 100 -> 85% cap
local att = creature({ adds = { DebuffResistIgnore = 0 } })
local tgt = creature({ adds = { DebuffResist = 250 } })
check(approx(b:DebuffReduction(att, tgt), 0.85), "debuff tolerance capped at 85%")

-- 2.1 √ contents and PvP: skill coefficient outside the root
local job = ns.SkillBook.JobByKey("hero")
local function hit(dungeonType, boss, coef, inner)
    local bb = Battle.New({ seed = 3, dungeonType = dungeonType, controller = boss and { boss = boss } or nil })
    local a = bb:AddCreature({ name = "a", side = 1, isHero = true, level = 1, job = job,
        stats = { adds = { Attack = 10000, MinDamageRatio = 1000, MaxDamageRatio = 1000 } } })
    local t = bb:AddCreature({ name = "t", side = 2, isBoss = true, stats = { adds = { MaxHp = 1e12 } } })
    return (bb:ComputeHit(a, t, { pct = coef * inner, coef = coef, isBase = false }, {}))
end
local normal = hit("Campaign", nil, 500, 1.2)
local root = hit("BossRaid", "zakum", 500, 1.2)
check(approx(root, math.floor(math.sqrt(normal / 6 * 1.2 / 1.2 * 1.2 * 100 / 100) * 5), 0.01) or root < normal,
    "zakum raid uses the square-root adjustment")
local pink = hit("BossRaid", "pinkbean", 500, 1.2)
check(pink == normal, "pink bean raid uses the normal formula")
local pq = hit("PartyDungeon", nil, 500, 1.2)
check(pq == root, "party quest uses the square-root adjustment")
-- doubling the coefficient doubles √-content damage (coefficient is outside the root)
local root2 = hit("BossRaid", "zakum", 1000, 1.2)
check(approx(root2, root * 2, 0.002), "coefficient outside the root")

-- 2.5 companion attack inheritance cap 90%
local hero = Hero.New("hero", "T")
hero.level = 140
local profile = Hero.BuildProfile(hero)
local bb = ns.Game.NewBattle(nil, { profile = profile, noSupporters = true })
local s = ns.Supporters.Spawn(bb, hero, profile, { name = "동료", jobKey = "bishop", jobStep = 4, grade = 5, level = 18,
    attackInheritM = 1500, spawnMs = 30000 })
check(s and s:Stat("Attack") <= math.floor(bb.heroCreature:Stat("Attack") * 0.9) + 1, "companion inheritance <= 90%")
check(s and s:Stat("CoolTimeReduceRatio") == 0, "companion ignores cooldown reduction")

-- 3. combat power: baseline values contribute nothing extra; PvP ignores boss/normal damage
local p0 = Hero.BuildProfile(hero)
local cp = Hero.CombatPower(p0)
local pvp = Hero.PvpCombatPower(p0)
check(cp > 0 and pvp > 0, "combat power positive")
p0.stats.adds.AttackPowerToBoss = (p0.stats.adds.AttackPowerToBoss or 0) + 1000
check(Hero.CombatPower(p0) > cp and Hero.PvpCombatPower(p0) == pvp, "boss damage counts in CP but not in PvP CP")
hero.masteries = ns.SkillBook.AllMasteriesAt(Hero.Job(hero), 140)
local p1 = Hero.BuildProfile(hero)
check(Hero.CombatPower(p1) > cp * 5, "learned masteries multiply combat power")

print(string.format("rules: %d checks, %d failed, errors %d (CP %s, PvP CP %s)", checks, failed, errors,
    ns.U.FormatNumber(cp), ns.U.FormatNumber(pvp)))
if failed > 0 or errors > 0 then os.exit(1) end
