-- Skill book: which skills a hero has at a level, their skill levels and the
-- creature skill set handed to the battle engine.
local ADDON, ns = ...
local U = ns.U
local D = ns.Data
local SB = {}
ns.SkillBook = SB

function SB.JobByKey(key)
    for _, j in ipairs(D.Jobs) do
        if j.key == key then return j end
    end
end

function SB.JobByIndex(idx)
    for _, j in ipairs(D.Jobs) do
        if j.index == idx then return j end
    end
end

-- points spent per job step (client assumption: every point spent, 3 per level from Lv11)
function SB.Enhance(step, level)
    local e = D.SkillRules.enhance[step]
    if not e then return 0 end
    return math.max(0, math.min(e.cap, U.trunc((level - e.levelOffset) * e.multiplier)))
end

-- bonus = { allSkill = n, [1]=n, [2]=n, [3]=n, [4]=n }
function SB.RowLevel(row, level, bonus)
    if row.DisableSkillLevel then return 1 end
    local step = row.JobStep or 0
    if step < 1 or step > 4 then return 1 end
    bonus = bonus or {}
    return math.max(1, 1 + SB.Enhance(step, level) + (bonus.allSkill or 0) + (bonus[step] or 0))
end

function SB.RowUnlocked(row, level)
    local step = row.JobStep or 0
    if step == 0 then return true end
    if level < (D.SkillRules.stepUnlockLevel[step] or 1) then return false end
    if row.RequireLevel and level < row.RequireLevel then return false end
    return true
end

function SB.Category(row)
    if row.isBasicAttack then return "basic" end
    if row.HeroSkillType == "PassiveSkill" then return "passive" end
    local s = D.Skills[row.SkillIndex]
    if s and s.TriggerType and s.TriggerType ~= "None" then return "passive" end
    return "active"
end

-- Learnable masteries: a node is available when its level and prerequisite are met.
function SB.MasteryAvailable(job, m, level, learned)
    if level < (m.RequireCreatureLevel or 0) then return false end
    if m.RequireMasteryIndex and not learned[m.RequireMasteryIndex] then return false end
    if not m.IsMainNode and not m.RequireMasteryIndex then return true end
    if m.IsMainNode then
        -- main chain: previous main node (TierIndex - 1) must be learned
        if m.TierIndex and m.TierIndex > 1 then
            for _, o in ipairs(job.masteries) do
                if o.IsMainNode and o.TierIndex == m.TierIndex - 1 then return learned[o.MasteryIndex] and true or false end
            end
        end
    end
    return true
end

-- hero = { jobKey, level, skillBonus = {allSkill, [1..4]}, masteries = {[MasteryIndex]=true}, disabledActives = {[sid]=true} }
-- returns skillSet, statAdds (from mastery stat nodes)
function SB.Build(hero)
    local job = SB.JobByKey(hero.jobKey)
    assert(job, "unknown job " .. tostring(hero.jobKey))
    local level = hero.level or 1
    local bonus = hero.skillBonus or {}
    local set = { levels = {}, passives = {}, actives = {}, masteries = {}, extraPassives = {} }
    local basicStep = -1
    for _, row in ipairs(job.rows) do
        if SB.RowUnlocked(row, level) then
            local sid = row.SkillIndex
            set.levels[sid] = SB.RowLevel(row, level, bonus)
            local cat = SB.Category(row)
            if cat == "basic" then
                if (row.JobStep or 0) > basicStep then
                    basicStep = row.JobStep or 0
                    set.basic = sid
                end
            elseif cat == "passive" then
                table.insert(set.passives, sid)
            else
                if not (hero.disabledActives and hero.disabledActives[sid]) then
                    table.insert(set.actives, sid)
                end
            end
        end
    end
    if not set.basic then set.basic = job.initialBaseAttack end
    local statAdds = {}
    local learned = hero.masteries or {}
    for _, m in ipairs(job.masteries) do
        if learned[m.MasteryIndex] then
            if m.StatData then
                local t = m.StatData.Type
                statAdds[t] = (statAdds[t] or 0) + (m.StatData.Value or 0)
            elseif m.programSkillId then
                table.insert(set.masteries, m.programSkillId)
            end
        end
    end
    -- actives: longer cooldown first so big skills are not starved
    table.sort(set.actives, function(a, b)
        local ca = (D.Skills[a] and D.Skills[a].CoolTimeMs) or 0
        local cb = (D.Skills[b] and D.Skills[b].CoolTimeMs) or 0
        if ca ~= cb then return ca > cb end
        return a < b
    end)
    return set, statAdds, job
end

-- every mastery reachable at the level (used for previews / tests)
function SB.AllMasteriesAt(job, level)
    local learned = {}
    local changed = true
    while changed do
        changed = false
        for _, m in ipairs(job.masteries) do
            if not learned[m.MasteryIndex] and SB.MasteryAvailable(job, m, level, learned) then
                learned[m.MasteryIndex] = true
                changed = true
            end
        end
    end
    return learned
end
