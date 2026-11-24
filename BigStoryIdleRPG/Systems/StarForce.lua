-- 스타포스 강화 (Star Force 0 -> 30), client 1.18.0 numbers from Data/Upgrades.lua (D.StarForce).
-- Also defines ns.Upgrades: helpers shared by every upgrade system (StarForce, Potential,
-- Scrolls, HeroPower, Ability, Artifacts, Journey). Load this file first of them.
--
-- Item fields (gear item tables owned by Systems/Equipment.lua):
--   item.star         current star 0..30
--   item.sfPoints     { [star] = enhance points }   point pity of the attempted star
--   item.sfDowns      consecutive downs (찬스타임 after 2)
--   item.sfDestroyed  star the item had when it was destroyed (nil = intact)
--
-- API  (probabilities per 1,000,000; rng defaults to ns.U.rng)
--   ns.StarForce.Row(star)                       -> data row of the attempt star -> star+1
--   ns.StarForce.Amp(star)                       -> { main = ‰, sub = ‰, fd = FinalDamage raw or nil }
--   ns.StarForce.Chances(item, opts)             -> { success, fail, down, destroy }, guaranteed, reason
--        opts = { preventDown = bool (하락 방지), preventDestroy = bool (파괴 완화) }
--        reason = "chance" (찬스타임) | "points" (포인트 확정) | nil
--   ns.StarForce.Cost(item, opts)                -> { starforceScroll = n, meso = n }
--   ns.StarForce.CanEnhance(hero, item, opts)    -> ok, errText
--   ns.StarForce.Enhance(hero, item, opts, rng)  -> result | nil, errText
--        result = "success" | "fail" | "down" | "destroy"; fires "STARFORCE_RESULT"(hero, item, result, fromStar)
--   ns.StarForce.Points(item) / MaxPoints(item)  -> current / required pity points of the current star
--   ns.StarForce.IsDestroyed(item)
--   ns.StarForce.RestoreTargets(item)            -> { star, ... } a destroyed item can be restored to
--   ns.StarForce.RestoreCost(toStar)             -> { redDia, meso, starforceScroll }
--   ns.StarForce.Restore(hero, item, toStar)     -> ok, errText
--   ns.StarForce.ItemStats(item, hero)           -> { {stat, raw}, ... }  pure: amplification of the item's
--        main options (amp.main) and sub/fixed options (amp.sub) + FinalDamage from 20★
--   ns.StarForce.PotentialUnlocked(item) / AdditionalUnlocked(item)   3★ / 12★ gates for cubes
--
-- ns.Upgrades (shared)
--   ApplyStat(hero, acc, stat, raw)    add one stat to a Hero accumulator; understands XxxR ratio
--        names (StrR, MaxHpR, DefenceR...), MainStat/MainStatR (routed to the job's main stat) and
--        MainStatPerLevelN / MainStatRPerLevelN
--   ApplyList(hero, acc, list)         list of {stat, raw}
--   StatLabel(stat), FormatStat(stat, raw)       Korean display ("공격력 +100", "데미지 +3%")
--   CanPay(hero, costs) / Pay(hero, costs, reason) / FormatCost(costs)   costs = { walletKey = n }
--   ItemOptions(item) -> mainList, subList       base options of a gear item (see below)
--   OptStat(option)   -> stat, raw
--   ItemPart(item), ItemGradeIndex(item)
--   RegisterItemHook(name, fn(item, acc, hero))  per-item stats; bound to
--        ns.Equipment.RegisterItemStatHook when it exists, otherwise applied to hero.equipment
--   ChapterBossCleared(hero, chapter), StageCleared(hero, ch, st)
--
-- Base options of an item: ns.Equipment.ItemBaseOptions(item) (or .BaseOptions) returning
-- mainList, subList (or {main=, sub=}); otherwise item.main / item.sub. Each option is
-- {type=StatType, value=raw} ({stat=, value=} and {StatType, raw} also work). Star force
-- amplification is NOT expected to be included in those values (this file adds it).
local ADDON, ns = ...
local U = ns.U
local D = ns.Data
local Hero = ns.Hero

---------------------------------------------------------------------------
-- ns.Upgrades: shared helpers
---------------------------------------------------------------------------
local UP = ns.Upgrades or {}
ns.Upgrades = UP

local floor = math.floor
local MAIN_KEY = { STR = "Str", DEX = "Dex", INT = "Int", LUK = "Luk" }
local RATIO_BASE = {
    StrR = "Str", DexR = "Dex", IntR = "Int", LukR = "Luk",
    MaxHpR = "MaxHp", MaxMpR = "MaxMp", DefenceR = "Defence", AttackR = "Attack",
}
local PER_LEVEL = { MainStatPerLevel1 = 1, MainStatPerLevel5 = 5, MainStatPerLevel10 = 10 }
local PER_LEVEL_R = {
    MainStatRPerLevel1 = 1, MainStatRPerLevel2 = 2, MainStatRPerLevel3 = 3,
    MainStatRPerLevel4 = 4, MainStatRPerLevel5 = 5, MainStatRPerLevel10 = 10,
}

function UP.rng(rng) return rng or U.rng end

function UP.MainStatKey(hero)
    if not hero or not hero.jobKey or not (ns.SkillBook and ns.SkillBook.JobByKey) then return nil end
    local ok, job = pcall(ns.SkillBook.JobByKey, hero.jobKey)
    return ok and job and MAIN_KEY[job.mainStat] or nil
end

-- Client rule: main stat display = trunc((base + flat main stat) * (1 + main stat %)), so flat
-- MainStat goes to the job's main stat (scaled by its % layer) and MainStatR to that % layer.
function UP.ApplyStat(hero, acc, stat, v)
    if not stat or not v or v == 0 then return end
    local base = RATIO_BASE[stat]
    if base then return acc:Ratio(base, v) end
    if stat == "MainStat" then return acc:Add(UP.MainStatKey(hero) or "MainStat", v) end
    if stat == "MainStatR" then
        local k = UP.MainStatKey(hero)
        if k then acc:Ratio(k, v) end
        return
    end
    local n = PER_LEVEL[stat]
    if n then return acc:Add(UP.MainStatKey(hero) or "MainStat", v * floor(((hero and hero.level) or 1) / n)) end
    n = PER_LEVEL_R[stat]
    if n then
        local k = UP.MainStatKey(hero)
        if k then acc:Ratio(k, v * floor(((hero and hero.level) or 1) / n)) end
        return
    end
    return acc:Add(stat, v)
end

function UP.ApplyList(hero, acc, list)
    for i = 1, #list do UP.ApplyStat(hero, acc, list[i][1], list[i][2]) end
end

function UP.StatLabel(stat)
    return (D.StatLabelsKo and D.StatLabelsKo[stat]) or stat
end

local function trimNum(x)
    local s = string.format("%.2f", x):gsub("0+$", ""):gsub("%.$", "")
    return s
end

function UP.FormatStat(stat, v)
    local disp = D.StatDisplay and D.StatDisplay[stat]
    local label = UP.StatLabel(stat)
    local sign = (v or 0) < 0 and "-" or "+"
    v = math.abs(v or 0)
    if disp == "Percent" or disp == "PercentP" then
        return string.format("%s %s%s%%", label, sign, trimNum(v / 10))
    elseif disp == "Duration" then
        return string.format("%s %s%s초", label, sign, trimNum(v / 1000))
    end
    return string.format("%s %s%s", label, sign, U.Comma(v))
end

function UP.CanPay(hero, costs)
    for k, n in pairs(costs or {}) do
        if n > 0 and Hero.Count(hero, k) < n then
            return false, (D.CurrencyName and D.CurrencyName(k) or k) .. "이(가) 부족합니다."
        end
    end
    return true
end

function UP.Pay(hero, costs, reason)
    local ok, err = UP.CanPay(hero, costs)
    if not ok then return false, err end
    for k, n in pairs(costs or {}) do
        if n > 0 then Hero.Spend(hero, k, n, reason) end
    end
    return true
end

function UP.FormatCost(costs)
    local parts = {}
    for _, k in ipairs(U.Keys(costs or {})) do
        if costs[k] > 0 then parts[#parts + 1] = string.format("%s %s", D.CurrencyName(k), U.Comma(costs[k])) end
    end
    return table.concat(parts, ", ")
end

function UP.OptStat(o)
    if type(o) ~= "table" then return nil end
    return o.type or o.stat or o[1], o.value or o.v or o[2]
end

-- Equipment items (item.code) keep roll steps in item.main, so their options come from
-- ns.Equipment.ItemBaseOptions; plain tables may carry option lists in item.main / item.sub.
local function optionList(t)
    if type(t) == "table" and type(t[1]) == "table" then return t end
    return {}
end

function UP.ItemOptions(item)
    local E = ns.Equipment
    local fn = E and (E.ItemBaseOptions or E.BaseOptions)
    if item.code and type(fn) == "function" then
        local ok, a, b = pcall(fn, item)
        if ok and type(a) == "table" then
            if a.main or a.sub then return a.main or {}, a.sub or {} end
            return a, b or {}
        end
    end
    return optionList(item.mainOptions or item.main), optionList(item.subOptions or item.sub)
end

function UP.ItemPart(item)
    return item and (item.part or item.slot or item.partKey)
end

-- gear grade "Grade1".."Grade6_1" -> ladder index 1..8 (nil if unknown)
function UP.ItemGradeIndex(item)
    local g = item and item.grade
    if type(g) == "number" then return g end
    for i, k in ipairs(D.GearGradeLadder or {}) do
        if k == g then return i end
    end
end

function UP.StageCleared(hero, ch, st)
    local cp = hero and hero.campaign
    if not cp then return false end
    if cp.cleared and cp.cleared[ch .. "-" .. st] then return true end
    return (cp.maxChapter or 0) > ch
end

function UP.ChapterBossCleared(hero, ch)
    local c = D.Chapters and D.Chapters[ch]
    local bossStage = c and #c.stages or 10
    if c then
        for i, s in ipairs(c.stages) do
            if s.boss then bossStage = s.stage or i end
        end
    end
    return UP.StageCleared(hero, ch, bossStage)
end

-- per-item stat hooks ------------------------------------------------------
UP.itemHooks = UP.itemHooks or {}
UP.itemHookOrder = UP.itemHookOrder or {}

local function resolveHero(acc, hero)
    return hero or (acc and acc.hero) or (Hero.Active and Hero.Active()) or nil
end

local function dispatch(item, acc, hero)
    if type(item) ~= "table" then return end
    hero = resolveHero(acc, hero)
    for _, name in ipairs(UP.itemHookOrder) do
        local ok, err = pcall(UP.itemHooks[name], item, acc, hero)
        if not ok and ns.Debug then ns.Debug("item hook %s: %s", name, tostring(err)) end
    end
end
UP.DispatchItem = dispatch

function UP.BindEquipment()
    if UP.boundEquipment then return true end
    local E = ns.Equipment
    if E and type(E.RegisterItemStatHook) == "function" then
        E.RegisterItemStatHook(dispatch)
        UP.boundEquipment = true
        return true
    end
    return false
end

function UP.RegisterItemHook(name, fn)
    if not UP.itemHooks[name] then table.insert(UP.itemHookOrder, name) end
    UP.itemHooks[name] = fn
    UP.BindEquipment()
end

-- Fallback when there is no Equipment item-hook API: apply the hooks to hero.equipment.
Hero.RegisterStatProvider("upgradeItems", function(hero, acc)
    acc.hero = acc.hero or hero
    if UP.BindEquipment() then return end
    if ns.Equipment and type(ns.Equipment.EquippedItems) == "function" then
        for _, item in pairs(ns.Equipment.EquippedItems(hero) or {}) do dispatch(item, acc, hero) end
        return
    end
    for _, item in pairs(hero.equipment or {}) do
        if type(item) == "table" then dispatch(item, acc, hero) end
    end
end)
if ns.On then
    ns.On("LOGIN", function() UP.BindEquipment() end)
    ns.On("HERO_ACTIVATED", function() UP.BindEquipment() end)
end

---------------------------------------------------------------------------
-- Star Force
---------------------------------------------------------------------------
local SF = {}
ns.StarForce = SF
local DS = D.StarForce
local R = DS.rules
local SCALE = DS.scale

-- Cube gates per slot star (global wiki "Star Force Enhancement": potential at stage 3,
-- bonus potential at stage 12; the KR extraction has no gate table).
SF.POTENTIAL_STAR = 3
SF.ADDITIONAL_STAR = 12
-- PROVISIONAL: restoration can return the item at most to the star it was destroyed at
-- (and the table ends at 20★); a destroyed item gives no star force bonus until restored.

function SF.Row(star) return DS.rows[star or 0] end
function SF.Amp(star) return DS.amp[star or 0] or DS.amp[0] end
function SF.IsDestroyed(item) return item.sfDestroyed ~= nil end
function SF.PotentialUnlocked(item) return (item.star or 0) >= SF.POTENTIAL_STAR end
function SF.AdditionalUnlocked(item) return (item.star or 0) >= SF.ADDITIONAL_STAR end

function SF.Points(item)
    local star = item.star or 0
    return (item.sfPoints and item.sfPoints[star]) or 0
end

function SF.MaxPoints(item)
    local row = SF.Row(item.star)
    return row and row.maxPoint or 0
end

function SF.Chances(item, opts)
    opts = opts or {}
    local row = SF.Row(item.star)
    if not row then return nil end
    if (item.sfDowns or 0) >= R.chanceTimeDownCount then
        return { success = SCALE, fail = 0, down = 0, destroy = 0 }, true, "chance"
    end
    if row.maxPoint > 0 and SF.Points(item) >= row.maxPoint then
        return { success = SCALE, fail = 0, down = 0, destroy = 0 }, true, "points"
    end
    local s, f, dn, ds = row.success, row.fail, row.down, row.destroy
    -- 하락 방지: the removed down chance moves to fail (유지)
    if opts.preventDown and row.pdScroll > 0 then
        f = f + (dn - row.preventDown)
        dn = row.preventDown
    end
    -- 파괴 완화: destroy chance becomes preventDestroy (half); the removed part is kept as fail.
    if opts.preventDestroy and row.pxScroll > 0 then
        f = f + (ds - row.preventDestroy)
        ds = row.preventDestroy
    end
    return { success = s, fail = f, down = dn, destroy = ds }, false
end

function SF.Cost(item, opts)
    opts = opts or {}
    local row = SF.Row(item.star)
    if not row then return nil end
    local c = { starforceScroll = row.scroll, meso = row.meso }
    local _, guaranteed = SF.Chances(item, opts)
    if not guaranteed then  -- 찬스타임·포인트 확정 시도는 보호 비용 없이 기본 비용만
        if opts.preventDown and row.pdScroll > 0 then
            c.starforceScroll = c.starforceScroll + row.pdScroll
            c.meso = c.meso + row.pdMeso
        end
        if opts.preventDestroy and row.pxScroll > 0 then
            c.starforceScroll = c.starforceScroll + row.pxScroll
            c.meso = c.meso + row.pxMeso
        end
    end
    return c
end

function SF.CanEnhance(hero, item, opts)
    if SF.IsDestroyed(item) then return false, "파괴된 장비입니다. 먼저 복구하세요." end
    if (item.star or 0) >= DS.maxStar then return false, "최대 별빛 강화입니다." end
    return UP.CanPay(hero, SF.Cost(item, opts))
end

function SF.Enhance(hero, item, opts, rng)
    local ok, err = SF.CanEnhance(hero, item, opts)
    if not ok then return nil, err end
    local ch, guaranteed = SF.Chances(item, opts)
    UP.Pay(hero, SF.Cost(item, opts), "starforce")
    rng = UP.rng(rng)
    local from = item.star or 0
    local result = "success"
    if not guaranteed then
        local idx = rng:Weighted({ ch.success, ch.fail, ch.down, ch.destroy }, SCALE)
        result = ({ "success", "fail", "down", "destroy" })[idx]
    end
    item.sfPoints = item.sfPoints or {}
    if result == "success" then
        item.star = from + 1
        item.sfPoints[from] = nil          -- success resets the attempted star's points
        item.sfDowns = 0
    elseif result == "fail" then
        item.sfPoints[from] = (item.sfPoints[from] or 0) + R.failPoint
        item.sfDowns = 0
    elseif result == "down" then
        item.sfPoints[from] = (item.sfPoints[from] or 0) + R.downPoint
        item.star = from - 1
        item.sfDowns = (item.sfDowns or 0) + 1
    else
        item.sfPoints[from] = (item.sfPoints[from] or 0) + R.destroyPoint
        item.sfDowns = 0
        item.sfDestroyed = from
        item.star = R.destroyResultStar
    end
    if ns.Fire then ns.Fire("STARFORCE_RESULT", hero, item, result, from) end
    Hero.Changed(hero, "starforce")
    return result
end

function SF.RestoreCost(toStar)
    local r = DS.restore[toStar]
    if not r then return nil end
    return { redDia = r.redDia, meso = r.meso, starforceScroll = r.scroll }
end

function SF.RestoreTargets(item)
    local out = {}
    if not item.sfDestroyed then return out end
    for s = R.destroyResultStar, math.min(item.sfDestroyed, 20) do
        if DS.restore[s] then out[#out + 1] = s end
    end
    return out
end

function SF.Restore(hero, item, toStar)
    if not item.sfDestroyed then return false, "파괴된 장비가 아닙니다." end
    toStar = toStar or R.destroyResultStar
    if toStar < R.destroyResultStar or toStar > item.sfDestroyed or not DS.restore[toStar] then
        return false, "복구할 수 없는 단계입니다."
    end
    local ok, err = UP.Pay(hero, SF.RestoreCost(toStar), "starforceRestore")
    if not ok then return false, err end
    item.star = toStar
    item.sfDestroyed = nil
    item.sfDowns = 0
    Hero.Changed(hero, "starforce")
    return true
end

function SF.ItemStats(item)
    local out = {}
    local star = item.star or 0
    if star <= 0 or SF.IsDestroyed(item) then return out end
    local amp = SF.Amp(star)
    local main, sub = UP.ItemOptions(item)
    for _, o in ipairs(main) do
        local st, v = UP.OptStat(o)
        if st and v and amp.main > 0 then
            local b = floor(v * amp.main / 1000)
            if b ~= 0 then out[#out + 1] = { st, b } end
        end
    end
    for _, o in ipairs(sub) do
        local st, v = UP.OptStat(o)
        if st and v and amp.sub > 0 then
            local b = floor(v * amp.sub / 1000)
            if b ~= 0 then out[#out + 1] = { st, b } end
        end
    end
    if amp.fd then out[#out + 1] = { "FinalDamage", amp.fd } end
    return out
end

UP.RegisterItemHook("starforce", function(item, acc, hero)
    UP.ApplyList(hero, acc, SF.ItemStats(item, hero))
end)
