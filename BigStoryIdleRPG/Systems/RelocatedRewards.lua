-- Guild content was removed (user decision). Its rewards are paid by other content:
--   길드 레이드 (자쿰/혼테일 누적 피해 주문서, 클리어 메달) -> 보스 레이드: weekly first clear + top-difficulty medal
--   길드 보스 대전 (에디셔널 큐브 10/3 + 버프)              -> 보스 레이드 weekly settlement
--   길드 대항전 (미라클 큐브 15/10/7/5/3 + 버프)             -> 몬스터파크 weekly best stage
--   길드 수련장 (무기 소환권 750..100)                        -> 용사의 수련장 weekly settlement
--   길드 현상수배 (마법 부여 주머니, 변환석, 불꽃 늑대 코인)  -> 월드보스 weekly tier (coins become 월드보스 코인)
--   현상수배 상점                                            -> 월드보스 코인 상점 (same prices)
--   길드 토벌전 (메소 버프 최대 +10%)                         -> 월드보스 weekly benefit
--   길드 창고 + 길드 상점                                     -> 주간 미션 last stage (Data/Income.lua)
-- Amounts are the original guild rewards (research/spec/research-income.md §6.3, §5.4).
-- Thresholds that map a guild rank onto the new content are PROVISIONAL (marked below).
local ADDON, ns = ...
local U = ns.U
local D = ns.Data
local Hero = ns.Hero
local C = ns.Content

local R = {}
ns.Relocated = R

-- 길드 레이드 누적 피해 보상 합계 (10/40/80%: 하급 3장씩, 50/90%: 중급 2장씩)
R.RAID_WEEKLY_FIRST = {
    zakum = { scrollZakum1 = 9, scrollZakum2 = 4 },
    horntail = { scrollHorntail1 = 9, scrollHorntail2 = 4 },
}
-- 길드 레이드 클리어 메달 (최종 데미지 +3% per boss) -> Data/Medals.lua (guildRaid); raidMedals marks the clear
-- 길드 보스 대전 win / lose
R.RAID_WEEK = { clear = { cubeAdditional = 10, exp = 160, gold = 160 }, tried = { cubeAdditional = 3, exp = 70, gold = 0 } }
-- 길드 대항전 rank 1..5; PROVISIONAL: monster park stage needed for each rank
R.PARK = {
    { stage = 10, cubeMiracle = 15, exp = 160, gold = 130 },
    { stage = 8, cubeMiracle = 10, exp = 130, gold = 130 },
    { stage = 6, cubeMiracle = 7, exp = 100, gold = 100 },
    { stage = 4, cubeMiracle = 5, exp = 70, gold = 0 },
    { stage = 1, cubeMiracle = 3, exp = 50, gold = 0 },
}
-- 길드 수련장 rank 1..7; PROVISIONAL: 용사의 수련장 highest stage needed for each rank
R.TRAINING = {
    { stage = 140, weaponTicket = 750 }, { stage = 120, weaponTicket = 500 }, { stage = 100, weaponTicket = 350 },
    { stage = 80, weaponTicket = 250 }, { stage = 60, weaponTicket = 200 }, { stage = 40, weaponTicket = 150 },
    { stage = 1, weaponTicket = 100 },
}
-- 현상수배 weekly rows (불꽃 늑대 코인 -> 월드보스 코인); PROVISIONAL: world-boss tier -> row
-- world-boss tier index: 1 = 챔피언1 ... 23 = 브론즈1
R.BOUNTY = {
    { coin = 14000, items = { enchantPouchTop = 10, subOptionStone = 300 } },
    { coin = 13000, items = { enchantPouchHigh = 10, subOptionStone = 200 } },
    { coin = 12000, items = { enchantPouchHigh = 9, subOptionStone = 100 } },
    { coin = 11000, items = { enchantPouchHigh = 8 } },
    { coin = 10000, items = { enchantPouchHigh = 7 } },
    { coin = 9500, items = { enchantPouchHigh = 6 } },
    { coin = 9000, items = { enchantPouchHigh = 5 } },
    { coin = 8500, items = { enchantPouchMid = 5 } },
    { coin = 8000, items = { enchantPouchMid = 4 } },
    { coin = 7800, items = { enchantPouchMid = 3 } },
    { coin = 7600, items = { enchantPouchMid = 2 } },
    { coin = 7400, items = { enchantPouch = 2 } },
    { coin = 7200, items = { enchantPouch = 1 } },
    { coin = 7000, items = {} },
}
R.BOUNTY_BY_TIER = { 1, 2, 3, 4, 4, 5, 5, 5, 6, 6, 7, 7, 7, 8, 8, 9, 9, 9, 10, 11, 12, 13, 14 }
-- 길드 토벌전 노블레스 메소 버프 (최대 +10%); PROVISIONAL tier bands
R.TOUBEOL = { { maxTier = 3, gold = 100 }, { maxTier = 8, gold = 70 }, { maxTier = 13, gold = 50 }, { maxTier = 18, gold = 30 } }

