-- 동료 패널: 등급별 동료 격자(레벨 / 조각), 메인 + 서브 6칸, 선택 동료 상세(장착/보유 효과, 공격력 계승),
-- 레벨업 / 최대 레벨업 / 모두 레벨업, 등급 승급, 자동 장착.
local ADDON, ns = ...
local W = ns.W
local U = ns.U
local UI = ns.UI
local D = ns.Data

local ICON, STEP, LABEL_W = 26, 28, 56
local SLOT_ICON, SLOT_STEP = 30, 36
local DX = 520 -- details column x

---------------------------------------------------------------------------
-- helpers
---------------------------------------------------------------------------
local function call(where, fn, ...)
    local ok, a, b, c = pcall(fn, ...)
    if not ok then
        if ns.Debug then ns.Debug("companion ui %s: %s", where, tostring(a)) end
        W.Toast(tostring(a), W.COLORS.red)
        return nil
    end
    return a, b, c
end

local function gradeHex(g) return W.Hex(W.GradeColor(g)) end

local function gradeName(g)
    local C = ns.Companions
    local gi = C and C.GradeInfo and C.GradeInfo(g)
    if gi and gi.ko then return gi.ko end
    local L = D.SummonLabels
    return L and L.companionGrades and L.companionGrades[g] or tostring(g)
end

local function jobDef(jobKey)
    if not (jobKey and ns.SkillBook and ns.SkillBook.JobByKey) then return nil end
    local ok, job = pcall(ns.SkillBook.JobByKey, jobKey)
    return ok and job or nil
end

local function jobDisplay(jobKey)
    local job = jobDef(jobKey)
    local skin = job and ns.Skin and ns.Skin.Job(job)
    return (skin and skin.display) or (job and job.mapleNameKo) or tostring(jobKey or "")
end

local iconCache = {}
local function companionIcon(sid)
    if iconCache[sid] then return iconCache[sid] end
    local c = ns.Companions.Def(sid)
    local job = c and jobDef(c.job)
    local skin = job and ns.Skin and ns.Skin.Job(job)
    local tex = skin and skin.icon or "Interface\\Icons\\INV_Misc_QuestionMark"
    iconCache[sid] = tex
    return tex
end

local function fmtStat(stat, raw)
    if ns.Upgrades and ns.Upgrades.FormatStat then return ns.Upgrades.FormatStat(stat, raw) end
    return string.format("%s +%s", ns.StatLabels and ns.StatLabels[stat] or stat,
        ns.FormatStat and ns.FormatStat(stat, raw) or tostring(raw))
end

