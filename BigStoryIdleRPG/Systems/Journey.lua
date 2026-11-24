-- 용사의 여정: 여정의 보물 (treasure gauge), 여정의 상자 (chest + blessings), 여정의 발자취 (trail).
--
-- 여정의 보물 (KR client 1.18.0 JourneyTreasure tables, D.Journey.treasure):
--   gauge EXP per hunting kill = monster base EXP x 0.0000001 (chapter 20+; quick hunt excluded),
--   offline kills (0.9/s, applied by Campaign) count too; internal level 1..1000 sets the EXP of the
--   next reward; up to 2 rewards are stored (200%), beyond that the gauge stops (excess lost).
--   Weekly acceleration: 1 use (the ad use, free here), +20/25/30% of the current requirement at
--   60/30/10%. Premium x1.7 offline and the extra premium acceleration are removed (paid).
--   Reward = pick 1 of 4 cards (KR inven 6554/596·625 + 1.14.0 tables): the picked card resets to
--   step 1, the other three advance one step (max 5).
-- 여정의 상자 / 발자취 (KR data missing -> global wiki Module:HeroJourney + maplestoryidle.info):
--   chest: 5 keys every Monday (cap 5), 1..10 keys per opening, base tokens by chapter progress,
--   7 blessings (+0/+5/+10%) from a transition table, 1 free blessing reset per day.
--   trail: each cleared chapter boss (20..41) opens a trail (meso + 여정의 증표 + wait), one-off
--   rewards, 3 options (Attack / Max HP / chapter stat) with grades 노말..미스틱+, re-rolled with
--   meso + 여정의 증표; 1 option can be locked (KR: 여정의 기운 since 9/3); the special option
--   is active when all 3 options are 유니크 or better.
-- PROVISIONAL:
--   * trails must be opened in chapter order, one at a time; a new trail starts at 노말 x3
--   * locked re-roll cost = 3 x meso of the normal re-roll + 1 여정의 기운 (global: 3x gold + 1 cube)
--   * chest base reward uses the highest chapter whose boss is cleared (20..41)
--
-- Hero fields: hero.journey = {
--     treasure = { level, exp, stored, cards = {step x4}, accelUsed },
--     chest    = { bless = {1..3 x7}, freeResets, keysGiven },
--     trail    = { opened = { [ch] = { grades = {g,g,g}, locked = slot|nil } }, opening = { ch, finishAt } },
--   }
-- API  (rng defaults to ns.U.rng)
--   ns.Journey.Unlocked(hero)                       -> bool (chapter 20 boss cleared)
--   ns.Journey.TreasureRequirement(level)           -> journey EXP of that reward level
--   ns.Journey.TreasureGauge(hero)                  -> per mille (0..2000)
--   ns.Journey.KillExp(ch, st)                      -> treasure EXP of one kill
--   ns.Journey.AddKills(hero, ch, st, kills)        -- feeds the gauge (hooked to MONSTER_KILLED / OFFLINE_REWARDS)
--   ns.Journey.AddTreasureExp(hero, exp)
--   ns.Journey.CanAccelerate(hero) / Accelerate(hero, rng) -> ok, gaugePermille|errText
--   ns.Journey.Cards(hero)                          -> { {key, step, amount}, x4 }
--   ns.Journey.ClaimTreasure(hero, cardIndex)       -> ok, errText     fires "JOURNEY_TREASURE_CLAIMED"
--   ns.Journey.ChestBase(hero)                      -> base tokens or nil
--   ns.Journey.Blessings(hero, rng)                 -> { 1..3 x7 }, bonus per mille
--   ns.Journey.ResetBlessings(hero, rng)            -> ok, errText
--   ns.Journey.OpenChest(hero, keys, rng)           -> tokens | nil, errText
--   ns.Journey.TrailInfo(ch)                        -> trail data
--   ns.Journey.CanOpenTrail(hero, ch) / OpenTrail(hero, ch) -> ok, errText
--   ns.Journey.TrailRemaining(hero)                 -> seconds or nil
--   ns.Journey.RerollCost(hero, ch)                 -> costs
--   ns.Journey.RerollTrail(hero, ch, rng)           -> ok, errText
--   ns.Journey.SetTrailLock(hero, ch, slot|nil)     -> ok, errText
--   ns.Journey.TrailStats(hero) / Stats(hero)       -> { {stat, raw}, ... }
--   ns.Journey.Update(hero)                         -- finishes trail timers (also run on kills / login)
local ADDON, ns = ...
local U = ns.U
local D = ns.Data
local Hero = ns.Hero
local UP = ns.Upgrades

