-- 결투장 (Arena): asynchronous PvP between players who have this addon.
-- Opponents are discovered over guild / party / the addon channel, their
-- battle profile (stats + skills) is cached, and the fight is simulated
-- locally with a seed both clients can reproduce.
--
-- Data (research/spec/research-income.md §6.2, KR after 2026-09-22):
--   tickets 5 per day (cap 20), 3 free opponent refreshes (+1 per 10 min) then 150 레드 다이아,
--   daily / weekly tier rewards (아레나 코인, 스타포스 강화 주문서), shop limits.
-- Tiers are ranked among known addon users (the user's choice), score thresholds as fallback.
--
-- API
--   ns.Arena.Peers()                     -> sorted list of known opponents
--   ns.Arena.Opponents(hero)             -> current matchmaking list (3)
--   ns.Arena.Refresh(hero)               -> ok, err
--   ns.Arena.Challenge(hero, name)       -> ok, err   (starts the battle)
--   ns.Arena.Tier(hero)                  -> tierIndex, tierRow, rank, total
--   ns.Arena.Shop / ns.Arena.Buy(hero, itemKey, n)
--   ns.Arena.Log(hero)                   -> recent attack / defense records
local ADDON, ns = ...
local U = ns.U
local D = ns.Data
local Hero = ns.Hero

local A = {}
ns.Arena = A

A.VERSION = 1
A.TICKETS_PER_DAY = 5
A.TICKET_CAP = 20
A.FREE_REFRESH = 3
A.REFRESH_REGEN_SEC = 600
A.REFRESH_COST_DIA = 150
A.SNAPSHOT_TTL = 3600           -- re-request profiles older than 1 h
A.HELLO_INTERVAL = 300
-- research/spec/research-arena.md
A.START_SCORE = 1000            -- World Arena / Colosseum start; matches observed arena week-end scores
A.WIN_SCORE = 20                -- about +20, scaled by CP (doubling own CP halves the gain)
A.DEFENSE_WIN_SCORE = 5
A.DEFENSE_LOSS_SCORE = -9
A.WIN_COINS, A.LOSS_COINS = 30, 20
A.QUICK_BATTLE_CP = 5           -- quick battle needs 5x the opponent's CP
-- win medals (100/500/1,000/2,000/3,000 attack wins, Main Stat +30 each) are in Data/Medals.lua
-- PROVISIONAL: not published
A.TIME_LIMIT_MS = 60000         -- typical fight ~15 s; time-over is the attacker's loss
A.LOSS_SCORE = -10
A.POTION_PVP_RATIO = 0.5
-- PROVISIONAL tier -> weekly benefit (which tier gives which buff is not published)
A.BUFFS = {
    { minTier = 6, name = "전문가 혜택", gold = 80, exp = 0 },
    { minTier = 11, name = "장인 혜택", gold = 160, exp = 0 },
    { minTier = 16, name = "달인 혜택", gold = 190, exp = 50 },
    { minTier = 21, name = "명인 혜택", gold = 220, exp = 100 },
    { minTier = 23, name = "패왕 혜택", gold = 250, exp = 150 },
}

-- lowest -> highest (index 1 = 브론즈1)
A.TIERS = {
    { name = "브론즈1", daily = 500, weekly = 1000, sf = 4 },
    { name = "실버1", daily = 600, weekly = 1200, sf = 6 },
    { name = "골드1", daily = 700, weekly = 1400, sf = 8 },
    { name = "플래티넘1", daily = 800, weekly = 1600, sf = 10 },
    { name = "다이아몬드1", daily = 850, weekly = 1700, sf = 12 },
    { name = "마스터5", daily = 880, weekly = 1760, sf = 14 },
    { name = "마스터4", daily = 910, weekly = 1820, sf = 16 },
    { name = "마스터3", daily = 940, weekly = 1880, sf = 18 },
    { name = "마스터2", daily = 970, weekly = 1940, sf = 20 },
    { name = "마스터1", daily = 1000, weekly = 2000, sf = 22 },
    { name = "그랜드마스터5", daily = 1050, weekly = 2100, sf = 24 },
    { name = "그랜드마스터4", daily = 1100, weekly = 2200, sf = 26 },
    { name = "그랜드마스터3", daily = 1150, weekly = 2300, sf = 28 },
    { name = "그랜드마스터2", daily = 1200, weekly = 2400, sf = 30 },
    { name = "그랜드마스터1", daily = 1250, weekly = 2500, sf = 32 },
    { name = "챌린저5", daily = 1300, weekly = 2600, sf = 34 },
    { name = "챌린저4", daily = 1400, weekly = 2800, sf = 36 },
    { name = "챌린저3", daily = 1500, weekly = 3000, sf = 40 },
    { name = "챌린저2", daily = 1600, weekly = 3200, sf = 44 },
    { name = "챌린저1", daily = 1700, weekly = 3400, sf = 48 },
    { name = "챔피언3", daily = 1800, weekly = 3600, sf = 52 },
    { name = "챔피언2", daily = 1900, weekly = 3800, sf = 56 },
    { name = "챔피언1", daily = 2000, weekly = 4000, sf = 60 },
}
-- PROVISIONAL: the share of players per tier is not published. Top rank % -> tier.
A.TIER_TOP_PERCENT = { 100, 90, 80, 70, 60, 52, 46, 40, 35, 30, 26, 22, 18, 15, 12, 10, 8, 6, 4.5, 3, 2, 1, 0.5 }
-- fallback when fewer than 10 addon users are known: score thresholds
A.TIER_SCORE = { 0, 1050, 1100, 1150, 1200, 1250, 1300, 1350, 1400, 1450, 1500, 1550, 1600, 1650, 1700, 1750,
    1800, 1850, 1900, 1950, 2000, 2050, 2100 }

-- shop (KR weekly limits; prices from the global guide where KR is unknown)
A.SHOP = {
    { key = "artifactChest", n = 1, price = 500, weekly = 10 },
    { key = "starforceScroll", n = 1, price = 150, weekly = 25 },
    { key = "journeyEnergy", n = 1, price = 300, weekly = 5, provisional = true },  -- PROVISIONAL price
}

---------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------
Hero.RegisterSystem("arena", {
    init = function(hero)
        hero.arena = hero.arena or {
            score = A.START_SCORE, wins = 0, losses = 0, defWins = 0, defLosses = 0,
            tickets = A.TICKETS_PER_DAY, refresh = A.FREE_REFRESH, refreshAt = U.Now(),
            opponents = {}, log = {}, bought = {}, attempts = 0, best = A.START_SCORE,
        }
        hero.arena.bought = hero.arena.bought or {}
    end,
    daily = function(hero)
        local ar = hero.arena
        ar.tickets = math.min(A.TICKET_CAP, (ar.tickets or 0) + A.TICKETS_PER_DAY)
        local idx = A.Tier(hero)
        local row = A.TIERS[idx]
        -- the daily settlement pays only if at least one battle was played that day
        if row and ar.playedToday then Hero.Add(hero, "arenaCoin", row.daily, "arenaDaily") end
        ar.lastDaily = { tier = idx, coins = ar.playedToday and row and row.daily or 0 }
        ar.playedToday = false
    end,
    weekly = function(hero)
        local ar = hero.arena
        local idx = A.Tier(hero)
        local row = A.TIERS[idx]
        if row then
            Hero.Add(hero, "arenaCoin", row.weekly, "arenaWeekly")
            Hero.Add(hero, "starforceScroll", row.sf, "arenaWeekly")
        end
        ar.lastWeekly = { tier = idx, coins = row and row.weekly, sf = row and row.sf }
        ar.bought = {}
        -- weekly benefit until the next settlement, then ranking points reset
        ar.buff = nil
        for _, bf in ipairs(A.BUFFS) do if idx >= bf.minTier then ar.buff = bf end end
        ar.score = A.START_SCORE
    end,
})

local function db()
    ns.db.arena = ns.db.arena or {}
    local a = ns.db.arena
    a.peers = a.peers or {}          -- [name] = { name, job, level, cp, score, seen, race, sex, class }
    a.snapshots = a.snapshots or {}  -- [name] = { profile, at, looks, race, sex }
    return a
end

---------------------------------------------------------------------------
-- Tickets / refresh
---------------------------------------------------------------------------
function A.UpdateRefresh(hero)
    local ar = hero.arena
    local now = U.Now()
    if ar.refresh < A.FREE_REFRESH then
        local gained = math.floor((now - (ar.refreshAt or now)) / A.REFRESH_REGEN_SEC)
        if gained > 0 then
            ar.refresh = math.min(A.FREE_REFRESH, ar.refresh + gained)
            ar.refreshAt = (ar.refreshAt or now) + gained * A.REFRESH_REGEN_SEC
        end
    else
        ar.refreshAt = now
    end
end

---------------------------------------------------------------------------
-- Peers & ranking
---------------------------------------------------------------------------
function A.Peers()
    local out = {}
    local me = UnitName and UnitName("player")
    for name, p in pairs(db().peers) do
        if name ~= me then out[#out + 1] = p end
    end
    table.sort(out, function(a, b) return (a.score or 0) > (b.score or 0) end)
    return out
end

function A.Tier(hero)
    local score = hero.arena.score or A.START_SCORE
    local peers = A.Peers()
    local total = #peers + 1
    local rank = 1
    for _, p in ipairs(peers) do if (p.score or 0) > score then rank = rank + 1 end end
    local idx = 1
    if total >= 10 then
        local pct = rank / total * 100
        for i = #A.TIER_TOP_PERCENT, 1, -1 do
            if pct <= A.TIER_TOP_PERCENT[i] then idx = i break end
        end
    else
        for i = #A.TIER_SCORE, 1, -1 do
            if score >= A.TIER_SCORE[i] then idx = i break end
        end
    end
    return idx, A.TIERS[idx], rank, total
end

-- 3 opponents near my score (one above, one similar, one below when possible)
function A.Pick(hero)
    local peers = A.Peers()
    local snaps = db().snapshots
    local list = {}
    for _, p in ipairs(peers) do if snaps[p.name] then list[#list + 1] = p end end
    local my = hero.arena.score
    table.sort(list, function(a, b) return math.abs((a.score or 0) - my) < math.abs((b.score or 0) - my) end)
    local out = {}
    for i = 1, math.min(3, #list) do out[i] = list[i].name end
    -- shuffle the order a little for variety
    if #list > 3 then
        local extra = list[U.rng:Int(4, #list)]
        out[3] = extra.name
    end
    hero.arena.opponents = out
    return out
end

function A.Opponents(hero)
    local ar = hero.arena
    local out = {}
    for _, name in ipairs(ar.opponents or {}) do
        local p = db().peers[name]
        if p and db().snapshots[name] then out[#out + 1] = p end
    end
    if #out == 0 then
        A.Pick(hero)
        for _, name in ipairs(ar.opponents) do out[#out + 1] = db().peers[name] end
    end
    return out
end

function A.Refresh(hero)
    A.UpdateRefresh(hero)
    local ar = hero.arena
    if ar.refresh > 0 then
        ar.refresh = ar.refresh - 1
        if ar.refresh == A.FREE_REFRESH - 1 then ar.refreshAt = U.Now() end
    elseif not Hero.Spend(hero, "redDia", A.REFRESH_COST_DIA, "arenaRefresh") then
        return false, "레드 다이아가 부족합니다."
    end
    A.Pick(hero)
    A.RequestSnapshots()
    return true
end

---------------------------------------------------------------------------
-- Battle
---------------------------------------------------------------------------
local Ctl = {}
Ctl.__index = Ctl

function Ctl:Update(b, dt)
    if not self.started then
        self.started = true
        local snap = self.snapshot
        local def = Hero.CreatureDef(snap.profile, 2, 1600)
        def.name = self.opponent
        def.isBoss = false
        def.arenaLooks = snap.looks
        def.arenaRace = snap.race
        def.arenaSex = snap.sex
        local c = b:AddCreature(def)
        self.enemy = c
        b:SetPvpBaseline(c, def)
        b:SetPvpBaseline(b.heroCreature, Hero.CreatureDef(self.myProfile, 1, 0))
        -- both sides' main companions join
        if ns.Supporters then
            ns.Supporters.Setup(b, hero, self.myProfile, {})
            ns.Supporters.Setup(b, nil, snap.profile, {}, c)
        end
    end
    local hero, enemy = b.heroCreature, self.enemy
    if not hero.alive then b:End("fail") return end
    if not enemy.alive then b:End("clear") return end
end

function Ctl:OnEnd(b, reason)
    local hero = self.hero
    local won
    if reason == "clear" then won = true
    elseif reason == "fail" then won = false
    else
        won = false   -- time-over counts as the attacker's loss
    end
    A.Finish(hero, self.opponent, won, self.seed)
end

-- arena damage: boss damage never applies (global wiki Character_Stats)
local function pvpStats(stats)
    local out = { adds = {}, ratios = {}, chains = {}, mults = {} }
    for k, v in pairs(stats.adds or {}) do out.adds[k] = v end
    for k, v in pairs(stats.ratios or {}) do out.ratios[k] = v end
    for k, l in pairs(stats.chains or {}) do out.chains[k] = { unpack(l) } end
    for k, l in pairs(stats.mults or {}) do out.mults[k] = { unpack(l) } end
    out.adds.AttackPowerToBoss = 0
    return out
end
A.PvpStats = pvpStats

function A.CanQuick(hero, name)
    local p = db().peers[name]
    local my = ns.Game.profile and Hero.PvpCombatPower(ns.Game.profile) or 0
    return p and (p.cp or 0) > 0 and my >= (p.cp or 0) * A.QUICK_BATTLE_CP
end

function A.Challenge(hero, name, quick)
    local ar = hero.arena
    if (ar.tickets or 0) <= 0 then return false, "결투장 입장권이 없습니다." end
    local snap = db().snapshots[name]
    if not snap then return false, "상대 정보를 아직 받지 못했습니다." end
    if ns.Game.mode ~= "hunt" then return false, "다른 콘텐츠 진행 중입니다." end
    ar.tickets = ar.tickets - 1
    ar.attempts = (ar.attempts or 0) + 1
    local me = UnitName and UnitName("player") or hero.name
    local seed = U.HashString(me .. ">" .. name .. "#" .. U.DayIndex() .. "#" .. ar.attempts)
    local profile = Hero.BuildProfile(hero)
    profile.stats = pvpStats(profile.stats)
    snap.profile.stats = pvpStats(snap.profile.stats)
    local ctl = setmetatable({ hero = hero, opponent = name, snapshot = snap, seed = seed, kind = "arena",
        title = "결투장: " .. name, timeLimit = A.TIME_LIMIT_MS, myProfile = profile,
        background = "Interface\\Glues\\LoadingScreens\\LoadScreenWarsongGulch" }, Ctl)
    ar.playedToday = true
    local b = ns.Game.StartContent(ctl, { seed = seed, profile = profile, dungeonType = "Arena", timeLimitMs = A.TIME_LIMIT_MS,
        noSupporters = true })
    if quick and A.CanQuick(hero, name) then
        -- 빠른 전투: same auto-battle, resolved instantly
        while not b.ended and b.time < A.TIME_LIMIT_MS + 1000 do b:Step() end
    end
    return true
end

function A.WinScore(hero, opponent)
    local p = db().peers[opponent]
    local my = ns.Game.profile and Hero.PvpCombatPower(ns.Game.profile) or 0
    local opp = p and p.cp or my
    if my <= 0 or opp <= 0 then return A.WIN_SCORE end
    return math.max(1, math.floor(A.WIN_SCORE * U.clamp(opp / my, 0.25, 4) + 0.5))
end

function A.Finish(hero, opponent, won, seed)
    local ar = hero.arena
    local delta = won and A.WinScore(hero, opponent) or A.LOSS_SCORE
    Hero.Add(hero, "arenaCoin", won and A.WIN_COINS or A.LOSS_COINS, "arenaBattle")
    ar.score = math.max(0, ar.score + delta)
    ar.best = math.max(ar.best or 0, ar.score)
    if won then ar.wins = ar.wins + 1 else ar.losses = ar.losses + 1 end
    table.insert(ar.log, 1, { at = U.Now(), kind = "attack", opp = opponent, won = won, delta = delta, score = ar.score })
    while #ar.log > 30 do table.remove(ar.log) end
    ns.Fire("ARENA_RESULT", hero, opponent, won, delta)
    if ns.Comm then
        ns.Comm.Send("ARES", { v = A.VERSION, won = won, seed = seed, score = ar.score }, "WHISPER", opponent)
    end
    A.SayHello()
end

---------------------------------------------------------------------------
-- Shop
---------------------------------------------------------------------------
function A.Buy(hero, idx, count)
    local row = A.SHOP[idx]
    if not row then return false end
    count = count or 1
    local ar = hero.arena
    local bought = ar.bought[row.key] or 0
    if bought + count > row.weekly then return false, "이번 주 구매 한도를 넘었습니다." end
    if not Hero.Spend(hero, "arenaCoin", row.price * count, "arenaShop") then return false, "결투장 주화가 부족합니다." end
    ar.bought[row.key] = bought + count
    Hero.Add(hero, row.key, row.n * count, "arenaShop")
    return true
end

function A.Log(hero) return hero.arena.log end

---------------------------------------------------------------------------
-- Network
---------------------------------------------------------------------------
local function myInfo()
    local hero = Hero.Active()
    if not hero then return nil end
    local cp = ns.Game.profile and Hero.PvpCombatPower(ns.Game.profile) or 0
    local race, sex, class
    if UnitRace then race = select(2, UnitRace("player")) end
    if UnitSex then sex = UnitSex("player") end
    if UnitClass then class = select(2, UnitClass("player")) end
    return { v = A.VERSION, job = hero.jobKey, level = hero.level, cp = cp, score = hero.arena.score,
        race = race, sex = sex, class = class }
end

function A.SayHello()
    local info = myInfo()
    if info and ns.Comm then ns.Comm.Broadcast("AHI", info) end
end

function A.RequestSnapshots()
    local now = U.Now()
    for name, p in pairs(db().peers) do
        local s = db().snapshots[name]
        if (not s or now - (s.at or 0) > A.SNAPSHOT_TTL) and now - (p.seen or 0) < 3600 and not p.requested then
            p.requested = now
            ns.Comm.Send("AREQ", { v = A.VERSION }, "WHISPER", name)
        elseif p.requested and now - p.requested > 120 then
            p.requested = nil
        end
    end
end

local function onHello(sender, info)
    if type(info) ~= "table" or info.v ~= A.VERSION then return end
    local p = db().peers[sender] or { name = sender }
    p.job, p.level, p.cp, p.score = info.job, info.level, info.cp, info.score
    p.race, p.sex, p.class = info.race, info.sex, info.class
    p.seen = U.Now()
    db().peers[sender] = p
    ns.Fire("ARENA_PEERS")
end

local function onRequest(sender)
    local hero = Hero.Active()
    if not hero then return end
    local profile = Hero.BuildProfile(hero)
    local looks = ns.Skin and ns.Skin.GearLooks(hero) or {}
    local info = myInfo()
    ns.Comm.Send("APROF", { v = A.VERSION, profile = profile, looks = looks, info = info }, "WHISPER", sender)
end

local function validProfile(p)
    return type(p) == "table" and type(p.stats) == "table" and type(p.skillSet) == "table"
        and ns.SkillBook.JobByKey(p.jobKey) ~= nil and type(p.level) == "number"
end

local function onProfile(sender, data)
    if type(data) ~= "table" or data.v ~= A.VERSION or not validProfile(data.profile) then return end
    data.profile.name = sender
    db().snapshots[sender] = { profile = data.profile, looks = data.looks, at = U.Now(),
        race = data.info and data.info.race, sex = data.info and data.info.sex }
    if data.info then onHello(sender, data.info) end
    local p = db().peers[sender]
    if p then p.requested = nil end
    ns.Fire("ARENA_PEERS")
end

local function onResult(sender, data)
    local hero = Hero.Active()
    if not hero or type(data) ~= "table" then return end
    local ar = hero.arena
    -- the attacker's win is our defense loss
    local defWon = not data.won
    local delta = defWon and A.DEFENSE_WIN_SCORE or A.DEFENSE_LOSS_SCORE
    ar.score = math.max(0, ar.score + delta)
    if defWon then ar.defWins = (ar.defWins or 0) + 1 else ar.defLosses = (ar.defLosses or 0) + 1 end
    table.insert(ar.log, 1, { at = U.Now(), kind = "defense", opp = sender, won = defWon, delta = delta, score = ar.score })
    while #ar.log > 30 do table.remove(ar.log) end
    local p = db().peers[sender]
    if p and data.score then p.score = data.score end
    ns.Fire("ARENA_DEFENSE", hero, sender, defWon)
end

if ns.Comm then
    ns.Comm.Register("AHI", onHello)
    ns.Comm.Register("AREQ", onRequest)
    ns.Comm.Register("APROF", onProfile)
    ns.Comm.Register("ARES", onResult)
end

ns.On("LOGIN", function()
    if not ns.Compat.NewTicker then return end
    ns.Compat.After(8, A.SayHello)
    ns.Compat.NewTicker(A.HELLO_INTERVAL, A.SayHello)
    ns.Compat.NewTicker(20, function()
        local hero = Hero.Active()
        if hero then A.UpdateRefresh(hero) end
        if ns.Comm then A.RequestSnapshots() end
    end)
end)

ns.RegisterSlash("arena", "결투장 상대 찾기(정보 다시 알리기)", function()
    A.SayHello()
    ns.Print("결투장: 주변 애드온 사용자에게 정보를 알렸습니다. 알려진 상대 %d명", #A.Peers())
end)

-- the weekly benefit buff
Hero.RegisterStatProvider("arena", function(hero, acc)
    local ar = hero.arena
    if not ar then return end
    if ar.buff then
        acc:Add("BonusGoldPercent", ar.buff.gold or 0)
        acc:Add("BonusExpPercent", ar.buff.exp or 0)
    end
end)
