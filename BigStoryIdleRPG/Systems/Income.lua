-- Free income: daily missions + weekly gauge, daily battle pass (free track),
-- monthly attendance, free daily claims (replacing ad rewards), weekly red-diamond
-- shop, 14-day newcomer missions. Data: Data/Income.lua.
--
-- API
--   ns.Income.Track(hero, key, n)               -- progress counters (kill, summon_weapon, dungeon, ...)
--   ns.Income.DailyMissions(hero)               -> { {def, progress, done, claimed}, ... }, clearCount
--   ns.Income.ClaimMission(hero, id) / ClaimDailyClear(hero) / ClaimWeekly(hero, stage)
--   ns.Income.PassState(hero) / ClaimPass(hero)  -> claims every reached step
--   ns.Income.AttendanceState(hero) / ClaimAttendance(hero)
--   ns.Income.ClaimFree(hero, id)
--   ns.Income.BuyRed(hero, index)
--   ns.Income.Newcomer(hero) / ClaimNewcomer(hero, day, index) / ClaimNewcomerDay(hero, day)
local ADDON, ns = ...
local U = ns.U
local D = ns.Data
local Hero = ns.Hero

local I = {}
ns.Income = I

local function monthIndex(t)
    local d = date and date("!*t", (t or U.Now()) + U.RESET_TZ_OFFSET) or os.date("!*t", (t or U.Now()) + U.RESET_TZ_OFFSET)
    return d.year * 12 + d.month
end

Hero.RegisterSystem("income", {
    init = function(hero)
        local s = hero.income or {}
        hero.income = s
        s.day = s.day or {}            -- daily counters: kill, summon_weapon, ...
        s.dayClaimed = s.dayClaimed or {}
        s.passClaimed = s.passClaimed or 0
        s.freeClaimed = s.freeClaimed or {}
        s.week = s.week or { points = 0, claimed = {} }
        s.weekShop = s.weekShop or {}
        s.shopOnce = s.shopOnce or {}
        s.att = s.att or { month = monthIndex(), claimedDays = 0, lastDay = -1 }
        s.progress = s.progress or {}  -- permanent maxima (dungeon stages, world boss, arena tier...)
        s.newcomer = s.newcomer or { start = U.DayIndex(), claimed = {}, dayClaimed = {}, total = 0 }
    end,
    daily = function(hero)
        local s = hero.income
        s.day, s.dayClaimed, s.passClaimed, s.freeClaimed = {}, {}, 0, {}
        if s.att.month ~= monthIndex() then s.att = { month = monthIndex(), claimedDays = 0, lastDay = -1 } end
    end,
    weekly = function(hero)
        local s = hero.income
        s.week = { points = 0, claimed = {} }
        s.weekShop = {}
    end,
})

---------------------------------------------------------------------------
-- tracking
---------------------------------------------------------------------------
function I.Track(hero, key, n)
    if not (hero and hero.income) then return end
    local d = hero.income.day
    d[key] = (d[key] or 0) + (n or 1)
end

local function setMax(hero, key, v)
    if not (hero and hero.income and v) then return end
    local p = hero.income.progress
    if (p[key] or 0) < v then p[key] = v end
end

local function addKills(hero, n)
    if not (hero and hero.income) then return end
    I.Track(hero, "kill", n)
    local p = hero.income.progress
    p.killTotal = (p.killTotal or 0) + n
