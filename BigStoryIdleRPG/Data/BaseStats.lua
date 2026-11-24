-- Base character stats.
-- From the official combat-power formula's baselines (in-game guide 3.1):
--   크리티컬 데미지 300 (30%), 최소 데미지 배율 650 (65%), 최대 데미지 배율 1000 (100%), 최대 MP 500.
-- PROVISIONAL: base HP, per-level HP/MP and base main/sub stats are not published
-- (research/maple_idle_database/missing_data.md); they are placeholders.
local ADDON, ns = ...
ns.Data = ns.Data or {}
local D = ns.Data

local MAIN_KEY = { STR = "Str", DEX = "Dex", INT = "Int", LUK = "Luk" }

D.BaseStats = {
    PROVISIONAL = true,
    hpBase = 300, hpPerLevel = 60,
    mpBase = 500, mpPerLevel = 12,
    mpRegen = 8,                 -- per second
    mainBase = 20, mainPerLevel = 5,
    subBase = 4, subPerLevel = 2,
    critChance = 50,             -- 5%
    critPower = 300,             -- +30% on crit (CP formula baseline)
    minDamage = 650,             -- 65% (CP formula baseline)
    maxDamage = 1000,            -- 100% (CP formula baseline)
    hitChance = 0,
    runSpeed = 3000,             -- mm/s
}

function D.BaseStats.Apply(hero, acc, job)
    local B = D.BaseStats
    local lv = hero.level or 1
    acc:Add("MaxHp", B.hpBase + B.hpPerLevel * lv)
    acc:Add("MaxMp", B.mpBase + B.mpPerLevel * lv)
    acc:Add("MpRegen", B.mpRegen)
    if job then
        acc:Add(MAIN_KEY[job.mainStat] or "Str", B.mainBase + B.mainPerLevel * lv)
        acc:Add(MAIN_KEY[job.subStat] or "Dex", B.subBase + B.subPerLevel * lv)
    end
    acc:Add("CriticalChance", B.critChance)
    acc:Add("CriticalPower", B.critPower)
    acc:Add("MinDamageRatio", B.minDamage)
    acc:Add("MaxDamageRatio", B.maxDamage)
    acc:Add("HitChance", B.hitChance)
    acc:Add("RunSpeedMms", B.runSpeed)
end
