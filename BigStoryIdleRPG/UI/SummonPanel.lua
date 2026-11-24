-- 소환 패널: 무기 / 동료 / 픽업 소환.
-- 소환 레벨과 경험치 막대, 현재 레벨 확률표(팝업 + 툴팁), 확정 소환 진행도, 비용(소환서 우선 → 붉은 다이아),
-- x1 / x10 / x최대(무기) 버튼, 등급 테두리 결과 격자와 순차 페이드인 연출(OnUpdate).
local ADDON, ns = ...
local W = ns.W
local U = ns.U
local UI = ns.UI
local D = ns.Data

local KINDS = { "weapon", "companion", "pickup" }
local KIND_NAMES = { weapon = "무기 소환", companion = "동료 소환", pickup = "픽업 소환" }

local GRID_X, GRID_Y = 336, -24
local CELL, ICON = 38, 32
local COLS, ROWS = 16, 5
local CELLS = COLS * ROWS
local REVEAL_TIME, FADE_TIME, FLASH_TIME = 1.2, 0.25, 0.6

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
-- pcall wrapper: a Lua error becomes a toast (+ ns.Debug), API errors are returned as usual
local function call(where, fn, ...)
    local ok, a, b, c = pcall(fn, ...)
    if not ok then
        if ns.Debug then ns.Debug("summon ui %s: %s", where, tostring(a)) end
        W.Toast(tostring(a), W.COLORS.red)
        return nil
    end
    return a, b, c
end

local function gradeHex(g) return W.Hex(W.GradeColor(g)) end

local function pctText(v)
    v = v or 0
    if v >= 10 then return string.format("%.2f%%", v) end
    if v >= 0.1 then return string.format("%.3f%%", v) end
    if v >= 0.001 then return string.format("%.4f%%", v) end
    return string.format("%.6f%%", v)
end

local function weaponGradeName(g)
    local L = D.SummonLabels
    return L and L.grades and L.grades[g] or tostring(g)
end

local function companionGradeName(g)
    local L = D.SummonLabels
    local n = L and L.companionGrades and L.companionGrades[g]
    if n then return n end
    local gi = ns.Companions and ns.Companions.GradeInfo and ns.Companions.GradeInfo(g)
    return gi and gi.ko or tostring(g)
end

local function weaponLabel(grade, tier)
    local WP = ns.Weapons
    local idx = WP and WP.IndexOf and WP.IndexOf(grade, tier)
    local t = idx and WP.Tier(idx)
    if t and t.label then return t.label end
    local L = D.SummonLabels
    return weaponGradeName(grade) .. " " .. (L and L.tiers and L.tiers[tier or 1] or "")
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

local function weaponIcon(hero, grade)
    local L = D.SkinLooks
    local wl = L and L.weapons and hero and L.weapons[hero.jobKey]
    local e = wl and wl.mainHand and wl.mainHand["Grade" .. (grade or 1)]
    return itemIcon(e and e.id) or ("Interface\\Icons\\" .. (WEAPON_FALLBACK[hero and hero.jobKey or ""] or "INV_Sword_04"))
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

local function companionIcon(sid)
    local c = ns.Companions and ns.Companions.Def(sid)
    local job = c and jobDef(c.job)
    local skin = job and ns.Skin and ns.Skin.Job(job)
    return skin and skin.icon or "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function companionName(sid)
    local c = ns.Companions and ns.Companions.Def(sid)
    return c and c.name or tostring(sid)
end

local function resultName(hero, r)
    if r.kind == "weapon" then
        return ns.Weapons and ns.Weapons.Name and ns.Weapons.Name(hero, r.idx) or weaponLabel(r.grade, r.tier)
    end
    return companionName(r.sid)
end

local function resultGradeText(r)
    if r.kind == "weapon" then return weaponLabel(r.grade, r.tier) end
    return companionGradeName(r.grade)
end

local function guaranteeLabel(kind, g)
    if kind == "weapon" then return weaponLabel(g.grade, g.tier) end
    return companionGradeName(g.grade)
end

-- "rare" results get a flash during the reveal
local function isRare(r)
    if r.kind == "weapon" then return (r.grade or 0) >= 5 end
    return (r.grade or 0) >= 4
end

