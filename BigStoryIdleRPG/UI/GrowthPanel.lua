-- 성장 패널: 하위 버튼으로 4개 화면을 전환한다.
--   용사의 힘(능력치 강화 / 단계 승급 타이머 / 시간 단축), 어빌리티(변환 / 줄 잠금 / 등급 확률),
--   유물(상자 / 각성 / 콘텐츠별 프리셋 / 공명 증폭), 여정(보물 게이지·카드, 여정의 상자·축복, 발자취).
local ADDON, ns = ...
local W = ns.W
local U = ns.U
local UI = ns.UI
local D = ns.Data

local VIEW_Y = -48
local VIEWS = {
    { key = "heroPower", label = "영웅의 힘", sys = "HeroPower" },
    { key = "ability", label = "어빌리티", sys = "Ability" },
    { key = "artifacts", label = "유물", sys = "Artifacts" },
    { key = "journey", label = "여정", sys = "Journey" },
}
local MAX_HP_SLOTS = 6
local MAX_AB_LINES = 8
local ART_COLS, ART_STEP, ART_ICON = 12, 30, 28
local ARTIFACT_ICONS = {
    "INV_Jewelry_Talisman_01", "INV_Misc_Idol_02", "INV_Misc_Orb_01", "INV_Misc_Rune_04", "INV_Misc_Gem_Pearl_05",
    "INV_Misc_Bone_ElfSkull_01", "INV_Misc_Ribbon_01", "INV_Misc_Book_09", "INV_Misc_Head_Dragon_01",
    "INV_Misc_Gem_Variety_02", "INV_Misc_Orb_02", "INV_Misc_Idol_03",
}
-- artifact grade 3..5 / ability & trail grades 1..7 -> widget grade colors
local ART_GRADE_COLOR = { [3] = 3, [4] = 4, [5] = 5 }

---------------------------------------------------------------------------
-- helpers
---------------------------------------------------------------------------
local function call(where, fn, ...)
    local ok, a, b, c = pcall(fn, ...)
    if not ok then
        if ns.Debug then ns.Debug("growth ui %s: %s", where, tostring(a)) end
        W.Toast(tostring(a), W.COLORS.red)
        return nil
    end
    return a, b, c
end

local function refreshNow() UI.RefreshPanel() end

local function fmtStat(stat, raw)
    if ns.Upgrades and ns.Upgrades.FormatStat then return ns.Upgrades.FormatStat(stat, raw) end
    return string.format("%s +%s", ns.StatLabels and ns.StatLabels[stat] or stat, tostring(raw))
end

