-- 유물 (Artifacts): 36 artifacts, 유물상자, 각성 0..5, equip presets per content, 공명 증폭.
-- Equip skills per awakening are the client 1.18.0 skill records (D.Artifacts.skills); they are
-- registered into D.Skills at load and run by the battle VM as extra passives.
--
-- Sources: equip skills / presets = KR client 1.18.0; chest grade split 89.5/9.5/1 % (KR, mekipick
-- relic simulator); slot unlocks at total awakening 10/30/50 and 1 duplicate per awakening star
-- (KR inven guide 6554/462); 보유 효과 per awakening and 공명 증폭 costs (global wiki).
-- PROVISIONAL:
--   * legendary 보유 효과 for awakening 1..5 (only awakening 0 is published): base x (1 + 0.2 x awakening),
--     the step every published artifact uses (e.g. 양초 30% -> 36%, 혼테일의 비늘 1% -> 1.2%)
--   * 공명 증폭 stats are not published: RESONANCE_STATS per level below; the "equip effect
--     increase" of resonance is not modelled
--   * artifact potential (잠재 옵션) pools are not published: not implemented
--   * 동맹의 증표 (518) is excluded by the client runtime rules (ally-only effect): no battle effect
--   * an unset content preset falls back to the 사냥 (Campaign) preset
-- Paid 픽업 유물상자 / 레전드리 유물 소환 are not implemented.
--
-- Hero fields: hero.artifacts = { owned = { [id] = { awakening = 0..5, dupes = n } },
--                                 presets = { [presetKey] = { id, id, ... } }, resonance = level }
--
-- API  (rng defaults to ns.U.rng)
--   ns.Artifacts.Get(id) / List()                -> data { id, code, grade (3..5), name, skills, inventory }
--   ns.Artifacts.GradeName(grade)                -> "에픽" | "유니크" | "레전드리"
--   ns.Artifacts.Presets()                       -> D.Artifacts.presets ({presetType, key, label})
--   ns.Artifacts.ChestChance(id)                 -> probability per 1,000,000 of one chest
--   ns.Artifacts.OpenChest(hero, n, rng)         -> { id, ... } | nil, errText    (spends artifactChest)
--   ns.Artifacts.Grant(hero, id)                 -- first copy -> owned, later copies -> dupes
--   ns.Artifacts.CanAwaken(hero, id) / Awaken(hero, id) -> ok, errText
--   ns.Artifacts.TotalAwakening(hero)            -> sum of awakening stars
--   ns.Artifacts.SlotCount(hero)                 -> equip slots (1..4)
--   ns.Artifacts.Equipped(hero, presetKey)       -> { id, ... } (falls back to Campaign)
--   ns.Artifacts.Equip(hero, presetKey, slot, id|nil) -> ok, errText
--   ns.Artifacts.EquipSkills(hero, presetKey)    -> { skillIndex, ... }
--   ns.Artifacts.InventoryStats(hero)            -> { {stat, raw}, ... } 보유 효과 of all owned artifacts
--   ns.Artifacts.InventoryEffect(id, awakening)  -> { {stat, raw, provisional}, ... }
--   ns.Artifacts.ResonanceMax(hero) / ResonanceCost(level) / Resonate(hero, levels) -> ok, gained|errText
--   ns.Artifacts.Stats(hero)                     -> inventory + resonance stats
-- Battle integration: BuildProfile results carry skillSet.artifactSkills = { [presetKey] = {sid...} };
-- Battle:SetupSkills is wrapped to register the list of the battle's dungeonType (fallback Campaign).
local ADDON, ns = ...
local D = ns.Data
local Hero = ns.Hero
local UP = ns.Upgrades

local AR = {}
ns.Artifacts = AR
local DA = D.Artifacts

AR.GRADE_NAMES = { [3] = "에픽", [4] = "유니크", [5] = "레전드리" }
AR.DUPES_PER_AWAKENING = 1
AR.RESONANCE_STATS = { { "Attack", 10 }, { "MaxHp", 100 } }   -- PROVISIONAL per resonance level

