-- 동료 패널: 등급별 동료 격자(레벨 / 조각), 메인 + 서브 6칸, 선택 동료 상세(장착/보유 효과, 공격력 계승),
-- 레벨업 / 최대 레벨업 / 모두 레벨업, 등급 승급, 자동 장착.
local ADDON, ns = ...
local W = ns.W
local U = ns.U
local UI = ns.UI
local D = ns.Data


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
    return (skin and skin.display) or tostring(jobKey or "")
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
-- panel: equipped slots on top, grade tabs + card grid, detail card on the right (original layout)
---------------------------------------------------------------------------
local CW, CH, GAP = 66, 80, 4
local CARD_W = 352

local function statRow(stat, raw)
    local txt = fmtStat(stat, raw)
    local l, v = txt:match("^(.-)%s+(%+.*)$")
    return { l or txt, v or "" }
end

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
        p.grade = 1

        -- equipped slots strip
        local strip = CreateFrame("Frame", nil, p, BackdropTemplateMixin and "BackdropTemplate" or nil)
        strip:SetPoint("TOPLEFT", 0, 0)
        strip:SetSize(590, 74)
        W.Backdrop(strip, { 0.04, 0.04, 0.05, 0.85 }, { 0.3, 0.3, 0.32, 1 }, 10)
        if W.ArtInfo("box_dark") then W.Slice(strip, "box_dark", 0.7) end
        local ml = W.Text(strip, 11, W.COLORS.gold, "CENTER")
        ml:SetPoint("TOPLEFT", 14, -6)
        ml:SetText("메인")
        p.mainSlot = W.Icon(strip, 50)
        p.mainSlot:SetPoint("TOPLEFT", 8, -20)
        p.mainSlot:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        p.mainSlot:SetScript("OnClick", function(self, button)
            if button == "RightButton" then setMain(p, nil)
            elseif p.selected then setMain(p, p.selected) end
        end)
        W.Tooltip(p.mainSlot, companionTooltip)
        local sl = W.Text(strip, 11, W.COLORS.gold, "LEFT")
        sl:SetPoint("TOPLEFT", 74, -6)
        sl:SetText("서브")
        p.subSlots = {}
        local nSub = D.CompanionSlots and D.CompanionSlots.subUnlockSummonLevel and #D.CompanionSlots.subUnlockSummonLevel or 6
        for i = 1, nSub do
            local s = W.Icon(strip, 44)
            s:SetPoint("TOPLEFT", 70 + (i - 1) * 48, -22)
            s.slot = i
            s.lock = W.Text(s, 10, W.COLORS.red, "CENTER")
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
        p.autoBtn = W.Button(strip, "자동 장착", 104, 26, autoEquip, "cyan")
        p.autoBtn:SetPoint("TOPRIGHT", -10, -10)
        p.allBtn = W.Button(strip, "모두 레벨업", 104, 26, levelUpAll, "green")
        p.allBtn:SetPoint("TOPRIGHT", -10, -40)

        -- grade tabs + grid
        local labels = {}
        for g = 1, 5 do labels[g] = gradeName(g) end
        p.tabs = W.Tabs(p, labels, 84, 24, function(i) p.grade = i; UI.RefreshPanel() end)
        p.tabs:SetPoint("TOPLEFT", 0, -82)
        p.cards = {}
        for i = 1, 16 do
            local col, row = (i - 1) % 8, math.floor((i - 1) / 8)
            local c = W.GradeCard(p, CW, CH, function(self)
                if self.sid then p.selected = self.sid; UI.RefreshPanel() end
            end)
            c:SetPoint("TOPLEFT", col * (CW + GAP), -114 - row * (CH + 6))
            W.Tooltip(c, companionTooltip)
            p.cards[i] = c
        end
        p.ownedText = W.Text(p, 12, W.COLORS.white, "LEFT")
        p.ownedText:SetPoint("TOPLEFT", 2, -296)
        p.ownedText:SetWidth(580)
        p.slotHint = W.Text(p, 11, W.COLORS.gray, "LEFT")
        p.slotHint:SetPoint("TOPLEFT", 2, -316)
        p.slotHint:SetWidth(580)
        p.slotHint:SetText("장착 칸 클릭: 선택한 동료 장착 · 우클릭: 해제 · 메인 동료는 전투에 함께 참여합니다.")

        -- detail card
        local card = W.InfoCard(p, CARD_W, 406)
        card:SetPoint("TOPRIGHT", 0, 0)
        p.card = card
        W.Tooltip(card.icon, function(tt, self) self.sid = p.selected; companionTooltip(tt, self) end)
        card.shards = W.Counter(card, 150)
        card.shards:SetPoint("TOPLEFT", 20, -262)
        card.promo = W.Counter(card, 150)
        card.promo:SetPoint("TOPRIGHT", -20, -262)
        card.hint = W.Text(card, 11, W.COLORS.gray, "CENTER")
        card.hint:SetPoint("TOP", 0, -290)
        card.hint:SetWidth(CARD_W - 30)
        local bw2 = math.floor((CARD_W - 40 - 6) / 2)
        local bw3 = math.floor((CARD_W - 40 - 12) / 3)
        p.lvBtn = W.Button(card, "레벨업", bw2, 26, function() levelUp(p, 1) end, "cyan")
        p.lvBtn:SetPoint("TOPLEFT", 20, -306)
        p.lvMaxBtn = W.Button(card, "최대 레벨업", bw2, 26, function() levelUp(p, nil) end, "cyan")
        p.lvMaxBtn:SetPoint("LEFT", p.lvBtn, "RIGHT", 6, 0)
        p.mainBtn = W.Button(card, "메인 장착", bw3, 26, function() if p.selected then setMain(p, p.selected) end end, "green")
        p.mainBtn:SetPoint("TOPLEFT", 20, -336)
        p.subBtn = W.Button(card, "서브 장착", bw3, 26, function() equipSub(p) end, "green")
        p.subBtn:SetPoint("LEFT", p.mainBtn, "RIGHT", 6, 0)
        p.offBtn = W.Button(card, "해제", bw3, 26, function() unequip(p) end, "cyan")
        p.offBtn:SetPoint("LEFT", p.subBtn, "RIGHT", 6, 0)
        p.prBtn = W.Button(card, "승급", CARD_W - 40, 30, function() promote(p) end, "orange")
        p.prBtn:SetPoint("BOTTOM", 0, 10)
    end,

    refresh = function(p, hero)
        local C = ns.Companions
        if not (C and p.cards) then return end
        local main, subs = C.Equipped(hero)
        local open = C.SubSlotsUnlocked(hero)
        if not p.selected then p.selected = main or C.All()[1] end
        if not p.gradeSynced and p.selected and C.Def(p.selected) then
            p.grade = C.Def(p.selected).grade
            p.tabs:Select(p.grade)
            p.gradeSynced = true
        end

        local where = {}
        if main then where[main] = "M" end
        for i, sid in pairs(subs) do where[sid] = "S" .. i end

        -- tabs: red dot when a companion of that grade can level up
        local owned, total = 0, 0
        for g = 1, 5 do
            local any = false
            for _, sid in ipairs(C.ByGrade(g)) do
                local rec = C.Get(hero, sid)
                total = total + 1
                if rec then
                    owned = owned + 1
                    local need = C.LevelUpCost(sid, rec.level)
                    if need and (rec.count or 0) >= need then any = true end
                end
            end
            p.tabs.buttons[g].dot:SetShown(any)
        end

        local list = C.ByGrade(p.grade)
        for i, c in ipairs(p.cards) do
            local sid = list[i]
            c.sid = sid
            c.icon.sid = sid
            if sid then
                local def = C.Def(sid)
                local rec = C.Get(hero, sid)
                c:Show()
                c.icon.icon:SetTexture(companionIcon(sid))
                W.SetCardGrade(c, def.grade, rec ~= nil)
                c.tier:SetText(U.Utf8Sub(jobDisplay(def.job), 5))
                c.level:SetText(rec and ("Lv." .. rec.level) or "")
                c.stars:SetText("")
                local need = rec and C.LevelUpCost(sid, rec.level)
                if rec then
                    c.bar:Show()
                    if need then
                        c.bar:SetValue(math.min(1, (rec.count or 0) / need))
                        c.bar.text:SetText(string.format("%d/%d", rec.count or 0, need))
                    else
                        c.bar:SetValue(1)
                        c.bar.text:SetText("MAX")
                    end
                else
                    c.bar:Hide()
                end
                c.tag:SetText(where[sid] and ("|cff9be05a" .. where[sid] .. "|r") or "")
                c.sel:SetShown(sid == p.selected)
                c.dot:SetShown(rec ~= nil and need ~= nil and (rec.count or 0) >= need)
            else
                c:Hide()
            end
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
        p.ownedText:SetText(string.format("보유 동료 |cffffffff%d|r / %d    서브 칸 %d / %d 개방", owned, total, open, #p.subSlots))

        -- detail card
        local card = p.card
        local sid = p.selected
        local c = C.Def(sid)
        if not c then return end
        local rec = C.Get(hero, sid)
        local slot = rec and slotOf(hero, sid)
        local lv = rec and rec.level or 1
        local need = rec and C.LevelUpCost(sid, rec.level)
        card.stars:SetText(gradeHex(c.grade) .. gradeName(c.grade) .. "|r")
        card.name:SetText(c.name)
        card.icon.icon:SetTexture(companionIcon(sid))
        card.icon.icon:SetDesaturated(not rec)
        W.SetBorderGrade(card.icon, c.grade)
        card.line1:SetText(gradeHex(c.grade) .. jobDisplay(c.job) .. "|r")
        card.line2:SetText(string.format("Lv. |cffffffff%d|r |cff999999/ %d|r", lv, c.maxLevel))
        card.line3:SetText(rec and (need and string.format("다음 레벨: 조각 %d개", need) or "|cffffd100최대 레벨|r") or "|cff808080동료 소환으로 획득|r")
        card.tag:SetText(not rec and "|cffff6060미보유|r" or (slot == "main" and "|cff9be05a메인|r")
            or (slot and string.format("|cff9be05a서브 %d|r", slot)) or "|cffcccccc보유|r")
        local eff = C.Effects(sid, lv)
        local lines = { { header = "장착 효과" } }
        for _, e in ipairs(eff.equip or {}) do lines[#lines + 1] = statRow(e[1], e[2]) end
        lines[#lines + 1] = { gap = 4 }
        lines[#lines + 1] = { header = "보유 효과" }
        for _, e in ipairs(eff.owned or {}) do lines[#lines + 1] = statRow(e[1], e[2]) end
        local okInh, inh = pcall(C.AttackInheritM, sid, lv, hero.level)
        if okInh then
            lines[#lines + 1] = { gap = 4 }
            lines[#lines + 1] = { "메인 공격력 계승", "영웅의 " .. U.PctM(inh, 1), W.COLORS.gold }
        end
        card:SetLines(lines)

        card.shards.text:SetText(string.format("|T%s:14:14|t 조각 %s%d|r / %s", companionIcon(sid),
            (need and rec and (rec.count or 0) >= need) and "|cff40ff40" or "|cffffffff", rec and rec.count or 0, need and tostring(need) or "-"))
        local pc = C.PromoteCost(c.grade)
        local have = C.PromotableCopies(hero, c.grade)
        local canPromote = pc and C.ByGrade(c.grade + 1)[1]
        card.promo.text:SetText(canPromote and string.format("승급 %s%s|r / %s", have >= pc and "|cff40ff40" or "|cffffffff",
            U.Comma(have), U.Comma(pc)) or "승급 -")
        card.hint:SetText(canPromote and string.format("%s 조각 %s개 → %s%s|r 동료 1명 (무작위)", gradeName(c.grade), U.Comma(pc),
            gradeHex(c.grade + 1), gradeName(c.grade + 1)) or "최고 등급은 승급할 수 없습니다.")

        p.lvBtn:SetEnabled(rec ~= nil and need ~= nil and (rec.count or 0) >= need)
        p.lvMaxBtn:SetEnabled(rec ~= nil and need ~= nil and (rec.count or 0) >= need)
        p.mainBtn:SetEnabled(rec ~= nil and slot ~= "main")
        p.subBtn:SetEnabled(rec ~= nil and open > 0 and type(slot) ~= "number")
        p.offBtn:SetEnabled(slot ~= nil)
        p.prBtn:SetEnabled(canPromote and have >= pc or false)
    end,
})
