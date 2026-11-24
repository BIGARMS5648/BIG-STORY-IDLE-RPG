-- Preview a screen of the addon: lua5.1 tools/preview/shot.lua <panelKey|main> <out.txt> [jobKey]
-- then: python3 tools/preview/render.py <out.txt> <out.png> --crop <printed crop>
package.path = "tools/test/?.lua;tools/preview/?.lua;" .. package.path
local Stub = require("wowstub")
Stub.Install()
local H = require("harness")
H.loadToc()
local ns = H.ns
ns.InitDB()
ns.Print = function() end
local L = require("layout")
local ef = ns.eventFrame
ef._scripts.OnEvent(ef, "ADDON_LOADED", "BigStoryIdleRPG")
ef._scripts.OnEvent(ef, "PLAYER_LOGIN")
local panel, out, jobKey = arg[1] or "main", arg[2] or "preview.txt", arg[3] or "hero"
local hero = ns.Hero.New(jobKey, "단빙구")
hero.level = 40
hero.jobStep = 2
hero.campaign.maxChapter, hero.campaign.maxStage = 5, 4
ns.Hero.SetActive(hero)
for _, k in ipairs({ "weaponTicket", "companionTicket", "redDia", "meso", "starforceScroll", "cubeMiracle", "eliteSummonPoint" }) do
    ns.Hero.Add(hero, k, 30000)
end
ns.MapleRank.AutoUpgrade(hero)
for _ = 1, 10 do ns.Summon.Pull(hero, "weapon", 10) end
for _ = 1, 5 do ns.Summon.Pull(hero, "companion", 10) end
if ns.Weapons.AutoEquip then pcall(ns.Weapons.AutoEquip, hero) end
if ns.Equipment and ns.Equipment.EliteSummonInstant then
    pcall(ns.Equipment.EliteSummonInstant, hero, 24)
    pcall(ns.Equipment.AutoEquip, hero)
end
if ns.Companions.AutoEquip then pcall(ns.Companions.AutoEquip, hero) end
if not (ns.UI.frame and ns.UI.frame:IsShown()) then ns.UI.Toggle() end
-- the stub has no layout engine: give frames sized by anchors their real size
local function fix(f) if f then local l, b, r, t = L.Rect(f); if l then f._w, f._h = r - l, t - b end end end
fix(ns.UI.frame); fix(ns.UI.battleArea); fix(ns.BattleView.frame)
ns.UI.Refresh()
for i = 1, 260 do
    if Stub.ticker then Stub.ticker() end
    ns.BattleView.OnUpdate(0.1)
    if i % 50 == 0 then Stub.RunTimers() end
end
-- BSI_ON_PLATFORM=1: keep fighting until the hero stands on a platform (jump preview)
if os.getenv("BSI_ON_PLATFORM") then
    for i = 1, 3000 do
        local J = ns.BattleMap.jump
        if J and J.grounded and J.y > 0 and i > 3 then break end
        if Stub.ticker then Stub.ticker() end
        ns.BattleView.OnUpdate(0.05)
        if i % 100 == 0 then Stub.RunTimers() end
    end
end
if panel ~= "main" then ns.UI.ShowPanel(panel) end
ns.UI.RefreshPanel()
if ns.UI.RefreshHeroBar then ns.UI.RefreshHeroBar() end
ns.BattleView.OnUpdate(0.1)
local n = L.Dump(out)
local l, b, r, t = L.Rect(ns.UI.frame)
print(string.format("ops %d crop %d,%d,%d,%d", n, l, b, r, t))
