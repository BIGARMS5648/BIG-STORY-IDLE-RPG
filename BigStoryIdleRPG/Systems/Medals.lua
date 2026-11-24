-- 훈장 (Medals): conditions from Data/Medals.lua are checked as the hero progresses. A met condition
-- is latched (it stays achieved even if, e.g., a star force level drops later); the medal is then
-- claimed (수령) to get its 보유 효과. One medal can be worn and is shown with the hero's name.
--
-- Saved: hero.medals = { achieved = {[id]=true}, claimed = {[id]=true}, equipped = id|nil,
--                        raidTop = {[boss]=n}, raidParty = n, journeySpecial = n }
-- API
--   ns.Medals.Progress(hero, def)  -> current, need
--   ns.Medals.Check(hero)          -> number of newly achieved medals
--   ns.Medals.Claim(hero, id) / ClaimAll(hero) / Equip(hero, id|nil)
--   ns.Medals.Equipped(hero)       -> def | nil
--   ns.Medals.Totals(hero)         -> { MainStat = n (capped), AttackPowerToBoss = n, FinalDamage = {..} }
-- Events: "MEDAL_ACHIEVED"(hero, id)
local ADDON, ns = ...
local U = ns.U
local D = ns.Data
local Hero = ns.Hero

local M = {}
ns.Medals = M

local byId = {}
for _, d in ipairs(D.Medals) do byId[d.id] = d end
function M.Def(id) return byId[id] end

Hero.RegisterSystem("medals", {
    init = function(hero)
        local s = hero.medals or {}
        hero.medals = s
        s.achieved = s.achieved or {}
        s.claimed = s.claimed or {}
        s.raidTop = s.raidTop or {}
        s.raidParty = s.raidParty or 0
        s.journeySpecial = s.journeySpecial or 0
    end,
})

---------------------------------------------------------------------------
-- condition values
---------------------------------------------------------------------------
local function items(hero)
    return hero.equipment and hero.equipment.items or {}
end

local function potLines(hero, field, grade)
    local n = 0
    for _, it in pairs(items(hero)) do
        local st = it[field]
        if st and st.grade and st.grade >= grade then n = n + #(st.lines or {}) end
    end
    return n
end

local function starSlots(hero, star)
    local parts, n = {}, 0
    for _, it in pairs(items(hero)) do
        if (it.star or 0) >= star and not it.sfDestroyed and not parts[it.part] then
            parts[it.part] = true
            n = n + 1
        end
    end
    return n
end

local function companions(hero, grade)
    local s = hero.companions
    if not (s and s.owned and ns.Companions) then return 0 end
    local n = 0
    for sid in pairs(s.owned) do
        local def = ns.Companions.Def(sid)
        if def and def.grade >= grade then n = n + 1 end
    end
    return n
end

local function pqClears(hero, questId)
    local pq = hero.content and hero.content.pq
    local quests = D.ContentPartyQuests and D.ContentPartyQuests.quests
    if not (pq and pq.cleared and quests) then return 0 end
    local n = 0
    for qi, q in ipairs(quests) do
        if q.id == questId then
            for k, v in pairs(pq.cleared) do
                if k:match("^(%d+)%-") == tostring(qi) then n = n + v end
            end
        end
    end
    return n
end

local function growthAll(hero)
    local g = hero.content and hero.content.growth
    if not g then return 0 end
    local low
    for _, k in ipairs({ "weapon", "exp", "gear", "training", "enhance" }) do
        local mx = g[k] and g[k].max or 0
        low = low and math.min(low, mx) or mx
    end
    return low or 0
end

local EVAL = {
    awakening = function(hero, c) return ns.Artifacts and ns.Artifacts.TotalAwakening(hero) or 0, c[2] end,
    jobStep = function(hero, c) return hero.jobStep or 1, c[2] end,
    potLines = function(hero, c) return potLines(hero, "potential", c[2]), c[3] end,
    addLines = function(hero, c) return potLines(hero, "additional", c[2]), c[3] end,
    starSlots = function(hero, c) return starSlots(hero, c[2]), c[3] end,
    heroPower = function(hero, c) return hero.heroPower and hero.heroPower.stage or 1, c[2] end,
    elite = function(hero, c)
        local el = hero.equipment and hero.equipment.elite
        return el and el.level or 1, c[2]
    end,
    companions = function(hero, c) return companions(hero, c[2]), c[3] end,
    journeySpecial = function(hero, c) return hero.medals.journeySpecial or 0, c[2] end,
    chapterBoss = function(hero, c)
        local cp = hero.campaign
        return (cp and cp.maxChapter > c[2]) and 1 or 0, 1
    end,
    pq = function(hero, c) return pqClears(hero, c[2]), c[3] end,
    growthAll = function(hero, c) return growthAll(hero), c[2] end,
    arenaWins = function(hero, c) return hero.arena and hero.arena.wins or 0, c[2] end,
    raidTop = function(hero, c) return hero.medals.raidTop[c[2]] or 0, c[3] end,
    raidParty = function(hero, c) return hero.medals.raidParty or 0, c[2] end,
    guildRaid = function(hero, c)
        local r = hero.relocated and hero.relocated.raidMedals
        return (r and r[c[2]]) and 1 or 0, 1
    end,
}

