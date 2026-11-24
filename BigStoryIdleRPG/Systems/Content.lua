-- Content core (던전/보스/길드): shared state, resets, AI allies, battle controller base,
-- reward granting, score conversion and the mode registry used by UI/ContentPanel.lua.
-- The modes live in Systems/ContentDungeons.lua, ContentBosses.lua, ContentParty.lua, ContentGuild.lua.
--
-- API
--   ns.Content.RegisterMode(key, def)        -- def = { order, title, group, info(hero, sel) -> lines,
--                                            --   selectors = {...}, actions = {...} } (see UI/ContentPanel.lua)
--   ns.Content.Modes()                       -> ordered list of mode defs
--   ns.Content.Start(hero, controller, opts) -> battle (wraps ns.Game.StartContent)
--   ns.Content.NewFight(proto, fields)       -> controller (base class C.Fight; proto overrides Setup/Tick/Finish...)
--   ns.Content.MakeAllies(hero, profile, n, rng) -> list of creature defs (AI party members)
--   ns.Content.Grant(hero, rewards, reason)  -- {key = n, exp = n, gear = {{code=...}}}; returns display lines
--   ns.Content.ConvertScore(raw, brackets)   -- guild nested-root score conversion
--   ns.Content.StageReached(hero, ch, st)    -- chapter progress gate (st = 0: chapter boss)
--   ns.Content.LastResult(hero, key)         -> { ok, reason, lines, at }
-- Events: "CONTENT_FINISHED"(hero, modeKey, result)
--
-- Co-op content (party quests, boss raids, guild raids, 마왕 발록 group) is entered SOLO; the empty
-- party slots are filled with AI allies generated from the player's own profile (user decision).
local ADDON, ns = ...
local U = ns.U
local D = ns.Data
local Hero = ns.Hero
local SB = ns.SkillBook

local C = {}
ns.Content = C

C.REVIVE_MS = 3000            -- same revive delay as chapter hunting (Systems/Campaign.lua)
-- PROVISIONAL: AI ally strength = player profile x random factor in [MIN, MAX] (flat stats only).
C.ALLY_STAT_MIN = 0.8
C.ALLY_STAT_MAX = 1.0
-- PROVISIONAL: guild content needs the player to be in a WoW guild ("길드 = 플레이어의 WoW 길드").
C.REQUIRE_GUILD = true

C.ALLY_NAMES = { "하늘", "바람", "별빛", "노을", "새벽", "구름", "은하", "단비", "가람", "누리", "다온", "라온",
    "미르", "보라", "솔빛", "아라", "여울", "윤슬", "이든", "한결", "해솔", "초롱", "푸름", "온새" }

---------------------------------------------------------------------------
-- Hero state
---------------------------------------------------------------------------
-- Sub-modules register their own state through C.RegisterState so that each file
-- owns its defaults and daily / weekly resets. Elapsed days are passed so a recharge
-- that happens server-side every day accumulates while the player is away.
C.states = {}
C.stateOrder = {}

function C.RegisterState(name, def)
    if not C.states[name] then table.insert(C.stateOrder, name) end
    C.states[name] = def
end

local function each(hookName, hero, ...)
    for _, name in ipairs(C.stateOrder) do
        local fn = C.states[name][hookName]
        if fn then
            local ok, err = pcall(fn, hero, ...)
            if not ok then ns.Print("|cffff4040콘텐츠 오류|r %s.%s: %s", name, hookName, tostring(err)) end
        end
    end
end

Hero.RegisterSystem("content", {
    init = function(hero)
        hero.content = hero.content or {}
        local ct = hero.content
        ct.last = ct.last or {}
        ct.gearInbox = ct.gearInbox or {}
        ct.buffs = ct.buffs or {}
        ct.day = ct.day or U.DayIndex()
        ct.week = ct.week or U.WeekIndex()
        each("init", hero, ct)
    end,
    daily = function(hero, day)
        local ct = hero.content
        local elapsed = math.max(1, day - (ct.day or day - 1))
        ct.day = day
        each("daily", hero, ct, elapsed, day)
    end,
    weekly = function(hero, week)
        local ct = hero.content
        local elapsed = math.max(1, week - (ct.week or week - 1))
        ct.week = week
        each("weekly", hero, ct, elapsed, week)
    end,
})

-- wallet top-up helpers
function C.Recharge(hero, key, add, cap)
    local have = Hero.Count(hero, key)
    local n = add
    if cap then n = math.min(add, math.max(0, cap - have)) end
    if n > 0 then Hero.Add(hero, key, n, "recharge") end
    return n