local function effectText(list)
    local parts = {}
    for _, e in ipairs(list or {}) do parts[#parts + 1] = fmtStat(e[1], e[2]) end
    return #parts > 0 and table.concat(parts, ", ") or "-"
end

-- slot of a companion: "main", sub index or nil
local function slotOf(hero, sid)
    local main, subs = ns.Companions.Equipped(hero)
    if main == sid then return "main" end
    for i, s in pairs(subs) do if s == sid then return i end end
    return nil
end

local function done(where, fn, ...)
    local a, b = call(where, fn, ...)
    UI.RefreshPanel()
    return a, b
end

---------------------------------------------------------------------------
-- actions
---------------------------------------------------------------------------
local function levelUp(p, times)
    local hero, sid = ns.Hero.Active(), p.selected
    if not (hero and sid) then return end
    if not ns.Companions.Get(hero, sid) then W.Toast("보유하지 않은 동료입니다.", W.COLORS.red) return end
    local n = done("levelUp", ns.Companions.LevelUp, hero, sid, times)
    if n and n > 0 then W.Toast(string.format("%s 레벨 +%d", ns.Companions.Def(sid).name, n), W.COLORS.green)
    elseif n then W.Toast("조각이 부족하거나 최대 레벨입니다.", W.COLORS.red) end
end

local function levelUpAll()
    local hero = ns.Hero.Active()
    if not hero then return end
    local n = done("levelUpAll", ns.Companions.LevelUpAll, hero)
    if n and n > 0 then W.Toast(string.format("동료 레벨 총 +%d", n), W.COLORS.green)
    elseif n then W.Toast("레벨업할 수 있는 동료가 없습니다.", W.COLORS.red) end
end

local function promote(p)
    local hero, sid = ns.Hero.Active(), p.selected
    if not (hero and sid) then return end
    local grade = ns.Companions.Def(sid).grade
    local new, err = done("promote", ns.Companions.Promote, hero, grade)
    if new then
        p.selected = new
        W.Toast(string.format("승급 성공! %s%s|r 획득", gradeHex(ns.Companions.Def(new).grade), ns.Companions.Def(new).name), W.COLORS.green)
        UI.RefreshPanel()
    elseif err then
        W.Toast(err, W.COLORS.red)
    end
end

local function autoEquip()
    local hero = ns.Hero.Active()
    if not hero then return end
    call("autoEquip", ns.Companions.AutoEquip, hero)
    W.Toast("동료를 자동 장착했습니다.")
    UI.RefreshPanel()
end

local function setMain(p, sid)
    local hero = ns.Hero.Active()
    if not hero then return end
    local ok, err = done("setMain", ns.Companions.SetMain, hero, sid)
    if not ok and err then W.Toast(err, W.COLORS.red) end
end

local function setSub(p, slot, sid)
    local hero = ns.Hero.Active()
    if not hero then return end
    local ok, err = done("setSub", ns.Companions.SetSub, hero, slot, sid)
    if not ok and err then W.Toast(err, W.COLORS.red) end
end

local function equipSub(p)
    local hero, sid = ns.Hero.Active(), p.selected
    if not (hero and sid) then return end
    local open = ns.Companions.SubSlotsUnlocked(hero)
    if open <= 0 then W.Toast("서브 칸은 동료 소환 레벨이 오르면 개방됩니다.", W.COLORS.red) return end
    local _, subs = ns.Companions.Equipped(hero)
    local target
    for i = 1, open do
        if not subs[i] then target = i break end
    end
    setSub(p, target or p.subSlot or 1, sid)
end

local function unequip(p)
    local hero, sid = ns.Hero.Active(), p.selected
    if not (hero and sid) then return end
    local where = slotOf(hero, sid)
    if where == "main" then setMain(p, nil)
    elseif where then setSub(p, where, nil)
    else W.Toast("장착하지 않은 동료입니다.", W.COLORS.red) end
end

---------------------------------------------------------------------------
-- tooltip
---------------------------------------------------------------------------
local function companionTooltip(tt, icon)
    local hero, C = ns.Hero.Active(), ns.Companions
    local sid = icon.sid
    local c = sid and C.Def(sid)
    if not (hero and c) then
        if icon.slotText then tt:AddLine(icon.slotText, 1, 1, 1) end
        return
    end
    local rec = C.Get(hero, sid)
    tt:AddLine(c.name, W.GradeColor(c.grade))
    tt:AddLine(string.format("%s · %s", gradeName(c.grade), jobDisplay(c.job)), 0.8, 0.8, 0.8)
    local lv = rec and rec.level or 1
    if rec then
        local need = C.LevelUpCost(sid, rec.level)
        tt:AddLine(string.format("Lv.%d / %d · 조각 %d%s", rec.level, c.maxLevel, rec.count or 0,
            need and string.format(" (다음 %d)", need) or ""), 1, 1, 1)
    else
        tt:AddLine("미보유 (Lv.1 기준)", 0.6, 0.6, 0.6)
    end
    local eff = C.Effects(sid, lv)
    tt:AddLine("장착 효과: " .. effectText(eff.equip), 0.4, 0.8, 1)
    tt:AddLine("보유 효과: " .. effectText(eff.owned), 0.3, 1, 0.3)
    local sk = D.CompanionSkillText and D.CompanionSkillText[sid]
    if sk and sk.enter then tt:AddLine("등장: " .. sk.enter, 0.9, 0.9, 0.6, true) end
    if icon.slotText then tt:AddLine(icon.slotText, 0.6, 0.6, 0.6) end
end

---------------------------------------------------------------------------
-- panel
---------------------------------------------------------------------------
UI.RegisterPanel("companions", {
    title = "동료", order = 34,
    build = function(p)
        local C = ns.Companions
        if not C then
            local t = W.Text(p, 13, W.COLORS.red, "LEFT")
            t:SetPoint("TOPLEFT", 4, -4)
            t:SetText("동료 시스템을 불러오지 못했습니다.")
            return
        end
        p.subSlot = 1
        -- grid: one row per grade
        p.icons = {}
        for g = 1, 5 do
            local l = W.Text(p, 11, { W.GradeColor(g) }, "LEFT")
            l:SetPoint("TOPLEFT", 0, -6 - (g - 1) * (STEP + 2))
            l:SetWidth(LABEL_W)
            l:SetText(gradeName(g))
            for i, sid in ipairs(C.ByGrade(g)) do
                local ic = W.Icon(p, ICON)
                ic:SetPoint("TOPLEFT", LABEL_W + (i - 1) * STEP, -(g - 1) * (STEP + 2))
                ic.sid = sid
                ic.sel = ic:CreateTexture(nil, "OVERLAY")
                ic.sel:SetTexture("Interface\\Buttons\\CheckButtonHilight")
                ic.sel:SetBlendMode("ADD")
                ic.sel:SetAllPoints()
                ic.sel:Hide()
                ic.copies = W.Text(ic, 9, W.COLORS.green, "LEFT")
                ic.copies:SetPoint("TOPLEFT", 1, -1)
                ic.mark = W.Text(ic, 9, W.COLORS.gold, "RIGHT")
                ic.mark:SetPoint("TOPRIGHT", -1, -1)
                ic:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
                ic:SetScript("OnClick", function(self)
                    p.selected = self.sid
                    UI.RefreshPanel()
                end)
                W.Tooltip(ic, companionTooltip)
                p.icons[#p.icons + 1] = ic
            end
        end

        -- slots
        local sy = -158
        local ml = W.Text(p, 12, W.COLORS.gold, "LEFT")
        ml:SetPoint("TOPLEFT", 0, sy - 8)
        ml:SetText("메인")
        p.mainSlot = W.Icon(p, SLOT_ICON)
        p.mainSlot:SetPoint("TOPLEFT", 34, sy)
        p.mainSlot:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        p.mainSlot:SetScript("OnClick", function(self, button)
            if button == "RightButton" then setMain(p, nil)
            elseif p.selected then setMain(p, p.selected) end
        end)
        W.Tooltip(p.mainSlot, companionTooltip)
        local sl = W.Text(p, 12, W.COLORS.gold, "LEFT")
        sl:SetPoint("TOPLEFT", 84, sy - 8)
        sl:SetText("서브")
        p.subSlots = {}
        local nSub = D.CompanionSlots and D.CompanionSlots.subUnlockSummonLevel and #D.CompanionSlots.subUnlockSummonLevel or 6
        for i = 1, nSub do
            local s = W.Icon(p, SLOT_ICON)
            s:SetPoint("TOPLEFT", 118 + (i - 1) * SLOT_STEP, sy)
            s.slot = i
            s.lock = W.Text(s, 9, W.COLORS.red, "CENTER")
            s.lock:SetPoint("CENTER")
            s:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            s:SetScript("OnClick", function(self, button)
                p.subSlot = self.slot
                if button == "RightButton" then setSub(p, self.slot, nil)
                elseif p.selected then setSub(p, self.slot, p.selected)
                else UI.RefreshPanel() end
            end)
            W.Tooltip(s, companionTooltip)
            p.subSlots[i] = s
        end
        p.slotHint = W.Text(p, 10, W.COLORS.gray, "LEFT")
        p.slotHint:SetPoint("TOPLEFT", 0, sy - 38)
        p.slotHint:SetWidth(340)
        p.slotHint:SetText("칸 클릭: 선택한 동료 장착 · 우클릭: 해제")

        p.allBtn = W.Button(p, "모두 레벨업", 100, 22, levelUpAll)
        p.allBtn:SetPoint("TOPLEFT", 346, sy)
        p.autoBtn = W.Button(p, "자동 장착", 100, 22, autoEquip)
        p.autoBtn:SetPoint("TOPLEFT", 346, sy - 26)
        p.ownedText = W.Text(p, 11, W.COLORS.white, "LEFT")
        p.ownedText:SetPoint("TOPLEFT", 0, sy - 56)
        p.ownedText:SetWidth(500)

        -- details
        p.bigIcon = W.Icon(p, 40)
        p.bigIcon:SetPoint("TOPLEFT", DX, -2)
        W.Tooltip(p.bigIcon, function(tt, self) self.sid = p.selected; companionTooltip(tt, self) end)
        p.name = W.Text(p, 14, W.COLORS.gold, "LEFT")
        p.name:SetPoint("TOPLEFT", p.bigIcon, "TOPRIGHT", 8, -2)
        p.name:SetWidth(370)
        p.sub = W.Text(p, 11, W.COLORS.gray, "LEFT")
        p.sub:SetPoint("TOPLEFT", p.name, "BOTTOMLEFT", 0, -4)
        p.sub:SetWidth(370)

        local function line(y)
            local t = W.Text(p, 11, W.COLORS.white, "LEFT")
            t:SetPoint("TOPLEFT", DX, y)
            t:SetWidth(420)
            t:SetJustifyV("TOP")
            return t
        end
        p.lvText = line(-48)
        p.eqText = line(-66)
        p.owText = line(-84)
        p.inText = line(-102)

        p.lvBtn = W.Button(p, "레벨업", 80, 22, function() levelUp(p, 1) end)
        p.lvBtn:SetPoint("TOPLEFT", DX, -122)
        p.lvMaxBtn = W.Button(p, "최대 레벨업", 90, 22, function() levelUp(p, nil) end)
        p.lvMaxBtn:SetPoint("LEFT", p.lvBtn, "RIGHT", 4, 0)
        p.mainBtn = W.Button(p, "메인 장착", 80, 22, function() if p.selected then setMain(p, p.selected) end end)
        p.mainBtn:SetPoint("LEFT", p.lvMaxBtn, "RIGHT", 4, 0)
        p.subBtn = W.Button(p, "서브 장착", 80, 22, function() equipSub(p) end)
        p.subBtn:SetPoint("LEFT", p.mainBtn, "RIGHT", 4, 0)
        p.offBtn = W.Button(p, "해제", 60, 22, function() unequip(p) end)
        p.offBtn:SetPoint("TOPLEFT", DX, -148)

        p.prText = line(-178)
        p.prBtn = W.Button(p, "승급", 80, 22, function() promote(p) end)
        p.prBtn:SetPoint("TOPLEFT", DX, -210)
    end,

    refresh = function(p, hero)
        local C = ns.Companions
        if not (C and p.icons) then return end
        local main, subs = C.Equipped(hero)
        local open = C.SubSlotsUnlocked(hero)
        if not p.selected then p.selected = main or C.All()[1] end

        local where = {}
        if main then where[main] = "M" end
        for i, sid in pairs(subs) do where[sid] = "S" .. i end

        local owned, total = 0, 0
        for _, ic in ipairs(p.icons) do
            local sid = ic.sid
            local c = C.Def(sid)
            local rec = C.Get(hero, sid)
            total = total + 1
            if rec then owned = owned + 1 end
            ic.icon:SetTexture(companionIcon(sid))
            W.SetBorderGrade(ic, c.grade)
            ic.icon:SetDesaturated(not rec)
            ic:SetAlpha(rec and 1 or 0.45)
            ic.count:SetText(rec and tostring(rec.level) or "")
            local need = rec and C.LevelUpCost(sid, rec.level)
            local cnt = rec and rec.count or 0
            ic.copies:SetText(cnt > 0 and ((need and cnt >= need) and ("|cffffd100" .. cnt .. "|r") or tostring(cnt)) or "")
            ic.mark:SetText(where[sid] or "")
            if sid == p.selected then ic.sel:Show() else ic.sel:Hide() end
        end

        -- slots
        local function fill(slotIcon, sid, text)
            slotIcon.sid = sid
            slotIcon.slotText = text
            if sid then
                slotIcon.icon:SetTexture(companionIcon(sid))
                slotIcon.icon:SetDesaturated(false)
                W.SetBorderGrade(slotIcon, C.Def(sid).grade)
                local rec = C.Get(hero, sid)
                slotIcon.count:SetText(rec and tostring(rec.level) or "")
            else
                slotIcon.icon:SetTexture("Interface\\PaperDoll\\UI-Backpack-EmptySlot")
                W.SetBorderGrade(slotIcon, nil)
                slotIcon.count:SetText("")
            end
        end
        fill(p.mainSlot, main, "메인 동료: 전투에 함께 참여하고 장착 효과를 줍니다.")
        local unlockLv = D.CompanionSlots and D.CompanionSlots.subUnlockSummonLevel or {}
        for i, s in ipairs(p.subSlots) do
            if i <= open then
                fill(s, subs[i], string.format("서브 %d칸: 장착 효과만 적용됩니다.", i))
                s.lock:SetText("")
                s.icon:SetDesaturated(false)
            else
                fill(s, nil, string.format("동료 소환 레벨 %d에서 개방", unlockLv[i] or 0))
                s.icon:SetDesaturated(true)
                s.lock:SetText("Lv" .. (unlockLv[i] or "?"))
            end
        end
        p.ownedText:SetText(string.format("보유 동료 %d / %d · 서브 칸 %d / %d 개방", owned, total, open, #p.subSlots))

        -- details
        local sid = p.selected
        local c = C.Def(sid)
        if not c then return end
        local rec = C.Get(hero, sid)
        p.bigIcon.icon:SetTexture(companionIcon(sid))
        p.bigIcon.icon:SetDesaturated(not rec)
        W.SetBorderGrade(p.bigIcon, c.grade)
        p.name:SetText(gradeHex(c.grade) .. c.name .. "|r")
        local slot = rec and slotOf(hero, sid)
        p.sub:SetText(string.format("%s · %s · %s", gradeName(c.grade), jobDisplay(c.job),
            not rec and "|cffff6060미보유|r" or (slot == "main" and "|cffffd100메인 장착|r")
            or (slot and string.format("|cffffd100서브 %d칸|r", slot)) or "보유 중"))
        local lv = rec and rec.level or 1
        local need = rec and C.LevelUpCost(sid, rec.level)
        if rec then
            p.lvText:SetText(string.format("Lv.%d / %d · 조각 %s%d|r%s", rec.level, c.maxLevel,
                (need and (rec.count or 0) >= need) and "|cff40ff40" or "|cffffffff", rec.count or 0,
                need and string.format(" · 다음 레벨 %d개", need) or " · |cffffd100최대 레벨|r"))
        else
            p.lvText:SetText("|cff808080미보유 · 동료 소환으로 획득합니다.|r")
        end
        local eff = C.Effects(sid, lv)
        p.eqText:SetText("|cff66ccff장착 효과|r  " .. effectText(eff.equip))
        p.owText:SetText("|cff40ff40보유 효과|r  " .. effectText(eff.owned))
        local okInh, inh = pcall(C.AttackInheritM, sid, lv, hero.level)
        p.inText:SetText(okInh and string.format("|cffffd100메인 계승|r  영웅 공격력의 %s", U.PctM(inh, 1)) or "")

        p.lvBtn:SetEnabled(rec ~= nil and need ~= nil and (rec.count or 0) >= need)
        p.lvMaxBtn:SetEnabled(rec ~= nil and need ~= nil and (rec.count or 0) >= need)
        p.mainBtn:SetEnabled(rec ~= nil and slot ~= "main")
        p.subBtn:SetEnabled(rec ~= nil and open > 0 and type(slot) ~= "number")
        p.offBtn:SetEnabled(slot ~= nil)

        local pc = C.PromoteCost(c.grade)
        local have = C.PromotableCopies(hero, c.grade)
        if pc and C.ByGrade(c.grade + 1)[1] then
            p.prText:SetText(string.format("승급: %s 등급 조각 %s%s|r / %s → %s%s|r 동료 1명 (무작위)\n|cff999999같은 등급 동료들의 조각을 고르게 사용합니다.|r",
                gradeName(c.grade), have >= pc and "|cff40ff40" or "|cffff5050", U.Comma(have), U.Comma(pc),
                gradeHex(c.grade + 1), gradeName(c.grade + 1)))
            p.prBtn:SetEnabled(have >= pc)
        else
            p.prText:SetText("|cff808080최고 등급은 승급할 수 없습니다.|r")
            p.prBtn:SetEnabled(false)
        end
    end,
})
