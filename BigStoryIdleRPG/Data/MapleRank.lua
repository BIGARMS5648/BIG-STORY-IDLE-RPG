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
    -- points per stat in a rank: rank 1 is 10 / 5 / 5 (screenshot).
    -- PROVISIONAL: ranks 2..28 have 25 points; defense stays 5 (calculator), split as main 15 / HP 5.
    caps = { [1] = { main = 10, defence = 5, hp = 5 }, default = { main = 15, defence = 5, hp = 5 } },
    -- PROVISIONAL: main stat / HP per point after rank 1 are not published; they scale like defense
    -- (rank 1 ratio main 1 : defense 3 : HP 10).
    mainPerPoint = function(rank) return math.max(1, math.floor(D.MapleRank.defencePerPoint[rank] / 3)) end,
    hpPerPoint = function(rank) return math.floor(D.MapleRank.defencePerPoint[rank] * 10 / 3) end,
    -- PROVISIONAL: special stat points granted per completed rank, cost to open / level a special stat
    specialPointsPerRank = 5,
    specialCost = 1,
    -- 특별 능력치: the complete list is these 6 (screenshot, confirmed by the user);
    -- value at level n = base + (n - 1) x step
    special = {
        { key = "AttackSpeed", label = "공격 속도", unlock = 10, max = 20, base = 30, step = 2, chain = true },
        { key = "CriticalChance", label = "크리티컬 확률", unlock = 20, max = 10, base = 50, step = 5 },
        { key = "MinDamageRatio", label = "최소 데미지 배율", unlock = 25, max = 20, base = 50, step = 3 },
        { key = "MaxDamageRatio", label = "최대 데미지 배율", unlock = 35, max = 20, base = 50, step = 3 },
        { key = "HitChance", label = "명중", unlock = 45, max = 20, base = 3, step = 1, flat = true },
        { key = "CriticalPower", label = "크리티컬 데미지", unlock = 55, max = 30, base = 50, step = 5 },
    },
}