local byId, byGrade, excluded = {}, {}, {}
for _, a in ipairs(DA.list) do
    byId[a.id] = a
    byGrade[a.grade] = byGrade[a.grade] or {}
    table.insert(byGrade[a.grade], a.id)
end
for _, id in ipairs(DA.excluded or {}) do excluded[id] = true end

-- make the equip skills runnable by the battle VM
D.Skills = D.Skills or {}
for sid, rec in pairs(DA.skills) do
    if not D.Skills[sid] then D.Skills[sid] = rec end
end
D.ExpressionMacros = D.ExpressionMacros or {}
for k, v in pairs(DA.macros or {}) do
    if not D.ExpressionMacros[k] then D.ExpressionMacros[k] = v end
end

Hero.RegisterSystem("artifacts", {
    init = function(hero)
        hero.artifacts = hero.artifacts or { owned = {}, presets = {}, resonance = 0 }
    end,
})

function AR.Get(id) return byId[id] end
function AR.List() return DA.list end
function AR.GradeName(g) return AR.GRADE_NAMES[g] or "?" end
function AR.Presets() return DA.presets end

function AR.ChestChance(id)
    local a = byId[id]
    if not a then return 0 end
    return DA.chestGradeOdds[a.grade] / #byGrade[a.grade]
end

function AR.Grant(hero, id)
    local own = hero.artifacts.owned
    if own[id] then
        own[id].dupes = (own[id].dupes or 0) + 1
    else
        own[id] = { awakening = 0, dupes = 0 }
    end
end

