-- 무기 패널: 직업 무기 29종(등급 x 티어) 격자, 선택 무기 상세(레벨, 장착/보유 공격력%), 강화(다음 / x10 / 최대),
-- 각성, 승급, 장착, 최적 장착. "강화 전체 / 추천 강화"는 ns.Weapons에 해당 API가 있을 때만 표시.
local ADDON, ns = ...
local W = ns.W
local U = ns.U
local UI = ns.UI
local D = ns.Data


local WEAPON_FALLBACK = {
    hero = "INV_Sword_39", paladin = "INV_Hammer_04", darkKnight = "INV_Spear_04", archMageIL = "INV_Staff_08",
    archMageFP = "INV_Staff_07", bishop = "INV_Mace_01", bowMaster = "INV_Weapon_Bow_07",
    marksman = "INV_Weapon_Crossbow_01", nightLord = "INV_ThrowingKnife_04", shadower = "INV_Weapon_ShortBlade_05",
    viper = "INV_Gauntlets_04", captain = "INV_Weapon_Rifle_01", nightWalker = "INV_ThrowingKnife_02",
    windBreaker = "INV_Weapon_Bow_02", flameWizard = "INV_Staff_06", soulMaster = "INV_Sword_04",
}

---------------------------------------------------------------------------
-- helpers
---------------------------------------------------------------------------
local function call(where, fn, ...)
    local ok, a, b, c = pcall(fn, ...)
    if not ok then
        if ns.Debug then ns.Debug("weapon ui %s: %s", where, tostring(a)) end
        W.Toast(tostring(a), W.COLORS.red)
        return nil
    end
    return a, b, c
end

local function gradeHex(g) return W.Hex(W.GradeColor(g)) end

local function gradeName(g)
    local L = D.SummonLabels
    return L and L.grades and L.grades[g] or tostring(g)
end

local function itemIcon(id)
    if not id then return nil end
    if C_Item and C_Item.GetItemIconByID then
        local ok, tex = pcall(C_Item.GetItemIconByID, id)
        if ok and tex then return tex end
    end
    if GetItemIcon then
        local ok, tex = pcall(GetItemIcon, id)
        if ok and tex then return tex end
    end
    return nil
end

local iconCache = {}
local function weaponIcon(hero, grade)
    local key = (hero and hero.jobKey or "?") .. grade
    if iconCache[key] then return iconCache[key] end
    local L = D.SkinLooks
    local wl = L and L.weapons and hero and L.weapons[hero.jobKey]
    local e = wl and wl.mainHand and wl.mainHand["Grade" .. grade]
    local tex = itemIcon(e and e.id)
    if not tex then
        return "Interface\\Icons\\" .. (WEAPON_FALLBACK[hero and hero.jobKey or ""] or "INV_Sword_04")
    end
    iconCache[key] = tex
    return tex
end

local function pct(v) return U.PctM(v or 0, 1) end

local function stars(n, max)
    local s = ""
    for i = 1, max do s = s .. (i <= n and "|cffffd100★|r" or "|cff555555☆|r") end
    return s
end

local function act(p, where, fn, ...)
    local a, b = call(where, fn, ...)
    UI.RefreshPanel()
    return a, b
end

---------------------------------------------------------------------------
-- actions
---------------------------------------------------------------------------
local function enhance(p, times)
    local hero, WP = ns.Hero.Active(), ns.Weapons
    local idx = p.selected
    if not (hero and idx) then return end
    if not WP.Get(hero, idx) then W.Toast("보유하지 않은 무기입니다.", W.COLORS.red) return end
    local gained, spent = act(p, "enhance", WP.Enhance, hero, idx, times)
    if gained and gained > 0 then
        W.Toast(string.format("강화 +%d (%s %s 사용)", gained, D.CurrencyName("weaponStone"), U.FormatNumber(spent or 0)), W.COLORS.green)
    elseif gained then
        local rec = WP.Get(hero, idx)
        if rec and rec.level >= WP.MaxLevel(rec) then W.Toast("레벨 상한입니다. 각성하면 상한이 오릅니다.", W.COLORS.red)
        else W.Toast(D.CurrencyName("weaponStone") .. "이(가) 부족합니다.", W.COLORS.red) end
    end
