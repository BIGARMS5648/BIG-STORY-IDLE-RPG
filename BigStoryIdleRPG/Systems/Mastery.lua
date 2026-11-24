-- Skill mastery (스킬 마스터리): 58 nodes per job, red-diamond cost and learn time.
-- API
--   ns.Mastery.Nodes(hero)            -> list of {node, state = "learned"|"learning"|"available"|"locked", remain}
--   ns.Mastery.Learn(hero, index)     -> ok, err   (spends red diamonds, starts the timer)
--   ns.Mastery.Update(hero)           -- completes finished learning (called by the game loop)
--   ns.Mastery.Skip(hero, seconds)    -- spends 시간 단축권(1분) to shorten the timer
local ADDON, ns = ...
local U = ns.U
local Hero = ns.Hero
local SB = ns.SkillBook

local M = {}
ns.Mastery = M

Hero.RegisterSystem("mastery", {
    init = function(hero)
        hero.masteries = hero.masteries or {}
        -- hero.masteryLearning = { index = n, finishAt = t }
    end,
})

local function cost(node)
    local c = node.CostData and node.CostData[1]
    if not c then return "redDia", 0 end
    -- client currency "FreeDia" is 레드 다이아
    return "redDia", c.Count or 0
end
M.Cost = cost

function M.Node(job, index)
    for _, m in ipairs(job.masteries) do
        if m.MasteryIndex == index then return m end
    end
end

function M.Nodes(hero)
    local job = Hero.Job(hero)
    local out = {}
    local learning = hero.masteryLearning
    for _, m in ipairs(job.masteries) do
        local state, remain = "locked", nil
        if hero.masteries[m.MasteryIndex] then
            state = "learned"
        elseif learning and learning.index == m.MasteryIndex then
            state = "learning"
            remain = math.max(0, learning.finishAt - U.Now())
        elseif SB.MasteryAvailable(job, m, hero.level, hero.masteries) then
            state = "available"
        end
        out[#out + 1] = { node = m, state = state, remain = remain }
    end
    return out
end

function M.Learn(hero, index)
    if hero.masteryLearning then return false, "이미 다른 마스터리를 배우는 중입니다." end
    local job = Hero.Job(hero)
    local node = M.Node(job, index)
    if not node then return false, "알 수 없는 마스터리" end
    if hero.masteries[index] then return false, "이미 배운 마스터리입니다." end
    if not SB.MasteryAvailable(job, node, hero.level, hero.masteries) then return false, "조건을 만족하지 않습니다." end
    local key, n = cost(node)
    if not Hero.Spend(hero, key, n, "mastery") then return false, ns.Data.CurrencyName(key) .. "이(가) 부족합니다." end
    local delay = node.LearnedDelaySeconds or 0
    if delay <= 0 then
        hero.masteries[index] = true
        Hero.Changed(hero, "mastery")
        return true
    end
    hero.masteryLearning = { index = index, finishAt = U.Now() + delay }
    Hero.Changed(hero, "mastery")
    return true
end

function M.Update(hero)
    local l = hero.masteryLearning
    if l and U.Now() >= l.finishAt then
        hero.masteries[l.index] = true
        hero.masteryLearning = nil
        ns.Fire("MASTERY_LEARNED", hero, l.index)
        Hero.Changed(hero, "mastery")
    end
end

-- 시간 단축권(1분): each ticket removes 60 s
function M.Skip(hero, tickets)
    local l = hero.masteryLearning
    if not l then return false end
    tickets = math.min(tickets, Hero.Count(hero, "timeSkip1m"))
    local needed = math.ceil(math.max(0, l.finishAt - U.Now()) / 60)
    tickets = math.min(tickets, needed)
    if tickets <= 0 then return false end
    Hero.Spend(hero, "timeSkip1m", tickets, "masterySkip")
    l.finishAt = l.finishAt - tickets * 60
    M.Update(hero)
    return true
end
