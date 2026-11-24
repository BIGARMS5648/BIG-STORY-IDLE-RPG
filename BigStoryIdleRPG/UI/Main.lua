-- Main window: header, hero bar, battle view area, tabbed panels, minimap button.
--
-- Panel API (for every system UI file):
--   ns.UI.RegisterPanel(key, { title = "장비", order = 30, build = function(parent) ... end,
--                              refresh = function(parent, hero) ... end })
local ADDON, ns = ...
local W = ns.W
local U = ns.U

local UI = {}
ns.UI = UI
UI.panels = {}
UI.panelOrder = {}

local WIDTH, HEIGHT = 980, 660
local BATTLE_H = 300

function UI.RegisterPanel(key, def)
    def.key = key
    UI.panels[key] = def
    table.insert(UI.panelOrder, def)
    table.sort(UI.panelOrder, function(a, b) return (a.order or 99) < (b.order or 99) end)
    if UI.frame then UI.BuildTabs() end
end

---------------------------------------------------------------------------
-- Frame
---------------------------------------------------------------------------
function UI.Create()
    if UI.frame then return UI.frame end
    local f = W.Panel(UIParent, WIDTH, HEIGHT, 0.95)
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    f:Hide()
    tinsert(UISpecialFrames, "BigStoryIdleMainFrame")
    _G.BigStoryIdleMainFrame = f
    UI.frame = f

    local title = W.Text(f, 15, W.COLORS.gold, "LEFT")
    title:SetPoint("TOPLEFT", 14, -10)
    title:SetText("빅 스토리 키우기")

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)

    -- hero bar
    local bar = CreateFrame("Frame", nil, f)
    bar:SetPoint("TOPLEFT", 10, -30)
    bar:SetPoint("TOPRIGHT", -10, -30)
    bar:SetHeight(26)
    UI.heroBar = bar
    bar.classIcon = W.Icon(bar, 22)
    bar.classIcon:SetPoint("LEFT", 0, 0)
    bar.name = W.Text(bar, 13, W.COLORS.white, "LEFT")
    bar.name:SetPoint("LEFT", bar.classIcon, "RIGHT", 6, 0)
    bar.exp = W.Bar(bar, 260, 14, 0.55, 0.35, 1)
    bar.exp:SetPoint("LEFT", bar.name, "RIGHT", 10, 0)
    bar.power = W.Text(bar, 12, W.COLORS.orange, "LEFT")
    bar.power:SetPoint("LEFT", bar.exp, "RIGHT", 10, 0)
    bar.money = W.Text(bar, 12, W.COLORS.white, "RIGHT")
    bar.money:SetPoint("RIGHT", 0, 0)

    -- battle view container
    local bv = CreateFrame("Frame", nil, f)
    bv:SetPoint("TOPLEFT", 10, -58)
    bv:SetPoint("TOPRIGHT", -10, -58)
    bv:SetHeight(BATTLE_H)
    UI.battleArea = bv
    if ns.BattleView then ns.BattleView.Create(bv) end

    -- tabs + content
    local content = W.Panel(f, WIDTH - 20, HEIGHT - BATTLE_H - 100, 0.6)
    content:SetPoint("BOTTOMLEFT", 10, 10)
    UI.content = content
    UI.tabBar = CreateFrame("Frame", nil, f)
    UI.tabBar:SetPoint("BOTTOMLEFT", content, "TOPLEFT", 0, 2)
    UI.tabBar:SetSize(WIDTH - 20, 24)
    UI.BuildTabs()

    f:SetScript("OnShow", function() UI.Refresh() end)
    f:SetScale(ns.db and ns.db.settings.scale or 1)
    return f
end

function UI.BuildTabs()
    if not UI.tabBar then return end
    UI.tabs = UI.tabs or {}
    local x = 0
    for i, def in ipairs(UI.panelOrder) do
        local tab = UI.tabs[def.key]
        if not tab then
            tab = W.Button(UI.tabBar, def.title, 74, 22, function() UI.ShowPanel(def.key) end)
            UI.tabs[def.key] = tab
        end
        tab:ClearAllPoints()
        tab:SetPoint("LEFT", x, 0)
        local w = math.max(56, (tab:GetFontString() and tab:GetFontString():GetStringWidth() or 40) + 20)
        tab:SetWidth(w)
        x = x + w + 2
    end
end

function UI.ShowPanel(key)
    local def = UI.panels[key]
    if not def then return end
    for k, d in pairs(UI.panels) do
        if d.frame then d.frame:Hide() end
        if UI.tabs[k] then UI.tabs[k]:UnlockHighlight() end
    end
    if not def.frame then
        local p = CreateFrame("Frame", nil, UI.content)
        p:SetPoint("TOPLEFT", 8, -8)
        p:SetPoint("BOTTOMRIGHT", -8, 8)
        def.frame = p
        local ok, err = pcall(def.build, p)
        if not ok then ns.Print("|cffff4040패널 오류|r %s: %s", key, tostring(err)) end
    end
    def.frame:Show()
    UI.tabs[key]:LockHighlight()
    UI.current = key
    UI.RefreshPanel()
end

function UI.RefreshPanel()
    local def = UI.current and UI.panels[UI.current]
    local hero = ns.Hero.Active()
    if def and def.refresh and def.frame and hero then
        local ok, err = pcall(def.refresh, def.frame, hero)
        if not ok then ns.Debug("panel refresh %s: %s", def.key, tostring(err)) end
    end
end

