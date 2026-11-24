-- Main window, laid out like the 메이플 키우기 main screen (landscape): the battle scene fills the
-- window and the HUD sits on top of it.
--   top left     portrait · combat power · rank · gold / diamonds, goal box (가이드 퀘스트 style)
--   top centre   zone · "Stage n/N" progress bar (red dot = boss) · next stage + orange 도전
--   top right    보상 · 소환 · 콘텐츠 · 결투장 · 메뉴 (full menu) · close
--   bottom       EXP along the bottom edge, companion circle (left), Lv/name/HP/MP box + Full Auto,
--                nav bar 캐릭터 / 장비 / 스킬 / 무기 / 동료 (red dots), skill slots (right)
-- Menus open as a large centred popup over the scene.
--
-- Panel API (for every system UI file):
--   ns.UI.RegisterPanel(key, { title = "장비", order = 30, build = function(parent) ... end,
--                              refresh = function(parent, hero) ... end, badge = function(hero) -> bool })
local ADDON, ns = ...
local W = ns.W
local U = ns.U
local T = W.THEME

local UI = {}
ns.UI = UI
UI.panels = {}
UI.panelOrder = {}

local WIDTH, HEIGHT = 1120, 630
UI.WIDTH, UI.HEIGHT = WIDTH, HEIGHT
local POPUP_W, POPUP_H = 990, 500
local BD = BackdropTemplateMixin and "BackdropTemplate" or nil

-- icons of every menu (WoW client icons)
UI.MENU_ICONS = {
    income = "Interface\\Icons\\INV_Misc_Gift_01", chapters = "Interface\\Icons\\INV_Misc_Map_01",
    character = "Interface\\Icons\\INV_Misc_Head_Human_01", mapleRank = "Interface\\Icons\\INV_Misc_Note_02",
    medals = "Interface\\Icons\\INV_Jewelry_Talisman_07", skills = "Interface\\Icons\\INV_Misc_Book_09",
    mastery = "Interface\\Icons\\INV_Misc_Book_07", summon = "Interface\\Icons\\INV_Misc_Bag_10",
    weapons = "Interface\\Icons\\INV_Sword_04", companions = "Interface\\Icons\\Spell_Holy_PrayerOfHealing02",
    equipment = "Interface\\Icons\\INV_Chest_Plate06", growth = "Interface\\Icons\\Spell_Holy_GreaterBlessingofKings",
    content = "Interface\\Icons\\INV_Misc_Key_10", arena = "Interface\\Icons\\INV_Sword_27",
}
UI.NAV = { "character", "equipment", "skills", "weapons", "companions" }
UI.TOP_ICONS = { "income", "summon", "content", "arena" }
UI.TITLES = { character = "캐릭터", equipment = "장비", skills = "스킬", weapons = "무기", companions = "동료",
    income = "보상", summon = "소환", content = "콘텐츠", arena = "결투장" }

function UI.RegisterPanel(key, def)
    def.key = key
    UI.panels[key] = def
    table.insert(UI.panelOrder, def)
    table.sort(UI.panelOrder, function(a, b) return (a.order or 99) < (b.order or 99) end)
end

local function hero() return ns.Hero.Active() end

---------------------------------------------------------------------------
-- small HUD helpers
---------------------------------------------------------------------------
local function capsule(parent, w, h, alpha)
    local c = CreateFrame("Frame", nil, parent, BD)
    c:SetSize(w, h)
    W.Backdrop(c, { 0, 0, 0, alpha or 0.55 }, { 0, 0, 0, 0 }, 10)
    return c
end

