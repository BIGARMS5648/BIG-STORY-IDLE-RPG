-- Game loop: owns the running battle, switches modes, applies offline rewards.
--
-- API
--   ns.Game.Start()                       -- after a hero is active
--   ns.Game.StartHunt()
--   ns.Game.StartChallenge()  -> ok, err
--   ns.Game.StartContent(controller, opts) -- dungeons / bosses / arena build their own controller
--   ns.Game.battle                         -- current Battle (UI reads creatures from it)
--   ns.Game.mode                           -- "hunt" | "challenge" | "boss" | controller.kind
--   ns.Game.speed                          -- simulation speed multiplier (1 = real time)
-- UI hooks: ns.Game.uiHooks.onDamage / onDeath / onCast / onSpawn / onEnd / onMiss / onHeal / onRevive
local ADDON, ns = ...
local U = ns.U
local Hero = ns.Hero
local Campaign = ns.Campaign

local G = {}
ns.Game = G
G.speed = 1
G.uiHooks = {}
G.TICK_SECONDS = 0.1

local function forward(name)
    return function(b, ...)
        local ctl = b.opts.controller
        if name == "onDeath" and ctl and ctl.OnKill then
            local victim = ...
            pcall(ctl.OnKill, ctl, b, victim)
        end
        if name == "onEnd" and ctl and ctl.OnEnd then
            local reason = ...
            pcall(ctl.OnEnd, ctl, b, reason)
            G.OnBattleEnd(b, reason)
        end
        local ui = G.uiHooks[name]
        if ui then pcall(ui, b, ...) end
    end
end

local HOOK_NAMES = { "onDamage", "onDeath", "onCast", "onSpawn", "onEnd", "onMiss", "onHeal", "onRevive" }

function G.NewBattle(controller, opts)
    local hero = Hero.Active()
    opts = opts or {}
    local hooks = {}
    for _, n in ipairs(HOOK_NAMES) do hooks[n] = forward(n) end
    local b = ns.Battle.New({
        seed = opts.seed or U.rng:Next(),
        controller = controller,
        dungeonType = opts.dungeonType or "Campaign",
        isTrial = opts.isTrial,
        difficulty = opts.difficulty,
        timeLimitMs = opts.timeLimitMs or (controller and controller.timeLimit),
        hooks = hooks,
    })
    local profile = opts.profile or Hero.BuildProfile(hero)
    G.profile = profile
    b.heroCreature = b:AddCreature(Hero.CreatureDef(profile, 1, 0))
    b.heroCreature.model = { unit = "player" }
    if ns.Companions and ns.Companions.SetupSupporters and not opts.noSupporters then
        pcall(ns.Companions.SetupSupporters, b, hero, profile, opts)
    end
    return b
end

function G.StartContent(controller, opts)
    G.battle = G.NewBattle(controller, opts)
    G.mode = controller and controller.kind or "hunt"
    ns.Fire("BATTLE_STARTED", G.battle, G.mode)
    return G.battle
end

function G.StartHunt()
    local hero = Hero.Active()
    if not hero then return end
    return G.StartContent(Campaign.NewHuntController(hero), { dungeonType = "Campaign" })
end

function G.StartChallenge()
    local hero = Hero.Active()
    if not hero then return false end
    local ctl, err = Campaign.NewChallengeController(hero)
    if not ctl then
        if err == "unlocked" then
            G.StartHunt()
            return true
        end
        return false, err
    end
    G.StartContent(ctl, { dungeonType = "Campaign", isTrial = true })
    return true
end

function G.OnBattleEnd(b, reason)
    if b ~= G.battle then return end
    local mode = G.mode
    -- after any content ends, return to hunting a moment later
    local delay = 2.0
    local function back()
        if G.battle == b then G.StartHunt() end
    end
    if ns.Compat and C_Timer then ns.Compat.After(delay, back) else back() end
    if mode == "challenge" or mode == "boss" then
        local hero = Hero.Active()
        if hero and reason ~= "clear" then hero.campaign.autoChallengeBlocked = true end
    end
end

