-- Opens every panel / section / popup and hovers every tooltip, records every string the UI draws
-- (SetText / AddLine / AddDoubleLine / toasts / chat) and fails if a 메이플 키우기 proper noun shows up.
-- The skin is WoW only: jobs, characters, places, bosses and branded names must not be visible.
package.path = "tools/test/?.lua;" .. package.path
local Stub = require("wowstub")
Stub.Install()
local seen, order = {}, {}
local function rec(s)
    if type(s) ~= "string" or s == "" then return end
    if not seen[s] then seen[s] = true; order[#order + 1] = s end
end
local frames = {}
local origCreate = CreateFrame
CreateFrame = function(...)
    local f = origCreate(...)
    frames[#frames + 1] = f
    return f
end
local mt = getmetatable(origCreate("Frame"))
local origSetText = mt.SetText
mt.SetText = function(self, t, ...) rec(t); return origSetText(self, t, ...) end
mt.AddLine = function(self, t) rec(t) end
mt.AddDoubleLine = function(self, a, b) rec(a); rec(b) end
mt.SetFormattedText = function(self, fmt, ...) rec(string.format(fmt, ...)) end
UIErrorsFrame = { AddMessage = function(_, msg) rec(msg) end }

local H = require("harness")
H.loadToc()
local ns = H.ns
ns.Print = function(fmt, ...) rec(select("#", ...) > 0 and string.format(fmt, ...) or tostring(fmt)) end
local ef = ns.eventFrame
ef._scripts.OnEvent(ef, "ADDON_LOADED", "BigStoryIdleRPG")
ef._scripts.OnEvent(ef, "PLAYER_LOGIN")
if not (ns.UI.frame and ns.UI.frame:IsShown()) then ns.UI.Toggle() end
for _, f in ipairs(frames) do if f._scripts.OnShow then pcall(f._scripts.OnShow, f) end end   -- job picker

local hero = ns.Hero.New(arg[1] or "hero", "S")
hero.level = 120
hero.jobStep = 4
hero.campaign.maxChapter, hero.campaign.maxStage = 40, 1
ns.Hero.SetActive(hero)
for _, k in ipairs({ "weaponTicket", "companionTicket", "redDia", "meso", "starforceScroll", "cubeMiracle" }) do
    ns.Hero.Add(hero, k, 1000000)
end
ns.Summon.Pull(hero, "companion", 100)
ns.Summon.Pull(hero, "weapon", 100)
ns.UI.Refresh()

local function hoverAll()
    for _, f in ipairs(frames) do
        if f._scripts.OnEnter then pcall(f._scripts.OnEnter, f) end
    end
end
for _, def in ipairs(ns.UI.panelOrder) do
    ns.UI.ShowPanel(def.key)
    ns.UI.RefreshPanel()
    local p = def.frame
    if p then
        for s = 1, 8 do
            if p.section ~= nil then p.section = s end
            if p.cat ~= nil then p.cat = s end
            pcall(ns.UI.RefreshPanel)
            hoverAll()
        end
        for pg = 0, 5 do if p.page ~= nil then p.page = pg; pcall(ns.UI.RefreshPanel) end end
    end
end
-- buttons that open popups (확률표 etc.)
for _, f in ipairs(frames) do
    local t = f._text or ""
    if type(t) == "string" and (t:find("확률") or t:find("정보") or t:find("목록")) and f._scripts.OnClick then
        pcall(f._scripts.OnClick, f, "LeftButton")
        hoverAll()
    end
end
for i = 1, 300 do
    if Stub.ticker then Stub.ticker() end
    ns.BattleView.OnUpdate(0.1)
end

-- every content mode (title, group, info lines with default selectors) and every data name
for _, m in ipairs(ns.Content.Modes()) do
    rec(m.title); rec(m.group)
    local sel = {}
    for _, sd in ipairs(m.selectors or {}) do
        local d = sd.default
        if type(d) == "function" then d = select(2, pcall(d, hero)) end
        if d == nil and sd.options then d = 1 end
        if d == nil and sd.min then d = sd.min end
        sel[sd.key] = d
    end
    if m.info then
        local ok, lines = pcall(m.info, hero, sel)
        if ok and type(lines) == "table" then for _, l in ipairs(lines) do rec(l) end end
    end
    for _, a in ipairs(m.actions or {}) do rec(a.label) end
end
for _, sid in ipairs(ns.Companions.All()) do rec(ns.Companions.Def(sid).name) end
for _, a in ipairs(ns.Data.Artifacts.list) do rec(a.name) end
for code in pairs(ns.Data.Gear) do
    local g = ns.Data.Gear[code]
    rec(ns.Equipment.ItemName({ code = code, grade = g.grade, tier = g.tier, part = g.part }))
end
for _, j in ipairs(ns.Data.Jobs) do
    rec(ns.Skin.Job(j).display)
    for _, row in ipairs(j.rows) do rec(ns.Skin.SkillName(row.SkillIndex)) end
end
for _, c in pairs(ns.Data.Currencies) do rec(c.name) end

local BANNED = { "히어로", "팔라딘", "다크나이트", "아크메이지", "비숍", "보우마스터", "신궁", "나이트로드", "섀도어",
    "바이퍼", "캡틴", "윈드브레이커", "나이트워커", "소울마스터", "플레임위자드", "지망생", "메이플", "자쿰", "혼테일",
    "핑크빈", "발록", "머쉬맘", "그리페", "마뇽", "엘리노어", "헤네시스", "엘리니아", "페리온", "커닝", "리스항구",
    "오르비스", "루디브리엄", "엘나스", "리프레", "아리안트", "마가티아", "시그너스", "첫 번째 동행", "차원의 균열",
    "여신의 흔적", "로미오", "줄리엣", "몬스터파크", "메소", "레드 다이아", "스타포스", "엘리트", "미라클 큐브",
    "에디셔널", "용사의 힘", "주문의 흔적", "브루스", "카산드라", "밍밍", "클로이", "카밀라", "케이시", "스탄" }
local bad = 0
for _, s in ipairs(order) do
    for _, w in ipairs(BANNED) do
        if s:find(w, 1, true) then
            bad = bad + 1
            if bad <= 400 then print(string.format("[%s] %s", w, s:gsub("\n", " / "):sub(1, 160))) end
            break
        end
    end
end
print(string.format("names: %d strings drawn, %d with original names", #order, bad))
if bad > 0 then os.exit(1) end
