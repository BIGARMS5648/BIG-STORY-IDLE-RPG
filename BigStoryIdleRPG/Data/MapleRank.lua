-- 메이플 등급 (Maple Rank) and base character stats.
-- Sources:
--   in-game screenshots (KR, Lv1 character): base 공격력 50, 방어력 10, 최대 HP 300, 최대 MP 500,
--     크리티컬 확률 0%, 크리티컬 데미지 30%, 공격 속도 0%, 초당 MP 회복 5, 최소/최대 데미지 배율 65%/100%,
--     전투력 232 (matches the official CP formula exactly); rank 1: 주 스탯 +1 x10, 방어력 +3 x5,
--     최대 HP +10 x5 (20 points, 1 point each); 특별 능력치 list with unlock levels.
--   namu.wiki 메이플 키우기/시스템: 5 stat points per level-up, 25 points per rank, a rank-up grants
--     special stat points.
--   mirpg.gg calculator (comparison-calculations.js): 28 ranks, defense per point by rank (Pe), cumulative
--     defense (rt), 5 defense points per rank.
--   Check: rank 1 (20) + ranks 2..28 (25 each) = 695 points = 5 x 139 level-ups -> all ranks at Lv140.
local ADDON, ns = ...
ns.Data = ns.Data or {}
local D = ns.Data

D.BaseCharacter = {
    Attack = 50, Defence = 10, MaxHp = 300, MaxMp = 500, MpRegen = 5,
    CriticalChance = 0, CriticalPower = 300, MinDamageRatio = 650, MaxDamageRatio = 1000, AttackSpeed = 0,
    RunSpeedMms = 3000,   -- PROVISIONAL (movement speed is not shown in the stat window)
}

D.MapleRank = {
    maxRank = 28,
    pointsPerLevel = 5,
    pointsRank1 = 20,
    pointsPerRank = 25,
    -- defense per point by rank (mirpg.gg Pe)
    defencePerPoint = { 3, 6, 9, 15, 21, 30, 39, 51, 63, 78, 90, 105, 120, 135, 150, 165, 180, 195, 210, 225, 240,
        255, 270, 285, 300, 300, 300, 300 },
    -- points per stat in a rank: rank 1 is 10 / 5 / 5 = 20 (screenshot); later ranks 10 / 5 / 10 = 25
    -- (user-compiled data from the game screen + overseas community, 2026-11-24)
    caps = { [1] = { main = 10, defence = 5, hp = 5 }, default = { main = 10, defence = 5, hp = 10 } },
    -- PROVISIONAL: main stat / HP per point after rank 1 are not published; they scale like defense
    -- (rank 1 ratio main 1 : defense 3 : HP 10).
    mainPerPoint = function(rank) return math.max(1, math.floor(D.MapleRank.defencePerPoint[rank] / 3)) end,
    hpPerPoint = function(rank) return math.floor(D.MapleRank.defencePerPoint[rank] * 10 / 3) end,
    -- special stat points per completed rank: 10 early, 20 from about Lv30. Ranks complete every
    -- 5 levels, so ranks 1-6 give 10 and later ranks 20 (PROVISIONAL boundary: "about Lv30").
    specialPointsPerRank = function(rank) return rank <= 6 and 10 or 20 end,
    -- PROVISIONAL: special stat costs are not published. Opening costs 1; upgrade n (0-based) costs
    -- 1 + floor(n / 5) (all 6 known stats maxed ~320 points vs ~480 earned by Lv140).
    specialOpenCost = 1,
    specialUpgradeCost = function(n) return 1 + math.floor(n / 5) end,
    -- 특별 능력치: opening gives `base`; each of the `max` upgrades adds `step` (raw 0.1% units).
    -- Screen values: 공격 속도 3% -> 3.2% (+0.2%, 20 upgrades), 크리티컬 확률 5% -> 5.5% (+0.5%, 10),
    -- 최소 / 최대 데미지 배율 5% -> 5.3% (+0.3%, 20), 명중 3 -> 4 (+1, 20), 크리티컬 데미지 5% -> 5.5% (+0.5%, 30).
    -- 데미지 opens at Lv85 (overseas community); its values are PROVISIONAL.
    special = {
        { key = "AttackSpeed", label = "공격 속도", unlock = 10, max = 20, base = 30, step = 2 },
        { key = "CriticalChance", label = "크리티컬 확률", unlock = 20, max = 10, base = 50, step = 5 },
        { key = "MinDamageRatio", label = "최소 데미지 배율", unlock = 25, max = 20, base = 50, step = 3 },
        { key = "MaxDamageRatio", label = "최대 데미지 배율", unlock = 35, max = 20, base = 50, step = 3 },
        { key = "HitChance", label = "명중", unlock = 45, max = 20, base = 3, step = 1, flat = true },
        { key = "CriticalPower", label = "크리티컬 데미지", unlock = 55, max = 30, base = 50, step = 5 },
        { key = "AttackPower", label = "데미지", unlock = 85, max = 20, base = 50, step = 5, provisional = true },
    },
}