-- 현상수배 상점 -> 월드보스 코인 상점 (prices in coins, same as the original)
D.WorldBossShop = {
    { name = "장비 부 옵션 변환석 200개", price = 4000, perChar = 10, items = { subOptionStone = 200 } },
    { name = "장비 부 옵션 변환석 200개 (주간)", price = 2000, weekly = 1, items = { subOptionStone = 200 } },
    { name = "하급 마법 부여 주머니", price = 200, weekly = 5, items = { enchantPouch = 1 } },
    { name = "중급 마법 부여 주머니", price = 400, weekly = 5, items = { enchantPouchMid = 1 } },
    { name = "상급 마법 부여 주머니", price = 600, weekly = 5, items = { enchantPouchHigh = 1 } },
    { name = "최상급 마법 부여 주머니", price = 1000, weekly = 5, items = { enchantPouchTop = 1 } },
    { name = "시간 단축 티켓(1분) 100개", price = 1000, items = { timeSkip1m = 100 } },
    { name = "버닝 필드 부스터 1개", price = 2000, items = { burningBooster = 1 } },
}

---------------------------------------------------------------------------
-- state
---------------------------------------------------------------------------
local function st(hero)
    hero.relocated = hero.relocated or {}
    local s = hero.relocated
    s.raidWeek = s.raidWeek or { cleared = {}, tried = false, firstPaid = {} }
    s.raidMedals = s.raidMedals or {}
    s.parkBest = s.parkBest or 0
    s.trainingPlayed = s.trainingPlayed or false
    s.wbShopWeek = s.wbShopWeek or {}
    s.wbShopTotal = s.wbShopTotal or {}
    return s
end

local function buff(hero, id, nameKo, exp, gold)
    if (exp or 0) == 0 and (gold or 0) == 0 then return end
    C.AddBuff(hero, { id = id, nameKo = nameKo, ["until"] = U.Now() + 7 * 86400,
        stats = { BonusExpPercent = exp or 0, BonusGoldPercent = gold or 0 } })
end

local function grant(hero, rewards, reason)
    local any = false
    for _, v in pairs(rewards) do if v and v > 0 then any = true end end
    if any then return C.Grant(hero, rewards, reason) end
    return {}
end

---------------------------------------------------------------------------
-- hooks
---------------------------------------------------------------------------
ns.On("BOSS_RAID_CLEARED", function(hero, boss, diff, mode)
    local s = st(hero)
    s.raidWeek.cleared[boss] = true
    s.raidWeek.tried = true
    local first = R.RAID_WEEKLY_FIRST[boss]
    if first and not s.raidWeek.firstPaid[boss] then
        s.raidWeek.firstPaid[boss] = true
        grant(hero, first, "raidWeeklyFirst")
    end
    local rd = D.ContentRaids[boss]
    if rd and diff >= #rd.difficulties and not s.raidMedals[boss] then
        s.raidMedals[boss] = true
        Hero.Changed(hero, "medal")
    end
end)

ns.On("CONTENT_FINISHED", function(hero, key, res)
    if type(key) ~= "string" then return end
    local s = st(hero)
    if key:find("^raid_") then
        s.raidWeek.tried = true
    elseif key == "monsterPark" and res and res.ok then
        local b = ns.Game.battle
        local ctl = b and b.opts and b.opts.controller
        if ctl and ctl.stage and not ctl.practice then s.parkBest = math.max(s.parkBest, ctl.stage) end
    elseif key == "growth_training" and res and res.ok then
        s.trainingPlayed = true
    end
end)