function UI.RefreshHeroBar()
    local hero = ns.Hero.Active()
    local bar = UI.heroBar
    if not (hero and bar) then return end
    local job = ns.Hero.Job(hero)
    local skin = ns.Skin and ns.Skin.Job(job)
    bar.classIcon.icon:SetTexture(skin and skin.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    local medal = ns.Medals and ns.Medals.Equipped(hero)
    bar.name:SetText(string.format("%s%s  |cffffd100Lv.%d|r  %s", medal and ("|cffa335ee<" .. medal.name .. ">|r ") or "",
        hero.name or "", hero.level, skin and skin.display or (job and job.mapleNameKo) or ""))
    local need = ns.Hero.ExpToNext(hero.level)
    bar.exp:SetValue(need < math.huge and hero.exp / need or 1)
    bar.exp.text:SetText(need < math.huge and string.format("%.2f%%", hero.exp / need * 100) or "MAX")
    if ns.Game.profile then
        bar.power:SetText("전투력 " .. U.FormatNumber(ns.Hero.CombatPower(ns.Game.profile)))
    end
    bar.money:SetText(W.Money("meso", ns.Hero.Count(hero, "meso")) .. "   " .. W.Money("redDia", ns.Hero.Count(hero, "redDia")))
end

function UI.Refresh()
    if not (UI.frame and UI.frame:IsShown()) then return end
    if not ns.Hero.Active() then
        UI.ShowCreate()
        return
    end
    if UI.createFrame then UI.createFrame:Hide() end
    UI.RefreshHeroBar()
    if not UI.current and UI.panelOrder[1] then UI.ShowPanel(UI.panelOrder[1].key) else UI.RefreshPanel() end
end

function UI.Toggle()
    local f = UI.Create()
    if f:IsShown() then f:Hide() else f:Show() end
end

-- throttled refresh on game events
local pending = false
local function queueRefresh()
    if pending or not (UI.frame and UI.frame:IsShown()) then return end
    pending = true
    ns.Compat.After(0.25, function()
        pending = false
        UI.Refresh()
    end)
end
for _, ev in ipairs({ "HERO_CHANGED", "WALLET_CHANGED", "HERO_LEVEL_UP", "STAGE_CLEARED", "MASTERY_LEARNED", "HERO_ACTIVATED" }) do
    ns.On(ev, queueRefresh)
end

---------------------------------------------------------------------------
-- Character creation (job select)
---------------------------------------------------------------------------
function UI.ShowCreate()
    local f = UI.createFrame
    if not f then
        f = W.Panel(UI.frame, WIDTH - 40, HEIGHT - 80, 0.98)
        f:SetPoint("CENTER", 0, -20)
        f:SetFrameLevel(UI.frame:GetFrameLevel() + 20)
        UI.createFrame = f
        local t = W.Text(f, 16, W.COLORS.gold, "CENTER")
        t:SetPoint("TOP", 0, -14)
        t:SetText("직업을 선택하세요")
        local jobs = ns.Data.Jobs
        for i, job in ipairs(jobs) do
            local skin = ns.Skin and ns.Skin.Job(job) or {}
            local col, row = (i - 1) % 4, math.floor((i - 1) / 4)
            local b = W.Panel(f, 220, 110, 0.9)
            b:SetPoint("TOPLEFT", 20 + col * 232, -50 - row * 122)
            local icon = W.Icon(b, 40, skin.icon)
            icon:SetPoint("TOPLEFT", 10, -10)
            local name = W.Text(b, 14, W.COLORS.gold, "LEFT")
            name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, 0)
            name:SetText(skin.display or job.mapleNameKo)
            local sub = W.Text(b, 11, W.COLORS.gray, "LEFT")
            sub:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -4)
            sub:SetText(string.format("주스탯 %s · %s", job.mainStat, job.attackType == "Magical" and "마법" or "물리"))
            local pick = W.Button(b, "선택", 90, 22, function()
                W.Confirm(string.format("%s(으)로 시작할까요?", skin.display or job.mapleNameKo), function()
                    local hero = ns.Hero.New(job.key)
                    ns.Hero.SetActive(hero)
                    f:Hide()
                    UI.Refresh()
                end)
            end)
            pick:SetPoint("BOTTOMRIGHT", -10, 10)
        end
    end
    f:Show()
end

---------------------------------------------------------------------------
-- Minimap button
---------------------------------------------------------------------------
function UI.CreateMinimapButton()
    if UI.minimap or not Minimap then return end
    local b = CreateFrame("Button", "BigStoryIdleMinimapButton", Minimap)
    b:SetSize(31, 31)
    b:SetFrameStrata("MEDIUM")
    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    local icon = b:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture("Interface\\Icons\\INV_Sword_39")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    local border = b:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")
    local function place()
        local a = math.rad(ns.db.settings.minimap.angle or 200)
        b:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * 80, math.sin(a) * 80)
    end
    b:RegisterForDrag("LeftButton")
    b:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local s = Minimap:GetEffectiveScale()
            ns.db.settings.minimap.angle = math.deg(math.atan2(cy / s - my, cx / s - mx))
            self:ClearAllPoints()
            place()
        end)
    end)
    b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    b:SetScript("OnClick", function() UI.Toggle() end)
    W.Tooltip(b, function(tt)
        tt:AddLine("빅 스토리 키우기", 1, 0.82, 0)
        tt:AddLine("클릭: 창 열기/닫기 · 드래그: 위치 이동", 1, 1, 1)
    end)
    place()
    if ns.db.settings.minimap.hide then b:Hide() end
    UI.minimap = b
end

ns.On("LOGIN", function()
    UI.CreateMinimapButton()
    if ns.db.settings.autoOpen then UI.Toggle() end
end)

ns.RegisterSlash("minimap", "미니맵 버튼 표시/숨김", function()
    ns.db.settings.minimap.hide = not ns.db.settings.minimap.hide
    if UI.minimap then
        if ns.db.settings.minimap.hide then UI.minimap:Hide() else UI.minimap:Show() end
    end
end)
