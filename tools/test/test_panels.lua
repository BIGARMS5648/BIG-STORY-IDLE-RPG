-- Headless test of the growth-system panels (소환 / 무기 / 동료 / 장비 / 성장):
-- creates a rich hero, opens every panel, clicks every button / check button the panels created
-- (left and right click), hovers every tooltip, runs OnUpdate animations and timers, refreshes,
-- and counts Lua errors (ns.Debug, "오류" prints, failed pcalls).
-- Run from the repository root: lua5.1 tools/test/test_panels.lua [jobIndex]
package.path = "tools/test/?.lua;" .. package.path
local Stub = require("wowstub")
Stub.Install()

-- remember every frame and its parent so buttons can be attributed to a panel
local frames = {}
local origCreate = CreateFrame
CreateFrame = function(kind, name, parent, template)
    local f = origCreate(kind, name, parent, template)
    f._parent = parent
    frames[#frames + 1] = f
    return f
end

local toasts = {}
UIErrorsFrame = { AddMessage = function(_, msg) toasts[#toasts + 1] = msg end }

local H = require("harness")
H.loadToc()
local ns = H.ns

local PANELS = {
    { key = "summon", file = "UI/SummonPanel.lua" },
    { key = "weapons", file = "UI/WeaponPanel.lua" },
    { key = "companions", file = "UI/CompanionPanel.lua" },
    { key = "equipment", file = "UI/EquipPanel.lua" },
    { key = "growth", file = "UI/GrowthPanel.lua" },
}
-- the TOC may or may not list the panels yet
for _, pdef in ipairs(PANELS) do
    if not ns.UI.panels[pdef.key] then H.load(pdef.file) end
end

local errors, failures = 0, 0
ns.Print = function(fmt, ...)
    local msg = select("#", ...) > 0 and string.format(fmt, ...) or tostring(fmt)
    if msg:find("오류") then errors = errors + 1; print("ERROR", msg) end
end
ns.Debug = function(fmt, ...)
    errors = errors + 1
    print("DEBUG", (select("#", ...) > 0) and string.format(fmt, ...) or tostring(fmt))
end
local function check(cond, msg)
    if not cond then failures = failures + 1; print("FAIL: " .. msg) end
end

-- controllable clock (trail / elite / hero power timers)
local realNow = ns.U.Now
local offset = 0
ns.U.Now = function() return realNow() + offset end

local ef = ns.eventFrame
ef._scripts.OnEvent(ef, "ADDON_LOADED", "BigStoryIdleRPG")
ef._scripts.OnEvent(ef, "PLAYER_LOGIN")
ns.UI.Toggle()

local D = ns.Data
local job = D.Jobs[tonumber(arg[1] or 3)] or D.Jobs[1]
local hero = ns.Hero.New(job.key)
ns.Hero.SetActive(hero)
ns.UI.Refresh()

---------------------------------------------------------------------------
-- a hero with something to do everywhere
---------------------------------------------------------------------------
hero.level = 120
hero.jobStep = 4
hero.campaign.maxChapter, hero.campaign.maxStage = 25, 1   -- chapters 1..24 cleared (journey, enchant)
local function fund()
    for key in pairs(D.Currencies) do
        local want = (key == "meso") and 1e12 or 1e7
        local have = ns.Hero.Count(hero, key)
        if have < want then ns.Hero.Add(hero, key, want - have, "test") end
    end
end
fund()

local E = ns.Equipment
local function giveGear(n)
    local codes = {}
    for code in pairs(D.Gear) do codes[#codes + 1] = code end
    table.sort(codes)
    local byPart = {}
    for _, code in ipairs(codes) do
        local part = D.Gear[code].part
        if not byPart[part] then byPart[part] = code; E.Give(hero, code) end
    end
    for i = 1, n do E.Give(hero, codes[(i * 37) % #codes + 1]) end
end
giveGear(20)
E.AutoEquip(hero)
-- make the first equipped item ready for cubes / star force
for _, part in ipairs(E.PARTS) do
    local it = E.Equipped(hero, part)
    if it then it.star = 12 break end
end
ns.Weapons.Add(hero, 1, 60)
ns.Weapons.Add(hero, 5, 12)
ns.Companions.Add(hero, ns.Companions.ByGrade(1)[1], 900)
ns.Companions.Add(hero, ns.Companions.ByGrade(2)[1], 400)
if ns.Journey then ns.Journey.AddTreasureExp(hero, 1e15) end
if ns.Scrolls and ns.Scrolls.Bag then
    local bag = ns.Scrolls.Bag(hero)
    for id = 1, #D.Scrolls.enchant.scrolls do bag[id] = 3 end
end

---------------------------------------------------------------------------
-- frame helpers
---------------------------------------------------------------------------
local function ownerPanel(f)
    local seen = 0
    while f and seen < 50 do
        for _, pdef in ipairs(PANELS) do
            local def = ns.UI.panels[pdef.key]
            if def and def.frame == f then return pdef.key end
        end
        f = f._parent
        seen = seen + 1
    end
    return nil
end

local function panelFrames(key)
    local out = {}
    for _, f in ipairs(frames) do
        if ownerPanel(f) == key then out[#out + 1] = f end
    end
    return out
end

local stats = { clicks = 0, tooltips = 0, updates = 0 }
local function run(where, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then
        errors = errors + 1
        print("LUA ERROR", where, err)
    end
end

local function tickTimers()
    Stub.RunTimers()
end

local function hoverAll(list)
    for _, f in ipairs(list) do
        if f._scripts.OnEnter then
            run("OnEnter", f._scripts.OnEnter, f)
            if f._scripts.OnLeave then run("OnLeave", f._scripts.OnLeave, f) end
            stats.tooltips = stats.tooltips + 1
        end
    end
end

local function updateAll(list, steps)
    for _ = 1, steps do
        for _, f in ipairs(list) do
            local fn = f._scripts.OnUpdate
            if fn then
                run("OnUpdate", fn, f, 0.2)
                stats.updates = stats.updates + 1
            end
        end
    end
end

-- sub-tab buttons of a panel (summon kinds, equipment / growth views)
local function tabButtons(p)
    local list = {}
    for _, field in ipairs({ "tabs", "viewBtns" }) do
        local t = p[field]
        if type(t) == "table" then
            local keys = {}
            for k in pairs(t) do keys[#keys + 1] = k end
            table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
            for _, k in ipairs(keys) do list[#list + 1] = t[k] end
        end
    end
    return list
end

local function clickAll(key, button, skip)
    local n = 0
    for _, f in ipairs(panelFrames(key)) do
        local fn = f._scripts.OnClick
        if fn and not (skip and skip[f]) then
            if f._kind == "CheckButton" then f._checked = not f._checked end
            run(key .. " OnClick", fn, f, button or "LeftButton")
            ns.UI.RefreshPanel()
            n = n + 1
        end
    end
    stats.clicks = stats.clicks + n
    return n
end

---------------------------------------------------------------------------
-- rounds
---------------------------------------------------------------------------
local perPanel = {}
for round = 1, 4 do
    -- later rounds: pickup banner and companion sub slots unlocked
    if round == 3 then hero.summon.companion.level = math.max(hero.summon.companion.level, 9) end
    for _, pdef in ipairs(PANELS) do
        ns.UI.ShowPanel(pdef.key)
        local frame = ns.UI.panels[pdef.key].frame
        check(frame ~= nil, pdef.key .. " panel built")
        ns.UI.RefreshPanel()
        local tabs = tabButtons(frame)
        local skip = {}
        for _, b in ipairs(tabs) do skip[b] = true end
        if #tabs == 0 then tabs = { false } end
        local n = 0
        for _, tab in ipairs(tabs) do
            if tab then
                run(pdef.key .. " tab", tab._scripts.OnClick, tab, "LeftButton")
                ns.UI.RefreshPanel()
                n = n + 1
            end
            n = n + clickAll(pdef.key, "LeftButton", skip)
            if round == 2 then n = n + clickAll(pdef.key, "RightButton", skip) end
            local list = panelFrames(pdef.key)
            hoverAll(list)
            updateAll(list, 12)
        end
        perPanel[pdef.key] = math.max(perPanel[pdef.key] or 0, n)
        ns.UI.RefreshPanel()
        tickTimers()
    end
    -- move time forward so every timer (trail opening, elite level-up, hero power) can finish
    offset = offset + 400000
    fund()
    giveGear(10)
    ns.UI.Refresh()
    tickTimers()
end

-- every panel again after the clock jump: refresh + hover only
for _, pdef in ipairs(PANELS) do
    ns.UI.ShowPanel(pdef.key)
    ns.UI.RefreshPanel()
    hoverAll(panelFrames(pdef.key))
end

---------------------------------------------------------------------------
-- the clicks reached the systems
---------------------------------------------------------------------------
local function count(t) local n = 0 for _ in pairs(t or {}) do n = n + 1 end return n end
check((hero.summon.weapon.total or 0) > 0, "weapon summons happened")
check((hero.summon.companion.total or 0) > 0, "companion summons happened")
check((hero.summon.pickup.total or 0) > 0, "pickup summons happened")
check(count(hero.weapons.owned) > 2, "weapons owned after summons")
check(count(hero.companions.owned) > 2, "companions owned after summons")
local starred, cubed, scrolled = false, false, false
for _, it in pairs(hero.equipment.items) do
    if (it.star or 0) > 0 then starred = true end
    if it.potential and it.potential.lines and #it.potential.lines > 0 then cubed = true end
    if it.scroll and it.scroll.slots and #it.scroll.slots > 0 then scrolled = true end
end
check(starred, "star force used")
check(cubed, "cube used")
check(scrolled, "scroll used")
check((hero.equipment.elite.summons or 0) > 0, "elite summoned")
check((hero.heroPower.stage or 1) >= 2, "hero power advanced")
check(count(hero.ability.lines) > 0, "ability converted")
check(count(hero.artifacts.owned) > 0, "artifacts opened")
check((hero.journey.treasure.stored or 0) < 2, "journey treasure claimed")
check(count(hero.journey.trail.opened) > 0, "journey trail opened")
for _, pdef in ipairs(PANELS) do
    check((perPanel[pdef.key] or 0) > 0, pdef.key .. " has clickable buttons")
end

local parts = {}
for _, pdef in ipairs(PANELS) do parts[#parts + 1] = pdef.key .. "=" .. (perPanel[pdef.key] or 0) end
print(string.format("panels test %s: clicks %d (%s), tooltips %d, updates %d, toasts %d, failures %d, errors %d",
    job.key, stats.clicks, table.concat(parts, " "), stats.tooltips, stats.updates, #toasts, failures, errors))
if errors > 0 or failures > 0 then os.exit(1) end
