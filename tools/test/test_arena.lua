-- Arena: a rival's profile arrives over addon messages, we challenge it, the
-- result is sent back; also checks determinism (same seed -> same winner).
package.path = "tools/test/?.lua;" .. package.path
local Stub = require("wowstub")
Stub.Install()
local H = require("harness")
H.loadToc()
local ns = H.ns
local errors = 0
ns.Print = function() end
ns.Debug = function(fmt, ...) errors = errors + 1; print("DEBUG", string.format(fmt, ...)) end
local ef = ns.eventFrame
ef._scripts.OnEvent(ef, "ADDON_LOADED", "BigStoryIdleRPG")

local Hero, A = ns.Hero, ns.Arena
local function strong(hero, lv)
    hero.level = lv
    hero.masteries = ns.SkillBook.AllMasteriesAt(Hero.Job(hero), lv)
end

-- the rival client builds and "sends" its profile
local rival = Hero.New("bishop", "Rival")
strong(rival, 120)
ns.Hero.SetActive(rival)
local sentBefore = #Stub.sent
ns.Comm.handlers.AREQ("Me", { v = A.VERSION })   -- rival answers our request
local tick = 100
while #ns.Comm.queue > 0 do tick = tick + 2; GetTime = function() return tick end; ns.Comm.Pump() end
local rivalMsgs = {}
for i = sentBefore + 1, #Stub.sent do rivalMsgs[#rivalMsgs + 1] = Stub.sent[i] end

-- now we are the local player
local me = Hero.New("hero", "Me")
strong(me, 120)
ns.db.active[ns.CharKey()] = nil
ns.Hero.SetActive(me)
GetTime = function() return 5000 end
for _, m in ipairs(rivalMsgs) do ns.Comm.OnMessage(m.prefix, m.msg, m.chan, "Rival-Realm") end
assert(ns.db.arena.snapshots.Rival, "rival snapshot missing")
print("peers:", #A.Peers(), "tier:", select(2, A.Tier(me)).name)

local function fight()
    local ok, err = A.Challenge(me, "Rival")
    assert(ok, err)
    local b = ns.Game.battle
    local steps = 0
    while not b.ended and steps < 2000 do b:Step(); steps = steps + 1 end
    return b.endReason, b.time
end

local r1, t1 = fight()
local ar = me.arena
print(string.format("fight 1: %s at %.1fs, score %d, tickets %d, log %s", r1, t1 / 1000, ar.score, ar.tickets,
    ar.log[1] and (ar.log[1].won and "win" or "loss") or "-"))
-- determinism: same seed again
local snap = ns.db.arena.snapshots.Rival
local function replay(seed)
    local profile = Hero.BuildProfile(me)
    profile.stats = A.PvpStats(profile.stats)
    local b = ns.Battle.New({ seed = seed, timeLimitMs = A.TIME_LIMIT_MS })
    local h = b:AddCreature(Hero.CreatureDef(profile, 1, 0))
    local e = b:AddCreature(Hero.CreatureDef(snap.profile, 2, 1600))
    while not b.ended and b.time < A.TIME_LIMIT_MS do
        b:Step()
        if not h.alive or not e.alive then break end
    end
    return h.hp, e.hp, b.time
end
local a1, b1, c1 = replay(12345)
local a2, b2, c2 = replay(12345)
assert(a1 == a2 and b1 == b2 and c1 == c2, "replay not deterministic")
print(string.format("deterministic replay ok (hp %d vs %d at %.1fs)", a1, b1, c1 / 1000))
-- result message to the rival
GetTime = function() return 9000 end
ns.Comm.Pump()
local found = false
for _, m in ipairs(Stub.sent) do
    if m.target == "Rival" and m.msg:find("^ARES") then found = true end
end
for _, m in ipairs(ns.Comm.queue) do
    if m.target == "Rival" and m.text:find("^ARES") then found = true end
end
assert(found, "result not sent")
-- daily reward
ns.Hero.systems.arena.daily(me)
print("daily coins:", Hero.Count(me, "arenaCoin"), "tickets:", me.arena.tickets)
assert(A.Buy(me, 2, 1), "shop buy failed")
print("arena ok, errors", errors)
