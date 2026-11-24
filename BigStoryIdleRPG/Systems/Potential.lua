-- 잠재능력 (미라클 큐브) / 에디셔널 잠재능력 (에디셔널 큐브), client 1.18.0 (D.Potential).
-- Both cubes roll the same option pools (GearAbilityOptionTable == GearAddAbilityOptionTable).
-- Every roll: grade-up check (chance per 1,000,000, guaranteed at the pity count = 천장),
-- then 3 lines rolled independently: line 1 from the current-grade pool, lines 2-3 from pools
-- that mix current-grade values with the previous grade's line-1 values (as in the data).
--
-- Item fields: item.part (or item.slot) = gear part key ("Cap", "Ring", ...), item.star
--   item.potential  = { grade = 1..6, lines = { {stat, raw}, {stat, raw}, {stat, raw} }, pity = n, rolls = n }
--   item.additional = same layout (에디셔널)
--
-- API  (kind = "miracle" | "additional"; rng defaults to ns.U.rng)
--   ns.Potential.GradeName(grade)                 -> "노말".."미스틱"
--   ns.Potential.State(item, kind)                -> state table (created on demand)
--   ns.Potential.Unlocked(item, kind)             -> bool (3★ / 12★ slot gate)
--   ns.Potential.Cost(item, kind)                 -> { cubeMiracle|cubeAdditional = 1, meso = n }
--   ns.Potential.GradeUpInfo(item, kind)          -> chance (per 1e6), pity count, rolls done at this grade
--   ns.Potential.LineOptions(part, grade, line)   -> { {stat, raw, prob}, ... } (prob per 1e6; UI odds table)
--   ns.Potential.RollState(state, part, kind, rng)-> gradedUp   pure roll on a state table (no cost)
--   ns.Potential.UseCube(hero, item, kind, rng)   -> ok|nil, gradedUp | errText
--        fires "POTENTIAL_ROLLED"(hero, item, kind, gradedUp)
--   ns.Potential.ItemStats(item)                  -> { {stat, raw}, ... } (potential + additional lines)
--   ns.Potential.FormatLine(line)                 -> "STR +3%"
local ADDON, ns = ...
local D = ns.Data
local Hero = ns.Hero
local UP = ns.Upgrades

local P = {}
ns.Potential = P
local DP = D.Potential
local MAX_GRADE = #DP.gradeNames
local CUBE_KEY = { miracle = "cubeMiracle", additional = "cubeAdditional" }
local FIELD = { miracle = "potential", additional = "additional" }

function P.GradeName(g) return DP.gradeNames[g] or "?" end

function P.State(item, kind)
    local f = FIELD[kind]
    item[f] = item[f] or { grade = 1, lines = {}, pity = 0, rolls = 0 }
    return item[f]
end

function P.Unlocked(item, kind)
    local SF = ns.StarForce
    if not SF then return true end
    if kind == "additional" then return SF.AdditionalUnlocked(item) end
    return SF.PotentialUnlocked(item)
end

local function gradeRow(kind, grade)
    return DP.gradeUp[kind][grade]
end

function P.Cost(item, kind)
    local st = item[FIELD[kind]]
    local row = gradeRow(kind, st and st.grade or 1)
    return { [CUBE_KEY[kind]] = row.cubes, meso = row.meso }
end

function P.GradeUpInfo(item, kind)
    local st = item[FIELD[kind]]
    local grade = st and st.grade or 1
    local row = gradeRow(kind, grade)
    return row.prob, row.pity, st and st.pity or 0
end

function P.LineOptions(part, grade, line)
    local pools = DP.pools[part]
    return pools and pools[grade] and pools[grade][line] or {}
end

-- cached weight arrays
local weightCache = setmetatable({}, { __mode = "k" })
local function weights(pool)
    local w = weightCache[pool]
    if not w then
        w = {}
        for i = 1, #pool do w[i] = pool[i][3] end
        weightCache[pool] = w
    end
    return w
end

function P.RollState(state, part, kind, rng)
    rng = UP.rng(rng)
    assert(DP.pools[part], "unknown gear part " .. tostring(part))
    local gradedUp = false
    state.rolls = (state.rolls or 0) + 1
    state.pity = (state.pity or 0) + 1
    if state.grade < MAX_GRADE then
        local row = gradeRow(kind, state.grade)
        if (row.pity > 0 and state.pity >= row.pity) or rng:ChanceM(row.prob / 1000) then
            state.grade = state.grade + 1
            state.pity = 0
            gradedUp = true
        end
    end
    local lines = {}
    for ln = 1, 3 do
        local pool = DP.pools[part][state.grade][ln]
        local pick = pool[rng:Weighted(weights(pool), DP.scale)]
        lines[ln] = { pick[1], pick[2] }
    end
    state.lines = lines
    return gradedUp
end

function P.UseCube(hero, item, kind, rng)
    kind = kind or "miracle"
    if not FIELD[kind] then return nil, "알 수 없는 큐브" end
    local part = UP.ItemPart(item)
    if not part or not DP.pools[part] then return nil, "잠재능력을 설정할 수 없는 장비입니다." end
    if not P.Unlocked(item, kind) then
        local need = (kind == "additional") and ns.StarForce.ADDITIONAL_STAR or ns.StarForce.POTENTIAL_STAR
        return nil, string.format("별빛 강화 %d성 이상에서 사용할 수 있습니다.", need)
    end
    local ok, err = UP.Pay(hero, P.Cost(item, kind), "cube")
    if not ok then return nil, err end
    local state = P.State(item, kind)
    local up = P.RollState(state, part, kind, rng)
    if ns.Fire then ns.Fire("POTENTIAL_ROLLED", hero, item, kind, up) end
    Hero.Changed(hero, "potential")
    return true, up
end

function P.ItemStats(item)
    local out = {}
    for _, f in pairs(FIELD) do
        local st = item[f]
        if st and st.lines then
            for _, l in ipairs(st.lines) do out[#out + 1] = { l[1], l[2] } end
        end
    end
    return out
end

function P.FormatLine(line)
    return UP.FormatStat(line[1], line[2])
end

UP.RegisterItemHook("potential", function(item, acc, hero)
    UP.ApplyList(hero, acc, P.ItemStats(item))
end)