function AR.OpenChest(hero, n, rng)
    n = n or 1
    if Hero.Count(hero, "artifactChest") < n then return nil, D.CurrencyName("artifactChest") .. "이(가) 부족합니다." end
    Hero.Spend(hero, "artifactChest", n, "artifactChest")
    rng = UP.rng(rng)
    local grades, weights = {}, {}
    for g, w in pairs(DA.chestGradeOdds) do grades[#grades + 1] = g end
    table.sort(grades)
    for i, g in ipairs(grades) do weights[i] = DA.chestGradeOdds[g] end
    local got = {}
    for _ = 1, n do
        local list = byGrade[grades[rng:Weighted(weights, 1000000)]]
        local id = list[rng:Int(1, #list)]
        AR.Grant(hero, id)
        got[#got + 1] = id
    end
    if ns.Fire then ns.Fire("ARTIFACT_CHEST_OPENED", hero, got) end
    Hero.Changed(hero, "artifacts")
    return got
end

function AR.CanAwaken(hero, id)
    local o = hero.artifacts.owned[id]
    if not o then return false, "보유하지 않은 유물입니다." end
    if o.awakening >= DA.maxAwakening then return false, "최대 각성입니다." end
    if (o.dupes or 0) < AR.DUPES_PER_AWAKENING then return false, "같은 유물이 더 필요합니다." end
    return true
end

function AR.Awaken(hero, id)
    local ok, err = AR.CanAwaken(hero, id)
    if not ok then return false, err end
    local o = hero.artifacts.owned[id]
    o.dupes = o.dupes - AR.DUPES_PER_AWAKENING
    o.awakening = o.awakening + 1
    Hero.Changed(hero, "artifacts")
    return true
end

function AR.TotalAwakening(hero)
    local n = 0
    for _, o in pairs(hero.artifacts.owned) do n = n + (o.awakening or 0) end
    return n
end

function AR.SlotCount(hero)
    local total, n = AR.TotalAwakening(hero), 0
    for _, need in ipairs(DA.slotUnlockAwakening) do
        if total >= need then n = n + 1 end
    end
    return n
end

function AR.Equipped(hero, presetKey)
    local p = hero.artifacts.presets
    local list = p[presetKey or "Campaign"] or p.Campaign or {}
    local out, slots = {}, AR.SlotCount(hero)
    for i = 1, slots do
        local id = list[i]
        if id and hero.artifacts.owned[id] then out[#out + 1] = id end
    end
    return out
end

function AR.Equip(hero, presetKey, slot, id)
    presetKey = presetKey or "Campaign"
    if slot < 1 or slot > AR.SlotCount(hero) then return false, "잠긴 슬롯입니다." end
    if id and not hero.artifacts.owned[id] then return false, "보유하지 않은 유물입니다." end
    local p = hero.artifacts.presets
    p[presetKey] = p[presetKey] or {}
    local list = p[presetKey]
    if id then
        for i = 1, #DA.slotUnlockAwakening do
            if list[i] == id then list[i] = false end   -- one copy per preset
        end
    end
    list[slot] = id or false
    Hero.Changed(hero, "artifacts")
    return true
end

function AR.EquipSkills(hero, presetKey)
    local out = {}
    for _, id in ipairs(AR.Equipped(hero, presetKey)) do
        local a = byId[id]
        local sid = a and a.skills[hero.artifacts.owned[id].awakening or 0]
        if sid and not excluded[id] then out[#out + 1] = sid end
    end
    return out
end

function AR.InventoryEffect(id, awakening)
    local a = byId[id]
    local out = {}
    if not a then return out end
    awakening = awakening or 0
    for _, e in ipairs(a.inventory) do
        local stat, vals = e[1], e[2]
        local v, prov = vals[awakening + 1], false
        if v == nil then
            v = math.floor(vals[1] * (10 + 2 * awakening) / 10)   -- PROVISIONAL (see header)
            prov = true
        end
        out[#out + 1] = { stat, v, prov }
    end
    return out
end

function AR.InventoryStats(hero)
    local out = {}
    for id, o in pairs(hero.artifacts.owned) do
        for _, e in ipairs(AR.InventoryEffect(id, o.awakening)) do out[#out + 1] = { e[1], e[2] } end
    end
    return out
end

function AR.ResonanceMax(hero)
    return DA.resonanceBaseMax + DA.resonancePerAwakening * AR.TotalAwakening(hero)
end

function AR.ResonanceCost(level)
    return DA.resonanceCost[level]
end

function AR.Resonate(hero, levels)
    levels = levels or 1
    local gained, err = 0, nil
    for _ = 1, levels do
        local nextLv = (hero.artifacts.resonance or 0) + 1
        if nextLv > AR.ResonanceMax(hero) or not DA.resonanceCost[nextLv] then err = "공명 증폭 최대 레벨입니다."; break end
        if not Hero.Spend(hero, "artifactStone", DA.resonanceCost[nextLv], "resonance") then
            err = D.CurrencyName("artifactStone") .. "이(가) 부족합니다."
            break
        end
        hero.artifacts.resonance = nextLv
        gained = gained + 1
    end
    if gained > 0 then Hero.Changed(hero, "artifacts") end
    if gained == 0 then return false, err end
    return true, gained
end

function AR.Stats(hero)
    local out = AR.InventoryStats(hero)
    local r = hero.artifacts.resonance or 0
    if r > 0 then
        for _, s in ipairs(AR.RESONANCE_STATS) do out[#out + 1] = { s[1], s[2] * r } end
    end
    return out
end

Hero.RegisterStatProvider("artifacts", function(hero, acc)
    if not hero.artifacts then return end
    UP.ApplyList(hero, acc, AR.Stats(hero))
end)

-- profile: carry the equip skills of every preset so content fights (and PvP snapshots) pick theirs
local origBuild = Hero.BuildProfile
function Hero.BuildProfile(hero, opts)
    local p = origBuild(hero, opts)
    if p and p.skillSet and hero.artifacts then
        local map = { Campaign = AR.EquipSkills(hero, "Campaign") }
        for key in pairs(hero.artifacts.presets) do map[key] = AR.EquipSkills(hero, key) end
        p.skillSet.artifactSkills = map
    end
    return p
end

local Battle = ns.Battle
if Battle and not Battle.artifactSkillsWrapped then
    Battle.artifactSkillsWrapped = true
    local origSetup = Battle.SetupSkills
    function Battle:SetupSkills(c, def)
        origSetup(self, c, def)
        local map = def and def.skillSet and def.skillSet.artifactSkills
        if map then
            for _, sid in ipairs(map[self.dungeonType or "Campaign"] or map.Campaign or {}) do
                self:RegisterPassive(c, sid)
            end
            c:Dirty()
        end
    end
end
