-- 메이플 등급: stat points from level-ups (5 each) are spent on 주 스탯 / 방어력 / 최대 HP of the
-- current rank; a filled rank advances to the next and grants special stat points for 특별 능력치.
--
-- API
--   ns.MapleRank.State(hero)  -> { rank, spent = {main, defence, hp}, pointsFree, need, done, specialFree }
--   ns.MapleRank.Upgrade(hero, stat, n)   stat = "main" | "defence" | "hp"  -> ok, err
--   ns.MapleRank.AutoUpgrade(hero)         spends every free point
--   ns.MapleRank.UpgradeSpecial(hero, index) -> ok, err ("능력치 개방" / 강화)
--   ns.MapleRank.SpecialValue(def, level)
local ADDON, ns = ...
local D = ns.Data
local Hero = ns.Hero

local M = {}
ns.MapleRank = M
local R = D.MapleRank

Hero.RegisterSystem("mapleRank", {
    init = function(hero)
        hero.mapleRank = hero.mapleRank or { rank = 1, spent = { main = 0, defence = 0, hp = 0 }, done = 0,
            special = {}, specialSpent = 0 }
        -- completed ranks' totals are recomputed from the rank number; nothing else to store
    end,
})

local function caps(rank) return R.caps[rank] or R.caps.default end
function M.Caps(rank) return caps(rank) end

function M.RankPoints(rank)
    local c = caps(rank)
    return c.main + c.defence + c.hp
end

-- points earned so far: 5 per level-up
function M.PointsEarned(hero)
    return R.pointsPerLevel * math.max(0, (hero.level or 1) - 1)
end

function M.PointsSpent(hero)
    local s = hero.mapleRank
    local total = 0
    for r = 1, s.rank - 1 do total = total + M.RankPoints(r) end
    return total + s.spent.main + s.spent.defence + s.spent.hp
end

function M.State(hero)
    local s = hero.mapleRank
    local need = M.RankPoints(s.rank)
    local inRank = s.spent.main + s.spent.defence + s.spent.hp
    return {
        rank = s.rank, spent = s.spent, caps = caps(s.rank), inRank = inRank, need = need,
        pointsFree = math.max(0, M.PointsEarned(hero) - M.PointsSpent(hero)),
        specialFree = math.max(0, (s.rank - 1) * R.specialPointsPerRank - (s.specialSpent or 0)),
        maxed = s.rank >= R.maxRank and inRank >= need,
    }
end

local function advance(hero)
    local s = hero.mapleRank
    if s.rank < R.maxRank and s.spent.main + s.spent.defence + s.spent.hp >= M.RankPoints(s.rank) then
        s.rank = s.rank + 1
        s.spent = { main = 0, defence = 0, hp = 0 }
        ns.Fire("MAPLE_RANK_UP", hero, s.rank)
        return true
    end
end

function M.Upgrade(hero, stat, n)
    n = n or 1
    local s = hero.mapleRank
    local c = caps(s.rank)
    if not c[stat] then return false, "알 수 없는 능력치" end
    local done = 0
    for _ = 1, n do
        local st = M.State(hero)
        if st.pointsFree < 1 then break end
        if s.spent[stat] >= caps(s.rank)[stat] then break end
        s.spent[stat] = s.spent[stat] + 1
        done = done + 1
        advance(hero)
    end
    if done == 0 then
        if M.State(hero).pointsFree < 1 then return false, "능력치 포인트가 부족합니다." end
        return false, "최대 레벨입니다."
    end
    Hero.Changed(hero, "mapleRank")
    return true, done
end

function M.AutoUpgrade(hero)
    local total = 0
    while true do
        local st = M.State(hero)
        if st.pointsFree < 1 or st.maxed then break end
        local progressed = false
        for _, stat in ipairs({ "main", "defence", "hp" }) do
            local ok, n = M.Upgrade(hero, stat, 1)
            if ok then total = total + n; progressed = true; break end
        end
        if not progressed then break end
    end
    return total
end

function M.SpecialValue(def, level)
    if not level or level < 1 then return 0 end
    return def.base + (level - 1) * def.step
end

function M.UpgradeSpecial(hero, idx)
    local def = R.special[idx]
    if not def then return false end
    local s = hero.mapleRank
    if hero.level < def.unlock then return false, string.format("%d 레벨 달성 필요", def.unlock) end
    local lv = s.special[idx] or 0
    if lv >= def.max then return false, "최대 레벨입니다." end
    if M.State(hero).specialFree < R.specialCost then return false, "특별 능력치 포인트가 부족합니다." end
    s.special[idx] = lv + 1
    s.specialSpent = (s.specialSpent or 0) + R.specialCost
    Hero.Changed(hero, "mapleRank")
    return true
end

local MAIN_KEY = { STR = "Str", DEX = "Dex", INT = "Int", LUK = "Luk" }

Hero.RegisterStatProvider("mapleRank", function(hero, acc)
    local s = hero.mapleRank
    if not s then return end
    local job = Hero.Job(hero)
    local main, def, hp = 0, 0, 0
    for r = 1, s.rank do
        local c = caps(r)
        local pm, pd, ph
        if r < s.rank then pm, pd, ph = c.main, c.defence, c.hp
        else pm, pd, ph = s.spent.main, s.spent.defence, s.spent.hp end
        main = main + pm * R.mainPerPoint(r)
        def = def + pd * R.defencePerPoint[r]
        hp = hp + ph * R.hpPerPoint(r)
    end
    if job then acc:Add(MAIN_KEY[job.mainStat] or "Str", main) end
    acc:Add("Defence", def)
    acc:Add("MaxHp", hp)
    for i, d in ipairs(R.special) do
        local v = M.SpecialValue(d, s.special[i])
        if v > 0 then acc:Add(d.key, v) end
    end
end)
