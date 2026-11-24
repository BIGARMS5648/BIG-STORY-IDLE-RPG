-- 소환 (Summon): weapon summon (무기 뽑기), companion summon (동료 뽑기) and the companion pickup banner
-- (신규 동료 픽업 소환). Summon levels, per-level grade x tier rates, guaranteed summons (확정 소환) and costs
-- exactly as in Data/Summon.lua (client 1.18.0). Randomness: ns.U.rng.
--
-- Cost per pull: 1 ticket or red diamonds (weapon 20, companion 50); tickets are used first.
-- Summon EXP: +1 per pull; levelUp[L] pulls raise L -> L+1 (EXP carries over).
-- A batch is rolled with the rates of the level it started at; level-ups are applied after the batch.
-- Weapon batches: 1 .. maxDraw[level] pulls. Companion / pickup batches: 1 or 10.
-- Guaranteed summon (확정 소환, KR 2026-09 notice): only at the listed summon level (weapon 18 / 19,
-- companion 13); every pull at that level fills the gauge, the pull that reaches `count` gives the target
-- (weapon: that grade+tier; companion: that grade, companion picked with the in-grade odds), and the gauge
-- resets when the target (or better) is summoned. Pickup pulls fill only the pickup gauge.
--
-- Saved: hero.summon = { weapon = { level, exp, total, pity = { [level] = n } },
--                        companion = { level, exp, total, pity = { [level] = n } },
--                        pickup = { total, pity = { [level] = n } } }
--
-- Public API (ns.Summon)
--   S.KINDS = { "weapon", "companion", "pickup" }
--   S.Info(hero, kind) -> { level, exp, need, maxLevel, total, maxBatch, batchSizes, cost = {ticket, redDia},
--        ticketKey, tickets, redDia, affordable, unlocked, guarantees = { {grade, tier, count, progress, active} },
--        rates = S.Rates(kind, level) }
--   S.Rates(kind, level) -> weapon: { {grade, tier, idx, percent} }
--                           companion/pickup: { {grade, percent, perCompanion = { [sid] = percent }} }
--   S.Cost(hero, kind, count) -> tickets, redDia, ok
--   S.CanPull(hero, kind, count) -> ok, err
--   S.Pull(hero, kind, count) -> results | nil, err
--       results = list of { kind = "weapon", idx, grade, tier, isNew, guaranteed }
--                      or { kind = "companion", sid, grade, isNew, guaranteed }
--       results.counts = { [idx|sid] = n }, results.spent = { ticket = n, redDia = n }, results.levelUps = n
--   S.LevelReward(kind, level) -> rewards table or nil (paid on reaching `level`)
-- Events: "SUMMON_RESULT"(hero, kind, results), "SUMMON_LEVEL_UP"(hero, kind, level)
local ADDON, ns = ...
local U = ns.U
local D = ns.Data
local H = ns.Hero

local S = {}
ns.Summon = S

S.KINDS = { "weapon", "companion", "pickup" }

local WS, CS = D.WeaponSummon, D.CompanionSummon

---------------------------------------------------------------------------
-- PROVISIONAL rules (not in the data; see report)
---------------------------------------------------------------------------
-- Pickup banner unlock: KR notice "동료 소환 레벨 9 달성 시 이용할 수 있습니다" (not client data).
S.PICKUP_MIN_LEVEL = 9
-- PROVISIONAL: pickup guarantee (own gauge). Count not published -> same as the normal companion row.
S.PICKUP_GUARANTEES = { { level = 13, grade = 5, count = 6250 } }
-- PROVISIONAL: the 30/30/40 split is published for 레전드리 only; the KR notices say the pickup also raises
-- the pickup jobs' 유니크 odds, so the same split is used for grade 4.
S.PICKUP_GRADES = { [4] = true, [5] = true }
-- Summon level rewards, paid when the level is reached: { [kind] = { [level] = { walletKey = n } } }.
-- Seen on in-game screens (global wiki, Pocket Gamer, LDPlayer TW, KR play; via the user 2026-11-25):
--   weapon   Lv5 100 · Lv6 150 · Lv13 500   -> all on 50 x (level - 3)
--   companion Lv7 120 · Lv8 140             -> 20 x (level - 1)
-- The other levels follow those lines (ESTIMATE); weapon Lv2-3 fall below the line and get 50 like Lv4.
S.LEVEL_REWARDS = { weapon = {}, companion = {} }
for lv = 2, 19 do S.LEVEL_REWARDS.weapon[lv] = { weaponTicket = math.max(50, 50 * (lv - 3)) } end
for lv = 2, 13 do S.LEVEL_REWARDS.companion[lv] = { companionTicket = 20 * (lv - 1) } end

