-- 용사의 힘 (Hero Power): 9 stages, 3-6 stat slots per stage leveled with 용사의 증표,
-- client 1.18.0 (D.HeroPower). Stage up when every slot is at max level, after the stage's
-- base wait time (no extra currency). A new stage keeps the previous stage's final values as
-- the slot base ("이전 단계 완성값은 한 번만 이어집니다"); the stage bonus (MainStat / MaxHp%)
-- is the value of the current stage. Membership time reduction is removed (paid).
--
-- Hero fields: hero.heroPower = { stage = 1..9, levels = { [slot] = level }, advance = { finishAt = t } | nil }
--
-- API
--   ns.HeroPower.Stage(hero)                    -> stage number, stage data
--   ns.HeroPower.Slots(hero)                    -> { {slot, type, label, level, maxLevel, value, nextValue, nextCost}, ... }
--   ns.HeroPower.LevelUpCost(hero, slot)        -> 용사의 증표 for the next level (nil at max)
--   ns.HeroPower.LevelUp(hero, slot, count)     -> levels gained, errText   (spends heroToken)
--   ns.HeroPower.IsStageComplete(hero)          -> bool
--   ns.HeroPower.CanAdvance(hero)               -> ok, errText
--   ns.HeroPower.StartAdvance(hero)             -> ok, errText   (starts the stage-up timer; 0 s finishes now)
--   ns.HeroPower.AdvanceRemaining(hero)         -> seconds or nil
--   ns.HeroPower.Skip(hero, tickets)            -> ok, errText   (시간 단축 티켓(1분) = 60 s each)
--   ns.HeroPower.Update(hero)                   -- completes a finished stage-up (call from the game tick)
--   ns.HeroPower.Stats(hero)                    -> { {stat, raw}, ... }
--   events: "HERO_POWER_CHANGED"(hero), "HERO_POWER_STAGE"(hero, stage)
local ADDON, ns = ...
local U = ns.U
local D = ns.Data
local Hero = ns.Hero
local UP = ns.Upgrades

local HP = {}
ns.HeroPower = HP
local DH = D.HeroPower

Hero.RegisterSystem("heroPower", {
    init = function(hero)
        hero.heroPower = hero.heroPower or { stage = 1, levels = {} }
    end,
})

function HP.Stage(hero)
    local s = hero.heroPower.stage
    return s, DH.stages[s]
end

local function slotValue(sl, level)
    if level <= 0 then return sl.base end
    return sl.values[level]
end
HP.SlotValue = slotValue

function HP.Slots(hero)
    local _, st = HP.Stage(hero)
    local out = {}
    for i, sl in ipairs(st.slots) do
        local lv = hero.heroPower.levels[i] or 0
        out[i] = {
            slot = i, type = sl.type, label = sl.label, level = lv, maxLevel = sl.maxLevel,
            value = slotValue(sl, lv),
            nextValue = lv < sl.maxLevel and sl.values[lv + 1] or nil,
            nextCost = lv < sl.maxLevel and sl.costs[lv + 1] or nil,
        }
    end
    return out
end

function HP.LevelUpCost(hero, slot)
    local _, st = HP.Stage(hero)
    local sl = st.slots[slot]
    if not sl then return nil end
    local lv = hero.heroPower.levels[slot] or 0
    if lv >= sl.maxLevel then return nil end
    return sl.costs[lv + 1]
end

function HP.LevelUp(hero, slot, count)
    count = count or 1
    if hero.heroPower.advance then return 0, "승급 중에는 강화할 수 없습니다." end
    local gained, err = 0, nil
    for _ = 1, count do
        local cost = HP.LevelUpCost(hero, slot)
        if not cost then err = err or "최대 레벨입니다."; break end
        if not Hero.Spend(hero, "heroToken", cost, "heroPower") then
            err = D.CurrencyName("heroToken") .. "이(가) 부족합니다."
            break
        end
        hero.heroPower.levels[slot] = (hero.heroPower.levels[slot] or 0) + 1
        gained = gained + 1
    end
    if gained > 0 then
        if ns.Fire then ns.Fire("HERO_POWER_CHANGED", hero) end
        Hero.Changed(hero, "heroPower")
    end
    return gained, err
end

function HP.IsStageComplete(hero)
    local _, st = HP.Stage(hero)
    for i, sl in ipairs(st.slots) do
        if (hero.heroPower.levels[i] or 0) < sl.maxLevel then return false end
    end
    return true
end

function HP.CanAdvance(hero)
    local s = hero.heroPower.stage
    if s >= DH.maxStage then return false, "최종 단계입니다." end
    if hero.heroPower.advance then return false, "이미 승급 중입니다." end
    if not HP.IsStageComplete(hero) then return false, "모든 능력치를 최대 레벨로 강화해야 합니다." end
    return true
end

local function finish(hero)
    local hp = hero.heroPower
    hp.stage = hp.stage + 1
    hp.levels = {}
    hp.advance = nil
    if ns.Fire then ns.Fire("HERO_POWER_STAGE", hero, hp.stage) end
    Hero.Changed(hero, "heroPower")
end

function HP.StartAdvance(hero)
    local ok, err = HP.CanAdvance(hero)
    if not ok then return false, err end
    local wait = DH.stages[hero.heroPower.stage + 1].waitSec or 0
    if wait <= 0 then
        finish(hero)
    else
        hero.heroPower.advance = { finishAt = U.Now() + wait }
        Hero.Changed(hero, "heroPower")
    end
    return true
end

function HP.AdvanceRemaining(hero)
    local a = hero.heroPower.advance
    if not a then return nil end
    return math.max(0, a.finishAt - U.Now())
end

function HP.Update(hero)
    local a = hero.heroPower and hero.heroPower.advance
    if a and U.Now() >= a.finishAt then finish(hero) end
end

function HP.Skip(hero, tickets)
    local a = hero.heroPower.advance
    if not a then return false, "승급 중이 아닙니다." end
    tickets = math.max(1, math.min(tickets or 1, math.ceil(HP.AdvanceRemaining(hero) / 60)))
    if not Hero.Spend(hero, "timeSkip1m", tickets, "heroPowerSkip") then
        return false, D.CurrencyName("timeSkip1m") .. "이(가) 부족합니다."
    end
    a.finishAt = a.finishAt - tickets * 60
    HP.Update(hero)
    return true
end

function HP.Stats(hero)
    local s, st = HP.Stage(hero)
    local out = {}
    for i, sl in ipairs(st.slots) do
        local v = slotValue(sl, hero.heroPower.levels[i] or 0)
        if v and v ~= 0 then out[#out + 1] = { sl.type, v } end
    end
    for _, b in ipairs(st.bonus) do out[#out + 1] = { b[1], b[2] } end
    return out
end

Hero.RegisterStatProvider("heroPower", function(hero, acc)
    if not hero.heroPower then return end
    UP.ApplyList(hero, acc, HP.Stats(hero))
end)