local function statList(list, maxN)
    local parts = {}
    for i, s in ipairs(list or {}) do
        if maxN and i > maxN then parts[#parts + 1] = "..." break end
        parts[#parts + 1] = fmtStat(s[1], s[2])
    end
    return parts
end

-- merge {stat, raw} pairs by stat, keep first-seen order
local function mergeStats(list)
    local out, idx = {}, {}
    for _, s in ipairs(list or {}) do
        local i = idx[s[1]]
        if i then out[i][2] = out[i][2] + s[2] else
            out[#out + 1] = { s[1], s[2] }
            idx[s[1]] = #out
        end
    end
    return out
end

local function costText(costs, hero)
    local parts = {}
    for _, k in ipairs(U.Keys(costs or {})) do
        local n = costs[k]
        if n and n > 0 then
            local s = (W.Money(k, n))
            if hero and ns.Hero.Count(hero, k) < n then s = "|cffff5050" .. s .. "|r" end
            parts[#parts + 1] = s
        end
    end
    return #parts > 0 and table.concat(parts, "  ") or "무료"
end

local function gradeHex(g) return W.Hex(W.GradeColor(g)) end

local function stars(n, max)
    local s = ""
    for i = 1, max do s = s .. (i <= n and "|cffffd100★|r" or "|cff555555☆|r") end
    return s
end

local function view(p)
    local v = CreateFrame("Frame", nil, p)
    v:SetPoint("TOPLEFT", 9, VIEW_Y)
    v:SetSize(944, 218)
    v:Hide()
    return v
end

local function selIcon(ic)
    ic.sel = ic:CreateTexture(nil, "OVERLAY")
    ic.sel:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    ic.sel:SetBlendMode("ADD")
    ic.sel:SetAllPoints()
    ic.sel:Hide()
    ic:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
end

---------------------------------------------------------------------------
-- 용사의 힘
---------------------------------------------------------------------------
local function hpLevelUp(slot, count)
    local hero = ns.Hero.Active()
    if not hero then return end
    local n, err = call("heroPowerLevelUp", ns.HeroPower.LevelUp, hero, slot, count)
    if n and n > 0 then W.Toast(string.format("영웅의 힘 +%d", n), W.COLORS.green) elseif err then W.Toast(err, W.COLORS.red) end
    refreshNow()
end

local function buildHeroPower(p)
    local v = view(p)
    v.title = W.Text(v, 14, W.COLORS.gold, "LEFT")
    v.title:SetPoint("TOPLEFT", 0, 0)
    v.title:SetWidth(640)
    v.bonus = W.Text(v, 11, W.COLORS.white, "LEFT")
    v.bonus:SetPoint("TOPLEFT", 0, -20)
    v.bonus:SetWidth(640)
    v.rows = {}
    for i = 1, MAX_HP_SLOTS do
        local y = -40 - (i - 1) * 25
        local r = {}
        r.label = W.Text(v, 12, W.COLORS.white, "LEFT")
        r.label:SetPoint("TOPLEFT", 0, y - 4)
        r.label:SetWidth(100)
        r.level = W.Text(v, 11, W.COLORS.gold, "LEFT")
        r.level:SetPoint("TOPLEFT", 100, y - 4)
        r.level:SetWidth(70)
        r.value = W.Text(v, 11, W.COLORS.white, "LEFT")
        r.value:SetPoint("TOPLEFT", 170, y - 4)
        r.value:SetWidth(240)
        r.cost = W.Text(v, 11, W.COLORS.white, "LEFT")
        r.cost:SetPoint("TOPLEFT", 410, y - 4)
        r.cost:SetWidth(100)
        r.b1 = W.Button(v, "+1", 40, 20, function() hpLevelUp(i, 1) end)
        r.b1:SetPoint("TOPLEFT", 512, y)
        r.b10 = W.Button(v, "+10", 42, 20, function() hpLevelUp(i, 10) end)
        r.b10:SetPoint("LEFT", r.b1, "RIGHT", 2, 0)
        r.bMax = W.Button(v, "최대", 46, 20, function() hpLevelUp(i, 1000) end)
        r.bMax:SetPoint("LEFT", r.b10, "RIGHT", 2, 0)
        v.rows[i] = r
    end
    v.adv = W.Text(v, 11, W.COLORS.white, "LEFT")
    v.adv:SetPoint("TOPLEFT", 0, -196)
    v.adv:SetWidth(420)
    v.advBtn = W.Button(v, "승급", 80, 22, function()
        local hero = ns.Hero.Active()
        if not hero then return end
        local ok, err = call("heroPowerAdvance", ns.HeroPower.StartAdvance, hero)
        if ok then W.Toast("영웅의 힘 승급을 시작했습니다.", W.COLORS.green) elseif err then W.Toast(err, W.COLORS.red) end
        refreshNow()
    end)
    v.advBtn:SetPoint("TOPLEFT", 430, -192)
    v.skipBtn = W.Button(v, "시간 단축", 96, 22, function()
        local hero = ns.Hero.Active()
        if not hero then return end
        local rem = ns.HeroPower.AdvanceRemaining(hero) or 0
        local ok, err = call("heroPowerSkip", ns.HeroPower.Skip, hero, math.max(1, math.ceil(rem / 60)))
        if ok then W.Toast("승급 시간을 단축했습니다.", W.COLORS.green) elseif err then W.Toast(err, W.COLORS.red) end
        refreshNow()
    end)
    v.skipBtn:SetPoint("LEFT", v.advBtn, "RIGHT", 4, 0)

    v.sumTitle = W.Text(v, 12, W.COLORS.gold, "LEFT")
    v.sumTitle:SetPoint("TOPLEFT", 680, 0)
    v.sumTitle:SetText("현재 영웅의 힘 효과")
    v.sum = W.Text(v, 11, W.COLORS.white, "LEFT")
    v.sum:SetPoint("TOPLEFT", 680, -20)
    v.sum:SetWidth(260)
    v.sum:SetJustifyV("TOP")

    v.elapsed = 0
    v:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + (elapsed or 0)
        if self.elapsed < 0.5 or not self.advancing then return end
        self.elapsed = 0
        local hero = ns.Hero.Active()
        if not hero then return end
        local rem = ns.HeroPower.AdvanceRemaining(hero)
        if not rem or rem <= 0 then
            self.advancing = nil
            call("heroPowerUpdate", ns.HeroPower.Update, hero)
            refreshNow()
        else
            self.adv:SetText("|cffffd100승급 중|r · 남은 시간 " .. U.FormatDuration(rem))
        end
    end)
    return v
end

local function refreshHeroPower(p, v, hero)
    local HP = ns.HeroPower
    call("heroPowerUpdate", HP.Update, hero)
    local stage, st = HP.Stage(hero)
    local maxStage = D.HeroPower and D.HeroPower.maxStage or 9
    v.title:SetText(string.format("영웅의 힘 |cffffffff%d단계|r |cff999999/ %d|r   %s", stage, maxStage,
        (W.Money("heroToken", ns.Hero.Count(hero, "heroToken")))))
    local bonus = statList(st and st.bonus or {})
    v.bonus:SetText(#bonus > 0 and ("단계 보너스: |cff40ff40" .. table.concat(bonus, ", ") .. "|r") or "|cff808080단계 보너스 없음|r")
    local slots = HP.Slots(hero)
    local advancing = hero.heroPower and hero.heroPower.advance ~= nil
    local tokens = ns.Hero.Count(hero, "heroToken")
    for i, r in ipairs(v.rows) do
        local s = slots[i]
        local show = s ~= nil
        for _, w in ipairs({ r.label, r.level, r.value, r.cost, r.b1, r.b10, r.bMax }) do
            if show then w:Show() else w:Hide() end
        end
        if s then
            r.label:SetText(s.label or ns.Upgrades.StatLabel(s.type))
            r.level:SetText(string.format("Lv.%d/%d", s.level, s.maxLevel))
            local cur = fmtStat(s.type, s.value or 0)
            r.value:SetText(s.nextValue and (cur .. " |cff40ff40→ " .. fmtStat(s.type, s.nextValue):gsub("^[^%+%-]*", "") .. "|r") or (cur .. " |cffffd100(최대)|r"))
            if s.nextCost then
                r.cost:SetText(costText({ heroToken = s.nextCost }, hero))
            else
                r.cost:SetText("")
            end
            local can = s.nextCost ~= nil and tokens >= s.nextCost and not advancing
            r.b1:SetEnabled(can)
            r.b10:SetEnabled(can)
            r.bMax:SetEnabled(can)
        end
    end
    local rem = HP.AdvanceRemaining(hero)
    if rem then
        v.advancing = true
        v.adv:SetText("|cffffd100승급 중|r · 남은 시간 " .. U.FormatDuration(rem))
        v.advBtn:SetEnabled(false)
        v.skipBtn:Show()
        v.skipBtn:SetText(string.format("단축 (%s)", U.FormatNumber(ns.Hero.Count(hero, "timeSkip1m"))))
        v.skipBtn:SetEnabled(ns.Hero.Count(hero, "timeSkip1m") > 0)
    else
        v.advancing = nil
        v.skipBtn:Hide()
        local ok, err = HP.CanAdvance(hero)
        if ok then
            local nextSt = D.HeroPower.stages[stage + 1]
            v.adv:SetText(string.format("|cff40ff40승급 가능|r · 대기 %s", U.FormatDuration(nextSt and nextSt.waitSec or 0)))
        else
            v.adv:SetText("|cff999999" .. tostring(err or "") .. "|r")
        end
        v.advBtn:SetEnabled(ok and true or false)
    end
    local sum = statList(mergeStats(HP.Stats(hero)))
    v.sum:SetText(#sum > 0 and table.concat(sum, "\n") or "|cff808080아직 효과가 없습니다.|r")
end

---------------------------------------------------------------------------
-- 어빌리티
---------------------------------------------------------------------------
local function abilityGradeColor(g) return gradeHex(math.min(g or 1, 8)) end

local function buildAbility(p)
    local v = view(p)
    v.title = W.Text(v, 14, W.COLORS.gold, "LEFT")
    v.title:SetPoint("TOPLEFT", 0, 0)
    v.title:SetWidth(460)
    v.bar = W.Bar(v, 440, 12, 0.4, 0.7, 1)
    v.bar:SetPoint("TOPLEFT", 0, -22)
    v.rows = {}
    for i = 1, MAX_AB_LINES do
        local y = -40 - (i - 1) * 22
        local r = {}
        r.lock = CreateFrame("CheckButton", nil, v, "UICheckButtonTemplate")
        r.lock:SetSize(20, 20)
        r.lock:SetPoint("TOPLEFT", 0, y)
        r.lock.slot = i
        r.lock:SetScript("OnClick", function(self)
            local hero = ns.Hero.Active()
            if not hero then return end
            local ok, err = call("abilityLock", ns.Ability.SetLock, hero, self.slot, self:GetChecked() and true or false)
            if not ok and err then W.Toast(err, W.COLORS.red) end
            refreshNow()
        end)
        W.Tooltip(r.lock, function(tt)
            tt:AddLine("줄 잠금", 1, 0.82, 0)
            tt:AddLine("잠근 줄은 변환해도 바뀌지 않습니다. 잠글수록 변환 비용이 오릅니다.", 1, 1, 1, true)
        end)
        r.text = W.Text(v, 12, W.COLORS.white, "LEFT")
        r.text:SetPoint("TOPLEFT", 26, y - 4)
        r.text:SetWidth(420)
        v.rows[i] = r
    end

    local RX = 480
    v.cost = W.Text(v, 12, W.COLORS.white, "LEFT")
    v.cost:SetPoint("TOPLEFT", RX, 0)
    v.cost:SetWidth(460)
    v.convBtn = W.Button(v, "변환", 120, 26, function()
        local hero = ns.Hero.Active()
        if not hero then return end
        local ok, err = call("abilityConvert", ns.Ability.Convert, hero)
        if not ok and err then W.Toast(err, W.COLORS.red) end
        refreshNow()
    end)
    v.convBtn:SetPoint("TOPLEFT", RX, -20)
    v.unlock = W.Text(v, 11, W.COLORS.gray, "LEFT")
    v.unlock:SetPoint("LEFT", v.convBtn, "RIGHT", 10, 0)
    v.unlock:SetWidth(330)
    v.chanceTitle = W.Text(v, 12, W.COLORS.gold, "LEFT")
    v.chanceTitle:SetPoint("TOPLEFT", RX, -56)
    v.chance = W.Text(v, 11, W.COLORS.white, "LEFT")
    v.chance:SetPoint("TOPLEFT", RX, -74)
    v.chance:SetWidth(220)
    v.chance:SetJustifyV("TOP")
    v.sum = W.Text(v, 11, W.COLORS.white, "LEFT")
    v.sum:SetPoint("TOPLEFT", RX + 230, -74)
    v.sum:SetWidth(230)
    v.sum:SetJustifyV("TOP")
    return v
end

local function refreshAbility(p, v, hero)
    local A = ns.Ability
    local DA = D.Ability or {}
    local lv, into, toNext = A.ExpInfo(hero)
    v.title:SetText(string.format("어빌리티 |cffffffffLv.%d|r |cff999999/ %d|r   %s", lv, DA.maxLevel or 20,
        (W.Money("honorMedal", ns.Hero.Count(hero, "honorMedal")))))
    if toNext then
        v.bar:SetValue(math.min(1, into / toNext))
        v.bar.text:SetText(string.format("%s / %s", U.Comma(into), U.Comma(toNext)))
    else
        v.bar:SetValue(1)
        v.bar.text:SetText("최대 레벨")
    end
    local slots = A.SlotCount(hero)
    local lines = A.Lines(hero)
    local unlockStage = DA.slotUnlockStage or {}
    for i, r in ipairs(v.rows) do
        local l = lines[i]
        if i <= slots then
            r.lock:Show()
            if l and l.opt then
                r.lock:SetChecked(l.locked and true or false)
                r.lock:SetEnabled(true)
                r.text:SetText(string.format("%s[%s]|r %s", abilityGradeColor(l.grade), l.gradeName or "", l.text or ""))
            else
                r.lock:SetChecked(false)
                r.lock:SetEnabled(false)
                r.text:SetText("|cff808080비어 있음 · 변환하면 옵션이 생깁니다.|r")
            end
        else
            r.lock:Hide()
            r.text:SetText(string.format("|cff555555잠김 · 영웅의 힘 %d단계에서 개방|r", unlockStage[i] or 0))
        end
    end
    local locked = A.LockedCount(hero)
    if slots > 0 then
        local cost = A.ConvertCost(hero)
        v.cost:SetText(string.format("변환 비용  %s  |cff999999(잠금 %d줄)|r", costText({ honorMedal = cost or 0 }, hero), locked))
        v.convBtn:SetEnabled(locked < slots and ns.Hero.Count(hero, "honorMedal") >= (cost or 0))
        v.unlock:SetText(slots < MAX_AB_LINES and string.format("다음 줄: 영웅의 힘 %d단계", unlockStage[slots + 1] or 0) or "모든 줄 개방")
    else
        v.cost:SetText("|cffff6060영웅의 힘 2단계에서 개방됩니다.|r")
        v.convBtn:SetEnabled(false)
        v.unlock:SetText("")
    end
    v.chanceTitle:SetText(string.format("Lv.%d 등급 확률", lv))
    local ch = A.GradeChances(lv) or {}
    local names = DA.gradeNames or {}
    local parts = {}
    for g, wgt in ipairs(ch) do
        if wgt > 0 then parts[#parts + 1] = string.format("%s%s|r  %.2f%%", abilityGradeColor(g), names[g] or g, wgt / 100) end
    end
    v.chance:SetText(table.concat(parts, "\n"))
    local sum = statList(mergeStats(A.Stats(hero)))
    v.sum:SetText(#sum > 0 and ("|cffffd100합계|r\n" .. table.concat(sum, "\n")) or "")
end

---------------------------------------------------------------------------
-- 유물
---------------------------------------------------------------------------
local function artifactIcon(id)
    return "Interface\\Icons\\" .. ARTIFACT_ICONS[(id % #ARTIFACT_ICONS) + 1]
end

local function artGrade(a) return ART_GRADE_COLOR[a.grade] or 3 end

local function artifactTooltip(tt, ic)
    local AR = ns.Artifacts
    local hero = ns.Hero.Active()
    local a = ic.id and AR.Get(ic.id)
    if not (a and hero) then
        if ic.slotText then tt:AddLine(ic.slotText, 1, 1, 1) end
        return
    end
    local o = hero.artifacts and hero.artifacts.owned[a.id]
    tt:AddLine(a.name, W.GradeColor(artGrade(a)))
    tt:AddLine(AR.GradeName(a.grade) .. " 유물", 0.8, 0.8, 0.8)
    if o then
        tt:AddLine(string.format("각성 %d / %d · 여분 %d개", o.awakening or 0, D.Artifacts.maxAwakening or 5, o.dupes or 0), 1, 1, 1)
    else
        tt:AddLine("미보유", 0.6, 0.6, 0.6)
    end
    local eff = AR.InventoryEffect(a.id, o and o.awakening or 0)
    for _, e in ipairs(eff) do
        tt:AddLine("보유 효과: " .. fmtStat(e[1], e[2]) .. (e[3] and " |cff999999(추정)|r" or ""), 0.3, 1, 0.3)
    end
    tt:AddLine(string.format("상자 획득 확률 %.4f%%", (AR.ChestChance(a.id) or 0) / 10000), 0.6, 0.6, 0.6)
    if ic.slotText then tt:AddLine(ic.slotText, 0.6, 0.6, 0.6) end
end

local function presetList()
    local AR = ns.Artifacts
    return AR.Presets and AR.Presets() or { { key = "Campaign", label = "사냥" } }
end

local function buildArtifacts(p)
    local v = view(p)
    v.icons = {}
    local list = {}
    for _, a in ipairs(ns.Artifacts.List()) do list[#list + 1] = a end
    table.sort(list, function(a, b)
        if a.grade ~= b.grade then return a.grade > b.grade end
        return a.id < b.id
    end)
    for i, a in ipairs(list) do
        local col, row = (i - 1) % ART_COLS, math.floor((i - 1) / ART_COLS)
        local ic = W.Icon(v, ART_ICON)
        ic:SetPoint("TOPLEFT", col * ART_STEP, -row * ART_STEP)
        ic.id = a.id
        selIcon(ic)
        ic.dupes = W.Text(ic, 9, W.COLORS.green, "LEFT")
        ic.dupes:SetPoint("TOPLEFT", 1, -1)
        ic:SetScript("OnClick", function(self) v.selected = self.id; refreshNow() end)
        W.Tooltip(ic, artifactTooltip)
        v.icons[#v.icons + 1] = ic
    end
    local gridH = math.ceil(#list / ART_COLS) * ART_STEP

    -- chest
    local y = -gridH - 6
    v.chest = W.Text(v, 12, W.COLORS.white, "LEFT")
    v.chest:SetPoint("TOPLEFT", 0, y - 4)
    v.chest:SetWidth(170)
    local function openChest(n)
        local hero = ns.Hero.Active()
        if not hero then return end
        local have = ns.Hero.Count(hero, "artifactChest")
        n = math.max(1, math.min(n, have))
        local got, err = call("artifactChest", ns.Artifacts.OpenChest, hero, n)
        if got then
            v.lastGot = got
            W.Toast(string.format("유물 %d개 획득", #got), W.COLORS.green)
        elseif err then
            W.Toast(err, W.COLORS.red)
        end
        refreshNow()
    end
    v.open1 = W.Button(v, "열기 x1", 70, 20, function() openChest(1) end)
    v.open1:SetPoint("TOPLEFT", 174, y)
    v.open10 = W.Button(v, "열기 x10", 76, 20, function() openChest(10) end)
    v.open10:SetPoint("LEFT", v.open1, "RIGHT", 4, 0)
    v.got = {}
    for i = 1, 10 do
        local ic = W.Icon(v, 22)
        ic:SetPoint("TOPLEFT", (i - 1) * 25, y - 26)
        ic:SetScript("OnClick", function(self) if self.id then v.selected = self.id; refreshNow() end end)
        W.Tooltip(ic, artifactTooltip)
        ic:Hide()
        v.got[i] = ic
    end

    -- resonance
    y = y - 56
    v.res = W.Text(v, 11, W.COLORS.white, "LEFT")
    v.res:SetPoint("TOPLEFT", 0, y - 4)
    v.res:SetWidth(240)
    v.res:SetJustifyV("TOP")
    local function resonate(n)
        local hero = ns.Hero.Active()
        if not hero then return end
        local ok, res = call("resonate", ns.Artifacts.Resonate, hero, n)
        if ok then W.Toast(string.format("공명 증폭 +%d", res or 1), W.COLORS.green) elseif res then W.Toast(res, W.COLORS.red) end
        refreshNow()
    end
    v.res1 = W.Button(v, "공명 증폭", 76, 20, function() resonate(1) end)
    v.res1:SetPoint("TOPLEFT", 244, y)
    v.res10 = W.Button(v, "x10", 40, 20, function() resonate(10) end)
    v.res10:SetPoint("LEFT", v.res1, "RIGHT", 2, 0)

    -- details
    local DX = 380
    v.bigIcon = W.Icon(v, 36)
    v.bigIcon:SetPoint("TOPLEFT", DX, 0)
    W.Tooltip(v.bigIcon, function(tt, self) self.id = v.selected; artifactTooltip(tt, self) end)
    v.name = W.Text(v, 13, W.COLORS.gold, "LEFT")
    v.name:SetPoint("TOPLEFT", v.bigIcon, "TOPRIGHT", 6, -1)
    v.name:SetWidth(300)
    v.aw = W.Text(v, 11, W.COLORS.white, "LEFT")
    v.aw:SetPoint("TOPLEFT", v.name, "BOTTOMLEFT", 0, -4)
    v.aw:SetWidth(300)
    v.awBtn = W.Button(v, "각성", 70, 22, function()
        local hero = ns.Hero.Active()
        if not (hero and v.selected) then return end
        local ok, err = call("artifactAwaken", ns.Artifacts.Awaken, hero, v.selected)
        if ok then W.Toast("유물 각성 성공!", W.COLORS.green) elseif err then W.Toast(err, W.COLORS.red) end
        refreshNow()
    end)
    v.awBtn:SetPoint("TOPRIGHT", 0, 0)
    v.eff = W.Text(v, 11, W.COLORS.white, "LEFT")
    v.eff:SetPoint("TOPLEFT", DX, -42)
    v.eff:SetWidth(560)
    v.eff:SetJustifyV("TOP")

    -- presets
    v.presetIdx = 1
    v.presetPrev = W.Button(v, "<", 24, 20, function()
        local n = #presetList()
        v.presetIdx = ((v.presetIdx - 2) % n) + 1
        refreshNow()
    end)
    v.presetPrev:SetPoint("TOPLEFT", DX, -98)
    v.presetName = W.Text(v, 12, W.COLORS.gold, "CENTER")
    v.presetName:SetPoint("LEFT", v.presetPrev, "RIGHT", 2, 0)
    v.presetName:SetWidth(130)
    v.presetNext = W.Button(v, ">", 24, 20, function()
        local n = #presetList()
        v.presetIdx = (v.presetIdx % n) + 1
        refreshNow()
    end)
    v.presetNext:SetPoint("LEFT", v.presetName, "RIGHT", 2, 0)
    v.presetHint = W.Text(v, 10, W.COLORS.gray, "LEFT")
    v.presetHint:SetPoint("LEFT", v.presetNext, "RIGHT", 8, 0)
    v.presetHint:SetWidth(370)
    v.presetHint:SetText("칸 클릭: 선택한 유물 장착 · 우클릭: 해제 · 비운 프리셋은 사냥 프리셋을 사용")
    v.slots = {}
    local nSlots = D.Artifacts and D.Artifacts.slotUnlockAwakening and #D.Artifacts.slotUnlockAwakening or 4
    for i = 1, nSlots do
        local s = W.Icon(v, 34)
        s:SetPoint("TOPLEFT", DX + (i - 1) * 42, -124)
        s.slot = i
        s.lock = W.Text(s, 9, W.COLORS.red, "CENTER")
        s.lock:SetPoint("CENTER")
        s:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        s:SetScript("OnClick", function(self, button)
            local hero = ns.Hero.Active()
            if not hero then return end
            local key = (presetList()[v.presetIdx] or {}).key or "Campaign"
            local id = (button ~= "RightButton") and v.selected or nil
            local ok, err = call("artifactEquip", ns.Artifacts.Equip, hero, key, self.slot, id)
            if not ok and err then W.Toast(err, W.COLORS.red) end
            refreshNow()
        end)
        W.Tooltip(s, artifactTooltip)
        v.slots[i] = s
    end
    v.skills = W.Text(v, 10, W.COLORS.gray, "LEFT")
    v.skills:SetPoint("TOPLEFT", DX, -166)
    v.skills:SetWidth(560)
    v.skills:SetJustifyV("TOP")
    return v
end

local function refreshArtifacts(p, v, hero)
    local AR = ns.Artifacts
    local DA = D.Artifacts or {}
    local owned = hero.artifacts and hero.artifacts.owned or {}
    if not v.selected then
        v.selected = next(owned) or (v.icons[1] and v.icons[1].id)
    end
    local nOwned = 0
    for _, ic in ipairs(v.icons) do
        local a = AR.Get(ic.id)
        local o = owned[ic.id]
        if o then nOwned = nOwned + 1 end
        ic.icon:SetTexture(artifactIcon(ic.id))
        W.SetBorderGrade(ic, artGrade(a))
        ic.icon:SetDesaturated(not o)
        ic:SetAlpha(o and 1 or 0.45)
        ic.count:SetText(o and (o.awakening or 0) > 0 and ("★" .. o.awakening) or "")
        ic.dupes:SetText(o and (o.dupes or 0) > 0 and ("+" .. o.dupes) or "")
        if ic.id == v.selected then ic.sel:Show() else ic.sel:Hide() end
    end
    local chests = ns.Hero.Count(hero, "artifactChest")
    v.chest:SetText(string.format("%s  보유 %d/%d", (W.Money("artifactChest", chests)), nOwned, #v.icons))
    v.open1:SetEnabled(chests > 0)
    v.open10:SetEnabled(chests > 0)
    for i, ic in ipairs(v.got) do
        local id = v.lastGot and v.lastGot[i]
        ic.id = id
        if id then
            local a = AR.Get(id)
            ic.icon:SetTexture(artifactIcon(id))
            W.SetBorderGrade(ic, a and artGrade(a) or nil)
            ic:Show()
        else
            ic:Hide()
        end
    end

    local level = hero.artifacts and hero.artifacts.resonance or 0
    local maxR = AR.ResonanceMax(hero)
    local nextCost = AR.ResonanceCost(level + 1)
    local resStats = {}
    for _, s in ipairs(AR.RESONANCE_STATS or {}) do resStats[#resStats + 1] = { s[1], s[2] * level } end
    v.res:SetText(string.format("공명 증폭 Lv.%d / %d · 총 각성 %d\n%s%s", level, maxR, AR.TotalAwakening(hero),
        nextCost and ("다음 " .. costText({ artifactStone = nextCost }, hero)) or "|cffffd100최대|r",
        level > 0 and ("\n|cff40ff40" .. table.concat(statList(resStats), ", ") .. "|r") or ""))
    local canRes = nextCost and level < maxR and ns.Hero.Count(hero, "artifactStone") >= nextCost
    v.res1:SetEnabled(canRes and true or false)
    v.res10:SetEnabled(canRes and true or false)

    -- details
    local a = v.selected and AR.Get(v.selected)
    if a then
        local o = owned[a.id]
        v.bigIcon.icon:SetTexture(artifactIcon(a.id))
        v.bigIcon.icon:SetDesaturated(not o)
        W.SetBorderGrade(v.bigIcon, artGrade(a))
        v.name:SetText(gradeHex(artGrade(a)) .. a.name .. "|r  |cff999999" .. AR.GradeName(a.grade) .. "|r")
        if o then
            v.aw:SetText(string.format("%s  여분 %d개 (각성당 %d개)", stars(o.awakening or 0, DA.maxAwakening or 5), o.dupes or 0,
                AR.DUPES_PER_AWAKENING or 1))
        else
            v.aw:SetText("|cffff6060미보유|r · 유물 상자에서 획득")
        end
        v.awBtn:SetEnabled(AR.CanAwaken(hero, a.id) and true or false)
        local aw = o and o.awakening or 0
        local cur = AR.InventoryEffect(a.id, aw)
        local nxt = aw < (DA.maxAwakening or 5) and AR.InventoryEffect(a.id, aw + 1) or nil
        local lines = {}
        for i, e in ipairs(cur) do
            local s = "보유 효과  " .. fmtStat(e[1], e[2])
            if nxt and nxt[i] then s = s .. " |cff40ff40→ " .. fmtStat(nxt[i][1], nxt[i][2]):gsub("^[^%+%-]*", "") .. "|r" end
            if e[3] then s = s .. " |cff999999(추정)|r" end
            lines[#lines + 1] = s
        end
        v.eff:SetText(#lines > 0 and table.concat(lines, "\n") or "|cff808080보유 효과 없음|r")
    end

    -- preset slots
    local presets = presetList()
    if v.presetIdx > #presets then v.presetIdx = 1 end
    local preset = presets[v.presetIdx] or { key = "Campaign", label = "사냥" }
    v.presetName:SetText(preset.label or preset.key)
    local raw = hero.artifacts and hero.artifacts.presets and hero.artifacts.presets[preset.key]
    local open = AR.SlotCount(hero)
    local unlock = DA.slotUnlockAwakening or {}
    for i, s in ipairs(v.slots) do
        local id = raw and raw[i] or nil
        if id == false then id = nil end
        if i <= open then
            s.lock:SetText("")
            s.slotText = string.format("%s 프리셋 %d번 칸", preset.label or preset.key, i)
            if id and owned[id] then
                s.id = id
                s.icon:SetTexture(artifactIcon(id))
                s.icon:SetDesaturated(false)
                W.SetBorderGrade(s, artGrade(AR.Get(id)))
            else
                s.id = nil
                s.icon:SetTexture("Interface\\PaperDoll\\UI-Backpack-EmptySlot")
                s.icon:SetDesaturated(false)
                W.SetBorderGrade(s, nil)
            end
        else
            s.id = nil
            s.slotText = string.format("총 각성 %d에서 개방", unlock[i] or 0)
            s.icon:SetTexture("Interface\\PaperDoll\\UI-Backpack-EmptySlot")
            s.icon:SetDesaturated(true)
            W.SetBorderGrade(s, nil)
            s.lock:SetText("각성" .. (unlock[i] or "?"))
        end
    end
    local eq = AR.Equipped(hero, preset.key)
    local names = {}
    for _, id in ipairs(eq) do local x = AR.Get(id); names[#names + 1] = x and x.name or tostring(id) end
    v.skills:SetText(string.format("적용 중인 유물 (%s): %s%s", preset.label or preset.key,
        #names > 0 and table.concat(names, ", ") or "없음",
        (not raw and preset.key ~= "Campaign") and " |cff999999(사냥 프리셋 사용)|r" or ""))
end

---------------------------------------------------------------------------
-- 여정
---------------------------------------------------------------------------
local function trailChapters()
    local list = {}
    for ch = 1, 80 do
        if ns.Journey.TrailInfo(ch) then list[#list + 1] = ch end
    end
    return list
end

local function trailGradeName(g)
    local t = D.Journey and D.Journey.trail and D.Journey.trail.gradeNames
    return t and t[g] or tostring(g)
end

local function buildJourney(p)
    local v = view(p)
    local J = ns.Journey
    v.lock = W.Text(v, 11, W.COLORS.red, "LEFT")
    v.lock:SetPoint("TOPLEFT", 610, 0)
    v.lock:SetWidth(330)

    -- treasure
    v.tTitle = W.Text(v, 12, W.COLORS.gold, "LEFT")
    v.tTitle:SetPoint("TOPLEFT", 0, 0)
    v.tTitle:SetText("여정의 보물")
    v.gauge = W.Bar(v, 290, 14, 0.95, 0.75, 0.2)
    v.gauge:SetPoint("TOPLEFT", 0, -20)
    v.gauge:SetMinMaxValues(0, 2)
    v.tInfo = W.Text(v, 11, W.COLORS.white, "LEFT")
    v.tInfo:SetPoint("TOPLEFT", 0, -40)
    v.tInfo:SetWidth(290)
    v.accBtn = W.Button(v, "가속", 70, 20, function()
        local hero = ns.Hero.Active()
        if not hero then return end
        local ok, res = call("journeyAccel", J.Accelerate, hero)
        if ok then W.Toast(string.format("보물 게이지 +%d%%", math.floor((res or 0) / 10)), W.COLORS.green)
        elseif res then W.Toast(res, W.COLORS.red) end
        refreshNow()
    end)
    v.accBtn:SetPoint("TOPLEFT", 0, -58)
    W.Tooltip(v.accBtn, function(tt)
        tt:AddLine("주간 가속", 1, 0.82, 0)
        tt:AddLine("주 1회, 현재 보물 요구량의 일부를 즉시 채웁니다.", 1, 1, 1, true)
    end)
    v.cardHint = W.Text(v, 10, W.COLORS.gray, "LEFT")
    v.cardHint:SetPoint("LEFT", v.accBtn, "RIGHT", 6, 0)
    v.cardHint:SetWidth(210)
    v.cards = {}
    for i = 1, 4 do
        local c = W.Icon(v, 40)
        c:SetPoint("TOPLEFT", (i - 1) * 72, -86)
        c.idx = i
        c.amount = W.Text(v, 10, W.COLORS.white, "CENTER")
        c.amount:SetPoint("TOP", c, "BOTTOM", 0, -2)
        c.amount:SetWidth(70)
        c.step = W.Text(v, 9, W.COLORS.gold, "CENTER")
        c.step:SetPoint("TOP", c.amount, "BOTTOM", 0, -1)
        c.step:SetWidth(70)
        c:SetScript("OnClick", function(self)
            local hero = ns.Hero.Active()
            if not hero then return end
            local ok, err = call("journeyClaim", J.ClaimTreasure, hero, self.idx)
            if ok then W.Toast("여정의 보물을 받았습니다.", W.COLORS.green) elseif err then W.Toast(err, W.COLORS.red) end
            refreshNow()
        end)
        W.Tooltip(c, function(tt, self)
            if not self.card then return end
            tt:AddLine(D.CurrencyName(self.card.key), 1, 0.82, 0)
            tt:AddLine(string.format("%s개 · %d단계", U.Comma(self.card.amount or 0), self.card.step or 1), 1, 1, 1)
            tt:AddLine("고르지 않은 카드는 한 단계씩 오릅니다.", 0.7, 0.7, 0.7, true)
        end)
        v.cards[i] = c
    end

    -- chest
    local CX = 310
    v.cTitle = W.Text(v, 12, W.COLORS.gold, "LEFT")
    v.cTitle:SetPoint("TOPLEFT", CX, 0)
    v.cTitle:SetText("여정의 상자")
    v.cInfo = W.Text(v, 11, W.COLORS.white, "LEFT")
    v.cInfo:SetPoint("TOPLEFT", CX, -20)
    v.cInfo:SetWidth(290)
    v.cInfo:SetJustifyV("TOP")
    v.bless = {}
    for i = 1, 7 do
        local b = v:CreateTexture(nil, "ARTWORK")
        b:SetSize(28, 10)
        b:SetPoint("TOPLEFT", CX + (i - 1) * 32, -60)
        b:SetColorTexture(0.3, 0.3, 0.3, 1)
        v.bless[i] = b
    end
    v.blessText = W.Text(v, 11, W.COLORS.white, "LEFT")
    v.blessText:SetPoint("TOPLEFT", CX, -76)
    v.blessText:SetWidth(290)
    v.resetBtn = W.Button(v, "축복 초기화", 96, 20, function()
        local hero = ns.Hero.Active()
        if not hero then return end
        local ok, err = call("journeyBless", J.ResetBlessings, hero)
        if not ok and err then W.Toast(err, W.COLORS.red) end
        refreshNow()
    end)
    v.resetBtn:SetPoint("TOPLEFT", CX, -96)
    local function openChest(all)
        local hero = ns.Hero.Active()
        if not hero then return end
        local keys = all and math.max(1, math.min(10, ns.Hero.Count(hero, "journeyKey"))) or 1
        local tokens, err = call("journeyChest", J.OpenChest, hero, keys)
        if tokens then W.Toast(string.format("%s %s 획득", D.CurrencyName("journeyToken"), U.Comma(tokens)), W.COLORS.green)
        elseif err then W.Toast(err, W.COLORS.red) end
        refreshNow()
    end
    v.chest1 = W.Button(v, "열기 x1", 70, 20, function() openChest(false) end)
    v.chest1:SetPoint("TOPLEFT", CX, -122)
    v.chestAll = W.Button(v, "모두 열기", 80, 20, function() openChest(true) end)
    v.chestAll:SetPoint("LEFT", v.chest1, "RIGHT", 4, 0)
    v.wallet = W.Text(v, 11, W.COLORS.white, "LEFT")
    v.wallet:SetPoint("TOPLEFT", CX, -150)
    v.wallet:SetWidth(290)
    v.wallet:SetJustifyV("TOP")

    -- trail
    local TX = 610
    v.trTitle = W.Text(v, 12, W.COLORS.gold, "LEFT")
    v.trTitle:SetPoint("TOPLEFT", TX, -14)
    v.trTitle:SetText("여정의 발자취")
    v.trList = W.ScrollList(v, 334, 84, 16, function(parent)
        local r = CreateFrame("Button", nil, parent)
        r:SetHeight(16)
        r:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        r.sel = r:CreateTexture(nil, "BACKGROUND")
        r.sel:SetAllPoints()
        r.sel:SetColorTexture(1, 0.82, 0, 0.18)
        r.sel:Hide()
        r.text = W.Text(r, 10, W.COLORS.white, "LEFT")
        r.text:SetPoint("LEFT", 2, 0)
        r.text:SetWidth(300)
        r:SetScript("OnClick", function(self) v.trSel = self.ch; refreshNow() end)
        return r
    end, function(r, e)
        r.ch = e.ch
        r.text:SetText(e.text)
        if e.ch == v.trSel then r.sel:Show() else r.sel:Hide() end
    end)
    v.trList:SetPoint("TOPLEFT", TX, -30)
    v.trSlots = {}
    for i = 1, 3 do
        local t = W.Text(v, 10, W.COLORS.white, "LEFT")
        t:SetPoint("TOPLEFT", TX, -120 - (i - 1) * 16)
        t:SetWidth(270)
        local b = W.Button(v, "잠금", 50, 16, function()
            local hero = ns.Hero.Active()
            if not (hero and v.trSel) then return end
            local t0 = hero.journey and hero.journey.trail and hero.journey.trail.opened[v.trSel]
            local slot = (t0 and t0.locked == i) and nil or i
            local ok, err = call("journeyLock", J.SetTrailLock, hero, v.trSel, slot)
            if not ok and err then W.Toast(err, W.COLORS.red) end
            refreshNow()
        end)
        b:SetPoint("TOPLEFT", TX + 276, -118 - (i - 1) * 16)
        v.trSlots[i] = { text = t, btn = b }
    end
    v.trInfo = W.Text(v, 10, W.COLORS.gray, "LEFT")
    v.trInfo:SetPoint("TOPLEFT", TX, -170)
    v.trInfo:SetWidth(334)
    v.trInfo:SetJustifyV("TOP")
    v.trOpen = W.Button(v, "개방", 60, 20, function()
        local hero = ns.Hero.Active()
        if not (hero and v.trSel) then return end
        local ok, err = call("journeyOpenTrail", J.OpenTrail, hero, v.trSel)
        if ok then W.Toast("발자취 개방을 시작했습니다.", W.COLORS.green) elseif err then W.Toast(err, W.COLORS.red) end
        refreshNow()
    end)
    v.trOpen:SetPoint("TOPLEFT", TX, -196)
    v.trReroll = W.Button(v, "재설정", 64, 20, function()
        local hero = ns.Hero.Active()
        if not (hero and v.trSel) then return end
        local ok, err = call("journeyReroll", J.RerollTrail, hero, v.trSel)
        if not ok and err then W.Toast(err, W.COLORS.red) end
        refreshNow()
    end)
    v.trReroll:SetPoint("LEFT", v.trOpen, "RIGHT", 4, 0)
    v.trCost = W.Text(v, 10, W.COLORS.white, "LEFT")
    v.trCost:SetPoint("LEFT", v.trReroll, "RIGHT", 6, 0)
    v.trCost:SetWidth(200)

    v.elapsed = 0
    v:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + (elapsed or 0)
        if self.elapsed < 1 or not self.opening then return end
        self.elapsed = 0
        local hero = ns.Hero.Active()
        if not hero then return end
        local rem = J.TrailRemaining(hero)
        if not rem or rem <= 0 then
            self.opening = nil
            call("journeyUpdate", J.Update, hero)
            refreshNow()
        end
    end)
    return v
end

local function refreshJourney(p, v, hero)
    local J = ns.Journey
    call("journeyUpdate", J.Update, hero)
    local unlocked = J.Unlocked(hero)
    local DJ = D.Journey or {}
    v.lock:SetText(unlocked and "" or "챕터 20 보스를 처치하면 개방됩니다.")
    local js = hero.journey or {}
    local t = js.treasure or { stored = 0, level = 1, exp = 0 }

    -- treasure
    local g = J.TreasureGauge(hero) or 0
    v.gauge:SetValue(g / 1000)
    v.gauge.text:SetText(string.format("%.1f%%", g / 10))
    local maxStored = DJ.treasure and DJ.treasure.maxStored or 2
    v.tInfo:SetText(string.format("보관 %d / %d · 보물 Lv.%d · 다음 %s", t.stored or 0, maxStored, t.level or 1,
        U.FormatNumber(J.TreasureRequirement(t.level or 1) or 0)))
    local canAcc = J.CanAccelerate(hero)
    v.accBtn:SetEnabled(canAcc and true or false)
    v.cardHint:SetText((t.stored or 0) > 0 and "|cff40ff40카드를 골라 보물을 받으세요.|r" or "보물이 쌓이면 카드를 고를 수 있습니다.")
    local cards = J.Cards(hero)
    for i, c in ipairs(v.cards) do
        local card = cards[i]
        c.card = card
        if card then
            c.icon:SetTexture(D.CurrencyIcon(card.key))
            W.SetBorderGrade(c, math.min(8, card.step or 1))
            c.amount:SetText(U.FormatNumber(card.amount or 0))
            c.step:SetText(string.rep("★", card.step or 1))
            c:SetEnabled((t.stored or 0) > 0)
            c.icon:SetDesaturated((t.stored or 0) <= 0)
        end
    end

    -- chest
    local base, ch = J.ChestBase(hero)
    local keys = ns.Hero.Count(hero, "journeyKey")
    local freeResets = js.chest and js.chest.freeResets or 0
    v.cInfo:SetText(string.format("%s · 열쇠당 기본 %s%s", (W.Money("journeyKey", keys)), base and U.Comma(base) or "-",
        ch and string.format(" |cff999999(챕터 %d)|r", ch) or ""))
    local bless, bonus = {}, 0
    if unlocked then
        local okB, b1, b2 = pcall(J.Blessings, hero)
        if okB then bless, bonus = b1 or {}, b2 or 0 end
    end
    local BC = { { 0.5, 0.5, 0.5 }, { 0.3, 0.8, 1 }, { 1, 0.82, 0 } }
    for i, tex in ipairs(v.bless) do
        local lvl = bless[i]
        local c = lvl and BC[lvl] or { 0.2, 0.2, 0.2 }
        tex:SetColorTexture(c[1], c[2], c[3], 1)
    end
    v.blessText:SetText(string.format("축복 보너스 |cff40ff40+%s%%|r · 무료 초기화 %d회", tostring((bonus or 0) / 10), freeResets))
    v.resetBtn:SetEnabled(unlocked and freeResets > 0)
    v.chest1:SetEnabled(unlocked and base ~= nil and keys > 0)
    v.chestAll:SetEnabled(unlocked and base ~= nil and keys > 0)
    v.wallet:SetText(string.format("%s\n%s", (W.Money("journeyToken", ns.Hero.Count(hero, "journeyToken"))),
        (W.Money("journeyEnergy", ns.Hero.Count(hero, "journeyEnergy")))))

    -- trail list
    local tr = js.trail or { opened = {} }
    local rows = {}
    local opening = tr.opening
    for _, c in ipairs(trailChapters()) do
        local o = tr.opened and tr.opened[c]
        local text
        if o then
            local parts = {}
            local special = true
            local minG = DJ.trail and DJ.trail.specialMinGrade or 4
            for i = 1, 3 do
                local gg = o.grades[i] or 1
                if gg < minG then special = false end
                parts[#parts + 1] = gradeHex(math.min(8, gg)) .. trailGradeName(gg) .. "|r"
            end
            text = string.format("%d장  %s%s", c, table.concat(parts, " "), special and " |cffffd100특수|r" or "")
        elseif opening and opening.ch == c then
            text = string.format("%d장  |cffffd100개방 중 %s|r", c, U.FormatDuration(J.TrailRemaining(hero) or 0))
        else
            local can = J.CanOpenTrail(hero, c)
            text = string.format("%d장  %s", c, can and "|cff40ff40개방 가능|r" or "|cff808080잠김|r")
        end
        rows[#rows + 1] = { ch = c, text = text }
    end
    if not v.trSel and rows[1] then v.trSel = rows[1].ch end
    v.trList:SetData(rows)
    v.opening = opening and true or nil

    local info = v.trSel and J.TrailInfo(v.trSel)
    local o = v.trSel and tr.opened and tr.opened[v.trSel]
    for i, s in ipairs(v.trSlots) do
        local sl = info and info.slots and info.slots[i]
        if sl then
            local gg = o and o.grades[i] or 1
            local locked = o and o.locked == i
            s.text:SetText(string.format("%s%s|r %s%s", gradeHex(math.min(8, gg)), trailGradeName(gg), fmtStat(sl[1], sl[2][gg] or 0),
                locked and " |cffffd100(잠금)|r" or ""))
            s.btn:SetText(locked and "해제" or "잠금")
            s.btn:SetEnabled(o ~= nil)
            s.btn:Show()
        else
            s.text:SetText("")
            s.btn:Hide()
        end
    end
    if info then
        local lines = {}
        if info.special then lines[#lines + 1] = "특수 옵션(모두 유니크 이상): " .. fmtStat(info.special[1], info.special[2]) end
        if o then
            lines[#lines + 1] = "재설정 비용 아래 표시 · 1줄 잠금 시 비용 증가"
        else
            lines[#lines + 1] = string.format("개방 %s · %s", costText(info.openCost, hero), U.FormatDuration(info.openSec or 0))
        end
        v.trInfo:SetText(table.concat(lines, "\n"))
        v.trCost:SetText(o and costText(J.RerollCost(hero, v.trSel), hero) or "")
    else
        v.trInfo:SetText("")
        v.trCost:SetText("")
    end
    local canOpen = v.trSel and J.CanOpenTrail(hero, v.trSel)
    v.trOpen:SetEnabled(canOpen and true or false)
    v.trReroll:SetEnabled(o ~= nil)
end

---------------------------------------------------------------------------
-- panel
---------------------------------------------------------------------------
local BUILD = { heroPower = buildHeroPower, ability = buildAbility, artifacts = buildArtifacts, journey = buildJourney }
local REFRESH = { heroPower = refreshHeroPower, ability = refreshAbility, artifacts = refreshArtifacts, journey = refreshJourney }

UI.RegisterPanel("growth", {
    title = "성장", order = 38,
    build = function(p)
        p.view = "heroPower"
        p.viewBtns, p.views = {}, {}
        local box = W.InfoCard(p, 962, 374, { plain = true })
        box:SetPoint("TOPLEFT", 0, -32)
        p.box = box
        local labels, keys = {}, {}
        for _, def in ipairs(VIEWS) do
            if ns[def.sys] then labels[#labels + 1] = def.label; keys[#keys + 1] = def.key end
        end
        p.viewTabs = W.Tabs(p, labels, 120, 26, function(i)
            p.view = keys[i]
            refreshNow()
        end)
        p.viewTabs:SetPoint("TOPLEFT", 0, 0)
        p.viewKeys = keys
        for i, def in ipairs(VIEWS) do
            if ns[def.sys] then
                local ok, v = pcall(BUILD[def.key], p)
                if ok then p.views[def.key] = v
                else
                    if ns.Debug then ns.Debug("growth ui build %s: %s", def.key, tostring(v)) end
                    ns.Print("|cffff4040패널 오류|r 성장/%s: %s", def.key, tostring(v))
                end
            end
        end
        if not p.views[p.view] then p.view = next(p.views) end
        p.missing = W.Text(p, 12, W.COLORS.gray, "LEFT")
        p.missing:SetPoint("TOPLEFT", 4, VIEW_Y - 4)
        p.missing:SetText(next(p.views) and "" or "성장 시스템을 불러오지 못했습니다.")
    end,

    refresh = function(p, hero)
        for i, key in ipairs(p.viewKeys or {}) do
            if key == p.view and p.viewTabs.index ~= i then p.viewTabs:Select(i) end
        end
        for key, v in pairs(p.views) do
            if key ~= p.view then v:Hide() end
        end
        local v = p.view and p.views[p.view]
        if not v then return end
        v:Show()
        REFRESH[p.view](p, v, hero)
    end,
})