end

---------------------------------------------------------------------------
-- Mode registry (UI)
---------------------------------------------------------------------------
C.modes = {}
C.modeList = {}

function C.RegisterMode(key, def)
    def.key = key
    if not C.modes[key] then table.insert(C.modeList, def) end
    C.modes[key] = def
    table.sort(C.modeList, function(a, b) return (a.order or 99) < (b.order or 99) end)
end

function C.Modes() return C.modeList end

function C.LastResult(hero, key)
    return hero.content and hero.content.last[key]
end

---------------------------------------------------------------------------
-- Progress gates
---------------------------------------------------------------------------
-- st = 0 means the chapter boss (the next chapter is open)
function C.StageReached(hero, ch, st)
    local cp = hero.campaign
    if not cp then return false end
    if st == 0 then return cp.maxChapter > ch end
    if cp.maxChapter > ch then return true end
    return cp.maxChapter == ch and cp.maxStage >= st
end

function C.GateText(ch, st)
    if st == 0 then return string.format("%d챕터 보스 클리어", ch) end
    return string.format("%d-%d 클리어", ch, st)
end

function C.InGuild()
    if not C.REQUIRE_GUILD then return true end
    if IsInGuild then return IsInGuild() and true or false end
    return true
end

function C.GuildName()
    if GetGuildInfo then
        local name = GetGuildInfo("player")
        if name then return name end
    end
    return "길드"
end

---------------------------------------------------------------------------
-- Look (WoW skin): ns.Skin.ContentModel(kind, key) -> model, name
---------------------------------------------------------------------------
function C.Look(kind, key, fallbackName)
    local model, name
    if ns.Skin and ns.Skin.ContentModel then model, name = ns.Skin.ContentModel(kind, key) end
    local bg
    local cont = D.SkinWorld and D.SkinWorld.content
    local e = cont and cont[kind]
    if key and type(e) == "table" and not e[1] then e = e[key] end
    if type(e) == "table" and e[1] then e = e[1] end
    if type(e) == "table" then bg = e.loadingScreen end
    return model, name or fallbackName, bg
end

---------------------------------------------------------------------------
-- Rewards
---------------------------------------------------------------------------
local function fmt(n) return U.FormatNumber(n) end