end

local function awaken(p)
    local hero, idx = ns.Hero.Active(), p.selected
    if not (hero and idx) then return end
    local ok, err = act(p, "awaken", ns.Weapons.Awaken, hero, idx)
    if ok then W.Toast("각성 성공! 레벨 상한이 올랐습니다.", W.COLORS.green) elseif err then W.Toast(err, W.COLORS.red) end
end

local function promote(p, times)
    local hero, idx = ns.Hero.Active(), p.selected
    if not (hero and idx) then return end
    local can, err = call("canPromote", ns.Weapons.CanPromote, hero, idx)
    if not can then
        if err then W.Toast(err, W.COLORS.red) end
        UI.RefreshPanel()
        return
    end
    local n = act(p, "promote", ns.Weapons.Promote, hero, idx, times)
    if n and n > 0 then
        W.Toast(string.format("%s %d개 획득!", ns.Weapons.Name(hero, idx + 1), n), W.COLORS.green)
    end
end

local function equip(p)
    local hero, idx = ns.Hero.Active(), p.selected
    if not (hero and idx) then return end
    local ok, err = act(p, "equip", ns.Weapons.Equip, hero, idx)
    if ok then W.Toast(ns.Weapons.Name(hero, idx) .. " 장착") elseif err then W.Toast(err, W.COLORS.red) end
end

local function equipBest(p)
    local hero = ns.Hero.Active()
    if not hero then return end
    local idx = act(p, "equipBest", ns.Weapons.EquipBest, hero)
    if idx then
        p.selected = idx
        W.Toast(ns.Weapons.Name(hero, idx) .. " 장착")
        UI.RefreshPanel()
    else
        W.Toast("보유한 무기가 없습니다.", W.COLORS.red)
    end
end

-- optional bulk APIs (not every build has them)
local OPTIONAL = {
    { fn = "EnhanceAll", label = "강화 전체", done = "무기 %d회 강화" },
    { fn = "EnhanceRecommended", label = "추천 강화", done = "추천 강화 %d회" },
}

local function optional(p, def)
    local hero = ns.Hero.Active()
    local fn = ns.Weapons and ns.Weapons[def.fn]
    if not (hero and fn) then return end
    local n, err = act(p, def.fn, fn, hero)
    if type(n) == "number" and n > 0 then W.Toast(string.format(def.done, n), W.COLORS.green)
    elseif err then W.Toast(tostring(err), W.COLORS.red) end
end

---------------------------------------------------------------------------
-- tooltip
---------------------------------------------------------------------------
local function weaponTooltip(tt, icon)
    local hero, WP = ns.Hero.Active(), ns.Weapons
    local idx = icon.idx
    local t = idx and WP.Tier(idx)
    if not (hero and t) then return end
    local rec = WP.Get(hero, idx)
    tt:AddLine(WP.Name(hero, idx), W.GradeColor(t.grade))
    local level = rec and rec.level or 1
    local e = WP.Effects(idx, level)
    if rec then
        tt:AddLine(string.format("Lv.%d / %d · 각성 %d · 여분 %d개", rec.level, WP.MaxLevel(rec), rec.awaken or 0, rec.count or 0), 1, 1, 1)
    else
        tt:AddLine("미보유 (Lv.1 기준)", 0.6, 0.6, 0.6)
    end
    tt:AddLine("장착 효과: 공격력 +" .. pct(e.equipM), 0.4, 0.8, 1)
    tt:AddLine("보유 효과: 공격력 +" .. pct(e.ownedM), 0.3, 1, 0.3)
    if (e.hit or 0) > 0 then tt:AddLine("명중 +" .. U.Comma(e.hit), 0.8, 0.8, 0.8) end
    if (e.aspdM or 0) > 0 then tt:AddLine("공격 속도 +" .. pct(e.aspdM), 0.8, 0.8, 0.8) end
    local eqIdx = WP.Equipped(hero)
    if eqIdx == idx then tt:AddLine("장착 중", 1, 0.82, 0) end