local CFG = {
    weapon = { data = WS, ticket = "weaponTicket", state = "weapon" },
    companion = { data = CS, ticket = "companionTicket", state = "companion" },
    pickup = { data = CS, ticket = "companionTicket", state = "companion" },   -- shares the level gauge
}

local function state(hero)
    local s = hero.summon
    if not s then
        s = {}
        hero.summon = s
    end
    s.weapon = s.weapon or { level = 1, exp = 0, total = 0, pity = {} }
    s.companion = s.companion or { level = 1, exp = 0, total = 0, pity = {} }
    s.pickup = s.pickup or { total = 0, pity = {} }
    return s
end

local function rng() return ns.U.rng end

---------------------------------------------------------------------------
-- Rates
---------------------------------------------------------------------------
local function pickupTargets()
    local t = {}
    for _, key in ipairs(CS.pickup.targets) do t[key] = true end
    return t
end

-- in-grade odds for companions: { {sid, weight} }, total weight
local function companionChoices(grade, pickup)
    local list = ns.Companions.ByGrade(grade)
    local out = {}
    if pickup and S.PICKUP_GRADES[grade] then
        local targets = pickupTargets()
        local nNew = 0
        for _, sid in ipairs(list) do
            if targets[ns.Companions.Def(sid).job] then nNew = nNew + 1 end
        end
        local nOld = #list - nNew
        -- weights in 1/(1000 * nOld) units keep the split exact
        for _, sid in ipairs(list) do
            local w
            if targets[ns.Companions.Def(sid).job] then
                w = CS.pickup.newSharePermille * nOld
            else
                w = CS.pickup.otherSharePermille
            end
            out[#out + 1] = { sid, w }
        end
        local total = 0
        for _, e in ipairs(out) do total = total + e[2] end
        return out, total
    end
    for _, sid in ipairs(list) do out[#out + 1] = { sid, 1 } end
    return out, #list
end

function S.Rates(kind, level)
    local cfg = CFG[kind]
    if not cfg then return {} end
    local out = {}
    if kind == "weapon" then
        level = U.clamp(level or 1, 1, WS.maxLevel)
        for _, r in ipairs(WS.rates[level]) do
            out[#out + 1] = { grade = r[1], tier = r[2], idx = ns.Weapons.IndexOf(r[1], r[2]),
                percent = r[3] * 100 / WS.totalWeight }
        end
        return out
    end
    level = U.clamp(level or 1, 1, CS.maxLevel)
    local gw = CS.gradeWeights[level]
    for grade = 1, 5 do
        local pct = gw[grade] * 100 / CS.totalWeight
        local per = {}
        local choices, total = companionChoices(grade, kind == "pickup")
        for _, c in ipairs(choices) do per[c[1]] = pct * c[2] / total end
        out[#out + 1] = { grade = grade, percent = pct, perCompanion = per }
    end
    return out
end

---------------------------------------------------------------------------
-- Costs
---------------------------------------------------------------------------
function S.Cost(hero, kind, count)
    local cfg = CFG[kind]
    local tickets = math.min(H.Count(hero, cfg.ticket), count)
    local red = (count - tickets) * cfg.data.cost.redDia
    return tickets, red, H.Count(hero, "redDia") >= red
end

local function affordable(hero, kind)
    local cfg = CFG[kind]
    return H.Count(hero, cfg.ticket) / cfg.data.cost.ticket
        + math.floor(H.Count(hero, "redDia") / cfg.data.cost.redDia)
end

local function maxBatch(hero, kind)
    if kind == "weapon" then return WS.maxDraw[state(hero).weapon.level] end
    return CS.batchSizes[#CS.batchSizes]
end

function S.PickupUnlocked(hero)
    return state(hero).companion.level >= S.PICKUP_MIN_LEVEL
end

function S.CanPull(hero, kind, count)
    local cfg = CFG[kind]
    if not cfg then return false, "알 수 없는 소환입니다." end
    count = math.floor(count or 1)
    if count < 1 then return false, "소환 횟수가 올바르지 않습니다." end
    if kind == "weapon" then
        if count > maxBatch(hero, kind) then
            return false, string.format("한 번에 최대 %d회까지 소환할 수 있습니다.", maxBatch(hero, kind))
        end
    else
        local okSize = false
        for _, n in ipairs(CS.batchSizes) do if n == count then okSize = true end end
        if not okSize then return false, "1회 또는 10회만 소환할 수 있습니다." end
        if kind == "pickup" and not S.PickupUnlocked(hero) then
            return false, string.format("동료 소환 레벨 %d 달성 시 이용할 수 있습니다.", S.PICKUP_MIN_LEVEL)
        end
    end
    local _, _, ok = S.Cost(hero, kind, count)
    if not ok then return false, "소환서 또는 붉은 다이아가 부족합니다." end
    return true
end

---------------------------------------------------------------------------
-- Guarantees
---------------------------------------------------------------------------
local function guaranteeRows(kind)
    if kind == "weapon" then return WS.guarantees end
    if kind == "pickup" then return S.PICKUP_GUARANTEES end
    return CS.guarantees
end

local function pityTable(hero, kind)
    local s = state(hero)
    local t = (kind == "pickup") and s.pickup or s[kind]
    t.pity = t.pity or {}
    return t.pity
end

local function meets(row, grade, tier)
    if grade ~= row.grade then return grade > row.grade end
    return (tier or 1) >= (row.tier or 1)
end

---------------------------------------------------------------------------
-- Pull
---------------------------------------------------------------------------
local function rollWeapon(level)
    local rates = WS.rates[level]
    local weights = {}
    for i, r in ipairs(rates) do weights[i] = r[3] end
    local r = rates[rng():Weighted(weights, WS.totalWeight)]
    return r[1], r[2]
end

local function rollCompanionGrade(level)
    return rng():Weighted(CS.gradeWeights[level], CS.totalWeight)
end

local function pickCompanion(grade, pickup)
    local choices, total = companionChoices(grade, pickup)
    local weights = {}
    for i, c in ipairs(choices) do weights[i] = c[2] end
    return choices[rng():Weighted(weights, total)][1]
end

function S.Pull(hero, kind, count)
    count = math.floor(count or 1)
    local ok, err = S.CanPull(hero, kind, count)
    if not ok then return nil, err end
    local cfg = CFG[kind]
    local st = state(hero)
    local lvState = st[cfg.state]
    local level = lvState.level

    -- pay: tickets first, then red diamonds
    local tickets, red = S.Cost(hero, kind, count)
    if tickets > 0 then H.Spend(hero, cfg.ticket, tickets, "summon") end
    if red > 0 then H.Spend(hero, "redDia", red, "summon") end

    local rows = {}
    for _, g in ipairs(guaranteeRows(kind)) do
        if g.level == level then rows[#rows + 1] = g end
    end
    local pity = pityTable(hero, kind)

    local results = { counts = {}, spent = { ticket = tickets, redDia = red }, levelUps = 0 }
    for _ = 1, count do
        local forced
        for _, g in ipairs(rows) do
            pity[g.level] = (pity[g.level] or 0) + 1
            if not forced and pity[g.level] >= g.count then forced = g end
        end
        local res
        if kind == "weapon" then
            local grade, tier
            if forced then grade, tier = forced.grade, forced.tier else grade, tier = rollWeapon(level) end
            local idx = ns.Weapons.IndexOf(grade, tier)
            res = { kind = "weapon", idx = idx, grade = grade, tier = tier, guaranteed = forced and true or nil }
            res.isNew = ns.Weapons.Get(hero, idx) == nil and not results.counts[idx]
            results.counts[idx] = (results.counts[idx] or 0) + 1
        else
            local grade = forced and forced.grade or rollCompanionGrade(level)
            local sid = pickCompanion(grade, kind == "pickup")
            res = { kind = "companion", sid = sid, grade = grade, guaranteed = forced and true or nil }
            res.isNew = ns.Companions.Get(hero, sid) == nil and not results.counts[sid]
            results.counts[sid] = (results.counts[sid] or 0) + 1
        end
        for _, g in ipairs(rows) do
            if meets(g, res.grade, res.tier) then pity[g.level] = 0 end
        end
        results[#results + 1] = res
    end

    -- grant
    for key, n in pairs(results.counts) do
        if kind == "weapon" then ns.Weapons.Add(hero, key, n, true) else ns.Companions.Add(hero, key, n, true) end
    end

    -- summon EXP / level
    lvState.total = (lvState.total or 0) + count
    if kind == "pickup" then st.pickup.total = (st.pickup.total or 0) + count end
    local data = cfg.data
    lvState.exp = lvState.exp + count
    while lvState.level < data.maxLevel and lvState.exp >= data.levelUp[lvState.level] do
        lvState.exp = lvState.exp - data.levelUp[lvState.level]
        lvState.level = lvState.level + 1
        results.levelUps = results.levelUps + 1
        local rew = S.LevelReward(cfg.state, lvState.level)
        if rew then H.Grant(hero, rew, "summonLevel") end
        ns.Fire("SUMMON_LEVEL_UP", hero, cfg.state, lvState.level)
    end
    if lvState.level >= data.maxLevel then lvState.exp = 0 end

    H.Changed(hero, kind == "weapon" and "weapon" or "companion")
    ns.Fire("SUMMON_RESULT", hero, kind, results)
    return results
end

function S.LevelReward(kind, level)
    local t = S.LEVEL_REWARDS[kind]
    return t and t[level] or nil
end

---------------------------------------------------------------------------
-- Info
---------------------------------------------------------------------------
function S.Info(hero, kind)
    local cfg = CFG[kind]
    if not cfg then return nil end
    local st = state(hero)
    local lv = st[cfg.state]
    local data = cfg.data
    local pity = pityTable(hero, kind)
    local gs = {}
    for _, g in ipairs(guaranteeRows(kind)) do
        gs[#gs + 1] = { level = g.level, grade = g.grade, tier = g.tier, count = g.count,
            progress = pity[g.level] or 0, active = (g.level == lv.level) }
    end
    return {
        kind = kind,
        level = lv.level,
        exp = lv.exp,
        need = data.levelUp[lv.level],
        maxLevel = data.maxLevel,
        total = (kind == "pickup") and st.pickup.total or lv.total,
        maxBatch = maxBatch(hero, kind),
        batchSizes = (kind == "weapon") and { 1, 10, maxBatch(hero, kind) } or data.batchSizes,
        cost = { ticket = data.cost.ticket, redDia = data.cost.redDia },
        ticketKey = cfg.ticket,
        tickets = H.Count(hero, cfg.ticket),
        redDia = H.Count(hero, "redDia"),
        affordable = affordable(hero, kind),
        unlocked = (kind ~= "pickup") or S.PickupUnlocked(hero),
        guarantees = gs,
        rates = S.Rates(kind, lv.level),
    }
end

---------------------------------------------------------------------------
-- Registration
---------------------------------------------------------------------------
H.RegisterSystem("summon", {
    init = function(hero) state(hero) end,
})