end
ns.On("MONSTER_KILLED", function(hero) addKills(hero, 1) end)
ns.On("OFFLINE_REWARDS", function(hero, rewards, secs, kills) addKills(hero, kills or 0) end)
ns.On("SUMMON_RESULT", function(hero, kind, results)
    local n = type(results) == "table" and #results or 1
    if kind == "pickup" then kind = "companion" end
    I.Track(hero, "summon_" .. tostring(kind), n)
end)
ns.On("GROWTH_DUNGEON_CLEARED", function(hero, key, stage)
    I.Track(hero, "dungeon", 1)
    setMax(hero, "dungeon_" .. tostring(key), stage)
end)
ns.On("CONTENT_FINISHED", function(hero, key, res)
    if type(key) == "string" and key:lower():find("world") then
        I.Track(hero, "worldboss", 1)
        if type(res) == "table" then setMax(hero, "worldboss", res.level or res.stage) end
    elseif key == "quickHunt" then
        I.Track(hero, "quickhunt", 1)
    end
end)
ns.On("ARENA_RESULT", function(hero)
    I.Track(hero, "arena", 1)
    setMax(hero, "arenaTotal", (hero.income.progress.arenaTotal or 0) + 1)
    if ns.Arena then setMax(hero, "arenaTier", ns.Arena.Tier(hero)) end
end)
ns.On("ENCHANT_USED", function(hero) setMax(hero, "enchant", (hero.income.progress.enchant or 0) + 1) end)
ns.On("POTENTIAL_ROLLED", function(hero, item)
    setMax(hero, "potentialRolls", (hero.income.progress.potentialRolls or 0) + 1)
    if item and item.potential then setMax(hero, "potentialGrade", item.potential.grade) end
end)
ns.On("STARFORCE_RESULT", function(hero, item) if item then setMax(hero, "star", item.star) end end)
ns.On("STAGE_CLEARED", function(hero, ch, st, kind) if kind == "boss" then setMax(hero, "chapterBoss", ch) end end)
ns.On("BOSS_RAID_CLEARED", function(hero)
    setMax(hero, "raidClear", (hero.income.progress.raidClear or 0) + 1)
end)
ns.On("CONTENT_FINISHED", function(hero, key, res)
    if key == "monsterPark" and res and res.ok then
        setMax(hero, "monsterPark", (hero.income.progress.monsterPark or 0) + 1)
    end
end)