local J = {}
ns.Journey = J
local DJ = D.Journey
local T, C, TR = DJ.treasure, DJ.chest, DJ.trail

J.LOCKED_MESO_MULT = 3        -- PROVISIONAL (see header)
J.LOCKED_ENERGY = 1           -- PROVISIONAL

local function state(hero)
    local j = hero.journey
    if not j then
        j = {}
        hero.journey = j
    end
    j.treasure = j.treasure or { level = 1, exp = 0, stored = 0, cards = { 1, 1, 1, 1 }, accelUsed = 0 }
    j.chest = j.chest or { freeResets = C.freeResetsPerDay }
    j.trail = j.trail or { opened = {} }
    j.trail.opened = j.trail.opened or {}
    return j
end

Hero.RegisterSystem("journey", {
    init = function(hero) state(hero) end,
    daily = function(hero) state(hero).chest.freeResets = C.freeResetsPerDay end,
    weekly = function(hero)
        local j = state(hero)
        j.treasure.accelUsed = 0
        if J.Unlocked(hero) then
            local need = C.keyCap - Hero.Count(hero, "journeyKey")
            if need > 0 then Hero.Add(hero, "journeyKey", math.min(C.keysPerWeek, need), "journeyWeekly") end
            j.chest.keysGiven = true
        end
    end,
})

function J.Unlocked(hero)
    return UP.ChapterBossCleared(hero, T.unlockChapter)
end

-- first unlock: the key stamina starts full
local function ensureUnlocked(hero)
    local j = state(hero)
    if not j.chest.keysGiven and J.Unlocked(hero) then
        j.chest.keysGiven = true
        local need = C.keyCap - Hero.Count(hero, "journeyKey")
        if need > 0 then Hero.Add(hero, "journeyKey", need, "journeyUnlock") end
    end
end

