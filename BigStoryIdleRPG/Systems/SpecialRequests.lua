-- 특별 의뢰 (Data/SpecialRequests.lua): one-time requests that open at a gate, count their goal from
-- that moment (or read a state goal) and are claimed once.
--
-- Saved: hero.requests = { opened = {[id]=true}, count = {[id]=n}, done = {[id]=true}, visited = {[panel]=true} }
-- API
--   ns.Requests.List(hero)          -> { {def, open, progress, need, complete, claimed}, ... }
--   ns.Requests.Claim(hero, id)     -> ok, err, rewardLines
local ADDON, ns = ...
local D = ns.Data
local Hero = ns.Hero

local R = {}
ns.Requests = R

local byId = {}
for _, d in ipairs(D.SpecialRequests) do byId[d.id] = d end

local function st(hero)
    local s = hero.requests
    if not s then
        s = {}
        hero.requests = s
    end
    s.opened = s.opened or {}
    s.count = s.count or {}
    s.done = s.done or {}
    s.visited = s.visited or {}
    return s
end

Hero.RegisterSystem("requests", { init = function(hero) st(hero) end })

local function gateOpen(hero, g)
    if not g then return true end
    if g.level and (hero.level or 1) < g.level then return false end
    if g.ch and not (ns.Content and ns.Content.StageReached(hero, g.ch, g.st or 1)) then return false end
    return true
end

local function progress(hero, d)
    local s, goal = st(hero), d.goal
    local kind = goal[1]
    if kind == "count" then return s.count[d.id] or 0, goal[3] end
    if kind == "level" then return hero.level or 1, goal[2] end
    if kind == "chapterBoss" then
        local cp = hero.campaign
        return (cp and cp.maxChapter > goal[2]) and 1 or 0, 1
    end
    if kind == "worldBoss" then
        local wb = hero.content and hero.content.worldBoss
        return math.min(wb and wb.max or 0, goal[2]), goal[2]
    end
    if kind == "summonLevel" then
        local info = ns.Summon and ns.Summon.Info(hero, goal[2])
        return info and info.level or 1, goal[3]
    end
    if kind == "visit" then return s.visited[goal[2]] and 1 or 0, 1 end
    return 0, 1
end

-- opens every request whose gate is met (counting starts here)
function R.Refresh(hero)
    local s = st(hero)
    for _, d in ipairs(D.SpecialRequests) do
        if not s.opened[d.id] and gateOpen(hero, d.gate) then
            s.opened[d.id] = true
            s.count[d.id] = 0
        end
    end
end

function R.List(hero)
    R.Refresh(hero)
    local s, out = st(hero), {}
    for _, d in ipairs(D.SpecialRequests) do
        local cur, need = progress(hero, d)
        out[#out + 1] = { def = d, open = s.opened[d.id] or false, progress = math.min(cur, need), need = need,
            complete = s.opened[d.id] and cur >= need, claimed = s.done[d.id] or false }
    end
    return out
end

function R.Claim(hero, id)
    local d = byId[id]
    if not d then return false, "알 수 없는 의뢰" end
    local s = st(hero)
    R.Refresh(hero)
    if s.done[id] then return false, "이미 완료한 의뢰입니다." end
    if not s.opened[id] then return false, "아직 열리지 않은 의뢰입니다." end
    local cur, need = progress(hero, d)
    if cur < need then return false, "아직 조건을 달성하지 못했습니다." end
    s.done[id] = true
    local lines = ns.Content.Grant(hero, d.rewards, "specialRequest")
    if d.gear and ns.Equipment then
        local item = ns.Equipment.CreateItem(hero, d.gear.code, d.gear.level)
        if item and ns.Equipment.AddItem(hero, item) then lines[#lines + 1] = ns.Equipment.ItemName(item) end
    end
    Hero.Changed(hero, "requests")
    return true, nil, lines
end

-- counters: only requests that are open and not done count
local function add(hero, key, n)
    if not (hero and hero.requests) then return end
    local s = hero.requests
    for _, d in ipairs(D.SpecialRequests) do
        if d.goal[1] == "count" and d.goal[2] == key and s.opened[d.id] and not s.done[d.id] then
            s.count[d.id] = (s.count[d.id] or 0) + (n or 1)
        end
    end
end
R.Add = add

ns.On("MONSTER_KILLED", function(hero) add(hero, "kill", 1) end)
ns.On("OFFLINE_REWARDS", function(hero, rewards, secs, kills) add(hero, "kill", kills or 0) end)
ns.On("ELITE_SUMMONED", function(hero) add(hero, "elite", 1) end)
ns.On("SUMMON_RESULT", function(hero, kind, results)
    if kind == "pickup" then kind = "companion" end
    add(hero, "summon_" .. tostring(kind), type(results) == "table" and #results or 1)
end)
ns.On("SCROLL_USED", function(hero) add(hero, "scroll", 1) end)
ns.On("STARFORCE_RESULT", function(hero) add(hero, "starforce", 1) end)
ns.On("POTENTIAL_ROLLED", function(hero) add(hero, "potential", 1) end)
ns.On("ABILITY_CONVERTED", function(hero) add(hero, "ability", 1) end)
ns.On("PARTY_QUEST_CLEARED", function(hero, questId) add(hero, "pq_" .. tostring(questId), 1) end)
for _, ev in ipairs({ "STAGE_CLEARED", "HERO_LEVEL_UP" }) do
    ns.On(ev, function(hero) if hero and hero.requests then R.Refresh(hero) end end)
end

-- "visit" goals: looking at a window
function R.Visited(hero, panel)
    if not hero then return end
    st(hero).visited[panel] = true
end
