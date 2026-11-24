-- 무기 패널: 직업 무기 29종(등급 x 티어) 격자, 선택 무기 상세(레벨, 장착/보유 공격력%), 강화(다음 / x10 / 최대),
-- 각성, 승급, 장착, 최적 장착. "강화 전체 / 추천 강화"는 ns.Weapons에 해당 API가 있을 때만 표시.
local ADDON, ns = ...
local W = ns.W
local U = ns.U
local UI = ns.UI
local D = ns.Data

local GRID_ICON, GRID_STEP, GRID_LABEL_W = 26, 28, 56
local DX = 186  -- details column x

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
-- panel
---------------------------------------------------------------------------
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
        -- grid: one row per grade, one column per tier
        p.icons = {}
        p.gradeLabels = {}
        for g = 1, 8 do
            local l = W.Text(p, 11, { W.GradeColor(g) }, "LEFT")
            l:SetPoint("TOPLEFT", 0, -6 - (g - 1) * GRID_STEP)
            l:SetWidth(GRID_LABEL_W)
            l:SetText(gradeName(g))
            p.gradeLabels[g] = l
        end
        for idx = 1, WP.Count() do
            local t = WP.Tier(idx)
            local ic = W.Icon(p, GRID_ICON)
            ic:SetPoint("TOPLEFT", GRID_LABEL_W + (t.tier - 1) * GRID_STEP, -(t.grade - 1) * GRID_STEP)
            ic.idx = idx
            ic.sel = ic:CreateTexture(nil, "OVERLAY")
            ic.sel:SetTexture("Interface\\Buttons\\CheckButtonHilight")
            ic.sel:SetBlendMode("ADD")
            ic.sel:SetAllPoints()
            ic.sel:Hide()
            ic.copies = W.Text(ic, 9, W.COLORS.green, "LEFT")
            ic.copies:SetPoint("TOPLEFT", 1, -1)
            ic.eq = W.Text(ic, 10, W.COLORS.gold, "RIGHT")
            ic.eq:SetPoint("TOPRIGHT", -1, -1)
            ic:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
            ic:SetScript("OnClick", function(self)
                p.selected = self.idx
                UI.RefreshPanel()
            end)
            W.Tooltip(ic, weaponTooltip)
            p.icons[idx] = ic
        end

        -- header: owned total + bulk buttons
        p.summary = W.Text(p, 12, W.COLORS.white, "LEFT")
        p.summary:SetPoint("TOPLEFT", DX, -4)
        p.summary:SetWidth(470)
        p.bestBtn = W.Button(p, "최적 장착", 80, 20, function() equipBest(p) end)
        p.bestBtn:SetPoint("TOPRIGHT", -2, 0)
        p.optBtns = {}
        local anchor = p.bestBtn
        for i, def in ipairs(OPTIONAL) do
            local b = W.Button(p, def.label, 80, 20, function() optional(p, def) end)
            b:SetPoint("RIGHT", anchor, "LEFT", -4, 0)
            b.def = def
            b:Hide()
            p.optBtns[i] = b
            anchor = b
        end

        -- selected weapon
        p.bigIcon = W.Icon(p, 44)
        p.bigIcon:SetPoint("TOPLEFT", DX, -28)
        W.Tooltip(p.bigIcon, function(tt, self) if p.selected then self.idx = p.selected; weaponTooltip(tt, self) end end)
        p.name = W.Text(p, 15, W.COLORS.gold, "LEFT")
        p.name:SetPoint("TOPLEFT", p.bigIcon, "TOPRIGHT", 10, -2)
        p.status = W.Text(p, 11, W.COLORS.gray, "LEFT")
        p.status:SetPoint("TOPLEFT", p.name, "BOTTOMLEFT", 0, -6)
        p.status:SetWidth(420)
        p.equipBtn = W.Button(p, "장착", 90, 24, function() equip(p) end)
        p.equipBtn:SetPoint("TOPRIGHT", -2, -30)

        local function row(x, y, label)
            local l = W.Text(p, 12, W.COLORS.gray, "LEFT")
            l:SetPoint("TOPLEFT", x, y)
            l:SetWidth(70)
            l:SetText(label)
            local v = W.Text(p, 12, W.COLORS.white, "LEFT")
            v:SetPoint("TOPLEFT", x + 72, y)
            v:SetWidth(300)
            return v
        end
        p.lvText = row(DX, -82, "레벨")
        p.awText = row(DX, -102, "각성")
        p.cpText = row(DX, -122, "여분")
        p.eqText = row(DX + 370, -82, "장착 효과")
        p.owText = row(DX + 370, -102, "보유 효과")
        p.exText = row(DX + 370, -122, "추가")

        -- enhance
        p.enhCost = W.Text(p, 11, W.COLORS.white, "LEFT")
        p.enhCost:SetPoint("TOPLEFT", DX, -148)
        p.enhCost:SetWidth(740)
        p.enh1 = W.Button(p, "강화", 90, 22, function() enhance(p, 1) end)
        p.enh1:SetPoint("TOPLEFT", DX, -166)
        p.enh10 = W.Button(p, "강화 x10", 90, 22, function() enhance(p, 10) end)
        p.enh10:SetPoint("LEFT", p.enh1, "RIGHT", 6, 0)
        p.enhMax = W.Button(p, "최대 강화", 90, 22, function() enhance(p, nil) end)
        p.enhMax:SetPoint("LEFT", p.enh10, "RIGHT", 6, 0)

        -- awaken / promote
        p.awCost = W.Text(p, 11, W.COLORS.white, "LEFT")
        p.awCost:SetPoint("TOPLEFT", DX, -196)
        p.awCost:SetWidth(360)
        p.awBtn = W.Button(p, "각성", 90, 22, function() awaken(p) end)
        p.awBtn:SetPoint("TOPLEFT", DX, -214)
        p.prCost = W.Text(p, 11, W.COLORS.white, "LEFT")
        p.prCost:SetPoint("TOPLEFT", DX + 370, -196)
        p.prCost:SetWidth(380)
        p.prBtn = W.Button(p, "승급", 90, 22, function() promote(p, 1) end)
        p.prBtn:SetPoint("TOPLEFT", DX + 370, -214)
        p.prAllBtn = W.Button(p, "모두 승급", 90, 22, function() promote(p, nil) end)
        p.prAllBtn:SetPoint("LEFT", p.prBtn, "RIGHT", 6, 0)
    end,

    refresh = function(p, hero)
        local WP = ns.Weapons
        if not (WP and p.icons) then return end
        local eqIdx = WP.Equipped(hero)
        if not p.selected then p.selected = eqIdx or 1 end

        -- grid
        for idx, ic in ipairs(p.icons) do
            local t = WP.Tier(idx)
            local rec = WP.Get(hero, idx)
            ic.icon:SetTexture(weaponIcon(hero, t.grade))
            W.SetBorderGrade(ic, t.grade)
            ic.icon:SetDesaturated(not rec)
            ic:SetAlpha(rec and 1 or 0.45)
            ic.count:SetText(rec and tostring(rec.level) or "")
            ic.copies:SetText((rec and (rec.count or 0) > 0) and ("+" .. rec.count) or "")
            ic.eq:SetText(idx == eqIdx and "E" or "")
            if idx == p.selected then ic.sel:Show() else ic.sel:Hide() end
        end

        -- header
        local owned = 0
        for idx = 1, WP.Count() do if WP.Get(hero, idx) then owned = owned + 1 end end
        p.summary:SetText(string.format("보유 %d / %d · 보유 효과 합계 |cff40ff40공격력 +%s|r · %s", owned, WP.Count(),
            pct(WP.OwnedTotalM(hero)), (W.Money("weaponStone", ns.Hero.Count(hero, "weaponStone")))))
        for _, b in ipairs(p.optBtns) do
            if WP[b.def.fn] then b:Show() else b:Hide() end
        end

        -- details
        local idx = p.selected
        local t = WP.Tier(idx)
        local rec = WP.Get(hero, idx)
        p.bigIcon.icon:SetTexture(weaponIcon(hero, t.grade))
        p.bigIcon.icon:SetDesaturated(not rec)
        W.SetBorderGrade(p.bigIcon, t.grade)
        p.name:SetText(gradeHex(t.grade) .. WP.Name(hero, idx) .. "|r")
        if not rec then
            p.status:SetText("|cffff6060미보유|r · 무기 소환이나 하위 무기 승급으로 획득합니다.")
        elseif idx == eqIdx then
            p.status:SetText("|cffffd100장착 중|r")
        else
            p.status:SetText("보유 중")
        end
        p.equipBtn:SetEnabled(rec ~= nil and idx ~= eqIdx)
        p.equipBtn:SetText(idx == eqIdx and "장착 중" or "장착")

        local level = rec and rec.level or 1
        local cap = rec and WP.MaxLevel(rec) or WP.MaxLevel(nil)
        local cur = WP.Effects(idx, level)
        local nxt = (rec and level < cap) and WP.Effects(idx, level + 1) or nil
        p.lvText:SetText(string.format("Lv.%d / %d  |cff999999(최대 %d)|r", level, cap, D.Weapons.maxLevel or 200))
        p.awText:SetText(stars(rec and rec.awaken or 0, WP.MAX_AWAKEN or 5))
        p.cpText:SetText(rec and string.format("%d개", rec.count or 0) or "-")
        p.eqText:SetText("공격력 +" .. pct(cur.equipM) .. (nxt and (" |cff40ff40→ +" .. pct(nxt.equipM) .. "|r") or ""))
        p.owText:SetText("공격력 +" .. pct(cur.ownedM) .. (nxt and (" |cff40ff40→ +" .. pct(nxt.ownedM) .. "|r") or ""))
        p.exText:SetText(string.format("명중 +%s · 공격 속도 +%s", U.Comma(cur.hit or 0), pct(cur.aspdM)))

        -- enhance costs
        local stones = ns.Hero.Count(hero, "weaponStone")
        if rec and level < cap then
            local c1 = WP.EnhanceCost(idx, level) or 0
            local to10 = math.min(level + 10, cap)
            local c10 = WP.CostRange(idx, level, to10)
            local toMax = WP.CostRange(idx, level, cap)
            p.enhCost:SetText(string.format("다음 레벨 %s · Lv.%d까지 %s · 상한(Lv.%d)까지 %s", (W.Money("weaponStone", c1)),
                to10, (W.Money("weaponStone", c10)), cap, (W.Money("weaponStone", toMax))))
            p.enh1:SetEnabled(stones >= c1)
            p.enh10:SetEnabled(stones >= c1)
            p.enhMax:SetEnabled(stones >= c1)
        else
            p.enhCost:SetText(rec and "|cffffd100레벨 상한입니다.|r 각성하면 상한이 20 오릅니다." or "|cff808080미보유 무기는 강화할 수 없습니다.|r")
            p.enh1:SetEnabled(false)
            p.enh10:SetEnabled(false)
            p.enhMax:SetEnabled(false)
        end

        -- awaken
        local need = rec and WP.AwakenCost(rec)
        if not rec then
            p.awCost:SetText("|cff808080각성: 미보유|r")
            p.awBtn:SetEnabled(false)
        elseif need then
            p.awCost:SetText(string.format("각성 %d단계: 같은 무기 %d개 필요 (여분 %s%d|r)", (rec.awaken or 0) + 1, need,
                (rec.count or 0) >= need and "|cff40ff40" or "|cffff5050", rec.count or 0))
            p.awBtn:SetEnabled((rec.count or 0) >= need)
        else
            p.awCost:SetText("|cffffd100최대 각성|r")
            p.awBtn:SetEnabled(false)
        end

        -- promote
        local can, why = WP.CanPromote(hero, idx)
        local nextT = WP.Tier(idx + 1)
        if nextT then
            p.prCost:SetText(string.format("승급: 최대 각성 + 같은 무기 %d개 → %s%s|r 1개%s", WP.PROMOTE_COPIES or 5,
                gradeHex(nextT.grade), nextT.label, can and "" or ("  |cffff5050" .. tostring(why or "") .. "|r")))
        else
            p.prCost:SetText("|cff808080더 높은 등급의 무기가 없습니다.|r")
        end
        p.prBtn:SetEnabled(can and true or false)
        p.prAllBtn:SetEnabled(can and true or false)
    end,
})
