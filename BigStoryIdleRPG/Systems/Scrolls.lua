-- 주문서 강화 (31 equipment scrolls, 10 slots per item, 이노센트 reset) and
-- 마법 부여 (127 enchant scrolls from 마법 부여 주머니), client 1.18.0 (D.Scrolls).
--
-- Each attempt uses the next free slot (1..10) whether it succeeds or not; slot 5 adds +10%p,
-- slot 10 +20%p (final rate capped at 100%). 알쏭달쏭 = slot 1 only, 확신 = slot 10 only.
-- 이노센트 주문서 (주문의 흔적 50) clears all slots. Membership bonuses are removed (paid).
-- 데미지 증폭 is mapped to the AttackPower2 stat (the battle engine's amplification factor).
--
-- Item fields: item.scroll = {
--     slots   = { {key = scrollKey, ok = bool, stats = { [stat] = raw }}, ... },   -- used slots in order
--     enchant = { [subLine] = { id = enchantId, stat = StatType, value = raw } },   -- 마법 부여 per sub option
--   }
-- Hero fields: hero.scrolls = { enchantBag = { [enchantId] = count } }   (enchant scrolls are not wallet keys)
--
-- API  (rates per 1,000; rng defaults to ns.U.rng)
--   ns.Scrolls.Get(key) / ns.Scrolls.List()             scroll records (D.Scrolls.list)
--   ns.Scrolls.Cost(key)                                -> { walletKey = n }
--   ns.Scrolls.NextSlot(item)                           -> 1..10 or nil when full
--   ns.Scrolls.SuccessRate(key, slot, bonus)            -> per mille (bonus = extra per mille, e.g. AddScrollSuccessProb)
--   ns.Scrolls.CanUse(hero, item, key)                  -> ok, errText
--   ns.Scrolls.Use(hero, item, key, rng, bonus)         -> success(bool) | nil, errText ; fires "SCROLL_USED"
--   ns.Scrolls.Reset(hero, item)                        -> ok, errText   (이노센트 주문서)
--   ns.Scrolls.ItemStats(item)                          -> { {stat, raw}, ... } (slots + enchants)
--   ns.Scrolls.RollDungeonDrop(stage, rng)              -> scroll key | nil   (강화 던전 clear/sweep drop)
--   -- 마법 부여
--   ns.Scrolls.EnchantUnlocked(hero)                    -> bool (14-10 cleared)
--   ns.Scrolls.Enchant(id)                              -> enchant record
--   ns.Scrolls.EnchantName(id)                          -> "에픽 공격력 주문서"
--   ns.Scrolls.OpenPouch(hero, pouchKey, n, rng)        -> { enchantId, ... } | nil, errText
--   ns.Scrolls.EnchantOptions(hero, item, line)         -> { enchantId, ... } usable on that sub-option line
--   ns.Scrolls.ApplyEnchant(hero, item, line, id, rng)  -> success(bool) | nil, errText ; fires "ENCHANT_USED"
local ADDON, ns = ...
local D = ns.Data
local Hero = ns.Hero
local UP = ns.Upgrades

local S = {}
ns.Scrolls = S
local DS = D.Scrolls
local floor = math.floor

-- PROVISIONAL: meso per attempt of the level (주문의 흔적) scrolls. KR data only says "+ 메소";
-- the 85-level values are from the global "Spell Tracing Guide" (30k/40k/50k), the rest are
-- placeholders following the same 70%/30%/15% step.
S.LEVEL_SCROLL_MESO = {
    lv35_70 = 10000, lv35_30 = 15000,
    lv65_70 = 20000, lv65_30 = 25000,
    lv85_70 = 30000, lv85_30 = 40000, lv85_15 = 50000,
    lv105_70 = 40000, lv105_30 = 50000, lv105_15 = 60000,
    lv115_70 = 50000, lv115_30 = 60000, lv115_15 = 70000,
}
-- PROVISIONAL: the value inside an enchant range is rolled uniformly (distribution not published);
-- pouch scrolls are drawn uniformly among the scrolls of the rolled grade.

local byKey = {}
for _, s in ipairs(DS.list) do byKey[s.key] = s end

function S.Get(key) return byKey[key] end
function S.List() return DS.list end

function S.Cost(key)
    local s = byKey[key]
    if not s then return nil end
    if s.innocent then return { spellTrace = s.cost.spellTrace } end
    if s.item then return { [s.item] = 1 } end
    return { spellTrace = s.spellTrace, meso = S.LEVEL_SCROLL_MESO[key] or 0 }
end

local function scrollData(item)
    item.scroll = item.scroll or {}
    item.scroll.slots = item.scroll.slots or {}
    item.scroll.enchant = item.scroll.enchant or {}
    return item.scroll
end

function S.NextSlot(item)
    local n = item.scroll and item.scroll.slots and #item.scroll.slots or 0
    if n >= DS.slots then return nil end
    return n + 1
end

function S.SuccessRate(key, slot, bonus)
    local s = byKey[key]
    if not s or not s.rate then return 0 end
    local r = s.rate + (DS.slotBonus[slot] or 0) + (bonus or 0)
    if r > 1000 then r = 1000 end
    return r
end

function S.CanUse(hero, item, key)
    local s = byKey[key]
    if not s or s.innocent then return false, "알 수 없는 주문서" end
    local slot = S.NextSlot(item)
    if not slot then return false, "주문서 강화 슬롯이 모두 사용되었습니다." end
    if s.onlySlot and s.onlySlot ~= slot then
        return false, string.format("%d번 슬롯 전용 주문서입니다.", s.onlySlot)
    end
    if s.levelReq and (hero.level or 1) < s.levelReq then
        return false, string.format("캐릭터 레벨 %d 이상부터 사용할 수 있습니다.", s.levelReq)
    end
    return UP.CanPay(hero, S.Cost(key))
end

local function rollTable(tbl, rng)
    local w = {}
    for i, r in ipairs(tbl) do w[i] = r.prob end
    return tbl[rng:Weighted(w, 1000)].stats
end

function S.Use(hero, item, key, rng, bonus)
    local ok, err = S.CanUse(hero, item, key)
    if not ok then return nil, err end
    rng = UP.rng(rng)
    local s = byKey[key]
    local slot = S.NextSlot(item)
    UP.Pay(hero, S.Cost(key), "scroll")
    local success = rng:ChanceM(S.SuccessRate(key, slot, bonus))
    local stats = {}
    if success then
        local src = s.stats
        if key == "mystery" then src = rollTable(DS.mysteryRolls, rng)
        elseif key == "certainty" then src = rollTable(DS.certaintyRolls, rng) end
        for k, v in pairs(src) do stats[k] = v end
    end
    local sd = scrollData(item)
    sd.slots[slot] = { key = key, ok = success, stats = stats }
    if ns.Fire then ns.Fire("SCROLL_USED", hero, item, key, success, slot) end
    Hero.Changed(hero, "scroll")
    return success
end

function S.Reset(hero, item)
    local sd = item.scroll
    if not sd or not sd.slots or #sd.slots == 0 then return false, "초기화할 주문서 강화가 없습니다." end
    local ok, err = UP.Pay(hero, S.Cost("innocent"), "innocent")
    if not ok then return false, err end
    sd.slots = {}
    Hero.Changed(hero, "scroll")
    return true
end

function S.ItemStats(item)
    local out = {}
    local sd = item.scroll
    if not sd then return out end
    for _, sl in ipairs(sd.slots or {}) do
        if sl.ok then
            for _, k in ipairs(ns.U.Keys(sl.stats or {})) do out[#out + 1] = { k, sl.stats[k] } end
        end
    end
    for _, e in pairs(sd.enchant or {}) do
        if e.stat and e.value then out[#out + 1] = { e.stat, e.value } end
    end
    return out
end

-- 강화 던전: 10% to get a scroll, then the stage band's grade split (values are final %).
function S.RollDungeonDrop(stage, rng)
    rng = UP.rng(rng)
    for _, b in ipairs(DS.dungeonDrop.bands) do
        if stage >= b.from and stage <= b.to then
            local r = rng:Float() * 100
            for _, k in ipairs({ "normal40", "rare40", "rare25", "epic70", "epic30", "epic15" }) do
                r = r - (b.pct[k] or 0)
                if r < 0 then return k end
            end
            return nil
        end
    end
    return nil
end

-- wallet key of a scroll item (nil for spell-trace scrolls)
function S.WalletKey(key)
    local s = byKey[key]
    return s and s.item
end

---------------------------------------------------------------------------
-- 마법 부여
---------------------------------------------------------------------------
local DE = DS.enchant
local byGrade = {}
for id, e in ipairs(DE.scrolls) do
    byGrade[e.grade] = byGrade[e.grade] or {}
    table.insert(byGrade[e.grade], id)
end

function S.Enchant(id) return DE.scrolls[id] end

function S.EnchantName(id)
    local e = DE.scrolls[id]
    if not e then return "?" end
    return string.format("%s %s 주문서", DE.gradeNames[e.grade], UP.StatLabel(e.stat))
end

function S.EnchantUnlocked(hero)
    local ch, st = DE.unlockStage:match("(%d+)-(%d+)")
    return UP.StageCleared(hero, tonumber(ch), tonumber(st))
end

local function bag(hero)
    hero.scrolls = hero.scrolls or {}
    hero.scrolls.enchantBag = hero.scrolls.enchantBag or {}
    return hero.scrolls.enchantBag
end
S.Bag = bag

function S.OpenPouch(hero, pouchKey, n, rng)
    n = n or 1
    local pouch
    for _, p in ipairs(DE.pouches) do if p.key == pouchKey then pouch = p end end
    if not pouch then return nil, "알 수 없는 주머니" end
    if Hero.Count(hero, pouchKey) < n then return nil, D.CurrencyName(pouchKey) .. "이(가) 부족합니다." end
    Hero.Spend(hero, pouchKey, n, "enchantPouch")
    rng = UP.rng(rng)
    local got, b = {}, bag(hero)
    for _ = 1, n do
        local grade = DE.pouchGrades[rng:Weighted(pouch.odds, 1000)]
        local list = byGrade[grade]
        local id = list[rng:Int(1, #list)]
        b[id] = (b[id] or 0) + 1
        got[#got + 1] = id
    end
    Hero.Changed(hero, "enchant")
    return got
end

local function lineStat(item, line)
    local _, sub = UP.ItemOptions(item)
    local o = sub[line]
    if not o then return nil end
    return (UP.OptStat(o))
end

-- 장비 부옵션과 같은 능력치의 주문서만 사용 (the scroll's stat must equal the sub-option's stat)
function S.EnchantOptions(hero, item, line)
    local stat = lineStat(item, line)
    local out = {}
    if not stat then return out end
    local gi = UP.ItemGradeIndex(item) or 0
    for id, cnt in pairs(bag(hero)) do
        local e = DE.scrolls[id]
        if cnt > 0 and e and e.stat == stat and (not e.minGearGrade or gi >= e.minGearGrade) then
            out[#out + 1] = id
        end
    end
    table.sort(out)
    return out
end

function S.ApplyEnchant(hero, item, line, id, rng)
    if not S.EnchantUnlocked(hero) then return nil, "14-10 보스를 처치하면 개방됩니다." end
    local e = DE.scrolls[id]
    if not e then return nil, "알 수 없는 주문서" end
    local stat = lineStat(item, line)
    if not stat then return nil, "부가 옵션이 없는 칸입니다." end
    if stat ~= e.stat then return nil, "같은 능력치의 부가 옵션에만 사용할 수 있습니다." end
    if e.minGearGrade and (UP.ItemGradeIndex(item) or 0) < e.minGearGrade then
        return nil, "유니크 등급 이상 장비에만 사용할 수 있습니다."
    end
    local b = bag(hero)
    if (b[id] or 0) < 1 then return nil, "주문서가 없습니다." end
    local ok, err = UP.CanPay(hero, { meso = e.meso })
    if not ok then return nil, err end
    UP.Pay(hero, { meso = e.meso }, "enchant")
    b[id] = b[id] - 1
    if b[id] <= 0 then b[id] = nil end
    rng = UP.rng(rng)
    local success = rng:ChanceM(e.rate)
    if success then
        local sd = scrollData(item)
        sd.enchant[line] = { id = id, stat = e.stat, value = rng:Int(e.min, e.max) }
    end
    if ns.Fire then ns.Fire("ENCHANT_USED", hero, item, line, id, success) end
    Hero.Changed(hero, "enchant")
    return success
end

UP.RegisterItemHook("scrolls", function(item, acc, hero)
    UP.ApplyList(hero, acc, S.ItemStats(item))
end)
