-- Runs a 60 s fight for every job against a boss dummy and a pack of monsters
-- to catch runtime errors in the skill VM and report damage share per skill.
package.path = "tools/test/?.lua;" .. package.path
local H = require("harness")
H.loadToc()
local ns = H.ns
local SB = ns.SkillBook
local U = ns.U

local errors = 0
ns.Debug = function(fmt, ...) errors = errors + 1; if errors < 15 then print("DEBUG", string.format(fmt, ...)) end end

local function heroStats(statAdds)
    local adds = { Attack = 50000, MaxHp = 500000, MaxMp = 20000, MpRegen = 300, Defence = 5000,
        CriticalChance = 600, CriticalPower = 1500, MinDamageRatio = 800, MaxDamageRatio = 1200,
        HitChance = 200, RunSpeedMms = 3000, Str = 3000, Dex = 3000, Int = 3000, Luk = 3000 }
    for k, v in pairs(statAdds) do adds[k] = (adds[k] or 0) + v end
    return { adds = adds, ratios = {}, chains = { AttackSpeed = { 500 } }, mults = {} }
end

for _, job in ipairs(ns.Data.Jobs) do
    local learned = SB.AllMasteriesAt(job, 140)
    local set, statAdds = SB.Build({ jobKey = job.key, level = 140, masteries = learned })
    local b = ns.Battle.New({ seed = 42, timeLimitMs = 60000 })
    local hero = b:AddCreature({ name = job.key, side = 1, isHero = true, level = 140, job = job,
        stats = heroStats(statAdds), skillSet = set, x = 0 })
    local boss = b:AddCreature({ name = "boss", side = 2, isBoss = true, level = 140, x = 1500,
        stats = { adds = { MaxHp = 1e15, Attack = 1000, Defence = 10000, AvoidChance = 50, HitChance = 50 } },
        reachMm = 600, stationary = true })
    for i = 1, 6 do
        b:AddCreature({ name = "mob", side = 2, level = 140, x = 1200 + i * 150,
            stats = { adds = { MaxHp = 1e14, Attack = 500, Defence = 5000 } } })
    end
    local casts = 0
    b.hooks.onCast = function() casts = casts + 1 end
    local ok, err = pcall(function() b:RunFor(60000) end)
    if not ok then print("ERROR", job.key, err) end
    local totalDmg = 0
    for _, v in pairs(b.stats.damage) do totalDmg = totalDmg + v end
    local top = {}
    for sid, v in pairs(b.stats.damage) do top[#top + 1] = { sid = sid, v = v } end
    table.sort(top, function(a, c) return a.v > c.v end)
    local parts = {}
    for i = 1, math.min(4, #top) do
        local s = ns.Data.Skills[top[i].sid]
        parts[#parts + 1] = string.format("%s %d%%", s and s.nameKo or tostring(top[i].sid), math.floor(top[i].v / totalDmg * 100))
    end
    print(string.format("%-12s casts %4d  dps %s  hp %.0f%%  | %s", job.key, casts, U.FormatNumber(totalDmg / 60),
        hero.hp / hero:Stat("MaxHp") * 100, table.concat(parts, ", ")))
end
print("debug errors:", errors)
