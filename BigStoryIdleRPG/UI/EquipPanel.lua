-- 장비 패널: 15부위 장착 칸(인형 배치), 가방 목록(선택 / 자동 장착 / 등급 이하 일괄 분해), 장비 툴팁
-- (주/부 옵션, 스타포스, 잠재능력, 주문서, 마법 부여), 그리고 오른쪽 하위 탭:
--   정보(장착·해제·잠금·분해·부옵션 변환) / 스타포스(확률·비용·하락 방지·파괴 완화·복구) /
--   잠재능력(미라클·에디셔널 큐브) / 주문서(주문서 사용·이노센트·마법 부여·주머니) /
--   정예 소환(레벨·포인트·소환·단계 강화·레벨업 타이머·자동 설정).
local ADDON, ns = ...
local W = ns.W
local U = ns.U
local UI = ns.UI
local D = ns.Data

local BAG_X, BAG_W = 232, 254     -- bag grid column (5 icons per row)
local RX, RW = 498, 450           -- right column (views)
local VIEW_Y = -50
local BAG_COLS, BAG_CELL = 5, 46
local MAX_LINES = 11
local MAX_SUBS = 6

local DOLL = {
    { "Cap", "Shoulder", "EyeAccessory" },
    { "Clothes", "Cape", "EarAccessory" },
    { "Pants", "Belt", "Pendant" },
    { "Glove", "BrowAccessory", "Ring" },
    { "Shoes", "Pocket", "Ring2" },
}
local EMPTY_TEX = {
    Cap = "Head", Shoulder = "Shoulder", Clothes = "Chest", Pants = "Legs", Glove = "Hands", Cape = "Chest",
    Belt = "Waist", Shoes = "Feet", Ring = "Finger", Ring2 = "Finger", Pendant = "Neck", EarAccessory = "Trinket",
    EyeAccessory = "Trinket", BrowAccessory = "Head", Pocket = "Bag",
}
local ACCESSORY_ICON = {
    Ring = "INV_Jewelry_Ring_03", Ring2 = "INV_Jewelry_Ring_04", Pendant = "INV_Jewelry_Necklace_04",
    EarAccessory = "INV_Jewelry_Talisman_03", EyeAccessory = "INV_Misc_Spyglass_03",
    BrowAccessory = "INV_Jewelry_Talisman_04", Pocket = "INV_Misc_Bag_07",
}
local ARMOR_ICON = {
    Cap = "INV_Helmet_03", Shoulder = "INV_Shoulder_02", Clothes = "INV_Chest_Chain_05", Pants = "INV_Pants_03",
    Glove = "INV_Gauntlets_04", Cape = "INV_Misc_Cape_02", Belt = "INV_Belt_03", Shoes = "INV_Boots_05",
}
local VIEWS = {
    { key = "info", label = "정보" }, { key = "sf", label = "별빛 강화" }, { key = "pot", label = "잠재능력" },
    { key = "scroll", label = "주문서" }, { key = "elite", label = "정예 소환" },
}
local KIND_TITLE = { main = "주 옵션", sub = "부 옵션", fixed = "고정 옵션" }
local CUBE_KINDS = {
    { kind = "miracle", field = "potential", title = "잠재능력", cube = "cubeMiracle" },
    { kind = "additional", field = "additional", title = "추가 잠재능력", cube = "cubeAdditional" },
}

---------------------------------------------------------------------------
-- helpers
---------------------------------------------------------------------------
local function call(where, fn, ...)
    local ok, a, b, c = pcall(fn, ...)
    if not ok then
        if ns.Debug then ns.Debug("equip ui %s: %s", where, tostring(a)) end
        W.Toast(tostring(a), W.COLORS.red)
        return nil
    end
    return a, b, c
end

local function trimNum(x)
    local s = string.format("%.2f", x):gsub("0+$", ""):gsub("%.$", "")
    return s
end

local function rankOf(item)
    return ns.Equipment.GradeRank(item.grade)
end

local function gradeHexRank(rank) return W.Hex(W.GradeColor(rank)) end

local function lineText(stat, v)
    local E = ns.Equipment
    local sign = (v or 0) < 0 and "-" or "+"
    v = math.abs(v or 0)
    if E.IsPercentStat(stat) then return string.format("%s %s%s%%", E.StatName(stat), sign, trimNum(v / 10)) end
    return string.format("%s %s%s", E.StatName(stat), sign, U.Comma(v))
end

local function fmtStat(stat, raw)
    if ns.Upgrades and ns.Upgrades.FormatStat then return ns.Upgrades.FormatStat(stat, raw) end
    return lineText(stat, raw)
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
local function gearIcon(hero, item)
    if not item then return "Interface\\Icons\\INV_Misc_QuestionMark" end
    local class = ns.Skin and ns.Skin.JobClass and hero and ns.Skin.JobClass(hero.jobKey) or "?"
    local key = class .. "|" .. tostring(item.part) .. "|" .. tostring(item.grade)
    if iconCache[key] then return iconCache[key] end
    local tex
    local L = D.SkinLooks
    if L then
        local e
        if item.part == "Cape" then e = L.cape and L.cape[item.grade]
        elseif L.armor and L.armor[class] and L.armor[class][item.part] then e = L.armor[class][item.part][item.grade] end
        tex = itemIcon(e and e.id)
    end
    if not tex then
        return "Interface\\Icons\\" .. (ACCESSORY_ICON[item.part] or ARMOR_ICON[item.part] or "INV_Misc_QuestionMark")
    end
    iconCache[key] = tex
    return tex
end

local function emptyTex(part)
    return "Interface\\PaperDoll\\UI-PaperDoll-Slot-" .. (EMPTY_TEX[part] or "Chest")
end

-- equip-compare cache (invalidated when the hero changes)
local cmpCache = {}
if ns.On then
    ns.On("HERO_CHANGED", function() cmpCache = {} end, "EquipPanel")
    ns.On("EQUIPMENT_CHANGED", function() cmpCache = {} end, "EquipPanel")
end
local function powerDiff(hero, item)
    if not (hero and item) or ns.Equipment.IsEquipped(hero, item) then return nil end
    local c = cmpCache[item.id]
    if c == nil then
        local ok, _, new, old = pcall(ns.Equipment.IsUpgrade, hero, item)
        c = (ok and new and old) and (new - old) or false
        cmpCache[item.id] = c
    end
    return c or nil
end