function C.RewardLines(rewards)
    local lines = {}
    if not rewards then return lines end
    local keys = {}
    for k in pairs(rewards) do if k ~= "gear" and k ~= "exp" then keys[#keys + 1] = k end end
    table.sort(keys, function(a, b)
        local ca, cb = D.Currencies[a], D.Currencies[b]
        return ((ca and ca.order) or 999) < ((cb and cb.order) or 999)
    end)
    if rewards.exp and rewards.exp > 0 then lines[#lines + 1] = "경험치 " .. fmt(rewards.exp) end
    for _, k in ipairs(keys) do
        if rewards[k] > 0 then lines[#lines + 1] = string.format("%s %s", D.CurrencyName(k), fmt(rewards[k])) end
    end
    for _, g in ipairs(rewards.gear or {}) do
        local gd = D.Gear and D.Gear[g.code]
        local grade = gd and ns.Equipment and ns.Equipment.GradeName and
            (ns.Equipment.GradeName(gd.grade) .. " " .. ns.Equipment.TierName(gd.tier) .. " ") or ""
        lines[#lines + 1] = "장비: " .. grade .. (g.name or (gd and gd.name) or g.code)
    end
    return lines
end

function C.AddReward(acc, key, n)
    if not n or n == 0 then return end
    acc[key] = (acc[key] or 0) + n
end

-- gear goes to ns.Equipment.Give(hero, code, level) when that system exists, else waits in
-- hero.content.gearInbox (delivered on the next grant / login). A full bag auto-dismantles (Equipment).
function C.FlushGearInbox(hero)
    local inbox = hero.content and hero.content.gearInbox
    if not (inbox and #inbox > 0) then return end
    local E = ns.Equipment
    if not (E and E.Give) then return end
    local keep = {}
    for _, g in ipairs(inbox) do
        local ok, item = pcall(E.Give, hero, g.code, g.level)
        if not ok then keep[#keep + 1] = g
        elseif item then
            item.source = g.source
            if E.ItemName then g.name = E.ItemName(item) end
        end
    end
    hero.content.gearInbox = keep
end

function C.Grant(hero, rewards, reason)
    if not rewards then return {} end
    for k, v in pairs(rewards) do
        if k == "exp" then
            Hero.GainExp(hero, v)
        elseif k == "gear" then
            for _, g in ipairs(v) do
                g.source = g.source or reason
                g.at = U.Now()
                table.insert(hero.content.gearInbox, g)
            end
        elseif k == "eliteSummonPoint" and ns.Equipment and ns.Equipment.GainElitePoints then
            ns.Equipment.GainElitePoints(hero, v)   -- respects the elite gauge cap of the equipment system
        elseif type(v) == "number" and v > 0 then
            Hero.Add(hero, k, v, reason)
        end
    end
    C.FlushGearInbox(hero)
    return C.RewardLines(rewards)
end

ns.On("HERO_ACTIVATED", function(hero) if hero.content then C.FlushGearInbox(hero) end end)

-- weighted pick from rows { {permille=..}, ... }; returns the row or nil (remainder)
function C.PickPermille(rows, rng, field)
    field = field or "permille"
    local r = (rng or U.rng):Float() * 1000
    for _, row in ipairs(rows) do
        r = r - (row[field] or 0)
        if r < 0 then return row end
    end
    return nil
end

---------------------------------------------------------------------------
-- Timed buffs from content rewards (EXP / meso %), e.g. 길드 보스 대전 win +16% for 7 days
---------------------------------------------------------------------------
-- buff = { id, nameKo, until (epoch s), stats = {StatType = raw} , excludeGuild = bool }
function C.AddBuff(hero, buff)
    local list = hero.content.buffs
    for i = #list, 1, -1 do if list[i].id == buff.id then table.remove(list, i) end end
    list[#list + 1] = buff
    Hero.Changed(hero, "contentBuff")
end

function C.ActiveBuffs(hero)
    local out, now = {}, U.Now()
    for _, b in ipairs(hero.content and hero.content.buffs or {}) do
        if (b["until"] or 0) > now then out[#out + 1] = b end
    end
    return out
end

Hero.RegisterStatProvider("contentBuffs", function(hero, acc)
    if not hero.content then return end
    for _, b in ipairs(C.ActiveBuffs(hero)) do
        if not (b.excludeGuild and C.buildingGuildProfile) then
            for stat, v in pairs(b.stats or {}) do acc:Add(stat, v) end
        end
    end
end)

---------------------------------------------------------------------------
-- Guild score conversion (19 brackets of nested roots, guild.html)
-- candidate = A + R^(1/n); above cap T: R = (candidate - T)^n, A = T, next bracket.
---------------------------------------------------------------------------
function C.ConvertScore(raw, brackets)
    if not raw or raw <= 0 then return 0 end
    local A, R = 0, raw
    for _, br in ipairs(brackets) do
        local cand = A + R ^ (1 / br.n)
        if br.cap and cand > br.cap then
            R = (cand - br.cap) ^ br.n
            A = br.cap
        else
            return math.floor(cand)
        end
    end
    return math.floor(A)
end

-- thresholds = { {min = score, ...row}, ... } sorted best first; returns the first row met
function C.TierFor(score, rows, field)
    field = field or "min"
    for i, row in ipairs(rows) do
        if score >= (row[field] or math.huge) then return row, i end
    end
end

---------------------------------------------------------------------------
-- AI allies (party slots filled by generated characters)
---------------------------------------------------------------------------
local FLAT = { Attack = true, MaxHp = true, MaxMp = true, Defence = true, Str = true, Dex = true, Int = true,
    Luk = true, MainStat = true }
local MAIN_KEY = { STR = "Str", DEX = "Dex", INT = "Int", LUK = "Luk" }

-- copy the player's profile stats onto another job: main/sub stat moved to the ally job's
-- main/sub stat, flat stats scaled by factor
function C.RemapStats(stats, fromJob, toJob, factor)
    local out = { adds = {}, ratios = {}, chains = {}, mults = {} }
    local map = {}
    if fromJob and toJob then
        local fm, fs = MAIN_KEY[fromJob.mainStat], MAIN_KEY[fromJob.subStat]
        local tm, ts = MAIN_KEY[toJob.mainStat], MAIN_KEY[toJob.subStat]
        if fm and tm and fm ~= tm then map[fm], map[tm] = tm, fm end
        if fs and ts and fs ~= ts and not map[fs] and not map[ts] then map[fs], map[ts] = ts, fs end
    end
    for k, v in pairs(stats.adds or {}) do
        local key = map[k] or k
        out.adds[key] = (out.adds[key] or 0) + (FLAT[k] and math.floor(v * factor) or v)
    end
    for k, v in pairs(stats.ratios or {}) do
        local key = map[k] or k
        out.ratios[key] = (out.ratios[key] or 0) + v
    end
    for k, list in pairs(stats.chains or {}) do
        local l = {}
        for i = 1, #list do l[i] = list[i] end
        out.chains[k] = l
    end
    for k, list in pairs(stats.mults or {}) do
        local l = {}
        for i = 1, #list do l[i] = list[i] end
        out.mults[k] = l
    end
    return out
end

-- n AI allies with distinct random jobs (other than the player's when possible)
function C.MakeAllies(hero, profile, n, rng)
    rng = rng or U.rng
    local defs = {}
    if not n or n <= 0 then return defs end
    local jobs = {}
    for _, j in ipairs(D.Jobs) do
        if j.key ~= (profile and profile.jobKey or hero.jobKey) then jobs[#jobs + 1] = j end
    end
    if #jobs < n then jobs = { unpack(D.Jobs) } end
    local names = {}
    for i, nm in ipairs(C.ALLY_NAMES) do names[i] = nm end
    local fromJob = SB.JobByKey(profile and profile.jobKey or hero.jobKey)
    local level = profile and profile.level or hero.level
    for i = 1, n do
        local ji = rng:Int(1, #jobs)
        local job = table.remove(jobs, ji)
        local nameIdx = rng:Int(1, #names)
        local name = table.remove(names, nameIdx) or ("동료" .. i)
        local learned = SB.AllMasteriesAt(job, level)
        local set = SB.Build({ jobKey = job.key, level = level, masteries = learned })
        local factor = C.ALLY_STAT_MIN + (C.ALLY_STAT_MAX - C.ALLY_STAT_MIN) * rng:Float()
        local skin = ns.Skin and ns.Skin.Job and ns.Skin.Job(job) or {}
        defs[#defs + 1] = {
            name = name,
            side = 1,
            isSupporter = true,
            isAiAlly = true,
            level = level,
            job = job,
            jobKey = job.key,
            jobDisplay = skin.display or job.mapleNameKo,
            stats = C.RemapStats(profile and profile.stats or {}, fromJob, job, factor),
            statFactor = factor,
            skillSet = set,
            x = -250 * i,
            facing = 1,
            radiusMm = 300,
        }
    end
    return defs
end

---------------------------------------------------------------------------
-- Monster definition for content creatures
---------------------------------------------------------------------------
-- o = { name, hp, atk, def, hit, avoid, boss, x, model, stationary, reach, interval, speed, radius, aggro,
--       shield, level, extra fields copied onto the def }
function C.MonsterDef(o)
    local def = {
        name = o.name or "몬스터",
        side = 2,
        level = o.level or 1,
        isBoss = o.boss or false,
        x = o.x or 2000,
        stats = { adds = {
            MaxHp = o.hp or 1,
            Attack = o.atk or 0,
            Defence = o.def or 0,
            -- PROVISIONAL: content rows without a hit column use hit = avoid (every boss row that has
            -- both columns in the client data has hit == avoid)
            HitChance = o.hit or o.avoid or 0,
            AvoidChance = o.avoid or 0,
        } },
        radiusMm = o.radius or (o.boss and 500 or 300),
        reachMm = o.reach or (o.boss and 1200 or 500),
        speedMms = o.speed or (o.boss and 600 or 900),
        attackIntervalMs = o.interval or (o.boss and 2500 or 2000),
        stationary = o.stationary,
        aggroMm = o.aggro,
        model = o.model,
    }
    if o.extra then for k, v in pairs(o.extra) do def[k] = v end end
    return def
end

---------------------------------------------------------------------------
-- Battle controller base
---------------------------------------------------------------------------
-- fields: kind, modeKey, title, timeLimit (ms), dungeonType, difficulty, allies (count),
--   teamDeaths (nil = no revive pool: a side with nobody alive fails), perUserDeaths,
--   revive (true = unlimited revives), noSupporter, background
local Fight = {}
Fight.__index = Fight
C.Fight = Fight

function C.NewFight(proto, fields)
    local o = fields or {}
    setmetatable(o, proto or Fight)
    o.damage = 0          -- all damage dealt by the player side (incl. shield absorption)
    o.heroDamage = 0      -- damage dealt by the player (and the player's summons)
    o.deaths = 0
    o.userDeaths = {}
    return o
end

function C.Proto()
    local p = setmetatable({}, { __index = Fight })
    p.__index = p
    return p
end

function C.ProfileFor(hero)
    if C.profileOverride then return C.profileOverride end
    return Hero.BuildProfile(hero)
end

-- a content battle (not hunting / chapter challenge) is running
function C.Busy()
    local G = ns.Game
    local b = G and G.battle
    if not b or b.ended then return false end
    local m = G.mode
    return m ~= "hunt" and m ~= "challenge" and m ~= "boss"
end

function C.Start(hero, ctl, opts)
    opts = opts or {}
    if C.Busy() then return nil, "다른 콘텐츠를 진행 중입니다." end
    opts.dungeonType = opts.dungeonType or ctl.dungeonType or "Campaign"
    opts.difficulty = opts.difficulty or ctl.difficulty
    opts.noSupporters = opts.noSupporters or ctl.noSupporter
    if ctl.guildContent then C.buildingGuildProfile = true end
    local okP, prof = pcall(C.ProfileFor, hero)
    C.buildingGuildProfile = nil
    if not okP then return nil, tostring(prof) end
    opts.profile = opts.profile or prof
    ctl.profile = opts.profile
    ctl.hero = hero
    local b = ns.Game.StartContent(ctl, opts)
    ctl.battle = b
    return b
end

function Fight:Hero() return self.hero end

-- install the damage hook (runs before the engine's death check)
function Fight:InstallHooks(b)
    local orig = b.hooks.onDamage
    local selfRef = self
    b.hooks.onDamage = function(bb, att, tgt, amount, crit, info)
        local ok, err = pcall(selfRef.HandleDamage, selfRef, bb, att, tgt, amount, crit, info)
        if not ok then ns.Print("|cffff4040콘텐츠 오류|r damage: %s", tostring(err)) end
        if orig then return orig(bb, att, tgt, amount, crit, info) end
    end
end

function Fight:IsPlayerSide(att)
    return att and att.side == 1
end

function Fight:IsPlayer(att, b)
    if not att then return false end
    local hc = b.heroCreature
    return att == hc or (att.owner and att.owner == hc)
end

function Fight:HandleDamage(b, att, tgt, amount, crit, info)
    if tgt.side == 2 then
        if tgt.hitCounter then
            -- special targets that take exactly 1 damage per hit (길드 수련장 특수 몬스터)
            tgt.hp = tgt.hp + amount - 1
            amount = 1
        end
        local absorbed = 0
        if tgt.trackShield then
            absorbed = math.max(0, (tgt.lastShield or 0) - (tgt.shield or 0))
            tgt.lastShield = tgt.shield
        end
        local dealt = amount + absorbed
        if self:IsPlayerSide(att) then
            self.damage = self.damage + dealt
            if self:IsPlayer(att, b) then self.heroDamage = self.heroDamage + dealt end
        end
        tgt.damageTaken = (tgt.damageTaken or 0) + dealt
        if tgt.infiniteHp then tgt.hp = tgt:Stat("MaxHp") end
        if self.OnDamage then self:OnDamage(b, att, tgt, dealt, info) end
    end
end

function Fight:Update(b, dt)
    if not self.started then
        self.started = true
        self.battle = b
        self:InstallHooks(b)
        local hc = b.heroCreature
        if hc then hc.userKey = "hero" end
        if (self.allies or 0) > 0 then
            local defs = C.MakeAllies(self.hero, self.profile, self.allies, b.rng)
            self.allyCreatures = {}
            for i, def in ipairs(defs) do
                def.x = (hc and hc.x or 0) - 250 * i
                local c = b:AddCreature(def)
                c.userKey = "ally" .. i
                self.allyCreatures[#self.allyCreatures + 1] = c
            end
        end
        if self.Setup then self:Setup(b) end
    end
    -- AI allies: MP regeneration and potions like the hero (the engine only does it for isHero)
    for _, c in ipairs(self.allyCreatures or {}) do
        if c.alive then
            local maxMp = c:Stat("MaxMp")
            c.mp = math.min(maxMp, c.mp + (c:Stat("MpRegen") * (1 + c:Stat("MpRegenRatio") / 1000)) * dt / 1000)
            b:Potions(c)
        end
    end
    self:UpdateRevives(b)
    if b.ended then return end
    if self.Tick then self:Tick(b, dt) end
    if b.ended then return end
    if self.UpdateTitle then self:UpdateTitle(b) end
    if b.time % 5000 < dt then self:CleanupEnemies(b) end
end

function Fight:CleanupEnemies(b)
    for i = #b.creatures, 1, -1 do
        local c = b.creatures[i]
        if not c.alive and c.side == 2 then table.remove(b.creatures, i) end
    end
end

function Fight:PlayerSideAlive(b)
    for _, c in ipairs(b.creatures) do
        if c.side == 1 and (c.isHero or c.isAiAlly) and (c.alive or c.reviveAt) then return true end
    end
    return false
end

function Fight:OnKill(b, victim)
    if victim.side == 1 then
        if not (victim.isHero or victim.isAiAlly) then return end
        self.deaths = self.deaths + 1
        local key = victim.userKey or tostring(victim.id)
        self.userDeaths[key] = (self.userDeaths[key] or 0) + 1
        local canRevive = self.revive
        if self.teamDeaths then canRevive = self.deaths <= self.teamDeaths end
        if canRevive and self.perUserDeaths and self.userDeaths[key] > self.perUserDeaths then canRevive = false end
        if canRevive then
            victim.reviveAt = b.time + C.REVIVE_MS
        end
        if self.teamDeaths and self.deaths > self.teamDeaths then
            b:End("fail")
            return
        end
        if not self:PlayerSideAlive(b) then b:End("fail") end
        return
    end
    if self.OnEnemyKilled then self:OnEnemyKilled(b, victim) end
end

function Fight:UpdateRevives(b)
    for _, c in ipairs(b.creatures) do
        if c.side == 1 and c.reviveAt and not c.alive and b.time >= c.reviveAt then
            c.reviveAt = nil
            c.alive = true
            c.hp = c:Stat("MaxHp")
            c.mp = c:Stat("MaxMp")
            c.states = {}
            c:Dirty()
            b:Hook("onRevive", c)
        end
    end
end

function Fight:OnEnd(b, reason)
    if self.finished then return end
    self.finished = true
    local ok, res = pcall(self.Finish, self, b, reason)
    if not ok then
        ns.Print("|cffff4040콘텐츠 오류|r %s: %s", tostring(self.modeKey), tostring(res))
        res = { ok = false, reason = "error", lines = { "오류: " .. tostring(res) } }
    end
    res = res or { ok = reason == "clear", reason = reason }
    C.Record(self.hero, self.modeKey or self.kind, res)
    if self.AfterFinish then pcall(self.AfterFinish, self, res) end
end

function Fight:Finish(b, reason)
    return { ok = reason == "clear", reason = reason }
end

-- helpers for subclasses -----------------------------------------------------
function Fight:Spawn(b, o)
    local def = C.MonsterDef(o)
    def.level = def.level > 1 and def.level or (self.profile and self.profile.level or 1)
    local c = b:AddCreature(def)
    if o.shield and o.shield > 0 then
        c.shield = o.shield
        c.trackShield = true
        c.lastShield = o.shield
    end
    if o.infinite then c.infiniteHp = true end
    if o.noDie then c.noDie = true end
    if o.untargetable then c.untargetable = true end
    c.tag = o.tag
    return c
end

function Fight:EnemiesAlive(b, tag)
    local n = 0
    for _, c in ipairs(b.creatures) do
        if c.alive and c.side == 2 and (not tag or c.tag == tag) then n = n + 1 end
    end
    return n
end

function Fight:SideOne(b)
    local out = {}
    for _, c in ipairs(b.creatures) do
        if c.side == 1 and c.alive then out[#out + 1] = c end
    end
    return out
end

function Fight:RemainingSec(b)
    if not b.timeLimit then return nil end
    return math.max(0, (b.timeLimit - b.time) / 1000)
end

function C.Record(hero, key, res)
    res.at = U.Now()
    hero.content.last[key] = res
    hero.content.lastKey = key
    ns.Fire("CONTENT_FINISHED", hero, key, res)
    if ns.UI and ns.UI.RefreshPanel then pcall(ns.UI.RefreshPanel) end
end

-- result helper: ok flag + header + reward lines
function C.Result(ok, reason, header, rewardLines, extra)
    local lines = { header }
    for _, l in ipairs(rewardLines or {}) do lines[#lines + 1] = "  · " .. l end
    local r = { ok = ok, reason = reason, lines = lines }
    if extra then for k, v in pairs(extra) do r[k] = v end end
    return r
end

C.REASON_KO = { clear = "클리어", fail = "실패", timeout = "시간 초과", error = "오류", sweep = "소탕" }
