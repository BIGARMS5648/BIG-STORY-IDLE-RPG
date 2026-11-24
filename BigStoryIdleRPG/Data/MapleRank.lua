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
    -- per point by rank. Screens: rank 1 main +1 / defense +3 / HP +10; rank 15 main +50 / defense +150 /
    -- HP +2,500. Main stat = defense / 3 holds at both ranks.
    mainPerPoint = function(rank) return math.max(1, math.floor(D.MapleRank.defencePerPoint[rank] / 3)) end,
    -- PROVISIONAL between the two known ranks: power law through (main 1 -> HP 10) and (main 50 -> HP 2,500)
    hpPerPoint = function(rank)
        if rank == 1 then return 10 end
        if rank == 15 then return 2500 end
        local m = D.MapleRank.mainPerPoint(rank)
        return math.floor(10 * m ^ (math.log(250) / math.log(50)) + 0.5)
    end,
    -- special stat points per completed rank: 10 early, 20 from about Lv30. Ranks complete every
    -- 5 levels, so ranks 1-6 give 10 and later ranks 20 (PROVISIONAL boundary: "about Lv30").
    specialPointsPerRank = function(rank) return rank <= 6 and 10 or 20 end,
    -- costs: an upgrade costs 1 special point (screen: "★1 강화"); opening is assumed to cost 1 as well
    specialOpenCost = 1,
    specialUpgradeCost = function(n) return 1 end,
    -- 특별 능력치 (11, screens at Lv1 and rank 15): opening gives `base`, each of `max` upgrades adds
    -- `step` (raw 0.1% units). Maxed values on the rank-15 screen confirm the model:
    -- 공격 속도 7%, 크리티컬 확률 10%, 최소/최대 데미지 배율 11%, 명중 23, 크리티컬 데미지 20%,
    -- 일반 몬스터 데미지 20% (30/30), 보스 몬스터 데미지 10% at 10/30.
    special = {
        { key = "AttackSpeed", label = "공격 속도", unlock = 10, max = 20, base = 30, step = 2 },
        { key = "CriticalChance", label = "크리티컬 확률", unlock = 20, max = 10, base = 50, step = 5 },
        { key = "MinDamageRatio", label = "최소 데미지 배율", unlock = 25, max = 20, base = 50, step = 3 },
        { key = "MaxDamageRatio", label = "최대 데미지 배율", unlock = 35, max = 20, base = 50, step = 3 },
        { key = "HitChance", label = "명중", unlock = 45, max = 20, base = 3, step = 1, flat = true },
        { key = "CriticalPower", label = "크리티컬 데미지", unlock = 55, max = 30, base = 50, step = 5 },
        -- PROVISIONAL unlock levels 60 / 65 (between 55 and 75; already opened on the screen)
        { key = "AttackPowerExcludeBoss", label = "일반 몬스터 데미지", unlock = 60, max = 30, base = 50, step = 5 },
        { key = "AttackPowerToBoss", label = "보스 몬스터 데미지", unlock = 65, max = 30, base = 50, step = 5 },
        { key = "SkillPower", label = "스킬 데미지", unlock = 75, max = 30, base = 100, step = 5 },
        { key = "AttackPower", label = "데미지", unlock = 85, max = 50, base = 100, step = 5 },
        { key = "MainStat", label = "주 스탯", unlock = 100, max = 160, base = 300, step = 5, flat = true },
    },
}
