-- 장비 (Equipment): 15 parts, gear records with main options + rolled sub options, item level,
-- equip / unequip, auto-equip by combat power, dismantle (분해 -> 장비 강화석), sub-option conversion
-- (부옵션 변환), and acquisition through 엘리트 몬스터 소환 (elite monster summoning).
-- Data: Data/Equipment.lua (itemlibrary client 1.18.0 + KR elite summon table, 40 levels).
--
-- Star force / potential / additional potential / scrolls / enchants belong to other systems: items keep
-- item.star (0), item.potential (nil), item.additional (nil), item.scroll (nil; enchants live in
-- item.scroll.enchant[subLine]) for them, and those systems plug in with E.RegisterItemStatHook (extra stats
-- per item; ns.Upgrades binds to it) or E.RegisterLineHook (rewrite the value of one main/sub line).
--
-- Item (saved) = { id, code, part, grade ("Grade1".."Grade6_1"), tier (1..4), level (item level), job,
--   main = { step1, step2, step3 },            -- roll step of each Gear.main row
--   subs = { { i = poolIndex, s = step }, ... },-- rolled sub options (0..4 lines)
--   star = 0, potential = nil, additional = nil, scroll = nil, locked = nil,
--   convertSlot = nil, convertCount = 0 }      -- fixed sub options (raid gear) come from Gear.fixed
-- Saved: hero.equipment = { items = { [id] = item }, nextId, equipped = { [part] = id },
--   elite = { level, step, upgradeEndsAt, summons }, settings = { autoEquip, autoDismantleRank } }
--
-- Public API (ns.Equipment)
--   E.PARTS (15 part keys, display order)  E.VISIBLE_PARTS (8 armor parts drawn on the character)
--   E.GradeRank(grade) -> 1..8      E.GradeName(grade)      E.TierName(tier)      E.PartName(part)
--   E.ItemName(item) -> display name
--   E.CreateItem(hero, code, level) -> item (rolled, not stored)
--   E.AddItem(hero, item) -> item (stored; returns nil when it was auto-dismantled because the bag is full)
--   E.Give(hero, code, level) -> item (create + add)
--   E.Get(hero, id)   E.Items(hero, part) -> list   E.ItemCount(hero)
--   E.Lines(item) -> { { stat, value, kind = "main"|"sub"|"fixed", index, base } }  (line hooks applied)
--   E.LineBase(row, itemLevel, step) -> base value of one option row
--   E.ItemBaseOptions(item) -> mainList, subList  ({ type = StatType, value = raw }; subList = rolled + fixed
--                              sub options; no hooks) - used by StarForce (ns.Upgrades.ItemOptions)
--   E.ItemStats(item, acc, hero) -> applies the item's stats to an accumulator (+ item stat hooks)
--   E.RegisterLineHook(fn(item, line) -> value)      E.RegisterItemStatHook(fn(item, acc, hero))
--   E.Equip(hero, id) / E.Unequip(hero, part)   (fire Hero.Changed(hero, "equipment"))
--   E.Equipped(hero, part) -> item     E.EquippedItems(hero) -> { [part] = item }
--   E.EquippedGrades(hero) -> { Cap = "Grade5", ... } (visible parts only, empty slots omitted)
--   E.Power(hero, overrides) -> combat power with { [part] = id|false } swapped in
--   E.IsUpgrade(hero, item) -> bool, newPower, oldPower
--   E.AutoEquip(hero) -> number of parts changed
--   E.DismantleValue(item) -> 장비 강화석     E.Dismantle(hero, ids) -> stones, count
--   E.DismantleBelow(hero, rank) -> stones, count   (bulk: skips equipped / locked / converted / enchanted)
--   E.SetLocked(hero, id, bool)
--   E.ConversionCost(item) -> stones, meso | nil, err
--   E.ConvertSubOption(hero, id, lineIndex) -> ok, err
--   Elite summoning:
--   E.EliteInfo(hero) -> { level, maxLevel, cost, drops, gauge, points, step, steps, stepCost, meso, delay,
--                          upgradeEndsAt, canStep, canLevelUp, rates = { {grade, tier, percent} } }
--   E.GainElitePoints(hero, n) -> added (capped at the level's gauge)
--   E.CanEliteSummon(hero) -> ok, err
--   E.EliteSummon(hero) -> encounter { level, creature, drops } (points spent; battle spawns the elite)
--   E.EliteRefund(hero, encounter)   (elite abandoned: points back)
--   E.EliteLoot(hero, encounter) -> items (rolled drops, added to the bag, auto-equip/dismantle settings)
--   E.EliteSummonInstant(hero, count) -> items, summons   (summon + kill immediately; idle/offline helper)
--   E.EliteStep(hero) -> ok, err    E.EliteStartLevelUp(hero) -> ok, err
--   E.EliteUpdate(hero, now) -> leveledUp (call on a timer / when the UI opens; EliteInfo calls it too)
--   E.EliteSkipTime(hero, tickets) -> used  (시간 단축 티켓 1분: -60 s each)
-- Events: "EQUIPMENT_CHANGED"(hero, what, item), "ELITE_LEVEL_UP"(hero, level)
local ADDON, ns = ...
local U = ns.U
local D = ns.Data
local H = ns.Hero

local E = {}
ns.Equipment = E

local GEAR = D.Gear
local POOLS = D.EquipOptionPools
local FACTOR = D.EquipLevelFactor
local ELITE = D.EliteSummon
local LABELS = D.EquipLabels

E.PARTS = LABELS.partOrder
E.VISIBLE_PARTS = { "Cap", "Shoulder", "Clothes", "Pants", "Glove", "Belt", "Shoes", "Cape" }
E.MAX_ITEM_LEVEL = #FACTOR[8]

---------------------------------------------------------------------------
-- PROVISIONAL rules (not published anywhere; see report)
---------------------------------------------------------------------------
-- PROVISIONAL: bag size (the original's limit is not in the data). Drops beyond it are dismantled.
E.BAG_SIZE = 300
-- PROVISIONAL: 분해 yields in 장비 강화석 (the KR guide only says dismantling gives the stones used for
-- elite summon level steps). Base by grade rank 1..8, x(1 + 0.2*(tier-1)).
E.DISMANTLE_BASE = { 5, 15, 50, 150, 500, 1500, 5000, 15000 }
E.DISMANTLE_TIER_MULT = { 10, 12, 14, 16 }     -- /10
-- PROVISIONAL: number of elites alive at once (base not published; paid membership / KR challenge +1).
E.ELITE_SIMULTANEOUS = 1
-- PROVISIONAL (KR inven guide, not client data): item level = character level when the item is obtained.
-- PROVISIONAL: roll steps are uniform in 1..steps (only the range is published).
-- PROVISIONAL: party-quest / raid gear level = hero level clamped to the gear's drop level range.

local GRADE_RANK = {}
for i, g in ipairs(LABELS.gradeOrder) do GRADE_RANK[g] = i end

-- normal (elite) gear lookup: grade|tier|part -> code
local NORMAL = {}
for code, g in pairs(GEAR) do
    if g.src == "normal" then NORMAL[g.grade .. "|" .. g.tier .. "|" .. g.part] = code end
end

function E.GradeRank(grade) return GRADE_RANK[grade] or 0 end
function E.GradeName(grade) return LABELS.grades[grade] or grade end
function E.TierName(tier) return LABELS.tiers[tier] or "" end
function E.PartName(part) return LABELS.parts[part] or part end
function E.StatName(stat) return LABELS.stats[stat] or stat end
function E.IsPercentStat(stat)
    for _, s in ipairs(LABELS.percentStats) do if s == stat then return true end end
    return false
end
function E.NormalGearCode(grade, tier, part) return NORMAL[grade .. "|" .. tier .. "|" .. part] end

function E.ItemName(item)
    local g = GEAR[item.code]
    if g and g.name then return g.name end
    return string.format("%s %s %s", E.GradeName(item.grade), E.TierName(item.tier), E.PartName(item.part))
end

local function state(hero)
    local s = hero.equipment
    if not s then
        s = {}
        hero.equipment = s
    end
    s.items = s.items or {}
    s.nextId = s.nextId or 1
    s.equipped = s.equipped or {}
    s.elite = s.elite or { level = 1, step = 0, summons = 0 }
    s.settings = s.settings or { autoEquip = false, autoDismantleRank = 0 }
    return s
end

local function changed(hero, what, item)
    ns.Fire("EQUIPMENT_CHANGED", hero, what, item)
    H.Changed(hero, "equipment")
end

local function rng() return ns.U.rng end

-- Hero.Spend with a 0 amount on a missing wallet key errors; treat 0 as free
local function spend(hero, key, n, reason)
    if not n or n <= 0 then return true end
    return H.Spend(hero, key, n, reason)
end

---------------------------------------------------------------------------
-- Values
---------------------------------------------------------------------------
-- row = { stat, min, max, steps, factorIndex }
function E.LineBase(row, level, step)
    local f = FACTOR[row[5]]
    local factor = f and f[U.clamp(level or 1, 1, #f)] or 1000
    local v = math.floor(row[2] * factor / 1000)
    if row[4] > 0 then v = v + math.floor((row[3] - row[2]) * step / row[4]) end
    return v
end

local lineHooks, statHooks = {}, {}
function E.RegisterLineHook(fn) lineHooks[#lineHooks + 1] = fn end
function E.RegisterItemStatHook(fn) statHooks[#statHooks + 1] = fn end

function E.Lines(item)
    local g = GEAR[item.code]
    local out = {}
    if not g then return out end
    local function push(row, step, kind, index)
        local base = E.LineBase(row, item.level, step)
        local line = { stat = row[1], base = base, value = base, kind = kind, index = index }
        for _, fn in ipairs(lineHooks) do
            local ok, v = pcall(fn, item, line)
            if ok and v then line.value = v end
        end
        out[#out + 1] = line
    end
    for i, row in ipairs(g.main) do push(row, item.main[i] or row[4], "main", i) end
    local pool = POOLS[g.pool]
    for i, sub in ipairs(item.subs or {}) do push(pool[sub.i], sub.s, "sub", i) end
    for i, row in ipairs(g.fixed or {}) do push(row, row[4], "fixed", i) end
    return out
end

function E.ItemBaseOptions(item)
    local main, sub = {}, {}
    local g = GEAR[item.code]
    if not g then return main, sub end
    for i, row in ipairs(g.main) do
        main[#main + 1] = { type = row[1], value = E.LineBase(row, item.level, item.main[i] or row[4]) }
    end
    local pool = POOLS[g.pool]
    for _, s in ipairs(item.subs or {}) do
        local row = pool[s.i]
        sub[#sub + 1] = { type = row[1], value = E.LineBase(row, item.level, s.s) }
    end
    for _, row in ipairs(g.fixed or {}) do
        sub[#sub + 1] = { type = row[1], value = E.LineBase(row, item.level, row[4]) }
    end
    return main, sub
end

function E.ItemStats(item, acc, hero)
    local job = item.job or (hero and hero.jobKey)
    for _, line in ipairs(E.Lines(item)) do
        ns.ApplyStat(acc, job, line.stat, line.value)
    end
    for _, fn in ipairs(statHooks) do pcall(fn, item, acc, hero) end
end

---------------------------------------------------------------------------
-- Creation
---------------------------------------------------------------------------
local function rollStep(row)
    if row[4] <= 0 then return 0 end
    return rng():Int(1, row[4])
end

local function rollSubs(g, count, exclude)
    local pool = POOLS[g.pool]
    local taken = {}
    for _, row in ipairs(g.fixed or {}) do taken[row[1]] = true end
    for k in pairs(exclude or {}) do taken[k] = true end
    local subs = {}
    for _ = 1, count do
        local cands = {}
        for i, row in ipairs(pool) do
            if not taken[row[1]] then cands[#cands + 1] = i end
        end
        if #cands == 0 then break end
        local i = cands[rng():Int(1, #cands)]
        taken[pool[i][1]] = true
        subs[#subs + 1] = { i = i, s = rollStep(pool[i]) }
    end
    return subs
end

function E.DefaultLevel(hero, code)
    local g = GEAR[code]
    local lv = U.clamp(hero and hero.level or 1, 1, E.MAX_ITEM_LEVEL)
    if g and g.dropLevel then lv = U.clamp(lv, g.dropLevel[1], g.dropLevel[2]) end
    return lv
end

function E.CreateItem(hero, code, level)
    local g = GEAR[code]
    if not g then return nil end
    level = U.clamp(level or E.DefaultLevel(hero, code), 1, E.MAX_ITEM_LEVEL)
    local item = {
        code = code, part = g.part, grade = g.grade, tier = g.tier, level = level,
        job = hero and hero.jobKey, main = {}, subs = nil,
        star = 0, potential = nil, additional = nil, scroll = nil, convertCount = 0,
    }
    for i, row in ipairs(g.main) do item.main[i] = rollStep(row) end
    local nLines = rng():Weighted(g.lines, 1000) - 1
    item.subs = rollSubs(g, nLines)
    return item
end

function E.ItemCount(hero)
    return U.Count(state(hero).items)
end

function E.Get(hero, id) return state(hero).items[id] end

function E.Items(hero, part)
    local out = {}
    for _, it in pairs(state(hero).items) do
        if not part or it.part == part then out[#out + 1] = it end
    end
    table.sort(out, function(a, b) return a.id < b.id end)
    return out
end

function E.AddItem(hero, item)
    local s = state(hero)
    if E.ItemCount(hero) >= E.BAG_SIZE then
        H.Add(hero, "gearStone", E.DismantleValue(item), "dismantle")
        return nil
    end
    item.id = s.nextId
    s.nextId = s.nextId + 1
    s.items[item.id] = item
    ns.Fire("EQUIPMENT_CHANGED", hero, "add", item)
    return item
end

function E.Give(hero, code, level)
    local item = E.CreateItem(hero, code, level)
    return item and E.AddItem(hero, item)
end

---------------------------------------------------------------------------
-- Equip
---------------------------------------------------------------------------
function E.Equipped(hero, part)
    local s = state(hero)
    local id = s.equipped[part]
    return id and s.items[id] or nil
end

function E.Equip(hero, id)
    local s = state(hero)
    local item = s.items[id]
    if not item then return false, "없는 장비입니다." end
    s.equipped[item.part] = id
    changed(hero, "equip", item)
    return true
end

function E.Unequip(hero, part)
    local s = state(hero)
    if not s.equipped[part] then return false end
    s.equipped[part] = nil
    changed(hero, "unequip", nil)
    return true
end

function E.IsEquipped(hero, item)
    return item and state(hero).equipped[item.part] == item.id
end

function E.EquippedItems(hero)
    local s = state(hero)
    local out = {}
    for part, id in pairs(s.equipped) do
        if s.items[id] then out[part] = s.items[id] end
    end
    return out
end

function E.EquippedGrades(hero)
    local out = {}
    for _, part in ipairs(E.VISIBLE_PARTS) do
        local it = E.Equipped(hero, part)
        if it then out[part] = it.grade end
    end
    return out
end

-- overrides = { [part] = id | false }  (false = empty slot)
function E.Power(hero, overrides)
    local s = state(hero)
    local saved = {}
    for part, id in pairs(overrides or {}) do
        saved[part] = s.equipped[part] or false
        s.equipped[part] = id or nil
    end
    local ok, p = pcall(function() return H.CombatPower(H.BuildProfile(hero)) end)
    for part, id in pairs(saved) do s.equipped[part] = id or nil end
    return ok and p or 0
end

function E.IsUpgrade(hero, item)
    local cur = E.Power(hero)
    local new = E.Power(hero, { [item.part] = item.id })
    return new > cur, new, cur
end

local function quickKey(it)
    return E.GradeRank(it.grade) * 1e6 + it.tier * 1e5 + it.level * 100 + #(it.subs or {})
end

function E.AutoEquip(hero)
    local s = state(hero)
    local changes = 0
    for _, part in ipairs(E.PARTS) do
        local cands = E.Items(hero, part)
        if #cands > 0 then
            table.sort(cands, function(a, b) return quickKey(a) > quickKey(b) end)
            local cur = s.equipped[part]
            local best, bestP = cur, E.Power(hero)
            for i = 1, math.min(6, #cands) do
                local it = cands[i]
                if it.id ~= cur then
                    local p = E.Power(hero, { [part] = it.id })
                    if p > bestP then best, bestP = it.id, p end
                end
            end
            if best and best ~= cur then
                s.equipped[part] = best
                changes = changes + 1
            end
        end
    end
    if changes > 0 then changed(hero, "equip", nil) end
    return changes
end

---------------------------------------------------------------------------
-- Dismantle
---------------------------------------------------------------------------
function E.DismantleValue(item)
    local base = E.DISMANTLE_BASE[E.GradeRank(item.grade)] or 0
    return math.floor(base * (E.DISMANTLE_TIER_MULT[item.tier] or 10) / 10)
end

function E.SetLocked(hero, id, locked)
    local it = E.Get(hero, id)
    if it then it.locked = locked and true or nil end
end

local function enchanted(item)
    return item.scroll ~= nil and item.scroll.enchant ~= nil and next(item.scroll.enchant) ~= nil
end

-- explicit dismantle: skips equipped and locked items
function E.Dismantle(hero, ids)
    local s = state(hero)
    local stones, count = 0, 0
    for _, id in ipairs(ids) do
        local it = s.items[id]
        if it and not it.locked and not E.IsEquipped(hero, it) then
            stones = stones + E.DismantleValue(it)
            count = count + 1
            s.items[id] = nil
        end
    end
    if stones > 0 then H.Add(hero, "gearStone", stones, "dismantle") end
    if count > 0 then ns.Fire("EQUIPMENT_CHANGED", hero, "dismantle", nil) end
    return stones, count
end

-- bulk dismantle (KR 2026-11-05: converted / enchanted gear is excluded from bulk and auto dismantle)
function E.DismantleBelow(hero, maxRank)
    local ids = {}
    for id, it in pairs(state(hero).items) do
        if E.GradeRank(it.grade) <= maxRank and not it.locked and not E.IsEquipped(hero, it)
            and (it.convertCount or 0) == 0 and not enchanted(it) then
            ids[#ids + 1] = id
        end
    end
    table.sort(ids)
    return E.Dismantle(hero, ids)
end

---------------------------------------------------------------------------
-- Sub-option conversion (부옵션 변환, 1.18)
---------------------------------------------------------------------------
function E.ConversionCost(item)
    local byTier = D.SubOptionConversion[item.grade]
    local row = byTier and byTier[item.tier]
    if not row then return nil, "변환할 수 없는 등급입니다." end
    local c = row[math.min((item.convertCount or 0) + 1, #row)]
    return c[1], c[2]
end

function E.ConvertSubOption(hero, id, lineIndex)
    local item = E.Get(hero, id)
    if not item then return false, "없는 장비입니다." end
    local sub = item.subs and item.subs[lineIndex]
    if not sub then return false, "변환할 부옵션이 없습니다." end
    if item.convertSlot and item.convertSlot ~= lineIndex then
        return false, "처음 변환한 부옵션만 변환할 수 있습니다."
    end
    local stones, meso = E.ConversionCost(item)
    if not stones then return false, meso end
    if H.Count(hero, "subOptionStone") < stones then return false, "장비 부 옵션 변환석이 부족합니다." end
    if H.Count(hero, "meso") < meso then return false, "골드가 부족합니다." end
    spend(hero, "subOptionStone", stones, "subConvert")
    spend(hero, "meso", meso, "subConvert")
    local g = GEAR[item.code]
    local pool = POOLS[g.pool]
    local exclude = {}
    for i, other in ipairs(item.subs) do
        if i ~= lineIndex then exclude[pool[other.i][1]] = true end
    end
    local new = rollSubs(g, 1, exclude)[1]
    if new then item.subs[lineIndex] = new end
    -- the converted slot loses its 마법 부여 (Systems/Scrolls.lua keeps it in item.scroll.enchant[line])
    if item.scroll and item.scroll.enchant then item.scroll.enchant[lineIndex] = nil end
    item.convertSlot = lineIndex
    item.convertCount = (item.convertCount or 0) + 1
    if E.IsEquipped(hero, item) then changed(hero, "convert", item)
    else ns.Fire("EQUIPMENT_CHANGED", hero, "convert", item) end
    return true
end

---------------------------------------------------------------------------
-- Elite monster summoning (엘리트 몬스터 소환)
---------------------------------------------------------------------------
local function eliteRow(level) return ELITE.levels[U.clamp(level, 1, ELITE.maxLevel)] end

function E.EliteInfo(hero)
    E.EliteUpdate(hero)                 -- finishes a level-up whose wait is over
    local el = state(hero).elite
    local row = eliteRow(el.level)
    local rates = {}
    for _, r in ipairs(row.rates) do
        rates[#rates + 1] = { grade = r[1], tier = r[2], percent = r[3] / 100 }
    end
    local maxed = el.level >= ELITE.maxLevel
    return {
        level = el.level, maxLevel = ELITE.maxLevel,
        cost = row.cost, drops = row.drops, gauge = row.gauge, creature = row.creature,
        points = H.Count(hero, "eliteSummonPoint"),
        step = el.step or 0, steps = row.steps, stepCost = row.stepCost,
        meso = row.meso, delay = row.delay, upgradeEndsAt = el.upgradeEndsAt,
        canStep = not maxed and not el.upgradeEndsAt and (el.step or 0) < row.steps,
        canLevelUp = not maxed and not el.upgradeEndsAt and (el.step or 0) >= row.steps,
        simultaneous = E.ELITE_SIMULTANEOUS,
        summons = el.summons or 0,
        rates = rates,
    }
end

function E.GainElitePoints(hero, n)
    local row = eliteRow(state(hero).elite.level)
    local have = H.Count(hero, "eliteSummonPoint")
    local add = math.max(0, math.min(n, row.gauge - have))
    if add > 0 then H.Add(hero, "eliteSummonPoint", add, "elitePoints") end
    return add
end

function E.CanEliteSummon(hero)
    local row = eliteRow(state(hero).elite.level)
    if H.Count(hero, "eliteSummonPoint") < row.cost then
        return false, "정예 소환 포인트가 부족합니다."
    end
    return true
end

function E.EliteSummon(hero)
    local ok, err = E.CanEliteSummon(hero)
    if not ok then return nil, err end
    local el = state(hero).elite
    local row = eliteRow(el.level)
    H.Spend(hero, "eliteSummonPoint", row.cost, "eliteSummon")
    el.summons = (el.summons or 0) + 1
    ns.Fire("ELITE_SUMMONED", hero, el.level)
    return { level = el.level, creature = row.creature, drops = row.drops, cost = row.cost }
end

function E.EliteRefund(hero, enc)
    if enc and enc.cost and not enc.done then
        enc.done = true
        H.Add(hero, "eliteSummonPoint", enc.cost, "eliteRefund")
    end
end

-- one drop: grade/tier from the level table, part uniform among the 8 armor parts (shoulders Epic+ only)
function E.RollEliteDrop(hero, level)
    local row = eliteRow(level)
    local weights = {}
    for i, r in ipairs(row.rates) do weights[i] = r[3] end
    local r = row.rates[rng():Weighted(weights, 10000)]
    local grade, tier = r[1], r[2]
    local parts = {}
    for _, p in ipairs(ELITE.parts) do
        if p ~= "Shoulder" or E.GradeRank(grade) >= E.GradeRank(ELITE.shoulderMinGrade) then
            parts[#parts + 1] = p
        end
    end
    local code = E.NormalGearCode(grade, tier, parts[rng():Int(1, #parts)])
    return E.CreateItem(hero, code)
end

function E.EliteLoot(hero, enc)
    if not enc or enc.done then return {} end
    enc.done = true
    local s = state(hero)
    local out = {}
    for _ = 1, enc.drops do
        local item = E.AddItem(hero, E.RollEliteDrop(hero, enc.level))
        if item then out[#out + 1] = item end
    end
    if s.settings.autoEquip then E.AutoEquip(hero) end
    local rank = s.settings.autoDismantleRank or 0
    if rank > 0 then
        local ids = {}
        for _, it in ipairs(out) do
            if E.GradeRank(it.grade) <= rank and not E.IsEquipped(hero, it) then ids[#ids + 1] = it.id end
        end
        E.Dismantle(hero, ids)
    end
    return out
end

function E.EliteSummonInstant(hero, count)
    local items, n = {}, 0
    for _ = 1, count or 1 do
        local enc = E.EliteSummon(hero)
        if not enc then break end
        n = n + 1
        for _, it in ipairs(E.EliteLoot(hero, enc)) do items[#items + 1] = it end
    end
    return items, n
end

-- level-up flow (KR client table): pay `steps` x stepCost 장비 강화석, then meso, then wait `delay` seconds.
-- Interpretation: the step/meso/delay values of row L are the cost of L -> L+1 (rows are not labelled).
function E.EliteStep(hero)
    local info = E.EliteInfo(hero)
    if not info.canStep then return false, "강화할 단계가 없습니다." end
    if not spend(hero, "gearStone", info.stepCost, "eliteStep") then return false, "장비 강화석이 부족합니다." end
    local el = state(hero).elite
    el.step = (el.step or 0) + 1
    ns.Fire("EQUIPMENT_CHANGED", hero, "eliteStep", nil)
    return true
end

function E.EliteStartLevelUp(hero)
    local info = E.EliteInfo(hero)
    if not info.canLevelUp then return false, "레벨업 조건을 만족하지 않습니다." end
    if not spend(hero, "meso", info.meso, "eliteLevelUp") then return false, "골드가 부족합니다." end
    state(hero).elite.upgradeEndsAt = U.Now() + info.delay
    E.EliteUpdate(hero)
    return true
end

function E.EliteUpdate(hero, now)
    local el = state(hero).elite
    if el.upgradeEndsAt and (now or U.Now()) >= el.upgradeEndsAt then
        el.upgradeEndsAt = nil
        el.level = math.min(el.level + 1, ELITE.maxLevel)
        el.step = 0
        ns.Fire("ELITE_LEVEL_UP", hero, el.level)
        ns.Fire("EQUIPMENT_CHANGED", hero, "eliteLevel", nil)
        return true
    end
    return false
end

function E.EliteSkipTime(hero, tickets)
    local el = state(hero).elite
    if not el.upgradeEndsAt then return 0 end
    local left = el.upgradeEndsAt - U.Now()
    local need = math.max(0, math.ceil(left / 60))
    local use = math.min(tickets or need, need, H.Count(hero, "timeSkip1m"))
    if use > 0 and spend(hero, "timeSkip1m", use, "eliteSkip") then
        el.upgradeEndsAt = el.upgradeEndsAt - use * 60
        E.EliteUpdate(hero)
    end
    return use
end

---------------------------------------------------------------------------
-- Registration
---------------------------------------------------------------------------
H.RegisterSystem("equipment", {
    init = function(hero) state(hero) end,
})

-- item stat hooks of Systems/StarForce.lua (ns.Upgrades) when it loaded before this file
if ns.Upgrades and ns.Upgrades.BindEquipment then ns.Upgrades.BindEquipment() end

H.RegisterStatProvider("equipment", function(hero, acc)
    local s = hero.equipment
    if not s then return end
    for part, id in pairs(s.equipped) do
        local item = s.items[id]
        if item then E.ItemStats(item, acc, hero) end
    end
end)