-- world boss weekly: bounty rewards + 토벌전 buff, after the normal settlement
local origSettle = C.WorldBoss and C.WorldBoss.Settle
if origSettle then
    C.WorldBoss.Settle = function(hero, which)
        local score = which == "weekly" and hero.content.worldBoss.weekBest or 0
        origSettle(hero, which)
        if which ~= "weekly" then return end
        local _, idx = C.WorldBoss.TierFor(score)
        if not idx then return end
        local row = R.BOUNTY[R.BOUNTY_BY_TIER[idx] or #R.BOUNTY]
        local rw = { worldBossCoin = row.coin }
        for k, v in pairs(row.items) do rw[k] = v end
        local lines = grant(hero, rw, "worldBossBounty")
        for _, t in ipairs(R.TOUBEOL) do
            if idx <= t.maxTier then
                buff(hero, "wbToubeol", "토벌 혜택", 0, t.gold)
                break
            end
        end
        hero.relocated = hero.relocated or {}
        hero.relocated.lastBounty = { lines = lines, at = U.Now() }
    end
end

Hero.RegisterSystem("relocated", {
    init = function(hero) st(hero) end,
    weekly = function(hero)
        local s = st(hero)
        local out = {}
        -- boss raid week (former 길드 보스 대전)
        local any = false
        for _ in pairs(s.raidWeek.cleared) do any = true end
        local r = any and R.RAID_WEEK.clear or (s.raidWeek.tried and R.RAID_WEEK.tried or nil)
        if r then
            grant(hero, { cubeAdditional = r.cubeAdditional }, "raidWeek")
            buff(hero, "raidWeek", any and "레이드 정복 혜택" or "레이드 도전 혜택", r.exp, r.gold)
            out[#out + 1] = string.format("보스 레이드 주간: 추가 잠재 큐브 %d", r.cubeAdditional)
        end
        -- monster park best stage (former 길드 대항전)
        for _, row in ipairs(R.PARK) do
            if s.parkBest >= row.stage then
                grant(hero, { cubeMiracle = row.cubeMiracle }, "parkWeek")
                buff(hero, "parkWeek", "투기장 혜택", row.exp, row.gold)
                out[#out + 1] = string.format("구루바시 투기장 주간: 잠재 큐브 %d", row.cubeMiracle)
                break
            end
        end
        -- 용사의 수련장 (former 길드 수련장)
        if s.trainingPlayed then
            local max = hero.content and hero.content.growth and hero.content.growth.training
                and hero.content.growth.training.max or 0
            for _, row in ipairs(R.TRAINING) do
                if max >= row.stage then
                    grant(hero, { weaponTicket = row.weaponTicket }, "trainingWeek")
                    out[#out + 1] = string.format("영웅의 수련장 주간: 무기 소환서 %d", row.weaponTicket)
                    break
                end
            end
        end
        s.raidWeek = { cleared = {}, tried = false, firstPaid = {} }
        s.parkBest = 0
        s.trainingPlayed = false
        s.wbShopWeek = {}
        s.lastWeek = { lines = out, at = U.Now() }
    end,
})

-- 월드보스 코인 상점
function R.BuyWB(hero, idx)
    local row = D.WorldBossShop[idx]
    if not row then return false end
    local s = st(hero)
    if row.weekly and (s.wbShopWeek[idx] or 0) >= row.weekly then return false, "이번 주 구매 한도입니다." end
    if row.perChar and (s.wbShopTotal[idx] or 0) >= row.perChar then return false, "구매 한도에 도달했습니다." end
    if not Hero.Spend(hero, "worldBossCoin", row.price, "wbShop") then return false, "월드보스 주화가 부족합니다." end
    s.wbShopWeek[idx] = (s.wbShopWeek[idx] or 0) + 1
    s.wbShopTotal[idx] = (s.wbShopTotal[idx] or 0) + 1
    Hero.Grant(hero, row.items, "wbShop")
    return true
end