---------------------------------------------------------------------------
-- rates
---------------------------------------------------------------------------
local function rateRows(kind, rates)
    local rows = {}
    if kind == "weapon" then
        local list = {}
        for _, r in ipairs(rates or {}) do
            if (r.percent or 0) > 0 then list[#list + 1] = r end
        end
        table.sort(list, function(a, b)
            if a.grade ~= b.grade then return a.grade > b.grade end
            return (a.tier or 0) > (b.tier or 0)
        end)
        for _, r in ipairs(list) do
            rows[#rows + 1] = { text = weaponLabel(r.grade, r.tier), grade = r.grade, percent = r.percent }
        end
        return rows
    end
    local list = {}
    for _, r in ipairs(rates or {}) do
        if (r.percent or 0) > 0 then list[#list + 1] = r end
    end
    table.sort(list, function(a, b) return a.grade > b.grade end)
    for _, r in ipairs(list) do
        rows[#rows + 1] = { text = companionGradeName(r.grade) .. " 등급", grade = r.grade, percent = r.percent, header = true }
        local per = {}
        for sid, pct in pairs(r.perCompanion or {}) do per[#per + 1] = { sid = sid, pct = pct } end
        table.sort(per, function(a, b)
            if a.pct ~= b.pct then return a.pct > b.pct end
            return a.sid < b.sid
        end)
        for _, e in ipairs(per) do
            local c = ns.Companions.Def(e.sid)
            rows[#rows + 1] = { text = "   " .. companionName(e.sid) .. (c and ("  |cff999999" .. jobDisplay(c.job) .. "|r") or ""),
                grade = r.grade, percent = e.pct }
        end
    end
    return rows
end

-- per-grade totals for the tooltip
local function gradeTotals(kind, rates)
    local t = {}
    for _, r in ipairs(rates or {}) do t[r.grade] = (t[r.grade] or 0) + (r.percent or 0) end
    local out = {}
    for g, pct in pairs(t) do
        if pct > 0 then out[#out + 1] = { grade = g, percent = pct } end
    end
    table.sort(out, function(a, b) return a.grade > b.grade end)
    return out
end

---------------------------------------------------------------------------
-- result grid
---------------------------------------------------------------------------
local function buildEntries(res)
    local entries = {}
    if #res <= CELLS then
        for i, r in ipairs(res) do
            entries[i] = { r = r, count = 1, isNew = r.isNew, guaranteed = r.guaranteed }
        end
        return entries, false
    end
    -- big batches: one cell per distinct result with a count
    local byKey = {}
    for _, r in ipairs(res) do
        local key = r.kind == "weapon" and r.idx or r.sid
        local e = byKey[key]
        if not e then
            e = { r = r, count = 0 }
            byKey[key] = e
            entries[#entries + 1] = e
        end
        e.count = e.count + 1
        if r.isNew then e.isNew = true end
        if r.guaranteed then e.guaranteed = true end
    end
    table.sort(entries, function(a, b)
        if a.r.grade ~= b.r.grade then return a.r.grade > b.r.grade end
        if (a.r.tier or 0) ~= (b.r.tier or 0) then return (a.r.tier or 0) > (b.r.tier or 0) end
        return a.count > b.count
    end)
    return entries, true
end

local function cellTooltip(tt, cell)
    local e = cell.entry
    if not e then return end
    local hero = ns.Hero.Active()
    local r = e.r
    tt:AddLine(resultName(hero, r), W.GradeColor(r.grade))
    tt:AddLine(resultGradeText(r), 0.8, 0.8, 0.8)
    if e.count and e.count > 1 then tt:AddLine(string.format("%s개 획득", U.Comma(e.count)), 1, 1, 1) end
    if e.isNew then tt:AddLine("신규 획득!", 0.3, 1, 0.3) end
    if e.guaranteed then tt:AddLine("확정 소환", 1, 0.82, 0) end
    if hero then
        if r.kind == "weapon" and ns.Weapons and ns.Weapons.Get then
            local rec = ns.Weapons.Get(hero, r.idx)
            if rec then tt:AddLine(string.format("보유: Lv.%d · 각성 %d · 여분 %d개", rec.level, rec.awaken or 0, rec.count or 0), 0.6, 0.6, 0.6) end
        elseif r.kind == "companion" and ns.Companions and ns.Companions.Get then
            local rec = ns.Companions.Get(hero, r.sid)
            local c = ns.Companions.Def(r.sid)
            if c then tt:AddLine(jobDisplay(c.job), 0.6, 0.6, 0.6) end
            if rec then tt:AddLine(string.format("보유: Lv.%d · 조각 %d개", rec.level, rec.count or 0), 0.6, 0.6, 0.6) end
        end
    end
end

local function animUpdate(self, elapsed)
    local a = self.anim
    if not a then self:SetScript("OnUpdate", nil) return end
    a.t = a.t + (elapsed or 0)
    local done = true
    for i = 1, a.n do
        local cell = self.cells[i]
        local start = (i - 1) * a.step
        local alpha = (a.t - start) / FADE_TIME
        if alpha < 1 then done = false end
        if alpha < 0 then alpha = 0 elseif alpha > 1 then alpha = 1 end
        cell:SetAlpha(alpha)
        if cell.flashOn then
            local f = 1 - (a.t - start - FADE_TIME) / FLASH_TIME
            if a.t < start + FADE_TIME then f = alpha end
            if f > 0 then done = false end
            if f < 0 then f = 0 elseif f > 1 then f = 1 end
            cell.flash:SetAlpha(f)
        end
    end
    if done then
        self.anim = nil
        self:SetScript("OnUpdate", nil)
    end
end

local function finishAnim(grid)
    grid.anim = nil
    grid:SetScript("OnUpdate", nil)
    for _, cell in ipairs(grid.cells) do
        cell:SetAlpha(1)
        cell.flash:SetAlpha(0)
    end
end

local function showResults(p, res, animate)
    local grid = p.grid
    local hero = ns.Hero.Active()
    if not res then
        for _, cell in ipairs(grid.cells) do cell.entry = nil; cell:Hide() end
        p.resTitle:SetText("소환 결과")
        p.resSummary:SetText("|cff999999소환 버튼을 눌러 보세요.|r")
        finishAnim(grid)
        return
    end
    local entries, grouped = buildEntries(res)
    for i, cell in ipairs(grid.cells) do
        local e = entries[i]
        cell.entry = e
        if e then
            local r = e.r
            cell.icon:SetTexture(r.kind == "weapon" and weaponIcon(hero, r.grade) or companionIcon(r.sid))
            W.SetBorderGrade(cell, r.grade)
            cell.count:SetText((grouped or e.count > 1) and ("x" .. e.count) or "")
            cell.new:SetText(e.isNew and "N" or (e.guaranteed and "!" or ""))
            cell.flashOn = isRare(r)
            cell.flash:SetVertexColor(W.GradeColor(r.grade))
            cell.flash:SetAlpha(0)
            cell:Show()
        else
            cell:Hide()
        end
    end
    -- summary
    local newCount, best = 0, nil
    for _, r in ipairs(res) do
        if r.isNew then newCount = newCount + 1 end
        if not best or r.grade > best.grade or (r.grade == best.grade and (r.tier or 0) > (best.tier or 0)) then best = r end
    end
    p.resTitle:SetText(string.format("소환 결과  |cffffffff%s회|r", U.Comma(#res)))
    local parts = {}
    if best then parts[#parts + 1] = "최고 " .. gradeHex(best.grade) .. resultGradeText(best) .. "|r" end
    if newCount > 0 then parts[#parts + 1] = string.format("|cff40ff40신규 %d|r", newCount) end
    if res.spent then
        if (res.spent.ticket or 0) > 0 then parts[#parts + 1] = "소환서 " .. U.Comma(res.spent.ticket) end
        if (res.spent.redDia or 0) > 0 then parts[#parts + 1] = "다이아 " .. U.Comma(res.spent.redDia) end
    end
    if grouped and #entries > CELLS then parts[#parts + 1] = string.format("외 %d종", #entries - CELLS) end
    p.resSummary:SetText(table.concat(parts, " · "))
    local n = math.min(#entries, CELLS)
    if animate and n > 0 then
        for i = 1, n do grid.cells[i]:SetAlpha(0) end
        grid.anim = { t = 0, n = n, step = math.min(0.08, REVEAL_TIME / n) }
        grid:SetScript("OnUpdate", animUpdate)
    else
        finishAnim(grid)
    end
end

---------------------------------------------------------------------------
-- actions
---------------------------------------------------------------------------
local function doPull(p, count)
    local hero = ns.Hero.Active()
    if not (hero and ns.Summon and count and count >= 1) then return end
    local res, err = call("pull", ns.Summon.Pull, hero, p.kind, count)
    if not res then
        if err then W.Toast(err, W.COLORS.red) end
        UI.RefreshPanel()
        return
    end
    p.results[p.kind] = res
    showResults(p, res, true)
    if (res.levelUps or 0) > 0 then
        local info = ns.Summon.Info(hero, p.kind)
        W.Toast(string.format("%s 레벨 상승! Lv.%d", KIND_NAMES[p.kind], info and info.level or 0), W.COLORS.green)
    end
    UI.RefreshPanel()
end

local function costText(hero, kind, n, info)
    local t, red, ok = ns.Summon.Cost(hero, kind, n)
    local parts = {}
    if (t or 0) > 0 then parts[#parts + 1] = (W.Money(info.ticketKey, t)) end
    if (red or 0) > 0 then parts[#parts + 1] = (W.Money("redDia", red)) end
    local s = table.concat(parts, " + ")
    if s == "" then s = "무료" end
    if not ok then s = "|cffff5050" .. s .. "|r" end
    return s
end

---------------------------------------------------------------------------
-- rates popup
---------------------------------------------------------------------------
local function refreshRates(p, info)
    local pop = p.ratesPop
    local key = p.kind .. ":" .. (info and info.level or 0)
    if pop.key == key then return end
    pop.key = key
    pop.title:SetText(string.format("%s 확률표  |cffffffffLv.%d|r", KIND_NAMES[p.kind], info and info.level or 0))
    pop.list:SetData(rateRows(p.kind, info and info.rates))
end

local function buildRatesPopup(p)
    local pop = W.Panel(p, 340, 232, 0.97)
    pop:SetPoint("TOPLEFT", GRID_X + 270, -4)
    pop:SetFrameLevel((p:GetFrameLevel() or 1) + 20)
    pop:EnableMouse(true)
    pop.title = W.Text(pop, 12, W.COLORS.gold, "LEFT")
    pop.title:SetPoint("TOPLEFT", 10, -8)
    pop.close = W.Button(pop, "닫기", 50, 18, function() pop:Hide() end)
    pop.close:SetPoint("TOPRIGHT", -6, -5)
    pop.list = W.ScrollList(pop, 326, 196, 16, function(parent)
        local r = CreateFrame("Frame", nil, parent)
        r:SetHeight(16)
        r.name = W.Text(r, 11, W.COLORS.white, "LEFT")
        r.name:SetPoint("LEFT", 2, 0)
        r.name:SetWidth(220)
        r.pct = W.Text(r, 11, W.COLORS.white, "RIGHT")
        r.pct:SetPoint("RIGHT", -2, 0)
        r.pct:SetWidth(80)
        return r
    end, function(r, e)
        local hexc = gradeHex(e.grade)
        r.name:SetText((e.header and hexc or "|cffcccccc") .. e.text .. "|r")
        r.pct:SetText((e.header and hexc or "|cffffffff") .. pctText(e.percent) .. "|r")
    end)
    pop.list:SetPoint("TOPLEFT", 8, -28)
    pop:Hide()
    p.ratesPop = pop
end

---------------------------------------------------------------------------
-- panel
---------------------------------------------------------------------------
UI.RegisterPanel("summon", {
    title = "소환", order = 30,
    build = function(p)
        p.kind = "weapon"
        p.results = {}

        -- kind tabs
        p.tabs = {}
        for i, kind in ipairs(KINDS) do
            local b = W.Button(p, KIND_NAMES[kind], 100, 22, function()
                p.kind = kind
                showResults(p, p.results[kind], false)
                if p.ratesPop:IsShown() then p.ratesPop.key = nil end
                UI.RefreshPanel()
            end)
            b:SetPoint("TOPLEFT", (i - 1) * 104, 0)
            p.tabs[kind] = b
        end

        p.title = W.Text(p, 14, W.COLORS.gold, "LEFT")
        p.title:SetPoint("TOPLEFT", 2, -32)

        p.ratesBtn = W.Button(p, "확률표", 70, 20, function()
            if p.ratesPop:IsShown() then p.ratesPop:Hide() else
                p.ratesPop.key = nil
                p.ratesPop:Show()
                UI.RefreshPanel()
            end
        end)
        p.ratesBtn:SetPoint("TOPLEFT", 248, -28)

        p.levelBar = W.Bar(p, 316, 14, 0.85, 0.6, 0.15)
        p.levelBar:SetPoint("TOPLEFT", 2, -54)
        p.levelBar:EnableMouse(true)
        W.Tooltip(p.levelBar, function(tt)
            local hero = ns.Hero.Active()
            local info = hero and ns.Summon and ns.Summon.Info(hero, p.kind)
            if not info then return end
            tt:AddLine(string.format("%s Lv.%d 확률", KIND_NAMES[p.kind], info.level), 1, 0.82, 0)
            for _, g in ipairs(gradeTotals(p.kind, info.rates)) do
                local name = p.kind == "weapon" and weaponGradeName(g.grade) or companionGradeName(g.grade)
                local r, gg, b = W.GradeColor(g.grade)
                tt:AddDoubleLine(name, pctText(g.percent), r, gg, b, 1, 1, 1)
            end
            if info.need then
                tt:AddLine(string.format("다음 레벨까지 %s회 소환", U.Comma(info.need - info.exp)), 0.7, 0.7, 0.7)
                local rew = ns.Summon.LevelReward and ns.Summon.LevelReward(p.kind == "pickup" and "companion" or p.kind, info.level + 1)
                if rew then tt:AddLine("레벨 보상 있음", 0.3, 1, 0.3) end
            end
            for _, g in ipairs(info.guarantees or {}) do
                tt:AddLine(string.format("확정 소환 Lv.%d: %s (%s회)", g.level, guaranteeLabel(p.kind, g), U.Comma(g.count)),
                    g.active and 1 or 0.6, g.active and 0.82 or 0.6, g.active and 0 or 0.6)
            end
            tt:AddLine("확률표 버튼으로 전체 목록을 볼 수 있습니다.", 0.6, 0.6, 0.6)
        end)

        p.pity = W.Text(p, 11, W.COLORS.white, "LEFT")
        p.pity:SetPoint("TOPLEFT", 2, -74)
        p.pity:SetWidth(320)
        p.pity:SetJustifyV("TOP")

        p.wallet = W.Text(p, 12, W.COLORS.white, "LEFT")
        p.wallet:SetPoint("TOPLEFT", 2, -108)
        p.wallet:SetWidth(320)

        p.info = W.Text(p, 11, W.COLORS.gray, "LEFT")
        p.info:SetPoint("TOPLEFT", 2, -126)
        p.info:SetWidth(320)

        p.pullBtns, p.costs = {}, {}
        for i = 1, 3 do
            local b = W.Button(p, "", 102, 26, function(self) doPull(p, self.count) end)
            b:SetPoint("TOPLEFT", 2 + (i - 1) * 108, -146)
            p.pullBtns[i] = b
            local c = W.Text(p, 11, W.COLORS.white, "CENTER")
            c:SetPoint("TOP", b, "BOTTOM", 0, -3)
            c:SetWidth(106)
            p.costs[i] = c
        end

        p.note = W.Text(p, 11, W.COLORS.gray, "LEFT")
        p.note:SetPoint("TOPLEFT", 2, -196)
        p.note:SetWidth(326)
        p.note:SetJustifyV("TOP")

        -- results
        p.resTitle = W.Text(p, 12, W.COLORS.gold, "LEFT")
        p.resTitle:SetPoint("TOPLEFT", GRID_X, -4)
        p.resSummary = W.Text(p, 11, W.COLORS.white, "LEFT")
        p.resSummary:SetPoint("LEFT", p.resTitle, "RIGHT", 10, 0)
        p.resSummary:SetWidth(380)
        p.skipBtn = W.Button(p, "모두 보기", 70, 18, function() finishAnim(p.grid) end)
        p.skipBtn:SetPoint("TOPRIGHT", -2, -1)

        local grid = CreateFrame("Frame", nil, p)
        grid:SetPoint("TOPLEFT", GRID_X, GRID_Y)
        grid:SetSize(COLS * CELL, ROWS * CELL)
        grid.cells = {}
        for i = 1, CELLS do
            local col, row = (i - 1) % COLS, math.floor((i - 1) / COLS)
            local cell = W.Icon(grid, ICON)
            cell:SetPoint("TOPLEFT", col * CELL + 3, -row * CELL - 3)
            cell.flash = cell:CreateTexture(nil, "OVERLAY")
            cell.flash:SetTexture("Interface\\Buttons\\CheckButtonHilight")
            cell.flash:SetBlendMode("ADD")
            cell.flash:SetAllPoints()
            cell.flash:SetAlpha(0)
            cell.new = W.Text(cell, 10, W.COLORS.green, "LEFT")
            cell.new:SetPoint("TOPLEFT", 1, -1)
            cell:SetScript("OnClick", function() finishAnim(grid) end)
            W.Tooltip(cell, cellTooltip)
            cell:Hide()
            grid.cells[i] = cell
        end
        p.grid = grid

        buildRatesPopup(p)
        showResults(p, nil, false)
    end,

    refresh = function(p, hero)
        if not ns.Summon then
            p.title:SetText("소환 시스템을 불러오지 못했습니다.")
            return
        end
        for kind, b in pairs(p.tabs) do
            if kind == p.kind then b:LockHighlight() else b:UnlockHighlight() end
        end
        local kind = p.kind
        local info = ns.Summon.Info(hero, kind)
        if not info then return end

        p.title:SetText(string.format("%s  |cffffffffLv.%d|r%s", KIND_NAMES[kind], info.level,
            info.level >= info.maxLevel and " |cff40ff40(최대)|r" or string.format(" |cff999999/ %d|r", info.maxLevel)))
        if info.need and info.level < info.maxLevel then
            p.levelBar:SetValue(math.min(1, info.exp / info.need))
            p.levelBar.text:SetText(string.format("%s / %s (%.1f%%)", U.Comma(info.exp), U.Comma(info.need), info.exp / info.need * 100))
        else
            p.levelBar:SetValue(1)
            p.levelBar.text:SetText("최대 레벨")
        end

        -- guaranteed summons (확정 소환)
        local lines = {}
        for _, g in ipairs(info.guarantees or {}) do
            local label = guaranteeLabel(kind, g)
            if g.active then
                lines[#lines + 1] = string.format("|cffffd100확정 소환|r %s%s|r  %s / %s", gradeHex(g.grade), label,
                    U.Comma(g.progress or 0), U.Comma(g.count))
            else
                lines[#lines + 1] = string.format("|cff808080확정 소환 %s: 소환 레벨 %d에서 진행 (%s / %s)|r", label, g.level,
                    U.Comma(g.progress or 0), U.Comma(g.count))
            end
        end
        if #lines == 0 then lines[1] = "|cff808080확정 소환 없음|r" end
        p.pity:SetText(table.concat(lines, "\n"))

        p.wallet:SetText(string.format("보유  %s   %s", (W.Money(info.ticketKey, info.tickets)), (W.Money("redDia", info.redDia))))
        p.info:SetText(string.format("누적 %s회 · 1회당 소환서 %d 또는 다이아 %d · 가능 %s회", U.Comma(info.total or 0),
            info.cost.ticket or 1, info.cost.redDia or 0, U.Comma(math.floor(info.affordable or 0))))

        -- pull buttons: 1 / 10 / max (weapon)
        local counts
        if kind == "weapon" then
            local maxN = info.maxBatch or 1
            local can = math.floor(info.affordable or 0)
            local third = (can > 10) and math.min(maxN, can) or maxN
            counts = { 1, 10, third }
        else
            counts = {}
            for i, n in ipairs(info.batchSizes or { 1, 10 }) do counts[i] = n end
        end
        for i, b in ipairs(p.pullBtns) do
            local n = counts[i]
            if n and info.unlocked then
                b.count = n
                b:SetText((i == 3 and kind == "weapon") and string.format("최대 x%s", U.Comma(n)) or ("x" .. n))
                b:SetEnabled((ns.Summon.CanPull(hero, kind, n)) and true or false)
                b:Show()
                p.costs[i]:SetText(costText(hero, kind, n, info))
                p.costs[i]:Show()
            else
                b.count = n
                b:Hide()
                p.costs[i]:Hide()
            end
        end

        local note = {}
        if kind == "pickup" then
            local targets = D.CompanionSummon and D.CompanionSummon.pickup and D.CompanionSummon.pickup.targets or {}
            local names = {}
            for _, key in ipairs(targets) do names[#names + 1] = jobDisplay(key) end
            if #names > 0 then note[#note + 1] = "|cffffd100픽업 대상|r " .. table.concat(names, ", ") end
            if not info.unlocked then
                note[#note + 1] = string.format("|cffff6060동료 소환 레벨 %d 달성 시 이용할 수 있습니다.|r", ns.Summon.PICKUP_MIN_LEVEL or 9)
            else
                note[#note + 1] = "소환 레벨은 동료 소환과 함께 오릅니다."
            end
        elseif kind == "weapon" then
            note[#note + 1] = string.format("한 번에 최대 %s회 · 소환서를 먼저 사용합니다.", U.Comma(info.maxBatch or 0))
        else
            if ns.Companions and ns.Companions.SubSlotsUnlocked then
                note[#note + 1] = string.format("서브 동료 칸 %d개 개방 (소환 레벨로 개방)", ns.Companions.SubSlotsUnlocked(hero))
            end
            note[#note + 1] = "소환서를 먼저 사용합니다."
        end
        p.note:SetText(table.concat(note, "\n"))

        if p.ratesPop:IsShown() then refreshRates(p, info) end
    end,
})