end

---------------------------------------------------------------------------
-- panel: card grid (2 grades per row, 4 tiers each) + detail card on the right (original layout)
---------------------------------------------------------------------------
local CW, CH, GAP, GG, ROW = 64, 76, 4, 20, 94
local CARD_W = 352

local function tierWord(t) return (t.label or ""):match("(%S+)$") or "" end

UI.RegisterPanel("weapons", {
    title = "무기", order = 32,
    build = function(p)
        local WP = ns.Weapons
        if not WP then
            local t = W.Text(p, 13, W.COLORS.red, "LEFT")
            t:SetPoint("TOPLEFT", 4, -4)
            t:SetText("무기 시스템을 불러오지 못했습니다.")
            return
        end
        p.summary = W.Text(p, 12, W.COLORS.white, "LEFT")
        p.summary:SetPoint("TOPLEFT", 2, -6)
        p.summary:SetWidth(440)
        p.bestBtn = W.Button(p, "최적 장착", 96, 24, function() equipBest(p) end, "cyan")
        p.bestBtn:SetPoint("TOPLEFT", 4 * CW + 3 * GAP + GG + 4 * CW + 3 * GAP - 96, 0)
        p.optBtns = {}
        local anchor = p.bestBtn
        for i, def in ipairs(OPTIONAL) do
            local b = W.Button(p, def.label, 86, 24, function() optional(p, def) end, "cyan")
            b:SetPoint("RIGHT", anchor, "LEFT", -4, 0)
            b.def = def
            b:Hide()
            p.optBtns[i] = b
            anchor = b
        end

        p.cards = {}
        p.gradeLabels = {}
        for g = 1, 8 do
            local col, row = (g - 1) % 2, math.floor((g - 1) / 2)
            local gx = col * (4 * CW + 3 * GAP + GG)
            local gy = -30 - row * ROW
            local l = W.Text(p, 11, { W.GradeColor(g) }, "LEFT")
            l:SetPoint("TOPLEFT", gx + 2, gy)
            l:SetText(gradeName(g))
            p.gradeLabels[g] = l
        end
        for idx = 1, WP.Count() do
            local t = WP.Tier(idx)
            local col, row = (t.grade - 1) % 2, math.floor((t.grade - 1) / 2)
            local gx = col * (4 * CW + 3 * GAP + GG)
            local c = W.GradeCard(p, CW, CH, function(self)
                p.selected = self.idx
                UI.RefreshPanel()
            end)
            c:SetPoint("TOPLEFT", gx + (t.tier - 1) * (CW + GAP), -30 - row * ROW - 14)
            c.idx = idx
            c.icon.idx = idx
            W.Tooltip(c, weaponTooltip)
            p.cards[idx] = c
        end

        -- detail card
        local card = W.InfoCard(p, CARD_W, 406)
        card:SetPoint("TOPRIGHT", 0, 0)
        p.card = card
        W.Tooltip(card.icon, function(tt, self) if p.selected then self.idx = p.selected; weaponTooltip(tt, self) end end)
        card.copies = W.Counter(card, 150)
        card.copies:SetPoint("TOPLEFT", 20, -262)
        card.stones = W.Counter(card, 150)
        card.stones:SetPoint("TOPRIGHT", -20, -262)
        card.hint = W.Text(card, 11, W.COLORS.gray, "CENTER")
        card.hint:SetPoint("TOP", 0, -290)
        card.hint:SetWidth(CARD_W - 30)
        local bw = math.floor((CARD_W - 40 - 12) / 3)
        p.awBtn = W.Button(card, "각성", bw, 26, function() awaken(p) end, "cyan")
        p.awBtn:SetPoint("TOPLEFT", 20, -306)
        p.prBtn = W.Button(card, "승급", bw, 26, function() promote(p, 1) end, "green")
        p.prBtn:SetPoint("LEFT", p.awBtn, "RIGHT", 6, 0)
        p.prAllBtn = W.Button(card, "모두 승급", bw, 26, function() promote(p, nil) end, "green")
        p.prAllBtn:SetPoint("LEFT", p.prBtn, "RIGHT", 6, 0)
        p.enh1 = W.Button(card, "레벨업", bw, 26, function() enhance(p, 1) end, "cyan")
        p.enh1:SetPoint("TOPLEFT", 20, -336)
        p.enh10 = W.Button(card, "레벨업 x10", bw, 26, function() enhance(p, 10) end, "cyan")
        p.enh10:SetPoint("LEFT", p.enh1, "RIGHT", 6, 0)
        p.enhMax = W.Button(card, "최대 레벨업", bw, 26, function() enhance(p, nil) end, "cyan")
        p.enhMax:SetPoint("LEFT", p.enh10, "RIGHT", 6, 0)
        p.equipBtn = W.Button(card, "장착", CARD_W - 40, 30, function() equip(p) end, "green")
        p.equipBtn:SetPoint("BOTTOM", 0, 10)
    end,

    refresh = function(p, hero)
        local WP = ns.Weapons
        if not (WP and p.cards) then return end
        local eqIdx = WP.Equipped(hero)
        if not p.selected then p.selected = eqIdx or 1 end

        -- cards
        local owned = 0
        for idx, c in ipairs(p.cards) do
            local t = WP.Tier(idx)
            local rec = WP.Get(hero, idx)
            if rec then owned = owned + 1 end
            c.icon.icon:SetTexture(weaponIcon(hero, t.grade))
            W.SetCardGrade(c, t.grade, rec ~= nil)
            c.tier:SetText(tierWord(t))
            c.level:SetText(rec and ("Lv." .. rec.level) or "")
            c.stars:SetText(rec and W.Stars(rec.awaken or 0, WP.MAX_AWAKEN or 5) or "")
            if rec then
                local need = WP.AwakenCost(rec) or WP.PROMOTE_COPIES or 5
                c.bar:Show()
                c.bar:SetValue(math.min(1, (rec.count or 0) / need))
                c.bar.text:SetText(string.format("%d/%d", rec.count or 0, need))
            else
                c.bar:Hide()
            end
            c.tag:SetText(idx == eqIdx and "|cff9be05aE|r" or "")
            c.sel:SetShown(idx == p.selected)
            local can = rec and ((WP.AwakenCost(rec) and (rec.count or 0) >= WP.AwakenCost(rec)) or WP.CanPromote(hero, idx))
            c.dot:SetShown(can and true or false)
        end
        p.summary:SetText(string.format("보유 |cffffffff%d|r / %d    보유 효과 합계 |cff40ff40공격력 +%s|r", owned, WP.Count(),
            pct(WP.OwnedTotalM(hero))))
        for _, b in ipairs(p.optBtns) do
            if WP[b.def.fn] then b:Show() else b:Hide() end
        end

        -- detail card
        local card = p.card
        local idx = p.selected
        local t = WP.Tier(idx)
        local rec = WP.Get(hero, idx)
        local level = rec and rec.level or 1
        local cap = rec and WP.MaxLevel(rec) or WP.MaxLevel(nil)
        local cur = WP.Effects(idx, level)
        local nxt = (rec and level < cap) and WP.Effects(idx, level + 1) or nil
        card.stars:SetText(W.Stars(rec and rec.awaken or 0, WP.MAX_AWAKEN or 5, true))
        card.name:SetText(WP.Name(hero, idx))
        card.icon.icon:SetTexture(weaponIcon(hero, t.grade))
        card.icon.icon:SetDesaturated(not rec)
        W.SetBorderGrade(card.icon, t.grade)
        card.line1:SetText(gradeHex(t.grade) .. (t.label or "") .. "|r")
        card.line2:SetText(string.format("%d 각성", rec and rec.awaken or 0))
        card.line3:SetText(string.format("Lv. |cffffffff%d|r |cff999999/ %d|r", level, cap))
        if idx == eqIdx then card.tag:SetText("|cff9be05a장착중|r")
        elseif rec then card.tag:SetText("|cffccccccc보유|r")
        else card.tag:SetText("|cffff6060미보유|r") end
        local function up(a, b) return "+" .. pct(a) .. ((b and b ~= a) and (" |cff9be05a→ +" .. pct(b) .. "|r") or "") end
        local lines = {
            { header = "장착 효과" },
            { "공격력", up(cur.equipM, nxt and nxt.equipM) },
        }
        if (cur.hit or 0) > 0 then lines[#lines + 1] = { "명중", U.Comma(cur.hit) } end
        if (cur.aspdM or 0) > 0 then lines[#lines + 1] = { "공격 속도", "+" .. pct(cur.aspdM) } end
        lines[#lines + 1] = { gap = 6 }
        lines[#lines + 1] = { header = "보유 효과" }
        lines[#lines + 1] = { "공격력", up(cur.ownedM, nxt and nxt.ownedM) }
        card:SetLines(lines)

        -- counters: spare copies toward awakening / promotion, stones toward the next level
        local need = rec and (WP.AwakenCost(rec) or WP.PROMOTE_COPIES or 5) or (WP.PROMOTE_COPIES or 5)
        local cnt = rec and rec.count or 0
        card.copies.text:SetText(string.format("|T%s:14:14|t %s%d|r / %d", weaponIcon(hero, t.grade),
            cnt >= need and "|cff40ff40" or "|cffffffff", cnt, need))
        local stones = ns.Hero.Count(hero, "weaponStone")
        local c1 = (rec and level < cap) and (WP.EnhanceCost(idx, level) or 0) or 0
        card.stones.text:SetText(string.format("|T%s:14:14|t %s%s|r / %s", D.CurrencyIcon("weaponStone"),
            stones >= c1 and "|cffffffff" or "|cffff5050", U.FormatNumber(stones), U.FormatNumber(c1)))

        -- hint + buttons
        local can, why = WP.CanPromote(hero, idx)
        local nextT = WP.Tier(idx + 1)
        local awNeed = rec and WP.AwakenCost(rec)
        if not rec then
            card.hint:SetText("무기 소환이나 하위 무기 승급으로 획득합니다.")
        elseif awNeed then
            card.hint:SetText(string.format("각성 %d단계: 같은 무기 %d개 · 레벨 상한 +20", (rec.awaken or 0) + 1, awNeed))
        elseif nextT then
            card.hint:SetText(string.format("승급: 같은 무기 %d개 → %s%s|r 1개", WP.PROMOTE_COPIES or 5, gradeHex(nextT.grade), nextT.label))
        else
            card.hint:SetText("최대 각성")
        end
        p.awBtn:SetEnabled(awNeed ~= nil and cnt >= awNeed)
        p.prBtn:SetEnabled(can and true or false)
        p.prAllBtn:SetEnabled(can and true or false)
        local canLv = rec and level < cap and stones >= c1
        p.enh1:SetEnabled(canLv and true or false)
        p.enh10:SetEnabled(canLv and true or false)
        p.enhMax:SetEnabled(canLv and true or false)
        p.equipBtn:SetEnabled(rec ~= nil and idx ~= eqIdx)
        p.equipBtn:SetText(idx == eqIdx and "장착중" or "장착")
        if not can and why and rec and not awNeed and nextT then card.hint:SetText("|cffff6060" .. why .. "|r") end
    end,
})