function M.Progress(hero, def)
    local f = EVAL[def.cond[1]]
    if not f then return 0, 1 end
    local ok, cur, need = pcall(f, hero, def.cond)
    if not ok then return 0, 1 end
    return cur or 0, need or 1
end

local checking = false
function M.Check(hero)
    if checking or not (hero and hero.medals) then return 0 end
    checking = true
    local s, n = hero.medals, 0
    for _, d in ipairs(D.Medals) do
        if not s.achieved[d.id] then
            local cur, need = M.Progress(hero, d)
            if cur >= need then
                s.achieved[d.id] = true
                n = n + 1
                ns.Fire("MEDAL_ACHIEVED", hero, d.id)
                if ns.Print and hero == Hero.Active() then
                    ns.Print("훈장 획득 조건 달성: |cffffd100%s|r (메뉴 → 훈장에서 수령)", d.name)
                end
            end
        end
    end
    checking = false
    if n > 0 then Hero.Changed(hero, "medalAchieved") end
    return n
end

---------------------------------------------------------------------------
-- claim / equip
---------------------------------------------------------------------------
function M.Claim(hero, id)
    local s = hero.medals
    if not byId[id] then return false, "알 수 없는 훈장" end
    if s.claimed[id] then return false, "이미 받은 훈장입니다." end
    if not s.achieved[id] then return false, "아직 조건을 달성하지 못했습니다." end
    s.claimed[id] = true
    if not s.equipped then s.equipped = id end
    Hero.Changed(hero, "medal")
    return true
end

function M.ClaimAll(hero)
    M.Check(hero)
    local n = 0
    for _, d in ipairs(D.Medals) do
        if hero.medals.achieved[d.id] and not hero.medals.claimed[d.id] and M.Claim(hero, d.id) then n = n + 1 end
    end
    if n == 0 then return false, "받을 훈장이 없습니다." end
    return true, n
end

function M.Equip(hero, id)
    local s = hero.medals
    if id ~= nil and not s.claimed[id] then return false, "보유하지 않은 훈장입니다." end
    s.equipped = id
    Hero.Changed(hero, "medal")
    return true
end

function M.Equipped(hero)
    local s = hero and hero.medals
    return s and s.equipped and byId[s.equipped] or nil
end

function M.Totals(hero)
    local out = { MainStat = 0, AttackPowerToBoss = 0, FinalDamage = {} }
    for _, d in ipairs(D.Medals) do
        if hero.medals.claimed[d.id] then
            for k, v in pairs(d.eff) do
                if k == "FinalDamage" then table.insert(out.FinalDamage, v) else out[k] = (out[k] or 0) + v end
            end
        end
    end
    out.MainStat = math.min(out.MainStat, D.MedalMainStatCap)
    return out
end

Hero.RegisterStatProvider("medals", function(hero, acc)
    if not hero.medals then return end
    local t = M.Totals(hero)
    if t.MainStat > 0 then acc:Add("MainStat", t.MainStat) end
    if t.AttackPowerToBoss > 0 then acc:Add("AttackPowerToBoss", t.AttackPowerToBoss) end
    for _, v in ipairs(t.FinalDamage) do acc:Mult("FinalDamage", v) end
end)

---------------------------------------------------------------------------
-- progress hooks
---------------------------------------------------------------------------
ns.On("BOSS_RAID_CLEARED", function(hero, boss, diff, mode)
    if not (hero and hero.medals) then return end
    local rd = D.ContentRaids and D.ContentRaids[boss]
    if rd and rd.difficulties and diff >= #rd.difficulties then
        hero.medals.raidTop[boss] = (hero.medals.raidTop[boss] or 0) + 1
    end
    if mode ~= "single" then hero.medals.raidParty = (hero.medals.raidParty or 0) + 1 end
    M.Check(hero)
end)

ns.On("JOURNEY_SPECIAL_OPENED", function(hero)
    if not (hero and hero.medals) then return end
    hero.medals.journeySpecial = (hero.medals.journeySpecial or 0) + 1
    M.Check(hero)
end)

-- other conditions read live state; check after changes, at most once a second per hero
local lastCheck = setmetatable({}, { __mode = "k" })
ns.On("HERO_CHANGED", function(hero, what)
    if not (hero and hero.medals) or what == "medal" or what == "medalAchieved" then return end
    local now = U.Now()
    if (lastCheck[hero] or -1) == now then return end
    lastCheck[hero] = now
    M.Check(hero)
end)
for _, ev in ipairs({ "JOB_ADVANCED", "ARENA_RESULT", "PARTY_QUEST_CLEARED", "GROWTH_DUNGEON_CLEARED", "STAGE_CLEARED",
    "STARFORCE_RESULT", "POTENTIAL_ROLLED", "HERO_POWER_STAGE", "ELITE_LEVEL_UP", "COMPANION_CHANGED" }) do
    ns.On(ev, function(hero) if hero and hero.medals then M.Check(hero) end end)
end