---------------------------------------------------------------------------
-- 여정의 보물
---------------------------------------------------------------------------
function J.TreasureRequirement(level)
    local L = T.levelExp
    return L[math.min(math.max(level or 1, 1), #L)]
end

function J.TreasureGauge(hero)
    local t = state(hero).treasure
    local g = t.stored * 1000
    if t.stored < T.maxStored then
        g = g + math.floor(t.exp * 1000 / J.TreasureRequirement(t.level))
    end
    return g
end

function J.KillExp(ch, st)
    if not ch or ch < T.unlockChapter then return 0 end
    local e = T.stageExp[ch] and T.stageExp[ch][st]
    if not e then
        local c = D.Chapters and D.Chapters[ch]
        local sd = c and c.stages[st]
        e = sd and sd.exp or 0
    end
    return e * T.expRate
end

function J.AddTreasureExp(hero, amount)
    if not amount or amount <= 0 or not J.Unlocked(hero) then return end
    local t = state(hero).treasure
    if t.stored >= T.maxStored then return end
    local before = t.stored
    t.exp = t.exp + amount
    while t.stored < T.maxStored do
        local req = J.TreasureRequirement(t.level)
        if t.exp < req then break end
        t.exp = t.exp - req
        t.stored = t.stored + 1
        if t.level < #T.levelExp then t.level = t.level + 1 end
    end
    if t.stored >= T.maxStored then t.exp = 0 end   -- beyond 200% is lost
    if t.stored > before and ns.Fire then ns.Fire("JOURNEY_TREASURE_READY", hero, t.stored) end
end

function J.AddKills(hero, ch, st, kills)
    if not kills or kills <= 0 then return end
    J.AddTreasureExp(hero, J.KillExp(ch, st) * kills)
end

function J.CanAccelerate(hero)
    if not J.Unlocked(hero) then return false, "챕터 20 보스를 처치하면 개방됩니다." end
    local t = state(hero).treasure
    if (t.accelUsed or 0) >= T.weeklyAccelUses then return false, "이번 주 가속을 모두 사용했습니다." end
    if t.stored >= T.maxStored then return false, "보물을 먼저 받아야 합니다." end
    return true
end

function J.Accelerate(hero, rng)
    local ok, err = J.CanAccelerate(hero)
    if not ok then return false, err end
    rng = UP.rng(rng)
    local t = state(hero).treasure
    local w = {}
    for i, o in ipairs(T.weeklyAccel) do w[i] = o.prob end
    local o = T.weeklyAccel[rng:Weighted(w, 1000)]
    t.accelUsed = (t.accelUsed or 0) + 1
    J.AddTreasureExp(hero, J.TreasureRequirement(t.level) * o.gauge / 1000)
    Hero.Changed(hero, "journey")
    return true, o.gauge
end

function J.Cards(hero)
    local t = state(hero).treasure
    local out = {}
    for i, c in ipairs(T.cards) do
        local step = t.cards[i] or 1
        out[i] = { key = c.key, step = step, amount = c.amounts[step] }
    end
    return out
end

function J.ClaimTreasure(hero, idx)
    local t = state(hero).treasure
    if t.stored <= 0 then return false, "받을 보물이 없습니다." end
    local c = T.cards[idx]
    if not c then return false, "알 수 없는 보상" end
    local step = t.cards[idx] or 1
    Hero.Add(hero, c.key, c.amounts[step], "journeyTreasure")
    for i = 1, #T.cards do
        if i == idx then t.cards[i] = 1
        else t.cards[i] = math.min(T.maxCardStep, (t.cards[i] or 1) + 1) end
    end
    t.stored = t.stored - 1
    if ns.Fire then ns.Fire("JOURNEY_TREASURE_CLAIMED", hero, c.key, c.amounts[step]) end
    Hero.Changed(hero, "journey")
    return true
end

---------------------------------------------------------------------------
-- 여정의 상자
---------------------------------------------------------------------------
function J.ChestBase(hero)
    local best
    for ch, tokens in pairs(C.tokens) do
        if UP.ChapterBossCleared(hero, ch) and (not best or ch > best) then best = ch end
    end
    return best and C.tokens[best] or nil, best
end

local function rollBlessings(rng)
    local out, prev = {}, 0
    for i = 1, C.blessings do
        prev = rng:Weighted(C.blessOdds[prev], 1000)
        out[i] = prev
    end
    return out
end

function J.Blessings(hero, rng)
    local ch = state(hero).chest
    if not ch.bless then ch.bless = rollBlessings(UP.rng(rng)) end
    local bonus = 0
    for _, b in ipairs(ch.bless) do bonus = bonus + C.blessBonus[b] end
    return ch.bless, bonus
end

function J.ResetBlessings(hero, rng)
    local ch = state(hero).chest
    if (ch.freeResets or 0) <= 0 then return false, "오늘의 무료 초기화를 모두 사용했습니다." end
    ch.freeResets = ch.freeResets - 1
    ch.bless = rollBlessings(UP.rng(rng))
    Hero.Changed(hero, "journey")
    return true
end

function J.OpenChest(hero, keys, rng)
    keys = math.floor(keys or 1)
    if keys < 1 or keys > C.maxKeysPerOpen then return nil, "열쇠는 한 번에 1~10개까지 사용할 수 있습니다." end
    if not J.Unlocked(hero) then return nil, "챕터 20 보스를 처치하면 개방됩니다." end
    local base = J.ChestBase(hero)
    if not base then return nil, "보상 정보가 없습니다." end
    if Hero.Count(hero, "journeyKey") < keys then return nil, D.CurrencyName("journeyKey") .. "이(가) 부족합니다." end
    local _, bonus = J.Blessings(hero, rng)
    Hero.Spend(hero, "journeyKey", keys, "journeyChest")
    local tokens = math.floor(base * keys * (1000 + bonus) / 1000)
    Hero.Add(hero, "journeyToken", tokens, "journeyChest")
    state(hero).chest.bless = rollBlessings(UP.rng(rng))
    Hero.Changed(hero, "journey")
    return tokens
end

---------------------------------------------------------------------------
-- 여정의 발자취
---------------------------------------------------------------------------
function J.TrailInfo(ch) return TR.chapters[ch] end

function J.CanOpenTrail(hero, ch)
    local info = TR.chapters[ch]
    if not info then return false, "여정의 발자취가 없는 챕터입니다." end
    local tr = state(hero).trail
    if tr.opened[ch] then return false, "이미 개방했습니다." end
    if tr.opening then return false, "다른 발자취를 개방하는 중입니다." end
    if not UP.ChapterBossCleared(hero, ch) then return false, string.format("챕터 %d 보스를 처치해야 합니다.", ch) end
    if TR.chapters[ch - 1] and not tr.opened[ch - 1] then return false, "이전 발자취를 먼저 개방하세요." end
    return UP.CanPay(hero, info.openCost)
end

function J.OpenTrail(hero, ch)
    local ok, err = J.CanOpenTrail(hero, ch)
    if not ok then return false, err end
    local info = TR.chapters[ch]
    UP.Pay(hero, info.openCost, "journeyTrail")
    state(hero).trail.opening = { ch = ch, finishAt = U.Now() + info.openSec }
    J.Update(hero)
    Hero.Changed(hero, "journey")
    return true
end

function J.TrailRemaining(hero)
    local o = state(hero).trail.opening
    if not o then return nil end
    return math.max(0, o.finishAt - U.Now())
end

function J.Update(hero)
    if not hero then return end
    local tr = state(hero).trail
    local o = tr.opening
    if o and U.Now() >= o.finishAt then
        tr.opening = nil
        tr.opened[o.ch] = { grades = { 1, 1, 1 } }
        Hero.Grant(hero, TR.chapters[o.ch].rewards, "journeyTrail")
        if ns.Fire then ns.Fire("JOURNEY_TRAIL_OPENED", hero, o.ch) end
        Hero.Changed(hero, "journey")
    end
    ensureUnlocked(hero)
end

function J.RerollCost(hero, ch)
    local info = TR.chapters[ch]
    local t = state(hero).trail.opened[ch]
    if not info then return nil end
    if t and t.locked then
        return { meso = info.change.meso * J.LOCKED_MESO_MULT, journeyEnergy = J.LOCKED_ENERGY }
    end
    return { meso = info.change.meso, journeyToken = info.change.journeyToken }
end

-- the trail's special option is on when every slot reaches TR.specialMinGrade
function J.SpecialActive(t)
    for i = 1, 3 do if (t.grades[i] or 1) < TR.specialMinGrade then return false end end
    return true
end

function J.RerollTrail(hero, ch, rng)
    local t = state(hero).trail.opened[ch]
    if not t then return false, "개방하지 않은 발자취입니다." end
    local ok, err = UP.Pay(hero, J.RerollCost(hero, ch), "journeyReroll")
    if not ok then return false, err end
    rng = UP.rng(rng)
    local before = J.SpecialActive(t)
    for i = 1, 3 do
        if t.locked ~= i then t.grades[i] = rng:Weighted(TR.gradeOdds, 1000) end
    end
    if not before and J.SpecialActive(t) and ns.Fire then ns.Fire("JOURNEY_SPECIAL_OPENED", hero, ch) end
    Hero.Changed(hero, "journey")
    return true
end

function J.SetTrailLock(hero, ch, slot)
    local t = state(hero).trail.opened[ch]
    if not t then return false, "개방하지 않은 발자취입니다." end
    if slot ~= nil and (slot < 1 or slot > 3) then return false, "잘못된 칸입니다." end
    t.locked = slot
    Hero.Changed(hero, "journey")
    return true
end

function J.TrailStats(hero)
    local out = {}
    for ch, t in pairs(state(hero).trail.opened) do
        local info = TR.chapters[ch]
        if info then
            local special = true
            for i, sl in ipairs(info.slots) do
                local g = t.grades[i] or 1
                out[#out + 1] = { sl[1], sl[2][g] }
                if g < TR.specialMinGrade then special = false end
            end
            if special then out[#out + 1] = { info.special[1], info.special[2] } end
        end
    end
    return out
end
J.Stats = J.TrailStats

Hero.RegisterStatProvider("journey", function(hero, acc)
    if not hero.journey then return end
    UP.ApplyList(hero, acc, J.TrailStats(hero))
end)

---------------------------------------------------------------------------
-- feeds
---------------------------------------------------------------------------
if ns.On then
    ns.On("MONSTER_KILLED", function(hero, victim, rewards, kind)
        if not hero or kind ~= "hunt" then return end
        local def = victim and victim.def
        local ch, st = def and def.chapter, def and def.stage
        if not ch and ns.Campaign then ch, st = ns.Campaign.Stage(hero) end
        J.AddKills(hero, ch, st, 1)
        J.Update(hero)
        if ns.HeroPower then ns.HeroPower.Update(hero) end
    end)
    ns.On("OFFLINE_REWARDS", function(hero, rewards, secs, kills)
        if not hero or not ns.Campaign then return end
        local ch, st = ns.Campaign.Stage(hero)
        J.AddKills(hero, ch, st, kills)
    end)
    ns.On("HERO_ACTIVATED", function(hero)
        J.Update(hero)
        if ns.HeroPower then ns.HeroPower.Update(hero) end
    end)
end