---------------------------------------------------------------------------
-- tooltip
---------------------------------------------------------------------------
local function itemTooltip(tt, item, hero)
    local E = ns.Equipment
    if not item then return end
    local rank = rankOf(item)
    local star = item.star or 0
    tt:AddLine(E.ItemName(item) .. (star > 0 and ("  ★" .. star) or ""), W.GradeColor(rank))
    tt:AddLine(string.format("%s · %s %s · 아이템 레벨 %d", E.PartName(item.part), E.GradeName(item.grade),
        E.TierName(item.tier), item.level or 1), 0.8, 0.8, 0.8)
    if hero and E.IsEquipped(hero, item) then tt:AddLine("장착 중", 1, 0.82, 0) end
    if item.locked then tt:AddLine("잠김 (분해되지 않음)", 1, 0.5, 0.5) end
    local SF = ns.StarForce
    if SF and SF.IsDestroyed and SF.IsDestroyed(item) then
        tt:AddLine(string.format("파괴됨 (%d성) - 복구 필요", item.sfDestroyed or 0), 1, 0.3, 0.3)
    end
    local last
    for _, l in ipairs(E.Lines(item)) do
        if l.kind ~= last then
            tt:AddLine(KIND_TITLE[l.kind] or l.kind, 1, 0.82, 0)
            last = l.kind
        end
        local conv = (l.kind == "sub" and item.convertSlot == l.index) and " |cff66ccff(변환)|r" or ""
        local r, g, b = 1, 1, 1
        if l.kind == "sub" then r, g, b = 0.6, 0.9, 1 elseif l.kind == "fixed" then r, g, b = 0.9, 0.7, 1 end
        tt:AddLine("  " .. lineText(l.stat, l.value) .. conv, r, g, b)
    end
    if SF and SF.ItemStats and star > 0 then
        local ok, list = pcall(SF.ItemStats, item)
        if ok and list and #list > 0 then
            local parts = {}
            for i, s in ipairs(list) do
                if i > 4 then parts[#parts + 1] = "..." break end
                parts[#parts + 1] = fmtStat(s[1], s[2])
            end
            tt:AddLine("별빛 강화: " .. table.concat(parts, ", "), 1, 0.82, 0.3, true)
        end
    end
    local P = ns.Potential
    for _, ck in ipairs(CUBE_KINDS) do
        local st = item[ck.field]
        if st and st.lines and #st.lines > 0 then
            local gname = P and P.GradeName(st.grade) or tostring(st.grade)
            tt:AddLine(string.format("%s (%s)", ck.title, gname), W.GradeColor(st.grade))
            for _, l in ipairs(st.lines) do
                tt:AddLine("  " .. (P and P.FormatLine(l) or fmtStat(l[1], l[2])), 0.9, 0.9, 0.9)
            end
        end
    end
    local sd = item.scroll
    if sd and sd.slots and #sd.slots > 0 then
        local okN = 0
        for _, s in ipairs(sd.slots) do if s.ok then okN = okN + 1 end end
        tt:AddLine(string.format("주문서 강화 %d / %d (성공 %d)", #sd.slots, D.Scrolls and D.Scrolls.slots or 10, okN), 0.5, 0.8, 1)
    end
    if sd and sd.enchant then
        for line, e in pairs(sd.enchant) do
            if e.stat then tt:AddLine(string.format("마법 부여 [부옵션 %d]: %s", line, fmtStat(e.stat, e.value or 0)), 0.75, 0.5, 1) end
        end
    end
    local diff = powerDiff(hero, item)
    if diff then
        tt:AddLine(string.format("장착 시 전투력 %s%s", diff >= 0 and "+" or "", U.FormatNumber(diff)),
            diff >= 0 and 0.3 or 1, diff >= 0 and 1 or 0.3, 0.3)
    end
    tt:AddLine(string.format("분해 시 %s", (W.Money("gearStone", E.DismantleValue(item)))), 0.6, 0.6, 0.6)
end

---------------------------------------------------------------------------
-- selection
---------------------------------------------------------------------------
local function selectedItem(p, hero)
    local E = ns.Equipment
    local item = p.selectedId and E.Get(hero, p.selectedId)
    if item then return item end
    p.selectedId = nil
    for _, part in ipairs(E.PARTS) do
        local it = E.Equipped(hero, part)
        if it then p.selectedId = it.id return it end
    end
    local all = E.Items(hero)
    if all[1] then p.selectedId = all[1].id return all[1] end
    return nil
end

local function refreshNow() UI.RefreshPanel() end

---------------------------------------------------------------------------
-- actions
---------------------------------------------------------------------------
local function withItem(p, fn)
    local hero = ns.Hero.Active()
    local item = hero and p.selectedId and ns.Equipment.Get(hero, p.selectedId)
    if not item then W.Toast("장비를 선택하세요.", W.COLORS.red) return end
    fn(hero, item)
    refreshNow()
end

local function equipToggle(p)
    withItem(p, function(hero, item)
        local E = ns.Equipment
        if E.IsEquipped(hero, item) then
            call("unequip", E.Unequip, hero, item.part)
        else
            local ok, err = call("equip", E.Equip, hero, item.id)
            if not ok and err then W.Toast(err, W.COLORS.red) end
        end
    end)
end

local function lockToggle(p)
    withItem(p, function(hero, item)
        call("lock", ns.Equipment.SetLocked, hero, item.id, not item.locked)
        W.Toast(item.locked and "잠금했습니다." or "잠금을 풀었습니다.")
    end)
end

local function dismantleOne(p)
    withItem(p, function(hero, item)
        local E = ns.Equipment
        if E.IsEquipped(hero, item) then W.Toast("장착 중인 장비는 분해할 수 없습니다.", W.COLORS.red) return end
        if item.locked then W.Toast("잠긴 장비입니다.", W.COLORS.red) return end
        W.Confirm(string.format("%s을(를) 분해할까요?", E.ItemName(item)), function()
            local stones, n = call("dismantle", E.Dismantle, hero, { item.id })
            if n and n > 0 then
                W.Toast(string.format("분해: %s %s 획득", D.CurrencyName("gearStone"), U.Comma(stones or 0)), W.COLORS.green)
                p.selectedId = nil
            end
            refreshNow()
        end)
    end)
end

local function autoEquip(p)
    local hero = ns.Hero.Active()
    if not hero then return end
    local n = call("autoEquip", ns.Equipment.AutoEquip, hero)
    if n and n > 0 then W.Toast(string.format("%d부위 장비를 교체했습니다.", n), W.COLORS.green)
    elseif n then W.Toast("더 좋은 장비가 없습니다.") end
    refreshNow()
end

local function dismantleBelow(p)
    local hero = ns.Hero.Active()
    if not hero then return end
    local E = ns.Equipment
    local order = D.EquipLabels and D.EquipLabels.gradeOrder or {}
    local name = E.GradeName(order[p.dismRank] or "")
    W.Confirm(string.format("%s 이하 장비를 모두 분해할까요?\n(장착·잠금·변환·마법 부여 장비 제외)", name), function()
        local stones, n = call("dismantleBelow", E.DismantleBelow, hero, p.dismRank)
        if n and n > 0 then
            W.Toast(string.format("%d개 분해: %s %s 획득", n, D.CurrencyName("gearStone"), U.Comma(stones or 0)), W.COLORS.green)
        elseif n then
            W.Toast("분해할 장비가 없습니다.")
        end
        refreshNow()
    end)
end

local function convertSub(p, line)
    withItem(p, function(hero, item)
        local ok, err = call("convert", ns.Equipment.ConvertSubOption, hero, item.id, line)
        if ok then W.Toast("부옵션을 변환했습니다.", W.COLORS.green) elseif err then W.Toast(err, W.COLORS.red) end
    end)
end

local function starforce(p)
    withItem(p, function(hero, item)
        local SF = ns.StarForce
        if not SF then return end
        local opts = { preventDown = p.sfPreventDown, preventDestroy = p.sfPreventDestroy }
        local from = item.star or 0
        local res, err = call("starforce", SF.Enhance, hero, item, opts)
        if not res then
            if err then W.Toast(err, W.COLORS.red) end
            return
        end
        local text = ({ success = "|cff40ff40성공!|r", fail = "|cffffd100실패 (유지)|r", down = "|cffff8040실패 (하락)|r",
            destroy = "|cffff3030파괴...|r" })[res] or res
        p.sfLast = string.format("%d성 → %d성: %s", from, item.star or 0, text)
        W.Toast(p.sfLast, res == "success" and W.COLORS.green or W.COLORS.red)
    end)
end

local function restore(p)
    withItem(p, function(hero, item)
        local SF = ns.StarForce
        local targets = SF and SF.RestoreTargets(item) or {}
        local to = targets[p.restoreIdx or #targets] or targets[#targets]
        if not to then W.Toast("복구할 수 없습니다.", W.COLORS.red) return end
        local ok, err = call("restore", SF.Restore, hero, item, to)
        if ok then W.Toast(string.format("%d성으로 복구했습니다.", to), W.COLORS.green) elseif err then W.Toast(err, W.COLORS.red) end
    end)
end

local function useCube(p, kind)
    withItem(p, function(hero, item)
        local P = ns.Potential
        if not P then return end
        local ok, res = call("cube", P.UseCube, hero, item, kind)
        if ok then
            p.cubeLast = p.cubeLast or {}
            p.cubeLast[kind] = res and "|cff40ff40등급 상승!|r" or "재설정 완료"
            if res then W.Toast("잠재능력 등급 상승!", W.COLORS.green) end
        elseif res then
            W.Toast(res, W.COLORS.red)
        end
    end)
end

local function useScroll(p, key)
    withItem(p, function(hero, item)
        local S = ns.Scrolls
        local res, err = call("scroll", S.Use, hero, item, key)
        if res == nil then
            if err then W.Toast(err, W.COLORS.red) end
        else
            local s = S.Get(key)
            W.Toast(string.format("%s: %s", s and s.name or key, res and "성공!" or "실패"), res and W.COLORS.green or W.COLORS.red)
        end
    end)
end

local function innocent(p)
    withItem(p, function(hero, item)
        W.Confirm("이노센트 주문서로 주문서 강화를 모두 초기화할까요?", function()
            local ok, err = call("innocent", ns.Scrolls.Reset, hero, item)
            if ok then W.Toast("주문서 강화를 초기화했습니다.", W.COLORS.green) elseif err then W.Toast(err, W.COLORS.red) end
            refreshNow()
        end)
    end)
end

local function bestEnchant(hero, item, line)
    local S = ns.Scrolls
    local ids = S.EnchantOptions(hero, item, line) or {}
    local best, bestG
    for _, id in ipairs(ids) do
        local e = S.Enchant(id)
        local g = e and e.grade or 0
        if not bestG or g > bestG then best, bestG = id, g end
    end
    return best
end

local function enchant(p, line)
    withItem(p, function(hero, item)
        local S = ns.Scrolls
        local id = bestEnchant(hero, item, line)
        if not id then W.Toast("이 부옵션에 쓸 마법 부여 주문서가 없습니다.", W.COLORS.red) return end
        local res, err = call("enchant", S.ApplyEnchant, hero, item, line, id)
        if res == nil then
            if err then W.Toast(err, W.COLORS.red) end
        else
            W.Toast(string.format("%s: %s", S.EnchantName(id), res and "성공!" or "실패"), res and W.COLORS.green or W.COLORS.red)
        end
    end)
end

local function openPouch(p, key)
    local hero = ns.Hero.Active()
    if not (hero and ns.Scrolls) then return end
    local got, err = call("pouch", ns.Scrolls.OpenPouch, hero, key, 1)
    if got then
        local names = {}
        for _, id in ipairs(got) do names[#names + 1] = ns.Scrolls.EnchantName(id) end
        W.Toast("획득: " .. table.concat(names, ", "), W.COLORS.green)
    elseif err then
        W.Toast(err, W.COLORS.red)
    end
    refreshNow()
end

local function eliteSummon(p, all)
    local hero = ns.Hero.Active()
    local E = ns.Equipment
    if not hero then return end
    local info = E.EliteInfo(hero)
    local n = 1
    if all then n = math.max(1, math.min(30, math.floor((info.points or 0) / math.max(1, info.cost or 1)))) end
    local ok, err = E.CanEliteSummon(hero)
    if not ok then W.Toast(err or "소환할 수 없습니다.", W.COLORS.red) refreshNow() return end
    -- bulk: run auto-equip once at the end instead of after every encounter
    local settings = hero.equipment and hero.equipment.settings
    local deferAuto = all and n > 1 and settings and settings.autoEquip
    if deferAuto then settings.autoEquip = false end
    local items, count = call("eliteSummon", E.EliteSummonInstant, hero, n)
    if deferAuto then
        settings.autoEquip = true
        call("eliteAutoEquip", E.AutoEquip, hero)
    end
    if count and count > 0 then
        p.eliteLoot = items or {}
        W.Toast(string.format("정예 몬스터 %d마리 처치 · 장비 %d개 획득", count, #(items or {})), W.COLORS.green)
    end
    refreshNow()
end

local function eliteStep(p)
    local hero = ns.Hero.Active()
    if not hero then return end
    local ok, err = call("eliteStep", ns.Equipment.EliteStep, hero)
    if ok then W.Toast("정예 소환 단계를 강화했습니다.", W.COLORS.green) elseif err then W.Toast(err, W.COLORS.red) end
    refreshNow()
end

local function eliteLevelUp(p)
    local hero = ns.Hero.Active()
    if not hero then return end
    local ok, err = call("eliteLevelUp", ns.Equipment.EliteStartLevelUp, hero)
    if ok then W.Toast("정예 소환 레벨업을 시작했습니다.", W.COLORS.green) elseif err then W.Toast(err, W.COLORS.red) end
    refreshNow()
end

local function eliteSkip(p)
    local hero = ns.Hero.Active()
    if not hero then return end
    local used = call("eliteSkip", ns.Equipment.EliteSkipTime, hero)
    if used and used > 0 then W.Toast(string.format("%s %d개 사용", D.CurrencyName("timeSkip1m"), used), W.COLORS.green)
    elseif used then W.Toast(D.CurrencyName("timeSkip1m") .. "이(가) 없거나 진행 중인 레벨업이 없습니다.", W.COLORS.red) end
    refreshNow()
end

---------------------------------------------------------------------------
-- build: paper doll
---------------------------------------------------------------------------
local DOLL_POS = {
    Cap = { 1, 1 }, Clothes = { 1, 2 }, Pants = { 1, 3 }, Glove = { 1, 4 }, Shoes = { 1, 5 },
    EyeAccessory = { 3, 1 }, EarAccessory = { 3, 2 }, Pendant = { 3, 3 }, Ring = { 3, 4 }, Ring2 = { 3, 5 },
    Shoulder = { 2, 6, 1 }, Cape = { 2, 6, 2 }, Belt = { 2, 6, 3 }, BrowAccessory = { 2, 6, 4 }, Pocket = { 2, 6, 5 },
}

local function buildDoll(p)
    local box = W.InfoCard(p, 226, 406, { plain = true })
    box:SetPoint("TOPLEFT", 0, 0)
    p.dollBox = box
    local m = CreateFrame("DressUpModel", nil, box)
    m:SetPoint("TOPLEFT", 58, -20)
    m:SetSize(110, 250)
    p.model = m
    if ns.BattleView then
        ns.BattleView.extraModels = ns.BattleView.extraModels or {}
        table.insert(ns.BattleView.extraModels, m)
    end
    p.slots = {}
    for _, parts in ipairs(DOLL) do
        for _, part in ipairs(parts) do
            local pos = DOLL_POS[part]
            local s = W.Icon(box, 40)
            if pos[2] <= 5 then
                s:SetPoint("TOPLEFT", pos[1] == 1 and 12 or 174, -14 - (pos[2] - 1) * 54)
            else
                s:SetPoint("TOPLEFT", 12 + (pos[3] - 1) * 41, -300)
                s:SetSize(36, 36)
            end
            s.part = part
            s.label = W.Text(s, 9, W.COLORS.gray, "CENTER")
            s.label:SetPoint("TOP", s, "BOTTOM", 0, -1)
            s.label:SetText(ns.Equipment.PartName(part))
            s.sel = s:CreateTexture(nil, "OVERLAY", nil, 3)
            s.sel:SetTexture("Interface\\Buttons\\CheckButtonHilight")
            s.sel:SetBlendMode("ADD")
            s.sel:SetAllPoints()
            s.sel:Hide()
            s:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
            s:SetScript("OnClick", function(self)
                local hero = ns.Hero.Active()
                if not hero then return end
                local it = ns.Equipment.Equipped(hero, self.part)
                if it then p.selectedId = it.id end
                p.filter = self.part
                refreshNow()
            end)
            W.Tooltip(s, function(tt, self)
                local hero = ns.Hero.Active()
                local it = hero and ns.Equipment.Equipped(hero, self.part)
                if it then itemTooltip(tt, it, hero)
                else
                    tt:AddLine(ns.Equipment.PartName(self.part), 1, 0.82, 0)
                    tt:AddLine("비어 있음 · 클릭하면 이 부위 장비만 보여줍니다.", 0.7, 0.7, 0.7)
                end
            end)
            p.slots[part] = s
        end
    end
    p.autoBtn = W.Button(box, "자동 장착", 200, 26, function() autoEquip(p) end, "green")
    p.autoBtn:SetPoint("BOTTOM", 0, 12)
end

---------------------------------------------------------------------------
-- build: bag
---------------------------------------------------------------------------
local function buildBag(p)
    local box = CreateFrame("Frame", nil, p, BackdropTemplateMixin and "BackdropTemplate" or nil)
    box:SetPoint("TOPLEFT", BAG_X - 4, 0)
    box:SetSize(BAG_W + 8, 406)
    W.Backdrop(box, { 0.05, 0.05, 0.06, 0.9 }, { 0.3, 0.3, 0.32, 1 }, 10)
    if W.ArtInfo("box_dark") then W.Slice(box, "box_dark", 0.7) end
    p.bagBox = box
    local title = W.Text(box, 13, W.COLORS.white, "LEFT")
    title:SetPoint("TOPLEFT", 8, -8)
    title:SetText("장비 관리")
    p.bagCount = W.Text(box, 12, W.COLORS.white, "RIGHT")
    p.bagCount:SetPoint("TOPRIGHT", -10, -8)
    p.bagCount:SetWidth(120)
    p.filterBtn = W.Button(p, "전체", 74, 22, function()
        if p.filter then p.filter = nil else
            local hero = ns.Hero.Active()
            local it = hero and selectedItem(p, hero)
            p.filter = it and it.part or nil
        end
        refreshNow()
    end, "cyan")
    p.filterBtn:SetPoint("TOPLEFT", BAG_X + 2, -28)
    p.rankBtn = W.Button(p, "", 96, 22, function()
        local n = D.EquipLabels and #D.EquipLabels.gradeOrder or 8
        p.dismRank = (p.dismRank % (n - 1)) + 1
        refreshNow()
    end, "gray")
    p.rankBtn:SetPoint("LEFT", p.filterBtn, "RIGHT", 4, 0)
    W.Tooltip(p.rankBtn, function(tt)
        tt:AddLine("일괄 분해 기준 등급", 1, 0.82, 0)
        tt:AddLine("클릭할 때마다 기준 등급이 바뀝니다.", 1, 1, 1)
    end)
    p.dismBtn = W.Button(p, "분해", 64, 22, function() dismantleBelow(p) end, "cyan")
    p.dismBtn:SetPoint("LEFT", p.rankBtn, "RIGHT", 4, 0)

    p.bag = W.ScrollList(p, BAG_W, 346, BAG_CELL, function(parent)
        local r = CreateFrame("Frame", nil, parent)
        r:SetHeight(BAG_CELL)
        r.cells = {}
        for i = 1, BAG_COLS do
            local c = W.Icon(r, 42)
            c:SetPoint("TOPLEFT", (i - 1) * BAG_CELL, -2)
            c.sel = c:CreateTexture(nil, "OVERLAY", nil, 3)
            c.sel:SetTexture("Interface\\Buttons\\CheckButtonHilight")
            c.sel:SetBlendMode("ADD")
            c.sel:SetAllPoints()
            c.sel:Hide()
            c.count:SetFont(c.count:GetFont() or "Fonts\\2002.TTF", 10, "OUTLINE")
            c.mark = W.Text(c, 10, W.COLORS.gold, "LEFT")
            c.mark:SetPoint("TOPLEFT", 4, -3)
            c.mark:SetDrawLayer("OVERLAY", 4)
            c:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
            c:SetScript("OnClick", function(self)
                if self.item then p.selectedId = self.item.id; if p.view == "elite" then p.view = "info" end end
                refreshNow()
            end)
            W.Tooltip(c, function(tt, self) if self.item then itemTooltip(tt, self.item, ns.Hero.Active()) end end)
            r.cells[i] = c
        end
        return r
    end, function(r, row)
        local hero = ns.Hero.Active()
        for i, c in ipairs(r.cells) do
            local e = row[i]
            c.item = e and e.item
            if e then
                local item = e.item
                c:Show()
                c.icon:SetTexture(gearIcon(hero, item))
                W.SetBorderGrade(c, rankOf(item))
                c.count:SetText((item.star or 0) > 0 and ("★" .. item.star) or ("Lv." .. (item.level or 1)))
                c.mark:SetText((e.equipped and "|cff9be05aE|r" or "") .. (item.locked and "|cffff6060L|r" or ""))
                c.sel:SetShown(item.id == p.selectedId)
            else
                c:Hide()
            end
        end
    end)
    p.bag:SetPoint("TOPLEFT", BAG_X + 2, -56)
end

---------------------------------------------------------------------------
-- build: views
---------------------------------------------------------------------------
local function viewFrame(p)
    local v = CreateFrame("Frame", nil, p)
    v:SetPoint("TOPLEFT", RX, VIEW_Y)
    v:SetSize(RW, 218)
    v:Hide()
    return v
end

local function buildInfo(p)
    local v = viewFrame(p)
    v.icon = W.Icon(v, 36)
    v.icon:SetPoint("TOPLEFT", 0, 0)
    W.Tooltip(v.icon, function(tt)
        local hero = ns.Hero.Active()
        itemTooltip(tt, hero and selectedItem(p, hero), hero)
    end)
    v.name = W.Text(v, 13, W.COLORS.gold, "LEFT")
    v.name:SetPoint("TOPLEFT", v.icon, "TOPRIGHT", 6, -1)
    v.name:SetWidth(250)
    v.sub = W.Text(v, 10, W.COLORS.gray, "LEFT")
    v.sub:SetPoint("TOPLEFT", v.name, "BOTTOMLEFT", 0, -3)
    v.sub:SetWidth(250)
    v.disBtn = W.Button(v, "분해", 54, 20, function() dismantleOne(p) end)
    v.disBtn:SetPoint("TOPRIGHT", -2, 0)
    v.lockBtn = W.Button(v, "잠금", 54, 20, function() lockToggle(p) end)
    v.lockBtn:SetPoint("RIGHT", v.disBtn, "LEFT", -3, 0)
    v.eqBtn = W.Button(v, "장착", 60, 20, function() equipToggle(p) end)
    v.eqBtn:SetPoint("RIGHT", v.lockBtn, "LEFT", -3, 0)
    v.power = W.Text(v, 10, W.COLORS.white, "RIGHT")
    v.power:SetPoint("TOPRIGHT", -2, -24)
    v.power:SetWidth(180)

    v.lines, v.convBtns = {}, {}
    for i = 1, MAX_LINES do
        local t = W.Text(v, 11, W.COLORS.white, "LEFT")
        t:SetPoint("TOPLEFT", 4, -40 - (i - 1) * 13)
        t:SetWidth(360)
        v.lines[i] = t
    end
    for i = 1, MAX_SUBS do
        local b = W.Button(v, "변환", 46, 14, function(self) convertSub(p, self.line) end)
        b.line = i
        b:Hide()
        v.convBtns[i] = b
    end
    v.foot = W.Text(v, 10, W.COLORS.gray, "LEFT")
    v.foot:SetPoint("TOPLEFT", 0, -188)
    v.foot:SetWidth(RW)
    v.foot:SetJustifyV("TOP")
    return v
end

local function refreshInfo(p, v, hero, item)
    local E = ns.Equipment
    local rank = rankOf(item)
    v.icon.icon:SetTexture(gearIcon(hero, item))
    W.SetBorderGrade(v.icon, rank)
    v.icon.count:SetText((item.star or 0) > 0 and ("★" .. item.star) or "")
    v.name:SetText(gradeHexRank(rank) .. E.ItemName(item) .. "|r")
    local equipped = E.IsEquipped(hero, item)
    v.sub:SetText(string.format("%s · %s %s · Lv.%d%s%s", E.PartName(item.part), E.GradeName(item.grade), E.TierName(item.tier),
        item.level or 1, equipped and " · |cffffd100장착 중|r" or "", item.locked and " · |cffff6060잠김|r" or ""))
    v.eqBtn:SetText(equipped and "해제" or "장착")
    v.lockBtn:SetText(item.locked and "잠금 해제" or "잠금")
    v.lockBtn:SetWidth(item.locked and 70 or 54)
    v.disBtn:SetEnabled(not equipped and not item.locked)
    local diff = powerDiff(hero, item)
    if diff then
        v.power:SetText(string.format("장착 시 전투력 %s%s|r", diff >= 0 and "|cff40ff40+" or "|cffff5050", U.FormatNumber(diff)))
    else
        v.power:SetText("")
    end

    local lines = E.Lines(item)
    local i = 0
    for _, b in ipairs(v.convBtns) do b:Hide() end
    local lastKind
    for _, l in ipairs(lines) do
        if i >= MAX_LINES then break end
        i = i + 1
        local head = ""
        if l.kind ~= lastKind then head = "|cffffd100" .. (KIND_TITLE[l.kind] or "") .. "|r  " lastKind = l.kind end
        local color = l.kind == "main" and "|cffffffff" or (l.kind == "sub" and "|cff99e6ff" or "|cffe6b3ff")
        local conv = (l.kind == "sub" and item.convertSlot == l.index) and "  |cff66ccff(변환)|r" or ""
        v.lines[i]:SetText(head .. color .. lineText(l.stat, l.value) .. "|r" .. conv)
        if l.kind == "sub" and v.convBtns[l.index] then
            local b = v.convBtns[l.index]
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", 400, -39 - (i - 1) * 13)
            b:SetEnabled(not item.convertSlot or item.convertSlot == l.index)
            b:Show()
        end
    end
    for j = i + 1, MAX_LINES do v.lines[j]:SetText("") end
    if i == 0 then v.lines[1]:SetText("|cff808080옵션 정보가 없습니다.|r") end

    -- footer: conversion cost + upgrade summary
    local foot = {}
    local stones, meso = E.ConversionCost(item)
    if stones then
        foot[#foot + 1] = string.format("부옵션 변환 %d회차: %s", (item.convertCount or 0) + 1,
            costText({ subOptionStone = stones, meso = meso }, hero))
    else
        foot[#foot + 1] = "|cff808080부옵션 변환: " .. tostring(meso or "불가") .. "|r"
    end
    local P = ns.Potential
    local pot = item.potential and item.potential.lines and #item.potential.lines > 0 and P and P.GradeName(item.potential.grade) or "없음"
    local add = item.additional and item.additional.lines and #item.additional.lines > 0 and P and P.GradeName(item.additional.grade) or "없음"
    local nScroll = item.scroll and item.scroll.slots and #item.scroll.slots or 0
    foot[#foot + 1] = string.format("잠재 %s · 추가 %s · 주문서 %d/%d · 분해 시 %s", pot, add, nScroll,
        D.Scrolls and D.Scrolls.slots or 10, (W.Money("gearStone", E.DismantleValue(item))))
    v.foot:SetText(table.concat(foot, "\n"))
end

local function buildStarForce(p)
    local v = viewFrame(p)
    v.title = W.Text(v, 14, W.COLORS.gold, "LEFT")
    v.title:SetPoint("TOPLEFT", 0, 0)
    v.title:SetWidth(RW)
    v.chance = W.Text(v, 12, W.COLORS.white, "LEFT")
    v.chance:SetPoint("TOPLEFT", 0, -24)
    v.chance:SetWidth(200)
    v.chance:SetJustifyV("TOP")
    v.pointLabel = W.Text(v, 11, W.COLORS.white, "LEFT")
    v.pointLabel:SetPoint("TOPLEFT", 210, -24)
    v.pointLabel:SetWidth(240)
    v.points = W.Bar(v, 250, 12, 0.9, 0.7, 0.2)
    v.points:SetPoint("TOPLEFT", 210, -42)
    v.special = W.Text(v, 11, W.COLORS.green, "LEFT")
    v.special:SetPoint("TOPLEFT", 210, -60)
    v.special:SetWidth(240)
    v.special:SetJustifyV("TOP")

    local function check(x, label, field)
        local cb = CreateFrame("CheckButton", nil, v, "UICheckButtonTemplate")
        cb:SetSize(22, 22)
        cb:SetPoint("TOPLEFT", x, -104)
        local t = W.Text(v, 11, W.COLORS.white, "LEFT")
        t:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        t:SetText(label)
        cb:SetScript("OnClick", function(self)
            p[field] = self:GetChecked() and true or false
            refreshNow()
        end)
        cb.label = t
        return cb
    end
    v.pdCheck = check(0, "하락 방지", "sfPreventDown")
    v.pxCheck = check(120, "파괴 완화", "sfPreventDestroy")

    v.cost = W.Text(v, 11, W.COLORS.white, "LEFT")
    v.cost:SetPoint("TOPLEFT", 0, -132)
    v.cost:SetWidth(RW)
    v.btn = W.Button(v, "강화", 110, 24, function() starforce(p) end)
    v.btn:SetPoint("TOPLEFT", 0, -150)
    v.last = W.Text(v, 12, W.COLORS.white, "LEFT")
    v.last:SetPoint("LEFT", v.btn, "RIGHT", 10, 0)
    v.last:SetWidth(320)

    v.restoreText = W.Text(v, 11, W.COLORS.red, "LEFT")
    v.restoreText:SetPoint("TOPLEFT", 0, -182)
    v.restoreText:SetWidth(RW)
    v.targetBtn = W.Button(v, "", 70, 20, function()
        local hero = ns.Hero.Active()
        local item = hero and selectedItem(p, hero)
        local targets = (item and ns.StarForce) and ns.StarForce.RestoreTargets(item) or {}
        if #targets > 0 then p.restoreIdx = ((p.restoreIdx or #targets) % #targets) + 1 end
        refreshNow()
    end)
    v.targetBtn:SetPoint("TOPLEFT", 0, -198)
    v.restoreBtn = W.Button(v, "복구", 70, 20, function() restore(p) end)
    v.restoreBtn:SetPoint("LEFT", v.targetBtn, "RIGHT", 4, 0)
    v.restoreCost = W.Text(v, 11, W.COLORS.white, "LEFT")
    v.restoreCost:SetPoint("LEFT", v.restoreBtn, "RIGHT", 8, 0)
    v.restoreCost:SetWidth(280)
    return v
end

local function pctM(x) return string.format("%.2f%%", (x or 0) / 10000) end

local function refreshStarForce(p, v, hero, item)
    local SF = ns.StarForce
    if not SF then v.title:SetText("별빛 강화 시스템이 없습니다.") return end
    local star = item.star or 0
    local destroyed = SF.IsDestroyed(item)
    local row = SF.Row(star)
    local opts = { preventDown = p.sfPreventDown, preventDestroy = p.sfPreventDestroy }
    v.pdCheck:SetChecked(p.sfPreventDown and true or false)
    v.pxCheck:SetChecked(p.sfPreventDestroy and true or false)
    v.last:SetText(p.sfLast or "")
    if not row then
        v.title:SetText(string.format("|cffffd100★ %d|r  최대 별빛 강화", star))
        v.chance:SetText("")
        v.pointLabel:SetText("")
        v.points:Hide()
        v.special:SetText("")
        v.cost:SetText("")
        v.btn:SetEnabled(false)
    else
        v.title:SetText(string.format("|cffffd100★ %d → ★ %d|r   |cff999999%s|r", star, star + 1, ns.Equipment.ItemName(item)))
        local ch, guaranteed, reason = SF.Chances(item, opts)
        ch = ch or { success = 0, fail = 0, down = 0, destroy = 0 }
        v.chance:SetText(string.format("|cff40ff40성공 %s|r\n|cffffd100실패(유지) %s|r\n|cffff8040하락 %s|r\n|cffff3030파괴 %s|r",
            pctM(ch.success), pctM(ch.fail), pctM(ch.down), pctM(ch.destroy)))
        local pts, maxP = SF.Points(item), SF.MaxPoints(item)
        if maxP and maxP > 0 then
            v.points:Show()
            v.points:SetValue(math.min(1, pts / maxP))
            v.points.text:SetText(string.format("%d / %d", pts, maxP))
            v.pointLabel:SetText("강화 포인트 (가득 차면 다음 강화 100%)")
        else
            v.points:Hide()
            v.pointLabel:SetText("|cff808080이 단계는 강화 포인트가 없습니다.|r")
        end
        local sp = {}
        if guaranteed then sp[#sp + 1] = reason == "chance" and "찬스타임! 다음 강화 성공 확정" or "포인트 확정! 다음 강화 성공" end
        if (item.sfDowns or 0) > 0 then sp[#sp + 1] = string.format("|cffff8040연속 하락 %d회|r", item.sfDowns) end
        if star < (SF.POTENTIAL_STAR or 3) then sp[#sp + 1] = string.format("|cff999999%d성에서 잠재능력 개방|r", SF.POTENTIAL_STAR or 3)
        elseif star < (SF.ADDITIONAL_STAR or 12) then sp[#sp + 1] = string.format("|cff999999%d성에서 추가 개방|r", SF.ADDITIONAL_STAR or 12) end
        v.special:SetText(table.concat(sp, "\n"))
        local canPD = (row.pdScroll or 0) > 0
        local canPX = (row.pxScroll or 0) > 0
        v.pdCheck:SetEnabled(canPD)
        v.pxCheck:SetEnabled(canPX)
        v.pdCheck.label:SetTextColor(canPD and 1 or 0.5, canPD and 1 or 0.5, canPD and 1 or 0.5)
        v.pxCheck.label:SetTextColor(canPX and 1 or 0.5, canPX and 1 or 0.5, canPX and 1 or 0.5)
        local cost = SF.Cost(item, opts)
        v.cost:SetText("비용  " .. costText(cost, hero))
        local can = SF.CanEnhance(hero, item, opts)
        v.btn:SetEnabled(can and not destroyed)
    end
    if destroyed then
        local targets = SF.RestoreTargets(item)
        if not p.restoreIdx or p.restoreIdx > #targets then p.restoreIdx = #targets end
        local to = targets[p.restoreIdx]
        v.restoreText:SetText(string.format("파괴된 장비입니다 (%d성). 복구할 단계를 고르세요.", item.sfDestroyed or 0))
        v.targetBtn:SetText(to and (to .. "성") or "-")
        v.targetBtn:Show()
        v.restoreBtn:Show()
        local rc = to and SF.RestoreCost(to)
        v.restoreCost:SetText(rc and costText(rc, hero) or "")
        v.restoreBtn:SetEnabled(to ~= nil)
    else
        v.restoreText:SetText("")
        v.targetBtn:Hide()
        v.restoreBtn:Hide()
        v.restoreCost:SetText("")
    end
end

local function buildPotential(p)
    local v = viewFrame(p)
    v.boxes = {}
    for i, ck in ipairs(CUBE_KINDS) do
        local b = CreateFrame("Frame", nil, v)
        b:SetPoint("TOPLEFT", (i - 1) * 228, 0)
        b:SetSize(222, 218)
        b.title = W.Text(b, 13, W.COLORS.gold, "LEFT")
        b.title:SetPoint("TOPLEFT", 0, 0)
        b.title:SetText(ck.title)
        b.grade = W.Text(b, 12, W.COLORS.white, "LEFT")
        b.grade:SetPoint("TOPLEFT", 0, -20)
        b.grade:SetWidth(222)
        b.lines = {}
        for ln = 1, 3 do
            local t = W.Text(b, 11, W.COLORS.white, "LEFT")
            t:SetPoint("TOPLEFT", 6, -40 - (ln - 1) * 16)
            t:SetWidth(216)
            b.lines[ln] = t
        end
        b.chance = W.Text(b, 11, W.COLORS.gray, "LEFT")
        b.chance:SetPoint("TOPLEFT", 0, -94)
        b.chance:SetWidth(222)
        b.chance:SetJustifyV("TOP")
        b.cost = W.Text(b, 11, W.COLORS.white, "LEFT")
        b.cost:SetPoint("TOPLEFT", 0, -128)
        b.cost:SetWidth(222)
        b.btn = W.Button(b, "큐브 사용", 100, 24, function() useCube(p, ck.kind) end)
        b.btn:SetPoint("TOPLEFT", 0, -148)
        b.last = W.Text(b, 11, W.COLORS.white, "LEFT")
        b.last:SetPoint("LEFT", b.btn, "RIGHT", 8, 0)
        b.last:SetWidth(112)
        b.lock = W.Text(b, 11, W.COLORS.red, "LEFT")
        b.lock:SetPoint("TOPLEFT", 0, -180)
        b.lock:SetWidth(222)
        W.Tooltip(b.btn, function(tt)
            local hero = ns.Hero.Active()
            local item = hero and selectedItem(p, hero)
            local P = ns.Potential
            if not (item and P) then return end
            local st = item[ck.field]
            local grade = st and st.grade or 1
            tt:AddLine(string.format("%s 1번째 줄 옵션 (%s)", ck.title, P.GradeName(grade)), 1, 0.82, 0)
            local list = P.LineOptions(item.part, grade, 1) or {}
            for k, o in ipairs(list) do
                if k > 14 then tt:AddLine("...", 0.6, 0.6, 0.6) break end
                tt:AddDoubleLine(fmtStat(o[1], o[2]), string.format("%.2f%%", (o[3] or 0) / 10000), 1, 1, 1, 0.7, 0.7, 0.7)
            end
        end)
        b.kind = ck
        v.boxes[i] = b
    end
    return v
end

local function refreshPotential(p, v, hero, item)
    local P = ns.Potential
    for _, b in ipairs(v.boxes) do
        local ck = b.kind
        if not P then b.grade:SetText("잠재능력 시스템이 없습니다.") b.btn:SetEnabled(false) else
            local st = item[ck.field]
            local grade = st and st.grade or 1
            local has = st and st.lines and #st.lines > 0
            b.grade:SetText(string.format("등급  %s%s|r%s", W.Hex(W.GradeColor(grade)), P.GradeName(grade), has and "" or " |cff808080(미설정)|r"))
            for ln = 1, 3 do
                local l = has and st.lines[ln]
                b.lines[ln]:SetText(l and P.FormatLine(l) or "|cff555555-|r")
            end
            local prob, pity, done = P.GradeUpInfo(item, ck.kind)
            if (prob or 0) > 0 then
                b.chance:SetText(string.format("등급 상승 %.3f%%\n천장 %d / %d", prob / 10000, done or 0, pity or 0))
            else
                b.chance:SetText("최고 등급입니다.")
            end
            local cost = P.Cost(item, ck.kind)
            b.cost:SetText(costText(cost, hero) .. string.format("  |cff999999(보유 %s)|r", U.Comma(ns.Hero.Count(hero, ck.cube))))
            local unlocked = P.Unlocked(item, ck.kind)
            local okPay = ns.Upgrades and ns.Upgrades.CanPay(hero, cost)
            b.btn:SetEnabled(unlocked and okPay and true or false)
            if unlocked then b.lock:SetText("") else
                local need = ck.kind == "additional" and (ns.StarForce and ns.StarForce.ADDITIONAL_STAR or 12)
                    or (ns.StarForce and ns.StarForce.POTENTIAL_STAR or 3)
                b.lock:SetText(string.format("별빛 강화 %d성 이상에서 사용할 수 있습니다.", need))
            end
            b.last:SetText(p.cubeLast and p.cubeLast[ck.kind] or "")
        end
    end
end

local function buildScroll(p)
    local v = viewFrame(p)
    v.head = W.Text(v, 11, W.COLORS.white, "LEFT")
    v.head:SetPoint("TOPLEFT", 0, 0)
    v.head:SetWidth(210)
    v.innoBtn = W.Button(v, "이노센트", 70, 18, function() innocent(p) end)
    v.innoBtn:SetPoint("TOPLEFT", 212, 1)
    W.Tooltip(v.innoBtn, function(tt)
        tt:AddLine("이노센트 주문서", 1, 0.82, 0)
        tt:AddLine("주문서 강화 슬롯을 모두 초기화합니다.", 1, 1, 1)
        local c = ns.Scrolls and ns.Scrolls.Cost("innocent")
        if c then tt:AddLine("비용: " .. costText(c, ns.Hero.Active()), 0.8, 0.8, 0.8) end
    end)
    v.list = W.ScrollList(v, 270, 196, 18, function(parent)
        local r = CreateFrame("Frame", nil, parent)
        r:SetHeight(18)
        r.name = W.Text(r, 10, W.COLORS.white, "LEFT")
        r.name:SetPoint("LEFT", 2, 0)
        r.name:SetWidth(112)
        r.rate = W.Text(r, 10, W.COLORS.green, "RIGHT")
        r.rate:SetPoint("LEFT", 114, 0)
        r.rate:SetWidth(34)
        r.have = W.Text(r, 10, W.COLORS.gray, "RIGHT")
        r.have:SetPoint("LEFT", 150, 0)
        r.have:SetWidth(50)
        r.btn = W.Button(r, "사용", 42, 16)
        r.btn:SetPoint("RIGHT", -2, 0)
        r.tip = CreateFrame("Frame", nil, r)
        r.tip:SetPoint("LEFT", 0, 0)
        r.tip:SetSize(200, 18)
        r.tip:EnableMouse(true)
        return r
    end, function(r, e)
        local s = e.scroll
        r.name:SetText((e.ok and "|cffffffff" or "|cff808080") .. (s.name or s.key) .. "|r")
        r.rate:SetText(string.format("%d%%", math.floor((e.rate or 0) / 10)))
        r.have:SetText(e.have)
        r.btn:SetEnabled(e.ok and true or false)
        r.btn:SetScript("OnClick", function() useScroll(p, s.key) end)
        W.Tooltip(r.tip, function(tt)
            tt:AddLine(s.name or s.key, 1, 0.82, 0)
            tt:AddLine(string.format("성공 확률 %d%% (현재 슬롯 기준)", math.floor((e.rate or 0) / 10)), 0.3, 1, 0.3)
            local parts = {}
            for _, k in ipairs(U.Keys(s.stats or {})) do parts[#parts + 1] = fmtStat(k, s.stats[k]) end
            if #parts > 0 then tt:AddLine(table.concat(parts, ", "), 1, 1, 1, true) end
            tt:AddLine("비용: " .. costText(ns.Scrolls.Cost(s.key) or {}, ns.Hero.Active()), 0.8, 0.8, 0.8)
            if s.levelReq then tt:AddLine(string.format("캐릭터 레벨 %d 이상", s.levelReq), 0.8, 0.8, 0.8) end
            if s.onlySlot then tt:AddLine(string.format("%d번 슬롯 전용", s.onlySlot), 0.8, 0.8, 0.8) end
            if not e.ok and e.err then tt:AddLine(e.err, 1, 0.3, 0.3, true) end
        end)
    end)
    v.list:SetPoint("TOPLEFT", 0, -20)

    -- enchant (마법 부여)
    local EX = 272
    v.enTitle = W.Text(v, 12, W.COLORS.gold, "LEFT")
    v.enTitle:SetPoint("TOPLEFT", EX, 0)
    v.enTitle:SetWidth(176)
    v.enLines, v.enBtns = {}, {}
    for i = 1, MAX_SUBS do
        local t = W.Text(v, 10, W.COLORS.white, "LEFT")
        t:SetPoint("TOPLEFT", EX, -20 - (i - 1) * 18)
        t:SetWidth(132)
        v.enLines[i] = t
        local b = W.Button(v, "부여", 40, 16, function(self) enchant(p, self.line) end)
        b:SetPoint("TOPLEFT", EX + 134, -18 - (i - 1) * 18)
        b.line = i
        v.enBtns[i] = b
    end
    v.bagText = W.Text(v, 10, W.COLORS.gray, "LEFT")
    v.bagText:SetPoint("TOPLEFT", EX, -132)
    v.bagText:SetWidth(176)
    v.pouchBtns = {}
    local pouches = D.Scrolls and D.Scrolls.enchant and D.Scrolls.enchant.pouches or {}
    local short = { "하급", "중급", "상급", "최상급" }
    for i, pouch in ipairs(pouches) do
        local b = W.Button(v, short[i] or pouch.name, 86, 18, function() openPouch(p, pouch.key) end)
        b:SetPoint("TOPLEFT", EX + ((i - 1) % 2) * 89, -148 - math.floor((i - 1) / 2) * 22)
        b.key = pouch.key
        b.short = short[i] or pouch.name
        W.Tooltip(b, function(tt)
            tt:AddLine(pouch.name or pouch.key, 1, 0.82, 0)
            tt:AddLine("열면 마법 부여 주문서를 1장 얻습니다.", 1, 1, 1)
            local names = D.Scrolls.enchant.gradeNames or {}
            local gr = D.Scrolls.enchant.pouchGrades or {}
            for k, odd in ipairs(pouch.odds or {}) do
                if odd > 0 then tt:AddDoubleLine(names[gr[k] or k] or tostring(k), string.format("%.1f%%", odd / 10), 1, 1, 1, 0.7, 0.7, 0.7) end
            end
        end)
        v.pouchBtns[i] = b
    end
    return v
end

local function refreshScroll(p, v, hero, item)
    local S = ns.Scrolls
    if not S then v.head:SetText("주문서 시스템이 없습니다.") return end
    local used = item.scroll and item.scroll.slots and #item.scroll.slots or 0
    local slot = S.NextSlot(item)
    local okN = 0
    for _, s in ipairs(item.scroll and item.scroll.slots or {}) do if s.ok then okN = okN + 1 end end
    local bonus = slot and D.Scrolls and D.Scrolls.slotBonus and D.Scrolls.slotBonus[slot]
    v.head:SetText(string.format("주문서 %d / %d (성공 %d)%s", used, D.Scrolls and D.Scrolls.slots or 10, okN,
        slot and string.format(" · %d번%s", slot, bonus and string.format(" |cff40ff40+%d%%|r", bonus / 10) or "") or " · |cffff6060가득 참|r"))
    v.innoBtn:SetEnabled(used > 0)

    local rows = {}
    for i, s in ipairs(S.List()) do
        if not s.innocent then
            local ok, err = S.CanUse(hero, item, s.key)
            local wk = S.WalletKey and S.WalletKey(s.key) or s.item
            local have
            if wk then have = "보유 " .. U.FormatNumber(ns.Hero.Count(hero, wk))
            else
                local c = S.Cost(s.key) or {}
                have = "흔적 " .. U.FormatNumber(c.spellTrace or 0)
            end
            rows[#rows + 1] = { scroll = s, ok = ok, err = err, rate = slot and S.SuccessRate(s.key, slot) or 0, have = have, order = i }
        end
    end
    table.sort(rows, function(a, b)
        if (a.ok and 1 or 0) ~= (b.ok and 1 or 0) then return a.ok and true or false end
        return a.order < b.order
    end)
    v.list:SetData(rows)

    -- enchant
    local unlocked = S.EnchantUnlocked(hero)
    v.enTitle:SetText("마법 부여" .. (unlocked and "" or " |cffff6060(14-10 클리어)|r"))
    local UP = ns.Upgrades
    local _, subs = UP.ItemOptions(item)
    for i = 1, MAX_SUBS do
        local o = subs[i]
        local t, b = v.enLines[i], v.enBtns[i]
        if o then
            local stat = UP.OptStat(o)
            local en = item.scroll and item.scroll.enchant and item.scroll.enchant[i]
            t:SetText(string.format("%d. %s%s", i, UP.StatLabel(stat),
                en and en.stat and (" |cffcc88ff" .. fmtStat(en.stat, en.value or 0):gsub("^[^%+%-]*", "") .. "|r") or " |cff808080-|r"))
            b:Show()
            b:SetEnabled(unlocked and bestEnchant(hero, item, i) ~= nil)
        else
            t:SetText(i == 1 and "|cff808080부옵션이 없습니다.|r" or "")
            b:Hide()
        end
    end
    local total = 0
    if S.Bag then for _, n in pairs(S.Bag(hero)) do total = total + n end end
    v.bagText:SetText(string.format("보유 마법 부여 주문서 %d장 · 주머니 열기:", total))
    for _, b in ipairs(v.pouchBtns) do
        local n = ns.Hero.Count(hero, b.key)
        b:SetText(string.format("%s (%s)", b.short, U.FormatNumber(n)))
        b:SetEnabled(n > 0)
    end
end

local function buildElite(p)
    local v = viewFrame(p)
    v.title = W.Text(v, 14, W.COLORS.gold, "LEFT")
    v.title:SetPoint("TOPLEFT", 0, 0)
    v.title:SetWidth(RW - 90)
    v.bar = W.Bar(v, 300, 14, 0.75, 0.3, 0.9)
    v.bar:SetPoint("TOPLEFT", 0, -22)
    v.bar:EnableMouse(true)
    W.Tooltip(v.bar, function(tt)
        local hero = ns.Hero.Active()
        if not hero then return end
        local info = ns.Equipment.EliteInfo(hero)
        tt:AddLine(string.format("정예 소환 Lv.%d 장비 등급 확률", info.level), 1, 0.82, 0)
        for _, r in ipairs(info.rates or {}) do
            local rk = ns.Equipment.GradeRank(r.grade)
            local cr, cg, cb = W.GradeColor(rk)
            tt:AddDoubleLine(ns.Equipment.GradeName(r.grade) .. " " .. ns.Equipment.TierName(r.tier),
                string.format("%.2f%%", r.percent or 0), cr, cg, cb, 1, 1, 1)
        end
        tt:AddLine("포인트는 사냥으로 모입니다.", 0.7, 0.7, 0.7)
    end)
    v.info = W.Text(v, 11, W.COLORS.white, "LEFT")
    v.info:SetPoint("TOPLEFT", 0, -40)
    v.info:SetWidth(RW)
    v.sumBtn = W.Button(v, "소환", 80, 22, function() eliteSummon(p, false) end)
    v.sumBtn:SetPoint("TOPLEFT", 270, -18)
    v.sumAllBtn = W.Button(v, "모두 소환", 86, 22, function() eliteSummon(p, true) end)
    v.sumAllBtn:SetPoint("LEFT", v.sumBtn, "RIGHT", 4, 0)

    v.step = W.Text(v, 11, W.COLORS.white, "LEFT")
    v.step:SetPoint("TOPLEFT", 0, -64)
    v.step:SetWidth(264)
    v.stepBtn = W.Button(v, "단계 강화", 86, 20, function() eliteStep(p) end)
    v.stepBtn:SetPoint("TOPLEFT", 270, -60)
    v.lvText = W.Text(v, 11, W.COLORS.white, "LEFT")
    v.lvText:SetPoint("TOPLEFT", 0, -88)
    v.lvText:SetWidth(264)
    v.lvBtn = W.Button(v, "레벨업", 86, 20, function() eliteLevelUp(p) end)
    v.lvBtn:SetPoint("TOPLEFT", 270, -84)
    v.timer = W.Text(v, 12, W.COLORS.gold, "LEFT")
    v.timer:SetPoint("TOPLEFT", 0, -112)
    v.timer:SetWidth(264)
    v.skipBtn = W.Button(v, "시간 단축", 86, 20, function() eliteSkip(p) end)
    v.skipBtn:SetPoint("TOPLEFT", 270, -108)

    v.autoEq = CreateFrame("CheckButton", nil, v, "UICheckButtonTemplate")
    v.autoEq:SetSize(22, 22)
    v.autoEq:SetPoint("TOPLEFT", 0, -134)
    v.autoEqText = W.Text(v, 11, W.COLORS.white, "LEFT")
    v.autoEqText:SetPoint("LEFT", v.autoEq, "RIGHT", 2, 0)
    v.autoEqText:SetText("획득 시 자동 장착")
    v.autoEq:SetScript("OnClick", function(self)
        local hero = ns.Hero.Active()
        local s = hero and hero.equipment and hero.equipment.settings
        if s then s.autoEquip = self:GetChecked() and true or false end
        refreshNow()
    end)
    v.autoDisBtn = W.Button(v, "", 150, 20, function()
        local hero = ns.Hero.Active()
        local s = hero and hero.equipment and hero.equipment.settings
        if not s then return end
        local n = D.EquipLabels and #D.EquipLabels.gradeOrder or 8
        s.autoDismantleRank = ((s.autoDismantleRank or 0) + 1) % n   -- 0 = off .. n-1
        refreshNow()
    end)
    v.autoDisBtn:SetPoint("TOPLEFT", 160, -134)

    v.lootTitle = W.Text(v, 11, W.COLORS.gray, "LEFT")
    v.lootTitle:SetPoint("TOPLEFT", 0, -164)
    v.loot = {}
    for i = 1, 14 do
        local ic = W.Icon(v, 26)
        ic:SetPoint("TOPLEFT", (i - 1) * 30, -180)
        ic:SetScript("OnClick", function(self)
            if self.item then p.selectedId = self.item.id; p.view = "info" end
            refreshNow()
        end)
        W.Tooltip(ic, function(tt, self) itemTooltip(tt, self.item, ns.Hero.Active()) end)
        ic:Hide()
        v.loot[i] = ic
    end

    -- live level-up timer
    v.elapsed = 0
    v:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + (elapsed or 0)
        if self.elapsed < 0.5 then return end
        self.elapsed = 0
        local hero = ns.Hero.Active()
        if not (hero and self.endsAt) then return end
        local left = self.endsAt - U.Now()
        if left <= 0 then
            self.endsAt = nil
            refreshNow()
        else
            self.timer:SetText("레벨업 중 · 남은 시간 " .. U.FormatDuration(left))
        end
    end)
    return v
end

local function refreshElite(p, v, hero)
    local E = ns.Equipment
    local ok, info = pcall(E.EliteInfo, hero)
    if not ok or not info then v.title:SetText("정예 소환 정보를 불러오지 못했습니다.") return end
    v.title:SetText(string.format("정예 몬스터 소환  |cffffffffLv.%d|r |cff999999/ %d|r  · 소환 %s회", info.level, info.maxLevel,
        U.Comma(info.summons or 0)))
    local gauge = math.max(1, info.gauge or 1)
    v.bar:SetValue(math.min(1, (info.points or 0) / gauge))
    v.bar.text:SetText(string.format("%s / %s", U.Comma(info.points or 0), U.Comma(info.gauge or 0)))
    v.info:SetText(string.format("1회 %s포인트 · 처치 시 장비 %d개 · 동시 %d마리 · 가방 %d / %d", U.Comma(info.cost or 0),
        info.drops or 0, info.simultaneous or 1, E.ItemCount(hero), E.BAG_SIZE or 0))
    local canSummon = (info.points or 0) >= (info.cost or 0)
    v.sumBtn:SetEnabled(canSummon)
    v.sumAllBtn:SetEnabled(canSummon)
    local maxed = info.level >= info.maxLevel
    if maxed then
        v.step:SetText("|cffffd100최대 레벨입니다.|r")
        v.lvText:SetText("")
    else
        v.step:SetText(string.format("강화 단계 %d / %d · 단계당 %s", info.step or 0, info.steps or 0,
            costText({ gearStone = info.stepCost or 0 }, hero)))
        v.lvText:SetText(string.format("레벨업 %s · 대기 %s", costText({ meso = info.meso or 0 }, hero), U.FormatDuration(info.delay or 0)))
    end
    v.stepBtn:SetEnabled(info.canStep and true or false)
    v.lvBtn:SetEnabled(info.canLevelUp and true or false)
    if info.upgradeEndsAt then
        v.endsAt = info.upgradeEndsAt
        v.timer:SetText("레벨업 중 · 남은 시간 " .. U.FormatDuration(math.max(0, info.upgradeEndsAt - U.Now())))
        v.skipBtn:Show()
        v.skipBtn:SetText(string.format("단축 (%s)", U.FormatNumber(ns.Hero.Count(hero, "timeSkip1m"))))
        v.skipBtn:SetEnabled(ns.Hero.Count(hero, "timeSkip1m") > 0)
    else
        v.endsAt = nil
        v.timer:SetText("")
        v.skipBtn:Hide()
    end
    local s = hero.equipment and hero.equipment.settings or {}
    v.autoEq:SetChecked(s.autoEquip and true or false)
    local rank = s.autoDismantleRank or 0
    local order = D.EquipLabels and D.EquipLabels.gradeOrder or {}
    v.autoDisBtn:SetText(rank > 0 and ("자동 분해: " .. E.GradeName(order[rank] or "") .. " 이하") or "자동 분해: 끔")

    local loot = {}
    for _, it in ipairs(p.eliteLoot or {}) do
        if E.Get(hero, it.id) then loot[#loot + 1] = it end
    end
    v.lootTitle:SetText(#loot > 0 and "최근 획득 장비" or "|cff808080최근 획득 장비 없음|r")
    for i, ic in ipairs(v.loot) do
        local it = loot[i]
        ic.item = it
        if it then
            ic.icon:SetTexture(gearIcon(hero, it))
            W.SetBorderGrade(ic, rankOf(it))
            ic:Show()
        else
            ic:Hide()
        end
    end
end

---------------------------------------------------------------------------
-- panel
---------------------------------------------------------------------------
UI.RegisterPanel("equipment", {
    title = "장비", order = 36,
    build = function(p)
        if not ns.Equipment then
            local t = W.Text(p, 13, W.COLORS.red, "LEFT")
            t:SetPoint("TOPLEFT", 4, -4)
            t:SetText("장비 시스템을 불러오지 못했습니다.")
            return
        end
        p.view = "info"
        p.dismRank = 2
        p.sfPreventDown, p.sfPreventDestroy = false, false
        buildDoll(p)
        buildBag(p)
        local vbox = W.InfoCard(p, 962 - RX + 12, 406, { plain = true })
        vbox:SetPoint("TOPLEFT", RX - 12, 0)
        p.viewBox = vbox
        local labels = {}
        for i, def in ipairs(VIEWS) do labels[i] = def.label end
        p.viewTabs = W.Tabs(p, labels, 86, 24, function(i)
            p.view = VIEWS[i].key
            refreshNow()
        end)
        p.viewTabs:SetPoint("TOPLEFT", RX - 2, -12)
        for _, b in ipairs(p.viewTabs.buttons) do b:SetFrameLevel(vbox:GetFrameLevel() + 5) end
        p.views = {
            info = buildInfo(p), sf = buildStarForce(p), pot = buildPotential(p),
            scroll = buildScroll(p), elite = buildElite(p),
        }
        p.noItem = W.Text(vbox, 12, W.COLORS.gray, "CENTER")
        p.noItem:SetPoint("TOPLEFT", 12, -90)
        p.noItem:SetWidth(RW)
        p.noItem:SetText("장비를 선택하세요.\n정예 소환으로 장비를 얻을 수 있습니다.")
        p.noItem:Hide()
    end,

    refresh = function(p, hero)
        local E = ns.Equipment
        if not (E and p.slots) then return end
        local item = selectedItem(p, hero)

        -- paper doll
        for part, s in pairs(p.slots) do
            local it = E.Equipped(hero, part)
            if it then
                s.icon:SetTexture(gearIcon(hero, it))
                s.icon:SetDesaturated(ns.StarForce and ns.StarForce.IsDestroyed and ns.StarForce.IsDestroyed(it) or false)
                W.SetBorderGrade(s, rankOf(it))
                s.count:SetText((it.star or 0) > 0 and ("★" .. it.star) or "")
            else
                s.icon:SetTexture(emptyTex(part))
                s.icon:SetDesaturated(false)
                W.SetBorderGrade(s, nil)
                s.count:SetText("")
            end
            if (item and it and item.id == it.id) or (p.filter == part) then s.sel:Show() else s.sel:Hide() end
        end

        -- bag
        local list = {}
        for _, it in ipairs(E.Items(hero, p.filter)) do
            list[#list + 1] = { item = it, equipped = E.IsEquipped(hero, it), rank = rankOf(it) }
        end
        table.sort(list, function(a, b)
            if a.equipped ~= b.equipped then return a.equipped end
            if a.rank ~= b.rank then return a.rank > b.rank end
            if a.item.tier ~= b.item.tier then return (a.item.tier or 0) > (b.item.tier or 0) end
            if (a.item.level or 0) ~= (b.item.level or 0) then return (a.item.level or 0) > (b.item.level or 0) end
            return a.item.id > b.item.id
        end)
        local rows = {}
        for i, e in ipairs(list) do
            local r = math.floor((i - 1) / BAG_COLS) + 1
            rows[r] = rows[r] or {}
            rows[r][#rows[r] + 1] = e
        end
        p.bag:SetData(rows)
        if not p.modelReady and p.model then
            p.modelReady = true
            pcall(p.model.SetUnit, p.model, "player")
            pcall(p.model.SetFacing, p.model, math.rad(15))
            if ns.BattleView and ns.BattleView.ApplyLooks then ns.BattleView.ApplyLooks(p.model) end
        end
        p.bagCount:SetText(string.format("|cffffffff%d|r / %d", E.ItemCount(hero), E.BAG_SIZE or 0))
        p.filterBtn:SetText(p.filter and E.PartName(p.filter) or "전체")
        local order = D.EquipLabels and D.EquipLabels.gradeOrder or {}
        p.rankBtn:SetText(E.GradeName(order[p.dismRank] or "") .. " 이하")

        -- right side
        for i, def in ipairs(VIEWS) do
            if def.key == p.view and p.viewTabs.index ~= i then p.viewTabs:Select(i) end
        end
        for key, v in pairs(p.views) do
            if key ~= p.view then v:Hide() end
        end
        local v = p.views[p.view]
        if p.view == "elite" then
            p.noItem:Hide()
            v:Show()
            refreshElite(p, v, hero)
        elseif not item then
            v:Hide()
            p.noItem:Show()
        else
            p.noItem:Hide()
            v:Show()
            if p.view == "info" then refreshInfo(p, v, hero, item)
            elseif p.view == "sf" then refreshStarForce(p, v, hero, item)
            elseif p.view == "pot" then refreshPotential(p, v, hero, item)
            elseif p.view == "scroll" then refreshScroll(p, v, hero, item) end
        end
    end,
})