local function iconButton(parent, key, size, label, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(size + 18, size + (label and 14 or 0))
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetSize(size, size)
    b.icon:SetPoint("TOP")
    b.icon:SetTexture(UI.MENU_ICONS[key] or key)
    b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    if label then
        b.text = W.Text(b, 11, W.COLORS.white, "CENTER")
        b.text:SetPoint("TOP", b.icon, "BOTTOM", 0, -2)
        b.text:SetText(label)
    end
    b.dot = W.Dot(b)
    b.dot:ClearAllPoints()
    b.dot:SetPoint("TOPRIGHT", b.icon, "TOPRIGHT", 6, 6)
    b:SetScript("OnClick", onClick)
    b:SetScript("OnEnter", function(self) self.icon:SetVertexColor(1, 1, 0.7) end)
    b:SetScript("OnLeave", function(self) self.icon:SetVertexColor(1, 1, 1) end)
    return b
end

---------------------------------------------------------------------------
-- Frame
---------------------------------------------------------------------------
function UI.Create()
    if UI.frame then return UI.frame end
    local f = CreateFrame("Frame", "BigStoryIdleMainFrame", UIParent, BD)
    f:SetSize(WIDTH, HEIGHT)
    f:SetPoint("CENTER")
    W.Backdrop(f, { 0.04, 0.05, 0.07, 1 }, { 0.22, 0.25, 0.3, 1 }, 14)
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    f:Hide()
    tinsert(UISpecialFrames, "BigStoryIdleMainFrame")
    UI.frame = f

    -- battle scene (whole window)
    local scene = CreateFrame("Frame", nil, f)
    scene:SetPoint("TOPLEFT", 4, -4)
    scene:SetPoint("BOTTOMRIGHT", -4, 4)
    UI.battleArea = scene
    if ns.BattleView then ns.BattleView.Create(scene) end

    local hud = CreateFrame("Frame", nil, f)
    hud:SetAllPoints(scene)
    hud:SetFrameLevel(scene:GetFrameLevel() + 20)
    UI.hud = hud
    UI.BuildHud(hud)
    UI.BuildHosts(f)

    f:SetScript("OnShow", function() UI.Refresh() end)
    f:SetScale(ns.db and ns.db.settings.scale or 1)
    return f
end

---------------------------------------------------------------------------
-- HUD
---------------------------------------------------------------------------
function UI.BuildHud(h)
    -- top left: portrait, combat power, rank, currencies
    local pf = W.Icon(h, 54)
    pf:SetPoint("TOPLEFT", 10, -8)
    h.portrait = pf
    pf:SetScript("OnClick", function() UI.ShowPanel("character") end)
    h.cp = W.Text(h, 15, W.COLORS.white, "LEFT")
    h.cp:SetPoint("TOPLEFT", pf, "TOPRIGHT", 8, -5)
    h.rank = W.Text(h, 12, { 0.85, 0.85, 0.9 }, "LEFT")
    h.rank:SetPoint("TOPLEFT", h.cp, "BOTTOMLEFT", 0, -6)
    h.gold = capsule(h, 132, 22)
    h.gold:SetPoint("TOPLEFT", pf, "BOTTOMLEFT", 0, -6)
    h.gold.text = W.Text(h.gold, 12, W.COLORS.white, "LEFT")
    h.gold.text:SetPoint("LEFT", 6, 0)
    h.dia = capsule(h, 112, 22)
    h.dia:SetPoint("LEFT", h.gold, "RIGHT", 6, 0)
    h.dia.text = W.Text(h.dia, 12, W.COLORS.white, "LEFT")
    h.dia.text:SetPoint("LEFT", 6, 0)

    -- goal box (가이드 퀘스트 style: the next thing to do)
    local goal = CreateFrame("Button", nil, h, BD)
    goal:SetSize(260, 52)
    goal:SetPoint("TOPLEFT", h.gold, "BOTTOMLEFT", 0, -12)
    W.Backdrop(goal, { 0, 0, 0, 0.5 }, { 0, 0, 0, 0 }, 8)
    goal.bar = goal:CreateTexture(nil, "ARTWORK")
    goal.bar:SetColorTexture(0.55, 0.85, 0.15, 1)
    goal.bar:SetPoint("TOPLEFT", 3, -5)
    goal.bar:SetPoint("BOTTOMLEFT", 3, 5)
    goal.bar:SetWidth(3)
    goal.title = W.Text(goal, 14, { 0.78, 0.95, 0.25 }, "LEFT")
    goal.title:SetPoint("TOPLEFT", 14, -8)
    goal.desc = W.Text(goal, 12, W.COLORS.white, "LEFT")
    goal.desc:SetPoint("TOPLEFT", goal.title, "BOTTOMLEFT", 0, -5)
    goal:SetScript("OnClick", function() if goal.action then goal.action() end end)
    h.goal = goal

    -- top centre: zone, stage bar, next stage + 도전
    h.zone = W.Text(h, 15, W.COLORS.white, "CENTER")
    h.zone:SetPoint("TOP", 0, -8)
    h.stageBar = W.Bar(h, 300, 7, 1, 0.78, 0.15)
    h.stageBar:SetPoint("TOP", 0, -44)
    h.stageBar.text:Hide()
    h.stageText = W.Text(h, 15, W.COLORS.white, "CENTER")
    h.stageText:SetPoint("BOTTOM", h.stageBar, "TOP", 0, 2)
    h.bossDot = h:CreateTexture(nil, "OVERLAY")
    h.bossDot:SetTexture("Interface\\COMMON\\Indicator-Red")
    h.bossDot:SetSize(14, 14)
    h.bossDot:SetPoint("CENTER", h.stageBar, "RIGHT", 0, 0)
    h.nextStage = W.Text(h, 15, W.COLORS.white, "RIGHT")
    h.nextStage:SetPoint("TOPRIGHT", h.stageBar, "BOTTOM", -14, -12)
    h.challenge = W.Button(h, "도전", 96, 30, function()
        local ok, err = ns.Game.StartChallenge()
        if not ok and err then W.Toast(err) end
    end, "orange")
    h.challenge:SetPoint("TOPLEFT", h.stageBar, "BOTTOM", 0, -6)
    h.timer = W.Text(h, 13, W.COLORS.orange, "CENTER")
    h.timer:SetPoint("TOP", h.stageBar, "BOTTOM", 0, -42)

    -- top right: menu icons + close
    local close = W.Button(h, "X", 28, 28, function() UI.frame:Hide() end, "gray")
    close:SetPoint("TOPRIGHT", -8, -8)
    h.menuBtn = iconButton(h, "Interface\\Icons\\INV_Misc_Book_08", 32, "메뉴", function() UI.ToggleMenu() end)
    h.menuBtn:SetPoint("TOPRIGHT", close, "TOPLEFT", -6, 0)
    h.top = {}
    local prev = h.menuBtn
    for i = #UI.TOP_ICONS, 1, -1 do
        local key = UI.TOP_ICONS[i]
        local b = iconButton(h, key, 32, UI.TITLES[key], function() UI.ShowPanel(key) end)
        b:SetPoint("TOPRIGHT", prev, "TOPLEFT", -4, 0)
        h.top[key] = b
        prev = b
    end

    -- bottom: EXP along the bottom edge
    h.exp = W.Bar(h, WIDTH - 8, 5, 0.6, 0.9, 0.2)
    h.exp:SetPoint("BOTTOMLEFT", 0, 0)
    h.exp:SetPoint("BOTTOMRIGHT", 0, 0)
    h.exp.text:Hide()
    h.expText = W.Text(h, 13, W.COLORS.white, "LEFT")
    h.expText:SetPoint("BOTTOMLEFT", 10, 9)

    -- bottom centre: nav bar
    local nav = capsule(h, 372, 60, 0.7)
    nav:SetPoint("BOTTOM", 0, 10)
    h.navBar = nav
    h.nav = {}
    for i, key in ipairs(UI.NAV) do
        local b = iconButton(nav, key, 28, UI.TITLES[key], function() UI.ShowPanel(key) end)
        b:SetPoint("LEFT", 12 + (i - 1) * 72, -1)
        h.nav[key] = b
    end

    -- character box (Lv / name / HP / MP)
    local box = CreateFrame("Frame", nil, h, BD)
    box:SetSize(254, 64)
    box:SetPoint("BOTTOM", nav, "TOP", -10, 8)
    W.Backdrop(box, { 0.1, 0.11, 0.14, 0.92 }, { 0.38, 0.41, 0.48, 1 }, 10)
    box.lv = W.Text(box, 14, { 1, 0.82, 0.25 }, "LEFT")
    box.lv:SetPoint("TOPLEFT", 12, -7)
    box.name = W.Text(box, 14, W.COLORS.white, "CENTER")
    box.name:SetPoint("TOP", 22, -7)
    box.hpLabel = W.Text(box, 10, W.THEME.dim, "LEFT")
    box.hpLabel:SetPoint("TOPLEFT", 12, -28)
    box.hpLabel:SetText("HP")
    box.hp = W.Bar(box, 200, 12, 0.92, 0.24, 0.36)
    box.hp:SetPoint("LEFT", box.hpLabel, "RIGHT", 12, 0)
    box.mpLabel = W.Text(box, 10, W.THEME.dim, "LEFT")
    box.mpLabel:SetPoint("TOPLEFT", 12, -45)
    box.mpLabel:SetText("MP")
    box.mp = W.Bar(box, 200, 12, 0.2, 0.62, 0.95)
    box.mp:SetPoint("LEFT", box.mpLabel, "RIGHT", 12, 0)
    h.box = box
    h.buffs = {}
    for i = 1, 8 do
        local bi = h:CreateTexture(nil, "OVERLAY")
        bi:SetSize(22, 22)
        bi:SetPoint("BOTTOMLEFT", box, "TOPLEFT", (i - 1) * 24, 4)
        bi:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        bi:Hide()
        h.buffs[i] = bi
    end

    -- Full Auto (자동 도전)
    local fa = CreateFrame("Button", nil, h)
    fa:SetSize(50, 58)
    fa:SetPoint("LEFT", box, "RIGHT", 10, 0)
    fa.icon = fa:CreateTexture(nil, "ARTWORK")
    fa.icon:SetSize(32, 32)
    fa.icon:SetPoint("TOP")
    fa.icon:SetTexture("Interface\\Icons\\Ability_Rogue_Sprint")
    fa.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    fa.text = W.Text(fa, 11, W.COLORS.white, "CENTER")
    fa.text:SetPoint("TOP", fa.icon, "BOTTOM", 0, -1)
    fa.text:SetText("Full\nAuto")
    fa:SetScript("OnClick", function()
        local hr = hero()
        if not hr then return end
        hr.campaign.autoChallenge = not hr.campaign.autoChallenge
        hr.campaign.autoChallengeBlocked = nil
        UI.RefreshHud()
    end)
    W.Tooltip(fa, function(tt)
        tt:AddLine("Full Auto", 1, 0.82, 0)
        tt:AddLine("켜 두면 다음 스테이지에 자동으로 도전합니다.", 1, 1, 1)
    end)
    h.fullAuto = fa

    -- bottom left: main companion
    local comp = W.Icon(h, 50)
    comp:SetPoint("BOTTOMRIGHT", nav, "BOTTOMLEFT", -16, 8)
    comp.level = W.Text(comp, 11, W.COLORS.white, "CENTER")
    comp.level:SetPoint("TOP", comp, "BOTTOM", 0, -1)
    comp:SetScript("OnClick", function() UI.ShowPanel("companions") end)
    h.companion = comp

    -- bottom right: skill slots (2 rows x 3) with cooldown numbers
    h.skills = {}
    for i = 1, 6 do
        local s = W.Icon(h, 46)
        local col, row = (i - 1) % 3, math.floor((i - 1) / 3)
        s:SetPoint("BOTTOMRIGHT", -14 - (2 - col) * 52, 16 + (1 - row) * 52)
        s.shade = s:CreateTexture(nil, "OVERLAY")
        s.shade:SetColorTexture(0, 0, 0, 0.6)
        s.shade:SetPoint("BOTTOMLEFT", 3, 3)
        s.shade:SetPoint("BOTTOMRIGHT", -3, 3)
        s.shade:SetHeight(1)
        s.shade:Hide()
        s.cdText = W.Text(s, 19, W.COLORS.white, "CENTER")
        s.cdText:SetPoint("CENTER")
        W.Tooltip(s, function(tt)
            if not s.inst then return end
            tt:AddLine(ns.Skin.SkillName(s.inst.id), 1, 0.82, 0)
            tt:AddLine(string.format("스킬 레벨 %d", s.inst.level or 1), 1, 1, 1)
        end)
        h.skills[i] = s
    end
end

function UI.RefreshHud()
    local h = UI.hud
    local hr = hero()
    if not (h and hr) then return end
    local job = ns.Hero.Job(hr)
    local skin = ns.Skin and ns.Skin.Job(job) or {}
    h.portrait.icon:SetTexture(skin.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    local cp = ns.Game.profile and ns.Hero.CombatPower(ns.Game.profile) or 0
    h.cp:SetText("|TInterface\\Icons\\INV_Sword_04:16:16|t " .. U.Comma(cp))
    local rankText = ""
    if ns.Arena and hr.arena then
        local _, row, rank = ns.Arena.Tier(hr)
        rankText = string.format("|TInterface\\Icons\\INV_BannerPVP_02:14:14|t %d 위 · %s", rank or 1, row and row.name or "")
    end
    h.rank:SetText(rankText)
    local function amount(key)
        local n = ns.Hero.Count(hr, key)
        return string.format("|T%s:16:16|t %s", ns.Data.CurrencyIcon(key), n < 1e8 and U.Comma(n) or U.FormatNumber(n))
    end
    h.gold.text:SetText(amount("meso"))
    h.dia.text:SetText(amount("redDia"))

    -- stage
    local cp2 = hr.campaign
    local cd = ns.Data.Chapters[cp2.chapter]
    local total = cd and #cd.stages or 1
    local zone = ns.Skin and ns.Skin.ChapterName and ns.Skin.ChapterName(cp2.chapter) or ("챕터 " .. cp2.chapter)
    h.zone:SetText(string.format("|TInterface\\Icons\\INV_Misc_Map_01:14:14|t %d.%s", cp2.chapter, zone))
    h.stageText:SetText(string.format("Stage %d/%d", cp2.stage, total))
    h.stageBar:SetValue(cp2.stage / math.max(1, total))
    local nch, nst, kind = ns.Campaign.NextChallenge(hr)
    if nch then
        local label = kind == "boss" and "보스" or ("Stage " .. nst)
        if nch ~= cp2.chapter then label = string.format("Stage %d-%d", nch, nst) end
        h.nextStage:SetText(label)
        h.challenge:Show()
    else
        h.nextStage:SetText("")
        h.challenge:Hide()
    end
    h.challenge:SetEnabled(ns.Game.mode == "hunt" and nch ~= nil)
    local b = ns.Game.battle
    h.timer:SetText(b and b.timeLimit and string.format("남은 시간 %.0f초", math.max(0, (b.timeLimit - b.time) / 1000)) or "")

    -- goal box: job advancement first, then the next stage
    local goal = h.goal
    local nx = ns.JobAdvance and ns.JobAdvance.Next(hr)
    if nx and nx.ready then
        goal.title:SetText(string.format("%s 전직", ns.Data.JobAdvancement.stepNames[nx.step]))
        goal.desc:SetText("전직 시험 통과하기: 0/1")
        goal.action = function() UI.ShowPanel("content") end
    elseif nch then
        goal.title:SetText(kind == "boss" and "챕터 보스" or "스테이지 돌파")
        goal.desc:SetText(string.format("%s - %d 돌파하기: 0/1", ns.Skin.ChapterName(nch), nst))
        goal.action = function() ns.Game.StartChallenge() end
    else
        goal.title:SetText("모든 챕터 완료")
        goal.desc:SetText("")
        goal.action = nil
    end

    -- character box
    local box = h.box
    box.lv:SetText("Lv." .. hr.level)
    local medal = ns.Medals and ns.Medals.Equipped(hr)
    box.name:SetText((medal and ("|cffa335ee<" .. medal.name .. ">|r ") or "") .. (hr.name or ""))
    local hc = b and b.heroCreature
    if hc then
        local mh, mm = math.max(1, hc:Stat("MaxHp")), math.max(1, hc:Stat("MaxMp"))
        box.hp:SetValue(hc.hp / mh)
        box.hp.text:SetText(string.format("%s/%s", U.Comma(math.floor(math.max(0, hc.hp))), U.Comma(mh)))
        box.mp:SetValue(hc.mp / mm)
        box.mp.text:SetText(string.format("%s/%s", U.Comma(math.floor(math.max(0, hc.mp))), U.Comma(mm)))
    end
    -- buffs (boosters, content buffs)
    local icons = {}
    if hr.booster and U.Now() < (hr.booster.untilTime or 0) then icons[#icons + 1] = "Interface\\Icons\\Spell_Holy_WordFortitude" end
    if hr.expBoosterBuff and U.Now() < (hr.expBoosterBuff.untilTime or 0) then icons[#icons + 1] = "Interface\\Icons\\INV_Potion_43" end
    if ns.Content and ns.Content.ActiveBuffs then
        for _ in pairs(ns.Content.ActiveBuffs(hr) or {}) do icons[#icons + 1] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofWisdom" end
    end
    for i, bi in ipairs(h.buffs) do
        if icons[i] then bi:SetTexture(icons[i]); bi:Show() else bi:Hide() end
    end
    local on = hr.campaign.autoChallenge
    h.fullAuto.icon:SetDesaturated(not on)
    h.fullAuto.text:SetTextColor(on and 0.55 or 0.7, on and 1 or 0.7, on and 0.4 or 0.7)

    -- EXP
    local need = ns.Hero.ExpToNext(hr.level)
    h.exp:SetValue(need < math.huge and hr.exp / need or 1)
    h.expText:SetText(need < math.huge and string.format("|cffffd100EXP|r %.3f%%", hr.exp / need * 100) or "|cffffd100EXP|r MAX")

    -- main companion
    local main = ns.Companions and hr.companions and hr.companions.main and ns.Companions.Def(hr.companions.main)
    if main then
        local look = ns.Skin.Job(ns.SkillBook.JobByKey(main.job))
        h.companion.icon:SetTexture(look.icon)
        W.SetBorderGrade(h.companion, main.grade)
        local rec = ns.Companions.Get(hr, hr.companions.main)
        h.companion.level:SetText("Lv." .. (rec and rec.level or 1))
        h.companion:Show()
    else
        h.companion:Hide()
    end

    -- red dots
    local any = false
    for key, btn in pairs(h.nav) do btn.dot:SetShown(UI.Badge(key, hr)) end
    for key, btn in pairs(h.top) do btn.dot:SetShown(UI.Badge(key, hr)) end
    for _, def in ipairs(UI.panelOrder) do if UI.Badge(def.key, hr) then any = true end end
    h.menuBtn.dot:SetShown(any)
    UI.RefreshSkills()
end
UI.RefreshHeroBar = UI.RefreshHud

-- live parts (called 4x a second by the battle view): HP / MP, timer, skill cooldowns
function UI.RefreshLive()
    local h = UI.hud
    local b = ns.Game.battle
    if not (h and b and UI.frame and UI.frame:IsShown()) then return end
    local hc = b.heroCreature
    if hc then
        local mh, mm = math.max(1, hc:Stat("MaxHp")), math.max(1, hc:Stat("MaxMp"))
        h.box.hp:SetValue(hc.hp / mh)
        h.box.hp.text:SetText(string.format("%s/%s", U.Comma(math.floor(math.max(0, hc.hp))), U.Comma(mh)))
        h.box.mp:SetValue(hc.mp / mm)
        h.box.mp.text:SetText(string.format("%s/%s", U.Comma(math.floor(math.max(0, hc.mp))), U.Comma(mm)))
    end
    h.timer:SetText(b.timeLimit and string.format("남은 시간 %.0f초", math.max(0, (b.timeLimit - b.time) / 1000)) or "")
    UI.RefreshSkills()
end

-- skill slots: active skills, cooldown shade + seconds
function UI.RefreshSkills()
    local h = UI.hud
    local b = ns.Game.battle
    local hc = b and b.heroCreature
    if not (h and hc) then return end
    local list = hc.activeList or {}
    for i, s in ipairs(h.skills) do
        local inst = list[i]
        if inst then
            s.icon:SetTexture(ns.Skin.SkillIcon and ns.Skin.SkillIcon(inst.id) or "Interface\\Icons\\INV_Misc_QuestionMark")
            local rem = hc.cooldowns and hc.cooldowns[inst.id] or 0
            local total = ns.Battle.CooldownFor(b, hc, inst)
            if rem > 0 and total > 0 then
                s.shade:SetHeight(math.max(1, 40 * rem / total))
                s.shade:Show()
                s.cdText:SetText(string.format("%d", math.ceil(rem / 1000)))
            else
                s.shade:Hide()
                s.cdText:SetText("")
            end
            s.inst = inst
        else
            s.icon:SetTexture(nil)
            s.shade:Hide()
            s.cdText:SetText("")
            s.inst = nil
        end
    end
end

---------------------------------------------------------------------------
-- red dots: a panel's badge(hero) (something to claim / spend)
---------------------------------------------------------------------------
function UI.Badge(key, hr)
    local def = UI.panels[key]
    if not (def and def.badge and hr) then return false end
    local ok, v = pcall(def.badge, hr)
    return ok and v and true or false
end

---------------------------------------------------------------------------
-- Panel host (centred popup) and the full menu
---------------------------------------------------------------------------
function UI.BuildHosts(f)
    local pop = W.Panel(f, POPUP_W, POPUP_H, 0.97)
    pop:SetPoint("CENTER", 0, -6)
    pop:SetFrameLevel(f:GetFrameLevel() + 60)
    pop:EnableMouse(true)
    pop:Hide()
    pop.header = CreateFrame("Frame", nil, pop, BD)
    pop.header:SetPoint("TOPLEFT", 4, -4)
    pop.header:SetPoint("TOPRIGHT", -4, -4)
    pop.header:SetHeight(40)
    W.Backdrop(pop.header, T.header, T.header, 8)
    pop.title = W.Text(pop.header, 17, W.COLORS.white, "CENTER")
    pop.title:SetPoint("CENTER")
    pop.close = W.Button(pop.header, "X", 30, 28, function() UI.ClosePanel() end, "gray")
    pop.close:SetPoint("RIGHT", -6, 0)
    UI.popup = pop
    UI.content = CreateFrame("Frame", nil, pop)
    UI.content:SetPoint("TOPLEFT", 14, -52)
    UI.content:SetPoint("BOTTOMRIGHT", -14, 12)

    local menu = W.Panel(f, 572, 260, 0.97)
    menu:SetPoint("TOPRIGHT", -10, -74)
    menu:SetFrameLevel(f:GetFrameLevel() + 70)
    menu:EnableMouse(true)
    menu:Hide()
    menu.title = W.Text(menu, 16, W.COLORS.white, "CENTER")
    menu.title:SetPoint("TOP", 0, -12)
    menu.title:SetText("전체 메뉴")
    menu.buttons = {}
    UI.menu = menu
end

function UI.ToggleMenu()
    local menu = UI.menu
    if menu:IsShown() then menu:Hide() return end
    local hr = hero()
    for i, def in ipairs(UI.panelOrder) do
        local b = menu.buttons[i]
        if not b then
            b = iconButton(menu, def.key, 40, def.title, function()
                menu:Hide()
                UI.ShowPanel(def.key)
            end)
            local col, row = (i - 1) % 7, math.floor((i - 1) / 7)
            b:SetPoint("TOPLEFT", 18 + col * 78, -44 - row * 98)
            b:SetWidth(70)
            menu.buttons[i] = b
        end
        b.dot:SetShown(UI.Badge(def.key, hr))
    end
    menu:Show()
end

function UI.ShowPanel(key)
    local def = UI.panels[key]
    if not def or not UI.content then return end
    if ns.Requests and hero() then ns.Requests.Visited(hero(), key) end
    for _, d in pairs(UI.panels) do if d.frame then d.frame:Hide() end end
    if not def.frame then
        local p = CreateFrame("Frame", nil, UI.content)
        p:SetAllPoints()
        def.frame = p
        local ok, err = pcall(def.build, p)
        if not ok then ns.Print("|cffff4040패널 오류|r %s: %s", key, tostring(err)) end
    end
    UI.popup.title:SetText(def.title)
    UI.popup:Show()
    if UI.menu then UI.menu:Hide() end
    def.frame:Show()
    UI.current = key
    UI.RefreshPanel()
end

function UI.ClosePanel()
    if UI.popup then UI.popup:Hide() end
    local def = UI.current and UI.panels[UI.current]
    if def and def.frame then def.frame:Hide() end
    UI.current = nil
end

function UI.RefreshPanel()
    local def = UI.current and UI.panels[UI.current]
    local hr = hero()
    if def and def.refresh and def.frame and hr then
        local ok, err = pcall(def.refresh, def.frame, hr)
        if not ok then ns.Debug("panel refresh %s: %s", def.key, tostring(err)) end
    end
end

function UI.Refresh()
    if not (UI.frame and UI.frame:IsShown()) then return end
    if not hero() then
        UI.ShowCreate()
        return
    end
    if UI.createFrame then UI.createFrame:Hide() end
    UI.RefreshHud()
    UI.RefreshPanel()
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
for _, ev in ipairs({ "HERO_CHANGED", "WALLET_CHANGED", "HERO_LEVEL_UP", "STAGE_CLEARED", "MASTERY_LEARNED", "HERO_ACTIVATED",
    "BATTLE_STARTED" }) do
    ns.On(ev, queueRefresh)
end

---------------------------------------------------------------------------
-- Character creation (job select)
---------------------------------------------------------------------------
function UI.ShowCreate()
    local f = UI.createFrame
    if not f then
        f = W.Panel(UI.frame, POPUP_W, POPUP_H + 50, 0.98)
        f:SetPoint("CENTER", 0, 0)
        f:SetFrameLevel(UI.frame:GetFrameLevel() + 80)
        f:EnableMouse(true)
        UI.createFrame = f
        local t = W.Text(f, 20, W.COLORS.white, "CENTER")
        t:SetPoint("TOP", 0, -16)
        t:SetText("직업 선택")
        for i, job in ipairs(ns.Data.Jobs) do
            local skin = ns.Skin and ns.Skin.Job(job) or {}
            local col, row = (i - 1) % 4, math.floor((i - 1) / 4)
            local b = W.Card(f, 234, 112)
            b:SetPoint("TOPLEFT", 16 + col * 242, -54 - row * 118)
            local icon = W.Icon(b, 46, skin.icon)
            icon:SetPoint("TOPLEFT", 10, -10)
            local name = W.Text(b, 15, W.COLORS.white, "LEFT")
            name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -2)
            name:SetText(skin.display)
            local sub = W.Text(b, 11, W.THEME.dim, "LEFT")
            sub:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -6)
            sub:SetText(string.format("주 스탯 %s · %s 공격", job.mainStat, job.attackType == "Magical" and "마법" or "물리"))
            local pick = W.Button(b, "선택", 96, 26, function()
                W.Confirm(string.format("%s(으)로 시작할까요?", skin.display), function()
                    local hr = ns.Hero.New(job.key)
                    ns.Hero.SetActive(hr)
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
    -- first run (no character yet): open the window so the job selection is visible
    local first = not ns.Hero.Active()
    if ns.db.settings.autoOpen or first then UI.Toggle() end
    ns.Print("|cffffd100빅 스토리 키우기|r 준비 완료 — |cff40ff40/bsi|r 또는 미니맵 버튼으로 창을 엽니다. (/bsi help: 명령어)")
end)

ns.RegisterSlash("minimap", "미니맵 버튼 표시/숨김", function()
    ns.db.settings.minimap.hide = not ns.db.settings.minimap.hide
    if UI.minimap then
        if ns.db.settings.minimap.hide then UI.minimap:Hide() else UI.minimap:Show() end
    end
end)
