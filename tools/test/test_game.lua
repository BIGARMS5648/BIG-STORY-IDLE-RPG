-- Headless game-loop test: new hero, hunts and challenges for simulated time.
package.path = "tools/test/?.lua;" .. package.path
local H = require("harness")
H.loadToc()
local ns = H.ns
ns.InitDB()
local errors = 0
ns.Debug = function(fmt, ...) errors = errors + 1; if errors < 10 then print("DEBUG", string.format(fmt, ...)) end end
ns.Print = function(fmt, ...) end

local jobKey = arg[1] or "hero"
local hero = ns.Hero.New(jobKey, "테스터")
ns.Hero.SetActive(hero)
local G = ns.Game
local clears, fails = 0, 0
ns.On("STAGE_CLEARED", function(_, ch, st, kind) clears = clears + 1 end)
ns.On("STAGE_FAILED", function(_, ch, st, kind, reason) fails = fails + 1 end)

-- simulate 30 minutes in 0.1 s ticks with an explicit clock
local clock = os.time()
ns.U.Now = function() return clock end
for i = 1, 30 * 60 * 10 do
    clock = clock + 0.1
    G.Tick(0.1)
    if G.battle and G.battle.ended and G.mode ~= "hunt" then G.StartHunt() end
end
local cp = hero.campaign
print(string.format("%s: Lv %d (exp %.0f)  stage %d-%d (max %d-%d)  kills %d  clears %d  fails %d  errors %d",
    jobKey, hero.level, hero.exp, cp.chapter, cp.stage, cp.maxChapter, cp.maxStage, hero.stats.kills, clears, fails, errors))
for k, v in pairs(hero.wallet) do io.write(k, "=", math.floor(v), " ") end
print()