---------------------------------------------------------------------------
-- Ticker
---------------------------------------------------------------------------
local accum = 0
local resetTimer = 0
local rebuildPending = false

function G.Tick(elapsed)
    local hero = Hero.Active()
    if not hero then return end
    local b = G.battle
    if b and not b.ended then
        accum = accum + elapsed * 1000 * (G.speed or 1)
        local steps = 0
        while accum >= ns.Battle.TICK and steps < 40 do
            accum = accum - ns.Battle.TICK
            b:Step()
            steps = steps + 1
        end
        if steps >= 40 then accum = 0 end
    end
    hero.lastOnline = U.Now()
    hero.stats.playSeconds = (hero.stats.playSeconds or 0) + elapsed
    if ns.Mastery then ns.Mastery.Update(hero) end
    if ns.HeroPower and ns.HeroPower.Update then pcall(ns.HeroPower.Update, hero) end
    if ns.Journey and ns.Journey.Update then pcall(ns.Journey.Update, hero) end
    if ns.Equipment and ns.Equipment.EliteUpdate then pcall(ns.Equipment.EliteUpdate, hero) end
    resetTimer = resetTimer + elapsed
    if resetTimer > 30 then
        resetTimer = 0
        Hero.CheckResets(hero)
        -- auto challenge when idle-hunting and allowed
        local cp = hero.campaign
        if G.mode == "hunt" and cp.autoChallenge and not cp.autoChallengeBlocked then
            G.StartChallenge()
        end
    end
    if rebuildPending then
        rebuildPending = false
        G.RebuildHero()
    end
end

-- rebuild the hero creature after equipment / level changes (keeps position)
function G.RebuildHero()
    local b = G.battle
    local hero = Hero.Active()
    if not (b and hero and b.heroCreature) or b.ended then return end
    if G.mode ~= "hunt" then return end -- content fights keep the snapshot they started with
    local old = b.heroCreature
    local profile = Hero.BuildProfile(hero)
    G.profile = profile
    local def = Hero.CreatureDef(profile, 1, old.x)
    b:Remove(old)
    local c = b:AddCreature(def)
    c.model = { unit = "player" }
    c.hp = math.min(c:Stat("MaxHp"), old.hp > 0 and old.hp or c:Stat("MaxHp"))
    b.heroCreature = c
    ns.Fire("HERO_REBUILT", c)
end

ns.On("HERO_CHANGED", function(hero, what)
    if what == "stage" then
        if G.mode == "hunt" then G.StartHunt() end
        hero.campaign.autoChallengeBlocked = nil
        return
    end
    rebuildPending = true
end)

ns.On("HERO_LEVEL_UP", function(hero)
    hero.campaign.autoChallengeBlocked = nil
end)

---------------------------------------------------------------------------
-- Login: offline rewards + start
---------------------------------------------------------------------------
function G.ApplyOffline(hero)
    local now = U.Now()
    local last = hero.lastOnline or now
    local seconds = now - last
    if seconds < 1 then return end
    local rewards = Campaign.OfflineRewards(hero, seconds)
    if rewards then
        local kills, secs = rewards.kills, rewards.seconds
        rewards.kills, rewards.seconds = nil, nil
        Campaign.ApplyRewards(hero, rewards, "offline")
        hero.stats.kills = (hero.stats.kills or 0) + kills
        ns.Fire("OFFLINE_REWARDS", hero, rewards, secs, kills)
    end
end

function G.Start()
    local hero = Hero.Active()
    if not hero then return end
    G.ApplyOffline(hero)
    G.StartHunt()
    if not G.ticker and ns.Compat and CreateFrame then
        G.ticker = ns.Compat.NewTicker(G.TICK_SECONDS, function() G.Tick(G.TICK_SECONDS) end)
    end
end

ns.On("HERO_ACTIVATED", function() G.Start() end)

ns.On("LOGIN", function()
    local hero = Hero.Active()
    if hero then
        Hero.SetActive(hero)
    end
end)

ns.On("LOGOUT", function()
    local hero = Hero.Active()
    if hero then hero.lastOnline = U.Now() end
end)
