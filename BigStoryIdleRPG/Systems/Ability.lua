-- 어빌리티 (Ability): up to 8 lines unlocked by 용사의 힘 stage 2..9, re-rolled ("변환") with
-- 명예의 훈장, client 1.18.0 (D.Ability).
--   * cost per conversion = medalsPerConversionByLockedLines[locked + 1] of the current ability level
--   * every medal spent = 1 ability EXP; levels 1..20 change the grade weights (per 10,000)
--   * option = grade by weight, then uniform among that grade's options (hero-ability-math.mjs)
--   * if kind, grade and value all equal the previous option of that line, re-roll inside the grade
--   * locked lines are kept; when every active line is locked no conversion is possible
-- PROVISIONAL: the value inside an option's [min, max] is rolled uniformly (distribution not
-- published); a newly unlocked line stays empty until the next conversion.
--
-- Hero fields: hero.ability = { level = 1..20, exp = total medals spent,
--                               lines = { [slot] = { opt = optionIndex, value = raw, locked = bool } } }
--
-- API  (rng defaults to ns.U.rng)
--   ns.Ability.SlotCount(hero)                -> active lines (0..8)
--   ns.Ability.LockedCount(hero)
--   ns.Ability.ConvertCost(hero)              -> 명예의 훈장 per conversion
--   ns.Ability.GradeChances(level)            -> { 노멀, 레어, 에픽, 유니크, 레전드리, 미스틱 } per 10,000
--   ns.Ability.Option(index)                  -> { grade, stat, name, min, max }
--   ns.Ability.OptionChance(level, index)     -> probability (0..1) of one option on one line
--   ns.Ability.Convert(hero, rng)             -> ok, errText   fires "ABILITY_CONVERTED"(hero)
--   ns.Ability.SetLock(hero, slot, locked)    -> ok, errText
--   ns.Ability.ExpInfo(hero)                  -> level, expIntoLevel, expToNext (nil at max)
--   ns.Ability.Lines(hero)                    -> { {slot, opt, grade, stat, value, locked, text}, ... }
--   ns.Ability.Stats(hero)                    -> { {stat, raw}, ... }
local ADDON, ns = ...
local D = ns.Data
local Hero = ns.Hero
local UP = ns.Upgrades

local A = {}
ns.Ability = A
local DA = D.Ability

local byGrade = {}
for i, o in ipairs(DA.options) do
    byGrade[o.grade] = byGrade[o.grade] or {}
    table.insert(byGrade[o.grade], i)
end

Hero.RegisterSystem("ability", {
    init = function(hero)
        hero.ability = hero.ability or { level = 1, exp = 0, lines = {} }
    end,
})

function A.SlotCount(hero)
    local stage = hero.heroPower and hero.heroPower.stage or 1
    local n = 0
    for _, need in ipairs(DA.slotUnlockStage) do
        if stage >= need then n = n + 1 end
    end
    return n
end

function A.LockedCount(hero)
    local n = 0
    for slot = 1, A.SlotCount(hero) do
        local l = hero.ability.lines[slot]
        if l and l.locked then n = n + 1 end
    end
    return n
end

function A.ConvertCost(hero)
    return DA.levels[hero.ability.level].cost[A.LockedCount(hero) + 1]
end

function A.GradeChances(level) return DA.levels[level or 1].weights end
function A.Option(i) return DA.options[i] end

function A.OptionChance(level, i)
    local o = DA.options[i]
    return DA.levels[level].weights[o.grade] / 10000 / #byGrade[o.grade]
end

local function rollLine(level, prev, rng)
    local grade = rng:Weighted(DA.levels[level].weights, 10000)
    local list = byGrade[grade]
    local opt, value
    for _ = 1, 100 do
        opt = list[rng:Int(1, #list)]
        local o = DA.options[opt]
        value = rng:Int(o.min, o.max)
        if not (prev and prev.opt == opt and prev.value == value) then break end
    end
    return { opt = opt, value = value }
end
A.RollLine = rollLine

local function levelFromExp(exp)
    local lv = 1
    while lv < DA.maxLevel and exp >= DA.levels[lv].exp do
        exp = exp - DA.levels[lv].exp
        lv = lv + 1
    end
    return lv, exp
end

function A.ExpInfo(hero)
    local lv, into = levelFromExp(hero.ability.exp or 0)
    if lv >= DA.maxLevel then return lv, into, nil end
    return lv, into, DA.levels[lv].exp
end

function A.Convert(hero, rng)
    local ab = hero.ability
    local slots = A.SlotCount(hero)
    if slots == 0 then return false, "용사의 힘 2단계에서 개방됩니다." end
    if A.LockedCount(hero) >= slots then return false, "모든 칸이 잠겨 있어 변환할 수 없습니다." end
    local cost = A.ConvertCost(hero)
    if not Hero.Spend(hero, "honorMedal", cost, "ability") then
        return false, D.CurrencyName("honorMedal") .. "이(가) 부족합니다."
    end
    rng = UP.rng(rng)
    for slot = 1, slots do
        local prev = ab.lines[slot]
        if not (prev and prev.locked) then
            ab.lines[slot] = rollLine(ab.level, prev, rng)
        end
    end
    ab.exp = (ab.exp or 0) + cost
    ab.level = (levelFromExp(ab.exp))
    if ns.Fire then ns.Fire("ABILITY_CONVERTED", hero) end
    Hero.Changed(hero, "ability")
    return true
end

function A.SetLock(hero, slot, locked)
    local l = hero.ability.lines[slot]
    if slot > A.SlotCount(hero) or not l then return false, "잠글 수 없는 칸입니다." end
    l.locked = locked and true or nil
    Hero.Changed(hero, "ability")
    return true
end

function A.Lines(hero)
    local out = {}
    for slot = 1, A.SlotCount(hero) do
        local l = hero.ability.lines[slot]
        if l then
            local o = DA.options[l.opt]
            out[#out + 1] = { slot = slot, opt = l.opt, grade = o.grade, gradeName = DA.gradeNames[o.grade],
                stat = o.stat, value = l.value, locked = l.locked or false, text = UP.FormatStat(o.stat, l.value) }
        else
            out[#out + 1] = { slot = slot }
        end
    end
    return out
end

function A.Stats(hero)
    local out = {}
    for slot = 1, A.SlotCount(hero) do
        local l = hero.ability.lines[slot]
        if l and DA.options[l.opt] then out[#out + 1] = { DA.options[l.opt].stat, l.value } end
    end
    return out
end

Hero.RegisterStatProvider("ability", function(hero, acc)
    if not hero.ability then return end
    UP.ApplyList(hero, acc, A.Stats(hero))
end)