---------------------------------------------------------------------------
-- daily / weekly missions
---------------------------------------------------------------------------
function I.DailyMissions(hero)
    local s = hero.income
    local out, done = {}, 0
    for _, m in ipairs(D.DailyMissions) do
        local prog = s.day[m.track] or 0
        local ok = prog >= m.goal
        if s.dayClaimed[m.id] then done = done + 1 end
        out[#out + 1] = { def = m, progress = math.min(prog, m.goal), done = ok, claimed = s.dayClaimed[m.id] }
    end
    return out, done
end

function I.ClaimMission(hero, id)
    local s = hero.income
    for _, m in ipairs(D.DailyMissions) do
        if m.id == id then
            if s.dayClaimed[id] then return false, "이미 받았습니다." end
            if (s.day[m.track] or 0) < m.goal then return false, "아직 완료하지 않았습니다." end
            s.dayClaimed[id] = true
            Hero.Grant(hero, m.rewards, "dailyMission")
            s.week.points = s.week.points + D.WeeklyMission.perDailyMission
            return true
        end
    end
    return false, "알 수 없는 미션"
end

function I.ClaimDailyClear(hero)
    local s = hero.income
    local _, done = I.DailyMissions(hero)
    if s.dayClaimed.__clear then return false, "이미 받았습니다." end
    if done < D.DailyMissionClear.need then
        return false, string.format("일일 미션 %d/%d", done, D.DailyMissionClear.need)
    end
    s.dayClaimed.__clear = true
    Hero.Grant(hero, D.DailyMissionClear.rewards, "dailyClear")
    return true
end

function I.ClaimWeekly(hero, idx)
    local s = hero.income
    local st = D.WeeklyMission.stages[idx]
    if not st then return false end
    if s.week.claimed[idx] then return false, "이미 받았습니다." end
    if s.week.points < st.need then return false, "주간 게이지가 부족합니다." end
    s.week.claimed[idx] = true
    Hero.Grant(hero, st.rewards, "weeklyMission")
    return true
end

---------------------------------------------------------------------------
-- daily battle pass (free track)
---------------------------------------------------------------------------
function I.PassState(hero)
    local s = hero.income
    local kills = s.day.kill or 0
    local reached = 0
    for i, st in ipairs(D.DailyPass) do if kills >= st.kills then reached = i end end
    return kills, reached, s.passClaimed
end

function I.ClaimPass(hero)
    local s = hero.income
    local _, reached = I.PassState(hero)
    if reached <= s.passClaimed then return false, "받을 보상이 없습니다." end
    local total = 0
    for i = s.passClaimed + 1, reached do total = total + D.DailyPass[i].redDia end
    s.passClaimed = reached
    Hero.Add(hero, "redDia", total, "dailyPass")
    return true, total
end

---------------------------------------------------------------------------
-- monthly attendance (needs today's daily-mission 8/8 clear)
---------------------------------------------------------------------------
function I.AttendanceState(hero)
    local s = hero.income
    local u = D.Attendance.unlock
    local cp = hero.campaign
    local unlocked = cp.maxChapter > u.ch or (cp.maxChapter == u.ch and cp.maxStage > u.st)
        or (cp.cleared and cp.cleared[u.ch .. "-" .. u.st])
    local today = U.DayIndex()
    local can = unlocked and s.dayClaimed.__clear and s.att.lastDay ~= today and s.att.claimedDays < #D.Attendance.days
    return { unlocked = unlocked, claimed = s.att.claimedDays, canClaim = can and true or false,
        next = D.Attendance.days[s.att.claimedDays + 1] }
end

local function grantItem(hero, key, n, reason)
    if key == "legendaryArtifactSummon" and ns.Artifacts and ns.Artifacts.List then
        local pool = {}
        for _, a in ipairs(ns.Artifacts.List()) do if a.grade == 5 then pool[#pool + 1] = a.id end end
        for _ = 1, n do
            if #pool > 0 then ns.Artifacts.Grant(hero, pool[U.rng:Int(1, #pool)]) end
        end
        return
    end
    Hero.Add(hero, key, n, reason)
end

function I.ClaimAttendance(hero)
    local st = I.AttendanceState(hero)
    if not st.canClaim then
        if not st.unlocked then return false, "챕터 3-2 클리어 후 이용할 수 있습니다." end
        return false, "일일 미션 8개를 완료하면 출석할 수 있습니다."
    end
    local s = hero.income
    local row = st.next
    s.att.claimedDays = s.att.claimedDays + 1
    s.att.lastDay = U.DayIndex()
    grantItem(hero, row[1], row[2], "attendance")
    return true, row
end

---------------------------------------------------------------------------
-- free daily claims (ad rewards without ads)
---------------------------------------------------------------------------
function I.ClaimFree(hero, id)
    local s = hero.income
    if s.freeClaimed[id] then return false, "오늘은 이미 받았습니다." end
    for _, f in ipairs(D.FreeDaily) do
        if f.id == id then
            if f.summon then
                local key = f.summon == "weapon" and "weaponTicket" or "companionTicket"
                Hero.Add(hero, key, f.count, "freeSummon")
                local res, err = ns.Summon.Pull(hero, f.summon, f.count)
                if not res then
                    Hero.Spend(hero, key, f.count)
                    return false, err
                end
                s.freeClaimed[id] = true
                return true, res
            end
            if f.booster then
                hero.booster = { untilTime = U.Now() + f.booster.seconds, exp = f.booster.exp, gold = f.booster.gold }
                Hero.Changed(hero, "booster")
            end
            if f.rewards then Hero.Grant(hero, f.rewards, "freeDaily") end
            s.freeClaimed[id] = true
            return true
        end
    end
    return false, "알 수 없는 보상"
end

-- wallet EXP boosters (경험치 부스터 100% / 50%); a new one replaces the running one
function I.UseBooster(hero, key)
    local b = D.Boosters[key]
    if not b then return false end
    if not Hero.Spend(hero, key, 1, "booster") then return false, D.CurrencyName(key) .. "이(가) 없습니다." end
    hero.expBoosterBuff = { untilTime = U.Now() + b.seconds, exp = b.exp }
    Hero.Changed(hero, "booster")
    return true
end

Hero.RegisterStatProvider("expBoosterItem", function(hero, acc)
    local b = hero.expBoosterBuff
    if b and U.Now() < (b.untilTime or 0) then acc:Add("BonusExpPercent", b.exp or 0) end
end)

Hero.RegisterStatProvider("booster", function(hero, acc)
    local b = hero.booster
    if b and U.Now() < (b.untilTime or 0) then
        acc:Add("BonusExpPercent", b.exp or 0)
        acc:Add("BonusGoldPercent", b.gold or 0)
    end
end)

---------------------------------------------------------------------------
-- red-diamond shop
---------------------------------------------------------------------------
function I.ShopUnlocked(hero, row)
    if not row.unlock then return true end
    local cp = hero.campaign
    local ch, st = row.unlock[1], row.unlock[2]
    return cp.maxChapter > ch or (cp.cleared and cp.cleared[ch .. "-" .. st]) or false
end

function I.BuyRed(hero, idx)
    local row = D.RedShop[idx]
    if not row then return false end
    local s = hero.income
    if not I.ShopUnlocked(hero, row) then return false, "아직 열리지 않았습니다." end
    if row.once and s.shopOnce[idx] then return false, "이미 구매했습니다." end
    local bought = s.weekShop[idx] or 0
    if row.limit and bought >= row.limit then return false, "이번 주 구매 한도입니다." end
    if not Hero.Spend(hero, "redDia", row.price, "redShop") then return false, "레드 다이아가 부족합니다." end
    s.weekShop[idx] = bought + 1
    if row.once then s.shopOnce[idx] = true end
    Hero.Grant(hero, row.items, "redShop")
    return true
end

---------------------------------------------------------------------------
-- 14-day newcomer missions
---------------------------------------------------------------------------
local function check(hero, spec)
    local kind, arg = spec:match("^([%w_]+):(.+)$")
    local n = tonumber(arg)
    local p = hero.income.progress
    if kind == "free" then return true, 1, 1 end
    if kind == "kill" then
        local v = p.killTotal or 0
        return v >= n, v, n
    end
    if kind == "level" then return hero.level >= n, hero.level, n end
    if kind == "elite" then
        local lv = ns.Equipment and ns.Equipment.EliteInfo and ns.Equipment.EliteInfo(hero).level or 0
        return lv >= n, lv, n
    end
    local sk = kind:match("^summonLv_(%a+)$")
    if sk then
        local info = ns.Summon.Info(hero, sk)
        return info.level >= n, info.level, n
    end
    local dk = kind:match("^dungeon_(%a+)$")
    if dk then
        local v = p["dungeon_" .. dk] or 0
        return v >= n, v, n
    end
    if kind == "ability" then
        local lv = hero.ability and hero.ability.level or 1
        return lv >= n, lv, n
    end
    if kind == "heroPower" then
        local st = ns.HeroPower and ns.HeroPower.Stage(hero) or 1
        return st >= n, st, n
    end
    if kind == "companionGrade" then
        local best = 0
        for sid in pairs(hero.companions and hero.companions.owned or {}) do
            local c = ns.Companions.Def(sid)
            if c and c.grade > best then best = c.grade end
        end
        return best >= n + 1, best, n + 1
    end
    if kind == "arena" then return (p.arenaTotal or 0) >= n, p.arenaTotal or 0, n end
    if kind == "arenaTier" then return (p.arenaTier or 1) >= n, p.arenaTier or 1, n end
    local v = p[kind] or 0
    return v >= n, v, n
end
I.Check = check

function I.Newcomer(hero)
    local nc = hero.income.newcomer
    local dayNo = U.DayIndex() - nc.start + 1
    local out = {}
    for d, day in ipairs(D.Newcomer14.days) do
        local rows = {}
        for i, spec in ipairs(day.m) do
            local ok, cur, goal = check(hero, spec)
            rows[i] = { spec = spec, done = ok, cur = cur, goal = goal, claimed = nc.claimed[d .. ":" .. i] }
        end
        out[d] = { open = d <= dayNo, rows = rows, clear = day.clear, clearClaimed = nc.dayClaimed[d] }
    end
    return out, nc.total, dayNo
end

function I.ClaimNewcomer(hero, d, i)
    local nc = hero.income.newcomer
    local list, _, dayNo = I.Newcomer(hero)
    local row = list[d] and list[d].rows[i]
    if not row then return false end
    if d > dayNo then return false, "아직 열리지 않은 날짜입니다." end
    if row.claimed then return false, "이미 받았습니다." end
    if not row.done then return false, "아직 완료하지 않았습니다." end
    nc.claimed[d .. ":" .. i] = true
    nc.total = nc.total + 1
    Hero.Grant(hero, D.Newcomer14.perMission, "newcomer")
    if nc.total == D.Newcomer14.finalAt and ns.Companions then
        local pool = ns.Companions.ByGrade(4)  -- 유니크
        if #pool > 0 then ns.Companions.Add(hero, pool[U.rng:Int(1, #pool)], 1) end
    end
    return true
end

function I.ClaimNewcomerDay(hero, d)
    local nc = hero.income.newcomer
    local list = I.Newcomer(hero)
    local day = list[d]
    if not day or nc.dayClaimed[d] then return false, "받을 수 없습니다." end
    for _, r in ipairs(day.rows) do if not r.claimed then return false, "5개 미션을 모두 받아야 합니다." end end
    nc.dayClaimed[d] = true
    nc.total = nc.total + 1
    Hero.Grant(hero, day.clear, "newcomerDay")
    return true
end
