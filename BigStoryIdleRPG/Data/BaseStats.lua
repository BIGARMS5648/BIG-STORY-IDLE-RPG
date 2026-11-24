-- Base character stats.
-- PROVISIONAL: the client keeps a hidden base value for HP/MP/main stat that is not
-- in the extracted data (research/spec/combat-stages.md "hiddenBase"). These values
-- are placeholders sized against chapter monster stats and will be replaced once
-- the real table is found. Everything else (equipment, weapons, companions...)
-- comes from the growth systems.
local ADDON, ns = ...
ns.Data = ns.Data or {}
local D = ns.Data

local MAIN_KEY = { STR = "Str", DEX = "Dex", INT = "Int", LUK = "Luk" }

D.BaseStats = {
    PROVISIONAL = true,
    hpBase = 300, hpPerLevel = 60,
    mpBase = 200, mpPerLevel = 12,
    mpRegen = 8,                 -- per second
    mainBase = 20, mainPerLevel = 5,
    subBase = 4, subPerLevel = 2,
    critChance = 50,             -- 5%
    critPower = 500,             -- +50% on crit
    minDamage = 800,             -- 80%
    maxDamage = 1000,            -- 100%
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
