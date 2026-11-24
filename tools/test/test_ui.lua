-- Executes the UI code paths against the WoW API stub: create hero via the job
-- picker, open every panel, run battle-view frames while the game ticks.
package.path = "tools/test/?.lua;" .. package.path
local Stub = require("wowstub")
Stub.Install()
local H = require("harness")
H.loadToc()
local ns = H.ns

local errors = 0
local origPrint = ns.Print
ns.Print = function(fmt, ...)
    local msg = select("#", ...) > 0 and string.format(fmt, ...) or tostring(fmt)
    if msg:find("오류") then errors = errors + 1; print(msg) end
end
ns.Debug = function(fmt, ...) errors = errors + 1; print("DEBUG", string.format(fmt, ...)) end

-- ADDON_LOADED + PLAYER_LOGIN
local ef = ns.eventFrame
ef._scripts.OnEvent(ef, "ADDON_LOADED", "BigStoryIdleRPG")
ef._scripts.OnEvent(ef, "PLAYER_LOGIN")
-- first run: the window opens by itself for the job selection
if not (ns.UI.frame and ns.UI.frame:IsShown()) then errors = errors + 1; print("window did not open on first run") end

-- character creation through the picker: click the first "선택" button equivalent
local job = ns.Data.Jobs[tonumber(arg[1] or 1)]
local hero = ns.Hero.New(job.key)
ns.Hero.SetActive(hero)
ns.UI.Refresh()

for i = 1, 600 do
    if Stub.ticker then Stub.ticker() end
    ns.BattleView.OnUpdate(0.1)
    if i % 50 == 0 then Stub.RunTimers() end
end
for _, def in ipairs(ns.UI.panelOrder) do
    ns.UI.ShowPanel(def.key)
    ns.UI.RefreshPanel()
end
ns.Game.StartChallenge()
for i = 1, 400 do
    if Stub.ticker then Stub.ticker() end
    ns.BattleView.OnUpdate(0.1)
    if i % 50 == 0 then Stub.RunTimers() end
end
-- people in the battle view (companions / arena opponents use dressed character models)
ns.Game.StartHunt()
local b = ns.Game.battle
local prof = ns.Hero.BuildProfile(hero)
local sup = ns.Supporters.Spawn(b, hero, prof, { name = "동료", jobKey = "bishop", jobStep = 4, grade = 5, level = 1,
    attackInheritM = 500, spawnMs = 30000 })
if not sup then errors = errors + 1; print("supporter not spawned") end
for i = 1, 20 do ns.BattleView.OnUpdate(0.1) end
print(string.format("UI test %s: panels %d, level %d, kills %d, errors %d", job.key, #ns.UI.panelOrder, hero.level,
    hero.stats.kills or 0, errors))
